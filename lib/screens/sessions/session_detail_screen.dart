import 'package:flutter/material.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/document_model.dart';
import '../../models/session_model.dart';
import '../../models/session_song_model.dart';
import '../../widgets/empty_state.dart';

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

  WorkspaceController get _ws => widget.controller;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loadingSongs = true);
    final songs = await _ws.loadSessionSongs(_session.id);
    if (mounted) {
      setState(() {
        _songs = songs;
        _loadingSongs = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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

  Future<void> _showAddSongSheet() async {
    final existingIds = _songs.map((s) => s.documentId).toSet();
    final available =
        _ws.documents.where((d) => !existingIds.contains(d.id)).toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All songs are already in the setlist')),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Add to setlist',
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
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final doc = available[i];
                  return ListTile(
                    leading: const Icon(Icons.music_note_outlined),
                    title: Text(
                      doc.title.isEmpty ? 'Untitled' : doc.title,
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _addSong(doc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSong(AppDocument doc) async {
    final user = _ws.client.auth.currentUser;
    if (user == null) return;

    await _ws.sessionService.addSongToSession(
      userId: user.id,
      sessionId: _session.id,
      documentId: doc.id,
      sortOrder: _songs.length,
    );
    await _loadSongs();
  }

  Future<void> _removeSong(SessionSong song) async {
    await _ws.sessionService.removeSongFromSession(
      sessionId: _session.id,
      documentId: song.documentId,
    );
    await _loadSongs();
  }

  Future<void> _reorderSongs(int oldIndex, int newIndex) async {
    final user = _ws.client.auth.currentUser;
    if (user == null) return;

    final list = List<SessionSong>.from(_songs);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);

    setState(() => _songs = list);

    await _ws.sessionService.upsertSessionSongOrder(
      userId: user.id,
      sessionId: _session.id,
      documentIds: list.map((s) => s.documentId).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final docMap = {for (final d in _ws.documents) d.id: d};

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit session',
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete session',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          _session.sessionDate != null
                              ? _formatDate(_session.sessionDate!)
                              : 'No date set',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (_session.notes.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        _session.notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Setlist header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 4),
            child: Row(
              children: [
                Text(
                  'SETLIST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  tooltip: 'Add song',
                  onPressed: _showAddSongSheet,
                ),
              ],
            ),
          ),

          // Setlist body
          Expanded(
            child: _loadingSongs
                ? const Center(child: CircularProgressIndicator())
                : _songs.isEmpty
                    ? const EmptyState(
                        icon: Icons.music_note_outlined,
                        title: 'No songs yet',
                        subtitle: 'Tap + to add songs to this setlist.',
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        itemCount: _songs.length,
                        onReorder: _reorderSongs,
                        itemBuilder: (_, i) {
                          final song = _songs[i];
                          final doc = docMap[song.documentId];
                          return ListTile(
                            key: ValueKey(song.documentId),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              doc?.title.isEmpty ?? true
                                  ? 'Untitled'
                                  : doc!.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      size: 20, color: cs.error),
                                  tooltip: 'Remove',
                                  onPressed: () => _removeSong(song),
                                ),
                                const Icon(Icons.drag_handle, size: 20),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
