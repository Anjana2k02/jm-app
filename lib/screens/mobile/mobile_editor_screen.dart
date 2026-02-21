import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/workspace_controller.dart';
import '../../models/document_model.dart';
import '../../utils/clipboard_to_delta_converter.dart';
import '../../utils/chord_detector.dart';
import '../../widgets/mobile_toolbar.dart';
import '../../widgets/save_status_chip.dart';
import '../../widgets/song_meta_bar.dart';

class MobileEditorScreen extends StatefulWidget {
  const MobileEditorScreen({
    super.key,
    required this.controller,
    required this.document,
  });

  final WorkspaceController controller;
  final AppDocument document;

  @override
  State<MobileEditorScreen> createState() => _MobileEditorScreenState();
}

class _MobileEditorScreenState extends State<MobileEditorScreen> {
  final _scrollController = ScrollController();
  final _editorFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  late final TextEditingController _titleController;

  bool _editingTitle = false;

  WorkspaceController get _ws => widget.controller;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    if (_ws.selectedDocument?.id != widget.document.id) {
      _ws.selectDocument(widget.document);
    }
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus && _editingTitle) {
        _commitTitle();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _startEditingTitle() {
    final doc = _ws.selectedDocument ?? widget.document;
    _titleController.text = doc.title;
    _titleController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _titleController.text.length,
    );
    setState(() => _editingTitle = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  Future<void> _commitTitle() async {
    if (!_editingTitle) return;
    setState(() => _editingTitle = false);
    final newTitle = _titleController.text.trim();
    final currentTitle = (_ws.selectedDocument ?? widget.document).title;
    if (newTitle.isNotEmpty && newTitle != currentTitle) {
      await _ws.renameDocument(newTitle);
    }
  }

  Future<void> _handleSmartPaste() async {
    final quill = _ws.quillController;
    if (quill == null) return;
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipData?.text;
    if (text == null || text.trim().isEmpty) return;
    if (!ChordDetector.looksLikeChordSheet(text)) return;
    final delta = ClipboardToDeltaConverter.fromPlainText(text);
    final sel = quill.selection;
    quill.replaceText(
      sel.start,
      sel.end - sel.start,
      delta,
      TextSelection.collapsed(offset: sel.start),
    );
  }

  Future<void> _insertImage() async {
    final quill = _ws.quillController;
    final user = _ws.client.auth.currentUser;
    if (quill == null || user == null) return;

    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final url =
        await _ws.storageService.uploadImage(userId: user.id, file: file);
    final index = quill.selection.baseOffset;
    quill.replaceText(
      index,
      0,
      BlockEmbed.image(url),
      TextSelection.collapsed(offset: index + 1),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _ws,
      builder: (context, _) {
        final quill = _ws.quillController;
        final doc = _ws.selectedDocument ?? widget.document;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () async {
                if (_editingTitle) await _commitTitle();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            titleSpacing: 0,
            title: _editingTitle
                // ── Inline editable title ──────────────────────────────
                ? TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Untitled',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _commitTitle(),
                  )
                // ── Tappable title ─────────────────────────────────────
                : GestureDetector(
                    onTap: _startEditingTitle,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            doc.title.isEmpty ? 'Untitled' : doc.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.edit_outlined,
                          size: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
            actions: _editingTitle
                ? [
                    // Confirm rename
                    IconButton(
                      icon: const Icon(Icons.check_rounded),
                      tooltip: 'Done',
                      onPressed: _commitTitle,
                    ),
                  ]
                : [
                    SaveStatusChip(saving: _ws.saving),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.save_outlined, size: 22),
                      tooltip: 'Save',
                      onPressed: _ws.saving ? null : _ws.saveDocument,
                    ),
                  ],
          ),
          body: quill == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    MobileToolbar(
                      controller: quill,
                      onImageInsert: _insertImage,
                      onSmartPaste: _handleSmartPaste,
                    ),
                    SongMetaBar(
                      key: ValueKey(doc.id),
                      document: doc,
                      onSave: _ws.updateSongMeta,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: QuillEditor(
                          controller: quill,
                          scrollController: _scrollController,
                          focusNode: _editorFocusNode,
                          config: const QuillEditorConfig(
                            autoFocus: true,
                            expands: true,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
