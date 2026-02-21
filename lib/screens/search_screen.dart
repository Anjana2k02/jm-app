import 'package:flutter/material.dart';

import '../controllers/workspace_controller.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/empty_state.dart';
import 'mobile/mobile_editor_screen.dart';
import 'sessions/session_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.controller,
    required this.onGoToSessions,
  });

  final WorkspaceController controller;
  final VoidCallback onGoToSessions;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  WorkspaceController get _ws => widget.controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = _ws.searchAll(_query);

    final docResults = results
        .where((r) => r.type == SearchResultType.document)
        .toList();
    final sessionResults = results
        .where((r) => r.type == SearchResultType.session)
        .toList();
    final templateResults = results
        .where((r) => r.type == SearchResultType.template)
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search docs, sessions, templates…',
            border: InputBorder.none,
            filled: false,
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
              onPressed: () => setState(() => _query = ''),
            ),
        ],
      ),
      body: _query.trim().isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search',
              subtitle: 'Start typing to search across documents, sessions, and templates.',
            )
          : results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'No results',
                  subtitle: 'Nothing matched "$_query".',
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (docResults.isNotEmpty) ...[
                      _SectionHeader(label: 'DOCUMENTS'),
                      ...docResults.map((r) {
                        final doc = _ws.documents.firstWhere(
                          (d) => d.id == r.id,
                        );
                        return DocumentListTile(
                          document: doc,
                          isSelected: false,
                          onTap: () {
                            _ws.selectDocument(doc);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MobileEditorScreen(
                                  controller: _ws,
                                  document: doc,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                    if (sessionResults.isNotEmpty) ...[
                      _SectionHeader(label: 'SESSIONS'),
                      ...sessionResults.map((r) {
                        final session = _ws.sessions.firstWhere(
                          (s) => s.id == r.id,
                        );
                        return ListTile(
                          leading: Icon(
                            Icons.event_outlined,
                            color: cs.primary,
                          ),
                          title: Text(r.title),
                          subtitle: r.subtitle != null
                              ? Text(
                                  r.subtitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(
                                controller: _ws,
                                session: session,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                    if (templateResults.isNotEmpty) ...[
                      _SectionHeader(label: 'TEMPLATES'),
                      ...templateResults.map((r) {
                        final template = _ws.templates.firstWhere(
                          (t) => t.id == r.id,
                        );
                        return ListTile(
                          leading: Icon(
                            Icons.layers_outlined,
                            color: cs.primary,
                          ),
                          title: Text(r.title),
                          subtitle: const Text(
                            'Template',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            _ws.switchTemplate(template);
                            Navigator.of(context).pop();
                          },
                        );
                      }),
                    ],
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
