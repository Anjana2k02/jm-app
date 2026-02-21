import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/workspace_controller.dart';
import '../models/template_model.dart';
import '../utils/chord_detector.dart';
import '../utils/clipboard_to_delta_converter.dart';
import '../theme/app_colors.dart';
import '../widgets/document_list_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/save_status_chip.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'sessions/sessions_screen.dart';

enum _DesktopView { home, documents, sessions }

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  _DesktopView _view = _DesktopView.home;

  WorkspaceController get _ws => widget.controller;

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSmartPaste() async {
    final controller = _ws.quillController;
    if (controller == null) return;
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipData?.text;
    if (text == null || text.trim().isEmpty) return;
    if (!ChordDetector.looksLikeChordSheet(text)) return;
    final delta = ClipboardToDeltaConverter.fromPlainText(text);
    final sel = controller.selection;
    controller.replaceText(
      sel.start,
      sel.end - sel.start,
      delta,
      TextSelection.collapsed(offset: sel.start),
    );
  }

  Future<void> _insertImage() async {
    final controller = _ws.quillController;
    final user = _ws.client.auth.currentUser;
    if (controller == null || user == null) return;

    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final url =
        await _ws.storageService.uploadImage(userId: user.id, file: file);
    final index = controller.selection.baseOffset;
    controller.replaceText(
      index,
      0,
      BlockEmbed.image(url),
      TextSelection.collapsed(offset: index + 1),
    );
    if (mounted) setState(() {});
  }

  Future<void> _showCreateDocDialog() async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
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
    if (mounted) await _ws.createDocument(title);
  }

  Future<void> _showCreateTemplateDialog() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Template name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    if (mounted) await _ws.createTemplate(name);
  }

  Future<void> _showCreateSessionDialog() async {
    final nameCtrl = TextEditingController();
    DateTime? selectedDate;
    final notesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Session name',
                    hintText: 'e.g. Friday rehearsal',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? _formatDate(selectedDate!)
                            : 'No date selected',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) {
                          setDialogState(() => selectedDate = d);
                        }
                      },
                      child: const Text('Pick date'),
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
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != true || nameCtrl.text.trim().isEmpty) return;
    await _ws.createSession(nameCtrl.text.trim(), selectedDate, notesCtrl.text);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          controller: _ws,
          onGoToSessions: () => setState(() => _view = _DesktopView.sessions),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ws,
      builder: (context, _) {
        if (_ws.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _DesktopSidebar(
                controller: _ws,
                currentView: _view,
                onViewChanged: (v) => setState(() => _view = v),
                onCreateDoc: _showCreateDocDialog,
                onCreateTemplate: _showCreateTemplateDialog,
                onSearch: _openSearch,
              ),
              Expanded(child: _buildMainContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (_view) {
      case _DesktopView.home:
        return HomeScreen(
          controller: _ws,
          onGoToDocuments: () => setState(() => _view = _DesktopView.documents),
          onGoToSessions: () => setState(() => _view = _DesktopView.sessions),
          onShowTemplates: () => setState(() => _view = _DesktopView.documents),
        );

      case _DesktopView.sessions:
        return SessionsScreen(
          controller: _ws,
          onCreateSession: _showCreateSessionDialog,
        );

      case _DesktopView.documents:
        return _ws.selectedDocument == null || _ws.quillController == null
            ? _buildEmptyEditor()
            : _buildEditor();
    }
  }

  Widget _buildEmptyEditor() {
    return EmptyState(
      icon: Icons.edit_document,
      title: 'No document selected',
      subtitle: 'Create or select a document from the sidebar.',
      action: FilledButton.icon(
        onPressed: _showCreateDocDialog,
        icon: const Icon(Icons.add),
        label: const Text('New document'),
      ),
    );
  }

  Widget _buildEditor() {
    final cs = Theme.of(context).colorScheme;
    final doc = _ws.selectedDocument!;

    return Column(
      children: [
        // Top bar: breadcrumb + actions
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_document, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Jammer Docs',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
              Expanded(
                child: Text(
                  doc.title.isEmpty ? 'Untitled' : doc.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SaveStatusChip(saving: _ws.saving),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _insertImage,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text('Image'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _handleSmartPaste,
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text('Smart Paste'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _ws.saving ? null : _ws.saveDocument,
                icon: const Icon(Icons.save_outlined, size: 20),
                tooltip: 'Save',
                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
              ),
            ],
          ),
        ),

        // Quill toolbar — horizontal scroll so it never overflows
        Container(
          color: cs.surfaceContainerLow,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillSimpleToolbar(
              controller: _ws.quillController!,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showFontFamily: true,
                showFontSize: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
                showAlignmentButtons: true,
                showBackgroundColorButton: false,
                showClearFormat: true,
                showCodeBlock: false,
                showDirection: false,
                showDividers: true,
                showHeaderStyle: true,
                showIndent: true,
                showInlineCode: false,
                showLineHeightButton: false,
                showListBullets: true,
                showListCheck: true,
                showListNumbers: true,
                showQuote: false,
                showSearchButton: false,
                showSmallButton: false,
                showSubscript: false,
                showSuperscript: false,
              ),
            ),
          ),
        ),

        // Editor body — centered, max-width for comfortable reading
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: QuillEditor(
                  controller: _ws.quillController!,
                  scrollController: _scrollController,
                  focusNode: _focusNode,
                  config: const QuillEditorConfig(
                    autoFocus: false,
                    expands: true,
                    padding: EdgeInsets.zero,
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

// ─── Desktop Sidebar ──────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.controller,
    required this.currentView,
    required this.onViewChanged,
    required this.onCreateDoc,
    required this.onCreateTemplate,
    required this.onSearch,
  });

  final WorkspaceController controller;
  final _DesktopView currentView;
  final ValueChanged<_DesktopView> onViewChanged;
  final VoidCallback onCreateDoc;
  final VoidCallback onCreateTemplate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? kSidebarDark : kSidebarLight;
    final borderColor = isDark ? kSidebarBorderDark : kSidebarBorderLight;

    final userEmail = controller.client.auth.currentUser?.email ?? '';
    final initial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';
    final docs = controller.orderedDocuments();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: avatar + workspace label + sign out
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'My Workspace',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: controller.signOut,
                  icon: const Icon(Icons.logout_outlined, size: 18),
                  tooltip: 'Sign out',
                  style:
                      IconButton.styleFrom(minimumSize: const Size(34, 34)),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // View switcher
          _SectionLabel(label: 'NAVIGATE'),
          _ViewSwitcher(
            currentView: currentView,
            onViewChanged: onViewChanged,
            onSearch: onSearch,
          ),

          Divider(height: 1, color: borderColor),

          // Only show doc list pane when in Documents view
          if (currentView == _DesktopView.documents) ...[
            // Template selector section
            _SectionLabel(label: 'VIEW'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _TemplateDropdown(
                      templates: controller.templates,
                      activeTemplate: controller.activeTemplate,
                      onChanged: controller.switchTemplate,
                    ),
                  ),
                  IconButton(
                    onPressed: onCreateTemplate,
                    icon: const Icon(Icons.layers_outlined, size: 18),
                    tooltip: 'New template',
                    style: IconButton.styleFrom(
                        minimumSize: const Size(34, 34)),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderColor),

            // Documents section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Text(
                    'DOCUMENTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onCreateDoc,
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'New document',
                    style: IconButton.styleFrom(
                        minimumSize: const Size(34, 34)),
                  ),
                ],
              ),
            ),

            // Document list
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'No documents yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : controller.activeTemplate == null
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final doc = docs[i];
                            return DocumentListTile(
                              document: doc,
                              isSelected:
                                  controller.selectedDocument?.id == doc.id,
                              onTap: () => controller.selectDocument(doc),
                            );
                          },
                        )
                      : ReorderableListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          onReorder: controller.reorderDocuments,
                          children: [
                            for (final doc in docs)
                              DocumentListTile(
                                key: ValueKey(doc.id),
                                document: doc,
                                isSelected:
                                    controller.selectedDocument?.id == doc.id,
                                onTap: () => controller.selectDocument(doc),
                                trailing: Icon(
                                  Icons.drag_handle,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
            ),
          ] else
            // Spacer for non-documents views
            const Spacer(),
        ],
      ),
    );
  }
}

// ─── View Switcher ────────────────────────────────────────────────────────────

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({
    required this.currentView,
    required this.onViewChanged,
    required this.onSearch,
  });

  final _DesktopView currentView;
  final ValueChanged<_DesktopView> onViewChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item(_DesktopView view, IconData icon, String label) {
      final isSelected = currentView == view;
      return InkWell(
        onTap: () => onViewChanged(view),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: cs.primaryContainer.withAlpha(120),
                  border: Border(
                    left: BorderSide(color: cs.primary, width: 2),
                  ),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        item(_DesktopView.home, Icons.home_outlined, 'Home'),
        item(_DesktopView.documents, Icons.description_outlined, 'Documents'),
        item(_DesktopView.sessions, Icons.event_outlined, 'Sessions'),
        InkWell(
          onTap: onSearch,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.search_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Template Dropdown ────────────────────────────────────────────────────────

class _TemplateDropdown extends StatelessWidget {
  const _TemplateDropdown({
    required this.templates,
    required this.activeTemplate,
    required this.onChanged,
  });

  final List<Template> templates;
  final Template? activeTemplate;
  final Future<void> Function(Template?) onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<Template?>(
        isExpanded: true,
        value: activeTemplate,
        borderRadius: BorderRadius.circular(10),
        style: TextStyle(fontSize: 13, color: cs.onSurface),
        hint: Text(
          'Default order',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
        items: [
          DropdownMenuItem<Template?>(
            value: null,
            child: Text(
              'Default order',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          for (final t in templates)
            DropdownMenuItem<Template?>(
              value: t,
              child: Text(t.name, style: const TextStyle(fontSize: 13)),
            ),
        ],
        onChanged: (t) => onChanged(t),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Shared placeholder screens used by mobile shell tabs ────────────────────

class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.layers_outlined,
      title: 'Templates',
      subtitle: 'Create templates to organize your document order.',
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email = controller.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : '?',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(
              email,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Signed in'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Sign out'),
            onTap: controller.signOut,
          ),
        ],
      ),
    );
  }
}
