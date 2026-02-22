import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/workspace_controller.dart';
import '../../widgets/document_list_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_dialog.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  WorkspaceController get _ws => widget.controller;

  @override
  void initState() {
    super.initState();
    _ws.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _ws.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    final err = _ws.operationError;
    if (err != null && mounted) {
      showGlassSnackBar(context, err);
    }
  }

  Future<void> _showCreateDocDialog() async {
    final titleController = TextEditingController();
    final title = await showGlassDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New document'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Untitled',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, titleController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title == null || title.trim().isEmpty) return;
    final ok = await _ws.createDocument(title);
    if (!mounted) return;
    if (ok) {
      showGlassSnackBar(context, 'Song created');
      if (_ws.selectedDocument != null) {
        context.push(
          '/docs/${_ws.selectedDocument!.id}',
          extra: _ws.selectedDocument,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ws,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Jammer Docs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Refresh',
                onPressed: _ws.loadAll,
              ),
            ],
          ),
          body: _ws.loading
              ? const Center(child: CircularProgressIndicator())
              : _ws.documents.isEmpty
              ? EmptyState(
                  icon: Icons.article_outlined,
                  title: 'No documents yet',
                  subtitle:
                      'Tap the button below to create your first document.',
                  action: FilledButton.icon(
                    onPressed: _showCreateDocDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('New document'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _ws.loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _ws.orderedDocuments().length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) {
                      final doc = _ws.orderedDocuments()[i];
                      return DocumentListTile(
                        document: doc,
                        isSelected: false,
                        onTap: () {
                          _ws.selectDocument(doc);
                          context.push('/docs/${doc.id}', extra: doc);
                        },
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showCreateDocDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Document'),
          ),
        );
      },
    );
  }
}
