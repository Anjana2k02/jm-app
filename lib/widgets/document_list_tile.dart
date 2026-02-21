import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document_model.dart';
import '../theme/app_colors.dart';

class DocumentListTile extends StatelessWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final AppDocument document;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark ? kDocTileSelectedDark : kDocTileSelectedLight;

    return Semantics(
      label: '${document.title}, updated ${_formatRelativeTime(document.updatedAt)}',
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.article : Icons.article_outlined,
                    size: 18,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          document.title.isEmpty ? 'Untitled' : document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? cs.onSurface
                                : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRelativeTime(document.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
