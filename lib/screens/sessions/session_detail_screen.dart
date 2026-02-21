import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/document_model.dart';
import '../../models/session_model.dart';
import '../../models/session_song_model.dart';
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

    await _ws.sessionService.upsertSessionSongOrder(
      userId: user.id,
      sessionId: _session.id,
      documentIds: list.map((s) => s.documentId).toList(),
    );
  }

  Future<void> _removeSong(SessionSong song) async {
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Add Songs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  itemCount: available.length,
                  itemBuilder: (_, i) {
                    final doc = available[i];
                    final checked = selected.contains(doc.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) => setSheet(() {
                        if (checked) {
                          selected.remove(doc.id);
                        } else {
                          selected.add(doc.id);
                        }
                      }),
                      title: Text(doc.title.isEmpty ? 'Untitled' : doc.title),
                      secondary: const Icon(Icons.music_note_outlined),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(ctx),
                    child: Text(
                      selected.isEmpty
                          ? 'Select songs to add'
                          : 'Add ${selected.length} song${selected.length == 1 ? '' : 's'}',
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    await _ws.deleteSession(_session.id);
    if (mounted) Navigator.of(context).pop();
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

  // ─── Mobile layout: sidebar toggleable via < / > ──────────────────────────

  Widget _buildMobileBody() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sidebar (shown only when _sidebarVisible)
        if (_sidebarVisible) ...[
          SizedBox(
            width: screenWidth * 0.72,
            child: _buildSidebar(showCollapseButton: true),
          ),
          const VerticalDivider(width: 1, thickness: 1),
        ],
        // Content area + expand tab
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildContentArea(),
              // ">" tab on the left edge — only shown when sidebar is hidden
              if (!_sidebarVisible)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _sidebarVisible = true),
                      child: Container(
                        width: 20,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar({required bool showCollapseButton}) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLow,
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
                        onDismissed: (_) => _removeSong(song),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: cs.onErrorContainer,
                                size: 22,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
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
        // Song title + position counter
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.title.isEmpty ? 'Untitled' : doc.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Song ${_selectedIndex + 1} of ${_songs.length}',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              if (doc.songKey != null ||
                  doc.bpm != null ||
                  doc.durationLabel != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
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
        const Divider(height: 1),

        // Read-only Quill content (scrollable independently)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: QuillEditor.basic(
              controller: controller,
              config: const QuillEditorConfig(enableInteractiveSelection: true),
            ),
          ),
        ),

        const Divider(height: 1),

        // Prev / Next navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _selectedIndex > 0 ? _goToPrev : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Prev'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectedIndex < _songs.length - 1
                    ? _goToNext
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Next'),
                iconAlignment: IconAlignment.end,
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
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
