import 'package:flutter/material.dart';

import '../models/document_model.dart';

/// A card representing a song in the session sidebar.
///
/// Displays in two states:
/// - Expanded: Shows full card with title, metadata
/// - Collapsed: Not visible (handled by parent)
///
/// Supports selection state and drag handles.
class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.document,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  final AppDocument document;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.3)
            : cs.surfaceContainerLowest,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Song number badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? cs.onPrimary
                          : cs.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Song title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.title.isEmpty ? 'Untitled' : document.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Drag handle always visible; delete shown only when selected
              if (isSelected)
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  tooltip: 'Remove from session',
                  onPressed: onRemove,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              Icon(
                Icons.drag_handle,
                size: 18,
                color: isSelected
                    ? cs.onPrimaryContainer.withValues(alpha: 0.5)
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
