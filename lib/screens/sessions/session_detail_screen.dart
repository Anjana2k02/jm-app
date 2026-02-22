import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/document_model.dart';
import '../../models/session_model.dart';
import '../../models/session_song_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptics.dart';
import '../../widgets/glass_dialog.dart';
import '../../widgets/dismissible_container.dart';
import '../../widgets/song_card.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.controller,
    required this.session,
  });

  final WorkspaceController controller;
  final JamSession session;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late JamSession _session;
  List<SessionSong> _songs = [];
  bool _loadingSongs = true;
  bool _sidebarVisible = true; // togglable on mobile only
  int _selectedIndex = 0;
  QuillController? _quillController;
  double _sheetScale = 1.0;
  double _baseSheetScale = 1.0;

  static const double _minSheetScale = 0.8;
  static const double _maxSheetScale = 2.0;

  WorkspaceController get _ws => widget.controller;

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadSongs();
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadSongs() async {
    setState(() => _loadingSongs = true);
    final songs = await _ws.loadSessionSongs(_session.id);
    if (!mounted) return;
    setState(() {
      _songs = songs;
      _loadingSongs = false;
      if (_songs.isNotEmpty) {
        _selectedIndex = _selectedIndex.clamp(0, _songs.length - 1);
        _rebuildController();
      } else {
        _selectedIndex = 0;
        _quillController?.dispose();
        _quillController = null;
      }
    });
  }

  void _rebuildController() {
    _quillController?.dispose();
    _quillController = null;
    final doc = _selectedDoc;
    if (doc == null) return;
    final quillDoc = doc.content.isEmpty
        ? Document()
        : Document.fromJson(doc.content);
    _quillController = QuillController(
      document: quillDoc,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  void _resetSheetScale() {
    _sheetScale = 1.0;
    _baseSheetScale = 1.0;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _baseSheetScale = _sheetScale;
    HapticsManager.dragStartFeedback();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    final nextScale = (_baseSheetScale * details.scale).clamp(
      _minSheetScale,
      _maxSheetScale,
    );
    if (nextScale == _sheetScale) return;
    setState(() => _sheetScale = nextScale);
    // Light haptic on every scale change
    HapticsManager.dragContinuousFeedback();
  }

  void _bumpSheetScale(double delta) {
    final nextScale = (_sheetScale + delta).clamp(
      _minSheetScale,
      _maxSheetScale,
    );
    if (nextScale == _sheetScale) return;
    setState(() => _sheetScale = nextScale);
    // Haptic feedback for keyboard zoom
    HapticsManager.zoomFeedback();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (!keys.contains(LogicalKeyboardKey.controlLeft) &&
        !keys.contains(LogicalKeyboardKey.controlRight)) {
      return;
    }

    // Ctrl + mouse wheel zooms in/out on desktop
    final delta = event.scrollDelta.dy > 0 ? -0.1 : 0.1;
    _bumpSheetScale(delta);
  }

  AppDocument? get _selectedDoc {
    if (_songs.isEmpty || _selectedIndex >= _songs.length) return null;
    final docId = _songs[_selectedIndex].documentId;
    try {
      return _ws.documents.firstWhere((d) => d.id == docId);
    } catch (_) {
      return null;
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _selectSong(int index) {
    if (_selectedIndex == index && _quillController != null) return;
    setState(() {
      _resetSheetScale();
      _selectedIndex = index;
      _rebuildController();
    });
  }

  void _goToPrev() {
    if (_selectedIndex > 0) _selectSong(_selectedIndex - 1);
  }

  void _goToNext() {
    if (_selectedIndex < _songs.length - 1) _selectSong(_selectedIndex + 1);
  }

  // ─── Song Management ───────────────────────────────────────────────────────

  Future<void> _reorderSongs(int oldIndex, int newIndex) async {
    HapticsManager.dragStartFeedback();

    final user = _ws.client.auth.currentUser;
    if (user == null) return;

    final list = List<SessionSong>.from(_songs);
    if (newIndex > oldIndex) newIndex -= 1;

    // Track the selected song through the reorder
    final selectedDocId = _songs.isNotEmpty
        ? _songs[_selectedIndex].documentId
        : null;

    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);

    int newSelected = _selectedIndex;
    if (selectedDocId != null) {
      final idx = list.indexWhere((s) => s.documentId == selectedDocId);
      if (idx != -1) newSelected = idx;
    }

    setState(() {
      _songs = list;
      _selectedIndex = newSelected;
    });

    // Haptic feedback when reorder completes
    HapticsManager.dragEndFeedback();

    await _ws.sessionService.upsertSessionSongOrder(
      userId: user.id,
      sessionId: _session.id,
      documentIds: list.map((s) => s.documentId).toList(),
    );
  }

  Future<bool> _confirmRemoveSong(SessionSong song) async {
    AppDocument? doc;
    try {
      doc = _ws.documents.firstWhere((d) => d.id == song.documentId);
    } catch (_) {}

    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        title: const Text('Remove from session?'),
        content: Text(
          'Remove "${doc?.title ?? 'this song'}" from this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _removeSong(SessionSong song) async {
    HapticsManager.dismissFeedback();
    await _ws.sessionService.removeSongFromSession(
      sessionId: _session.id,
      documentId: song.documentId,
    );
    await _loadSongs();
  }

  Future<void> _showAddSongsSheet() async {
    final existingIds = _songs.map((s) => s.documentId).toSet();
    final available = _ws.documents
        .where((d) => !existingIds.contains(d.id))
        .toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All songs are already in this session'),
          ),
        );
      }
      return;
    }

    final selected = <String>{};
    const kSong = Color(0xFF7C3AED);
    const kMedley = Color(0xFF2563EB);

    await showGlassBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.92,
          minChildSize: 0.35,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Builder(
                builder: (ctx2) {
                  final isDark2 = Theme.of(ctx2).brightness == Brightness.dark;
                  return Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark2 ? kGlassDarkBorder : kGlassLightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Add Songs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Song chips
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: available.map((doc) {
                      final isSel = selected.contains(doc.id);
                      final isMedley = doc.songType == SongType.medley;
                      final accent = isMedley ? kMedley : kSong;

                      return GestureDetector(
                        onTap: () => setSheet(() {
                          if (isSel) {
                            selected.remove(doc.id);
                          } else {
                            selected.add(doc.id);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? accent
                                : accent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSel
                                  ? Colors.transparent
                                  : accent.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.40),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMedley
                                    ? Icons.queue_music_rounded
                                    : Icons.music_note_rounded,
                                size: 14,
                                color: isSel
                                    ? Colors.white
                                    : accent.withValues(alpha: 0.80),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                doc.title.isEmpty ? 'Untitled' : doc.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : accent.withValues(alpha: 0.90),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Add button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      selected.isEmpty
                          ? 'Select songs to add'
                          : 'Add ${selected.length} song${selected.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected.isEmpty || !mounted) return;

    final user = _ws.client.auth.currentUser;
    if (user == null) return;

    for (int i = 0; i < selected.length; i++) {
      await _ws.sessionService.addSongToSession(
        userId: user.id,
        sessionId: _session.id,
        documentId: selected.elementAt(i),
        sortOrder: _songs.length + i,
      );
    }
    await _loadSongs();
  }

  // ─── Session Edit / Delete ─────────────────────────────────────────────────

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _session.name);
    final notesCtrl = TextEditingController(text: _session.notes);
    DateTime? selectedDate = _session.sessionDate;
    bool clearDate = false;

    final result = await showGlassDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.transparent,
          title: const Text('Edit session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Session name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? _formatDate(selectedDate!)
                            : 'No date set',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) {
                          setDialogState(() {
                            selectedDate = d;
                            clearDate = false;
                          });
                        }
                      },
                      child: const Text('Pick date'),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear date',
                        onPressed: () => setDialogState(() {
                          selectedDate = null;
                          clearDate = true;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final updated = _session.copyWith(
      name: nameCtrl.text.trim(),
      sessionDate: selectedDate,
      clearDate: clearDate,
      notes: notesCtrl.text,
    );
    await _ws.updateSession(updated, clearDate: clearDate);
    if (mounted) setState(() => _session = updated);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        title: const Text('Delete session?'),
        content: Text(
          'This will permanently delete "${_session.name}" and its setlist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _ws.deleteSession(_session.id);
    if (!mounted) return;
    if (ok) Navigator.of(context).pop();
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

  /// Sum of durationSeconds for all songs in the session that have a duration.
  String? get _totalDurationLabel {
    int total = 0;
    for (final song in _songs) {
      try {
        final doc = _ws.documents.firstWhere((d) => d.id == song.documentId);
        total += doc.durationSeconds ?? 0;
      } catch (_) {}
    }
    if (total <= 0) return null;
    final m = total ~/ 60;
    final s = total % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_session.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _showEditDialog();
              if (v == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit session')),
              PopupMenuItem(value: 'delete', child: Text('Delete session')),
            ],
          ),
        ],
      ),
      body: _isMobile ? _buildMobileBody() : _buildDesktopBody(),
    );
  }

  // ─── Desktop layout: sidebar always visible ────────────────────────────────

  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 280, child: _buildSidebar(showCollapseButton: false)),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildContentArea()),
      ],
    );
  }

  // ─── Mobile layout: sidebar as overlay with tap-outside-to-dismiss ──────────

  Widget _buildMobileBody() {
    final cs = Theme.of(context).colorScheme;
    final sidebarWidth = MediaQuery.of(context).size.width * 0.78;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Content always fills full width underneath
        _buildContentArea(),

        // Dim scrim — tap anywhere outside the sidebar to close it
        if (_sidebarVisible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _sidebarVisible = false),
              child: const ColoredBox(color: Color(0x55000000)),
            ),
          ),

        // Sidebar overlay
        if (_sidebarVisible)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: sidebarWidth,
            child: _buildSidebar(showCollapseButton: true),
          ),

        // Expand handle — shown when sidebar is hidden
        if (!_sidebarVisible)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _sidebarVisible = true),
                child: Container(
                  width: 28,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    border: Border.all(color: cs.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar({required bool showCollapseButton}) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? kSidebarDark : kSidebarLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Add Songs + optional collapse button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _showAddSongsSheet,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text('Add Songs'),
                      ],
                    ),
                  ),
                ),
                if (showCollapseButton) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    tooltip: 'Collapse sidebar',
                    onPressed: () => setState(() => _sidebarVisible = false),
                  ),
                ],
              ],
            ),
          ),
          if (_totalDurationLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Total: $_totalDurationLabel',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, thickness: 1),

          // Song list
          Expanded(
            child: _loadingSongs
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 40,
                            color: cs.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No songs yet',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add Songs" above.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    itemCount: _songs.length,
                    onReorder: _reorderSongs,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (_, __) {
                          final t = Curves.easeOut.transform(animation.value);
                          return Transform.scale(
                            scale: 1.0 + t * 0.03,
                            child: Material(
                              color: Colors.transparent,
                              elevation: 12 * t,
                              shadowColor: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (ctx, i) {
                      final song = _songs[i];
                      final cs = Theme.of(ctx).colorScheme;
                      AppDocument? doc;
                      try {
                        doc = _ws.documents.firstWhere(
                          (d) => d.id == song.documentId,
                        );
                      } catch (_) {}

                      if (doc == null) {
                        return SizedBox.shrink(key: ValueKey(song.documentId));
                      }

                      return Dismissible(
                        key: ValueKey(song.documentId),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmRemoveSong(song),
                        onDismissed: (_) => _removeSong(song),
                        background: buildDismissibleBackground(
                          context,
                          label: 'Remove',
                          icon: Icons.delete_outline,
                        ),
                        child: ReorderableDelayedDragStartListener(
                          index: i,
                          child: SongCard(
                            key: ValueKey('card_${song.documentId}'),
                            document: doc,
                            isSelected: _selectedIndex == i,
                            onTap: () => _selectSong(i),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Main content area ─────────────────────────────────────────────────────

  Widget _buildContentArea() {
    final cs = Theme.of(context).colorScheme;

    if (_loadingSongs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No songs in this session',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add songs using the sidebar.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final doc = _selectedDoc;
    final controller = _quillController;

    if (doc == null || controller == null) {
      return Center(
        child: Text(
          'Song not found.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title row — meta chips aligned to the right
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  doc.title.isEmpty ? 'Untitled' : doc.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (doc.songKey != null ||
                  doc.bpm != null ||
                  doc.durationLabel != null) ...[
                const SizedBox(width: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (doc.songKey != null)
                      _MetaChip(
                        icon: Icons.piano_outlined,
                        label: doc.songKey!,
                        cs: cs,
                      ),
                    if (doc.bpm != null)
                      _MetaChip(
                        icon: Icons.speed_outlined,
                        label: '${doc.bpm} BPM',
                        cs: cs,
                      ),
                    if (doc.durationLabel != null)
                      _MetaChip(
                        icon: Icons.timer_outlined,
                        label: doc.durationLabel!,
                        cs: cs,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Song counter + Prev / Next in one row
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 8, 10),
          child: Row(
            children: [
              Text(
                'Song ${_selectedIndex + 1} of ${_songs.length}',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectedIndex > 0 ? _goToPrev : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Prev'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _selectedIndex < _songs.length - 1
                    ? _goToNext
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Next'),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Read-only Quill content (scrollable independently)
        Expanded(
          child: FocusableActionDetector(
            autofocus: true,
            shortcuts: {
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.equal,
              ): const _ZoomIntent(
                0.1,
              ),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.add):
                  const _ZoomIntent(0.1),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.numpadAdd,
              ): const _ZoomIntent(
                0.1,
              ),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.minus,
              ): const _ZoomIntent(
                -0.1,
              ),
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.numpadSubtract,
              ): const _ZoomIntent(
                -0.1,
              ),
            },
            actions: {
              _ZoomIntent: CallbackAction<_ZoomIntent>(
                onInvoke: (intent) {
                  _bumpSheetScale(intent.delta);
                  return null;
                },
              ),
            },
            child: Listener(
              onPointerSignal: _handlePointerSignal,
              child: GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                behavior: HitTestBehavior.opaque,
                child: ClipRect(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Transform.scale(
                      alignment: Alignment.topLeft,
                      scale: _sheetScale,
                      child: QuillEditor.basic(
                        controller: controller,
                        config: const QuillEditorConfig(
                          enableInteractiveSelection: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Meta chip ─────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.cs});

  final IconData icon;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF7C3AED); // kSeedSecondary violet

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomIntent extends Intent {
  const _ZoomIntent(this.delta);

  final double delta;
}
