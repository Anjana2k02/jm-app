import 'dart:async';

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_model.dart';
import '../models/session_model.dart';
import '../models/session_song_model.dart';
import '../models/template_item.dart';
import '../models/template_model.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/template_service.dart';
import '../utils/chord_detector.dart';
import '../utils/clipboard_to_delta_converter.dart';

// Search result type
enum SearchResultType { document, session, template }

class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
  });

  final SearchResultType type;
  final String id;
  final String title;
  final String? subtitle;
}

class WorkspaceController extends ChangeNotifier {
  WorkspaceController() {
    _client = Supabase.instance.client;
    _documentService = DocumentService(_client);
    _templateService = TemplateService(_client);
    _storageService = StorageService(_client);
    _sessionService = SessionService(_client);
    loadAll();
  }

  late final SupabaseClient _client;
  late final DocumentService _documentService;
  late final TemplateService _templateService;
  late final StorageService _storageService;
  late final SessionService _sessionService;

  // Documents + templates
  List<AppDocument> documents = [];
  List<Template> templates = [];
  List<TemplateItem> templateItems = [];
  Template? activeTemplate;
  AppDocument? selectedDocument;
  QuillController? quillController;
  bool loading = true;
  bool saving = false;
  String? loadError; // non-null when the last loadAll() had a fetch failure

  Timer? _autoSaveTimer;

  // ─── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    quillController?.dispose();
    super.dispose();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), saveDocument);
  }

  // Sessions
  List<JamSession> sessions = [];

  SupabaseClient get client => _client;
  StorageService get storageService => _storageService;
  SessionService get sessionService => _sessionService;

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      // No authenticated user — clear loading so the UI doesn't hang.
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    loadError = null;
    notifyListeners();

    try {
      // Fetch all three collections in parallel.
      // Each has its own error handler so a single failing table
      // (e.g. sessions not yet created in Supabase) doesn't block the rest.
      final docsFuture = _documentService.fetchDocuments(user.id).catchError((
        Object e,
      ) {
        loadError = 'Could not load documents: $e';
        return <AppDocument>[];
      });

      final templatesFuture = _templateService
          .fetchTemplates(user.id)
          .catchError((Object e) {
            loadError ??= 'Could not load templates: $e';
            return <Template>[];
          });

      final sessionsFuture = _sessionService.fetchSessions(user.id).catchError((
        Object e,
      ) {
        loadError ??= 'Could not load sessions: $e';
        return <JamSession>[];
      });

      final results = await Future.wait([
        docsFuture,
        templatesFuture,
        sessionsFuture,
      ], eagerError: false);

      documents = results[0] as List<AppDocument>;
      templates = results[1] as List<Template>;
      sessions = results[2] as List<JamSession>;

      selectedDocument = documents.isNotEmpty ? documents.first : null;
      quillController = selectedDocument == null
          ? null
          : _makeController(selectedDocument!.content);

      if (activeTemplate != null) {
        await _loadTemplateItems(activeTemplate!);
      }
    } catch (e) {
      loadError = 'Unexpected error: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ─── Template helpers ─────────────────────────────────────────────────────

  Future<void> _loadTemplateItems(Template template) async {
    final items = await _templateService.fetchTemplateItems(template.id);
    templateItems = items;
    notifyListeners();
    await _ensureTemplateItems(template, items);
  }

  Future<void> _ensureTemplateItems(
    Template template,
    List<TemplateItem> items,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existingIds = items.map((i) => i.documentId).toSet();
    final missing = documents
        .where((d) => !existingIds.contains(d.id))
        .map((d) => d.id)
        .toList();

    if (missing.isEmpty) return;

    final updatedOrder = [...orderedDocumentIds(), ...missing];
    await _templateService.upsertTemplateOrder(
      userId: user.id,
      templateId: template.id,
      documentIds: updatedOrder,
    );

    final refreshed = await _templateService.fetchTemplateItems(template.id);
    templateItems = refreshed;
    notifyListeners();
  }

  List<String> orderedDocumentIds() {
    if (activeTemplate == null) {
      return documents.map((d) => d.id).toList();
    }
    return templateItems.map((i) => i.documentId).toList();
  }

  List<AppDocument> orderedDocuments() {
    if (activeTemplate == null) return documents;

    final map = {for (final d in documents) d.id: d};
    final ordered = <AppDocument>[];
    for (final item in templateItems) {
      final doc = map[item.documentId];
      if (doc != null) ordered.add(doc);
    }
    for (final doc in documents) {
      if (!ordered.contains(doc)) ordered.add(doc);
    }
    return ordered;
  }

  Document _documentFromContent(List<dynamic> content) {
    if (content.isEmpty) return Document()..insert(0, '');
    return Document.fromJson(content);
  }

  /// Creates a [QuillController] pre-configured with the chord-aware paste hook
  /// and a 2-second debounced auto-save listener.
  QuillController _makeController(List<dynamic> content) {
    final ctrl = QuillController(
      document: _documentFromContent(content),
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onClipboardPaste: _handleSmartPaste,
        ),
      ),
    );
    ctrl.document.changes.listen((_) => _scheduleAutoSave());
    return ctrl;
  }

  /// Intercepts clipboard paste to detect chord sheets and apply monospace
  /// formatting so chord alignment is preserved.
  ///
  /// Returns `true` if the paste was handled (chord sheet detected), or
  /// `false` to fall through to flutter_quill's default paste pipeline.
  Future<bool> _handleSmartPaste() async {
    final controller = quillController;
    if (controller == null) return false;

    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipData?.text;
    if (text == null || text.trim().isEmpty) return false;

    if (!ChordDetector.looksLikeChordSheet(text)) return false;

    final delta = ClipboardToDeltaConverter.fromPlainText(text);
    final sel = controller.selection;
    controller.replaceText(
      sel.start,
      sel.end - sel.start,
      delta,
      TextSelection.collapsed(offset: sel.start),
    );
    return true;
  }

  // ─── Documents ────────────────────────────────────────────────────────────

  Future<void> createDocument(
    String title, [
    SongType songType = SongType.song,
  ]) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final document = await _documentService.createDocument(
      userId: user.id,
      title: title.trim(),
      songType: songType,
    );

    documents = [...documents, document];
    selectedDocument = document;
    quillController = _makeController(document.content);
    notifyListeners();

    if (activeTemplate != null) {
      await _loadTemplateItems(activeTemplate!);
    }
  }

  void selectDocument(AppDocument document) {
    if (selectedDocument?.id == document.id) return;

    selectedDocument = document;
    quillController = _makeController(document.content);
    notifyListeners();
  }

  Future<void> renameDocument(String newTitle) async {
    final document = selectedDocument;
    if (document == null || newTitle.trim().isEmpty) return;

    final trimmed = newTitle.trim();
    final updated = document.copyWith(
      title: trimmed,
      updatedAt: DateTime.now(),
    );

    await _documentService.updateDocument(
      documentId: document.id,
      title: trimmed,
      content: document.content,
    );

    selectedDocument = updated;
    documents = documents
        .map((d) => d.id == document.id ? updated : d)
        .toList();
    notifyListeners();
  }

  Future<void> saveDocument() async {
    final document = selectedDocument;
    final controller = quillController;
    if (document == null || controller == null) return;

    saving = true;
    notifyListeners();

    await _documentService.updateDocument(
      documentId: document.id,
      title: document.title,
      content: controller.document.toDelta().toJson(),
    );

    documents = documents.map((d) {
      if (d.id == document.id) {
        return d.copyWith(
          content: controller.document.toDelta().toJson(),
          updatedAt: DateTime.now(),
        );
      }
      return d;
    }).toList();
    saving = false;
    notifyListeners();
  }

  /// Saves song metadata (key, bpm, duration) for the currently selected song.
  /// Accepts a map of DB column names → values (null clears the field).
  Future<void> updateSongMeta(Map<String, dynamic> fields) async {
    final doc = selectedDocument;
    if (doc == null) return;

    await _documentService.updateSongMeta(documentId: doc.id, fields: fields);

    final updated = doc.copyWith(
      songKey: fields.containsKey('song_key')
          ? (fields['song_key'] as String?)
          : doc.songKey,
      bpm: fields.containsKey('bpm') ? (fields['bpm'] as int?) : doc.bpm,
      durationSeconds: fields.containsKey('duration_seconds')
          ? (fields['duration_seconds'] as int?)
          : doc.durationSeconds,
      clearSongKey:
          fields['song_key'] == null && fields.containsKey('song_key'),
      clearBpm: fields['bpm'] == null && fields.containsKey('bpm'),
      clearDuration:
          fields['duration_seconds'] == null &&
          fields.containsKey('duration_seconds'),
    );

    selectedDocument = updated;
    documents = documents.map((d) => d.id == doc.id ? updated : d).toList();
    notifyListeners();
  }

  Future<void> deleteDocument(String documentId) async {
    await _documentService.deleteDocument(documentId);
    if (selectedDocument?.id == documentId) {
      selectedDocument = null;
      quillController?.dispose();
      quillController = null;
    }
    documents = documents.where((d) => d.id != documentId).toList();
    notifyListeners();
  }

  Future<void> reorderDocuments(int oldIndex, int newIndex) async {
    if (activeTemplate == null) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    final ids = orderedDocumentIds();
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    await _templateService.upsertTemplateOrder(
      userId: user.id,
      templateId: activeTemplate!.id,
      documentIds: ids,
    );

    final refreshed = await _templateService.fetchTemplateItems(
      activeTemplate!.id,
    );
    templateItems = refreshed;
    notifyListeners();
  }

  // ─── Templates ────────────────────────────────────────────────────────────

  Future<void> createTemplate(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final template = await _templateService.createTemplate(
      userId: user.id,
      name: name.trim(),
    );

    templates = [...templates, template];
    activeTemplate = template;
    notifyListeners();

    await _loadTemplateItems(template);
  }

  Future<void> switchTemplate(Template? template) async {
    activeTemplate = template;
    templateItems = [];
    notifyListeners();

    if (template != null) {
      await _loadTemplateItems(template);
    }
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────

  Future<void> createSession(String name, DateTime? date, String notes) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final session = await _sessionService.createSession(
      userId: user.id,
      name: name.trim(),
      sessionDate: date,
      notes: notes,
    );

    sessions = [...sessions, session];
    // Re-sort by session_date ASC, nulls last
    sessions.sort((a, b) {
      if (a.sessionDate == null && b.sessionDate == null) return 0;
      if (a.sessionDate == null) return 1;
      if (b.sessionDate == null) return -1;
      return a.sessionDate!.compareTo(b.sessionDate!);
    });
    notifyListeners();
  }

  Future<void> updateSession(
    JamSession updated, {
    bool clearDate = false,
  }) async {
    await _sessionService.updateSession(
      sessionId: updated.id,
      name: updated.name,
      sessionDate: updated.sessionDate,
      clearDate: clearDate,
      notes: updated.notes,
    );
    sessions = sessions.map((s) => s.id == updated.id ? updated : s).toList();
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionService.deleteSession(sessionId);
    sessions = sessions.where((s) => s.id != sessionId).toList();
    notifyListeners();
  }

  Future<List<SessionSong>> loadSessionSongs(String sessionId) async {
    return _sessionService.fetchSessionSongs(sessionId);
  }

  // ─── Upcoming sessions (date >= today) ───────────────────────────────────

  List<JamSession> get upcomingSessions {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return sessions
        .where(
          (s) => s.sessionDate != null && !s.sessionDate!.isBefore(todayDate),
        )
        .toList();
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  List<SearchResult> searchAll(String query) {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();
    final results = <SearchResult>[];

    for (final doc in documents) {
      if (doc.title.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.document,
            id: doc.id,
            title: doc.title.isEmpty ? 'Untitled' : doc.title,
            subtitle: 'Document',
          ),
        );
      }
    }

    for (final session in sessions) {
      if (session.name.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.session,
            id: session.id,
            title: session.name,
            subtitle: session.sessionDate != null
                ? 'Session · ${_formatDate(session.sessionDate!)}'
                : 'Session',
          ),
        );
      }
    }

    for (final template in templates) {
      if (template.name.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.template,
            id: template.id,
            title: template.name,
            subtitle: 'Template',
          ),
        );
      }
    }

    return results;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await AuthService(_client).signOut();
  }
}
