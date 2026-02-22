import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'glass_container.dart';

/// Simplified toolbar for mobile/tablet — guitar chord app focused.
///
/// Groups: Font Family | Size – + | B I U | Color | Image | Smart Paste
class MobileToolbar extends StatelessWidget {
  const MobileToolbar({
    super.key,
    required this.controller,
    this.onImageInsert,
    this.onSmartPaste,
  });

  final QuillController controller;
  final VoidCallback? onImageInsert;

  /// When provided, a Smart Paste button is shown at the end of the toolbar.
  /// It reads clipboard text and applies chord-aware monospace formatting.
  final VoidCallback? onSmartPaste;

  static const List<double> _sizes = [
    8,
    10,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    36,
    48,
  ];

  void _changeFontSize(int direction) {
    final attr = controller.getSelectionStyle().attributes[Attribute.size.key];
    final current = double.tryParse(attr?.value?.toString() ?? '') ?? 14.0;

    final idx = _sizes.indexWhere((s) => s >= current);
    int next;
    if (direction > 0) {
      next = (idx < 0
          ? _sizes.length - 1
          : (idx + 1).clamp(0, _sizes.length - 1));
    } else {
      next = (idx <= 0 ? 0 : (idx - 1).clamp(0, _sizes.length - 1));
    }
    final newSize = _sizes[next];
    controller.formatSelection(
      Attribute.fromKeyValue(Attribute.size.key, '${newSize.toInt()}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final activeStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(cs.primaryContainer),
      foregroundColor: WidgetStatePropertyAll(cs.primary),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    final inactiveStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStatePropertyAll(cs.onSurfaceVariant),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    );

    final theme = QuillIconTheme(
      iconButtonSelectedData: IconButtonData(style: activeStyle),
      iconButtonUnselectedData: IconButtonData(style: inactiveStyle),
    );

    const sz = 18.0;

    QuillToolbarToggleStyleButton fmt(Attribute attr) =>
        QuillToolbarToggleStyleButton(
          attribute: attr,
          controller: controller,
          options: QuillToolbarToggleStyleButtonOptions(
            iconSize: sz,
            iconTheme: theme,
          ),
        );

    Widget div() => Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: cs.outlineVariant,
    );

    Widget sizeBtn({
      required IconData icon,
      required int dir,
      required String tip,
    }) => Tooltip(
      message: tip,
      child: IconButton(
        icon: Icon(icon, size: sz),
        onPressed: () => _changeFontSize(dir),
        padding: EdgeInsets.zero,
        style: inactiveStyle,
      ),
    );

    return GlassContainer(
      enableBlur: false,
      borderRadius: 0,
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Font family ──────────────────────────────────────────────
            QuillToolbarFontFamilyButton(
              controller: controller,
              options: QuillToolbarFontFamilyButtonOptions(
                iconSize: sz,
                iconTheme: theme,
              ),
            ),
            div(),

            // ── Font size – / + ──────────────────────────────────────────
            sizeBtn(icon: Icons.remove, dir: -1, tip: 'Decrease font size'),
            sizeBtn(icon: Icons.add, dir: 1, tip: 'Increase font size'),
            div(),

            // ── Inline formatting ────────────────────────────────────────
            fmt(Attribute.bold),
            fmt(Attribute.italic),
            fmt(Attribute.underline),
            div(),

            // ── Color ────────────────────────────────────────────────────
            QuillToolbarColorButton(
              controller: controller,
              isBackground: false,
              options: QuillToolbarColorButtonOptions(
                iconSize: sz,
                iconTheme: theme,
              ),
            ),

            // ── Image ────────────────────────────────────────────────────
            if (onImageInsert != null) ...[
              div(),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: Icon(
                    Icons.image_outlined,
                    size: sz,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onImageInsert,
                  tooltip: 'Insert image',
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],

            // ── Smart Paste ───────────────────────────────────────────────
            if (onSmartPaste != null) ...[
              div(),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: Icon(
                    Icons.content_paste,
                    size: sz,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onSmartPaste,
                  tooltip: 'Smart Paste (preserves chord formatting)',
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
