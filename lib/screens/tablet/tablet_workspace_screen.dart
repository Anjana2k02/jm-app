import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/document_model.dart'; // AppDocument, SongType
import '../../models/template_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/document_list_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/save_status_chip.dart';
import '../../widgets/song_meta_bar.dart';
import '../home_screen.dart';
import '../sessions/sessions_screen.dart';

class TabletWorkspaceScreen extends StatefulWidget {
  const TabletWorkspaceScreen({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<TabletWorkspaceScreen> createState() => _TabletWorkspaceScreenState();
}

class _TabletWorkspaceScreenState extends State<TabletWorkspaceScreen> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  // Rail destinations: 0=Home, 1=Documents, 2=Sessions, 3=Settings
  int _selectedNavIndex = 0;

  WorkspaceController get _ws => widget.controller;

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _insertImage() async {
    final controller = _ws.quillController;
    final user = _ws.client.auth.currentUser;
    if (controller == null || user == null) return;

    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final url = await _ws.storageService.uploadImage(
      userId: user.id,
      file: file,
    );
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
    final titleCtrl = TextEditingController();
    SongType selectedType = SongType.song;

    final result = await showDialog<({String title, SongType type})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Song title',
                  hintText: 'Untitled',
                ),
                onSubmitted: (_) => Navigator.pop(
                  ctx,
                  (title: titleCtrl.text, type: selectedType),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Type',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              RadioGroup<SongType>(
                groupValue: selectedType,
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<SongType>(
                      title: const Text('Song'),
                      value: SongType.song,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    RadioListTile<SongType>(
                      title: const Text('Medley'),
                      value: SongType.medley,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                (title: titleCtrl.text, type: selectedType),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.title.trim().isEmpty) return;
    if (mounted) await _ws.createDocument(result.title, result.type);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final extendRail = width >= 840;

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
              // Navigation Rail
              _TabletRail(
                selectedIndex: _selectedNavIndex,
                extended: extendRail,
                onDestinationSelected: (i) =>
                    setState(() => _selectedNavIndex = i),
                onSignOut: _ws.signOut,
              ),

              // Main content area
              Expanded(child: _buildContent()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedNavIndex) {
      case 0: // Home
        return HomeScreen(
          controller: _ws,
          onGoToDocuments: () => setState(() => _selectedNavIndex = 1),
          onGoToSessions: () => setState(() => _selectedNavIndex = 2),
          onShowTemplates: () => setState(() => _selectedNavIndex = 1),
        );

      case 2: // Sessions
        return SessionsScreen(controller: _ws);

      case 3: // Settings
        return _TabletSettingsPane(controller: _ws);

      case 1: // Documents (default)
      default:
        return Row(
          children: [
            // Document list pane (fixed 280dp)
            SizedBox(
              width: 280,
              child: _DocumentListPane(
                controller: _ws,
                onCreateDoc: _showCreateDocDialog,
                onCreateTemplate: _showCreateTemplateDialog,
              ),
            ),

            // Editor pane (expanded)
            Expanded(
              child: _ws.selectedDocument == null || _ws.quillController == null
                  ? EmptyState(
                      icon: Icons.music_note_outlined,
                      title: 'No song selected',
                      subtitle: 'Select or create a song.',
                      action: FilledButton.icon(
                        onPressed: _showCreateDocDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('New song'),
                      ),
                    )
                  : _EditorPane(
                      key: ValueKey(_ws.selectedDocument?.id),
                      controller: _ws,
                      scrollController: _scrollController,
                      focusNode: _focusNode,
                      onInsertImage: _insertImage,
                    ),
            ),
          ],
        );
    }
  }
}

// ─── Navigation Rail ──────────────────────────────────────────────────────────

class _TabletRail extends StatelessWidget {
  const _TabletRail({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Sign out',
              onPressed: onSignOut,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.music_note_outlined),
          selectedIcon: Icon(Icons.music_note),
          label: Text('Songs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: Text('Sessions'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Settings'),
        ),
      ],
    );
  }
}

// ─── Document List Pane ───────────────────────────────────────────────────────

class _DocumentListPane extends StatelessWidget {
  const _DocumentListPane({
    required this.controller,
    required this.onCreateDoc,
    required this.onCreateTemplate,
  });

  final WorkspaceController controller;
  final VoidCallback onCreateDoc;
  final VoidCallback onCreateTemplate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? kSidebarDark : kSidebarLight;
    final borderColor = isDark ? kSidebarBorderDark : kSidebarBorderLight;
    final docs = controller.orderedDocuments();

    return Container(
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Template selector row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
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
                  style: IconButton.styleFrom(minimumSize: const Size(34, 34)),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Documents header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Row(
              children: [
                Text(
                  'SONGS',
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
                  tooltip: 'New song',
                  style: IconButton.styleFrom(minimumSize: const Size(34, 34)),
                ),
              ],
            ),
          ),

          // Document list
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Text(
                      'No songs yet',
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
                    itemBuilder: (_, i) {
                      final doc = docs[i];
                      return DocumentListTile(
                        document: doc,
                        isSelected: controller.selectedDocument?.id == doc.id,
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
                          isSelected: controller.selectedDocument?.id == doc.id,
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
        ],
      ),
    );
  }
}

// ─── Editor Pane ──────────────────────────────────────────────────────────────

class _EditorPane extends StatefulWidget {
  const _EditorPane({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
    required this.onInsertImage,
  });

  final WorkspaceController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final VoidCallback onInsertImage;

  @override
  State<_EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<_EditorPane> {
  late final TextEditingController _titleCtrl;

  WorkspaceController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    final doc = _ctrl.selectedDocument!;
    _titleCtrl = TextEditingController(
      text: doc.title.isEmpty ? '' : doc.title,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submitTitle() {
    final text = _titleCtrl.text.trim();
    if (text.isNotEmpty && text != _ctrl.selectedDocument?.title) {
      _ctrl.renameDocument(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final AppDocument doc = _ctrl.selectedDocument!;

    return Column(
      children: [
        // Editor top bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Untitled',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submitTitle(),
                  onEditingComplete: _submitTitle,
                ),
              ),
              SaveStatusChip(saving: _ctrl.saving),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onInsertImage,
                icon: const Icon(Icons.image_outlined, size: 20),
                tooltip: 'Insert image',
                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
              ),
              IconButton(
                onPressed: _ctrl.saving ? null : _ctrl.saveDocument,
                icon: const Icon(Icons.save_outlined, size: 20),
                tooltip: 'Save',
                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
              ),
            ],
          ),
        ),

        // Song metadata bar (Key / BPM / Duration)
        SongMetaBar(
          document: doc,
          onSave: _ctrl.updateSongMeta,
        ),

        // Toolbar
        Container(
          color: cs.surfaceContainerLow,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillSimpleToolbar(
              controller: _ctrl.quillController!,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showColorButton: true,
                showFontSize: true,
                showLink: true,
                showUndo: true,
                showRedo: true,
                showAlignmentButtons: true,
                showDividers: true,
                showHeaderStyle: true,
                showListBullets: true,
                showListNumbers: true,
                showListCheck: true,
                showClearFormat: true,
                showFontFamily: false,
                showStrikeThrough: false,
                showBackgroundColorButton: false,
                showCodeBlock: false,
                showDirection: false,
                showIndent: true,
                showInlineCode: false,
                showLineHeightButton: false,
                showQuote: false,
                showSearchButton: false,
                showSmallButton: false,
                showSubscript: false,
                showSuperscript: false,
              ),
            ),
          ),
        ),

        // Editor
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: QuillEditor(
              controller: _ctrl.quillController!,
              scrollController: widget.scrollController,
              focusNode: widget.focusNode,
              config: const QuillEditorConfig(
                autoFocus: false,
                expands: true,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Settings Pane ────────────────────────────────────────────────────────────

class _TabletSettingsPane extends StatelessWidget {
  const _TabletSettingsPane({required this.controller});

  final WorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email = controller.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              title: const Text(
                'Account',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout_outlined, color: cs.error),
              title: Text('Sign out', style: TextStyle(color: cs.error)),
              onTap: controller.signOut,
            ),
          ),
        ],
      ),
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
