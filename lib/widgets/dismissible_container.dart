import 'package:flutter/material.dart';

/// Builds a consistent dismissible background container for delete/remove actions.
///
/// Provides:
/// - Consistent color scheme (error container)
/// - Smooth animation with spring curve
/// - Proper spacing and padding
/// - Icon and label centered and vertically oriented
Widget buildDismissibleBackground(
  BuildContext context, {
  String label = 'Delete',
  IconData icon = Icons.delete_outline,
  double iconSize = 20,
  EdgeInsets padding = const EdgeInsets.only(right: 16),
  EdgeInsets margin = const EdgeInsets.symmetric(vertical: 3),
}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    alignment: Alignment.centerRight,
    padding: padding,
    margin: margin,
    decoration: BoxDecoration(
      color: cs.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.onErrorContainer, size: iconSize),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onErrorContainer,
          ),
        ),
      ],
    ),
  );
}
