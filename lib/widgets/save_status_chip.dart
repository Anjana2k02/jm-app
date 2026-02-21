import 'package:flutter/material.dart';

class SaveStatusChip extends StatelessWidget {
  const SaveStatusChip({super.key, required this.saving});

  final bool saving;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: saving
          ? Chip(
              key: const ValueKey('saving'),
              avatar: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              label: Text(
                'Saving…',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              backgroundColor: cs.surfaceContainerLow,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            )
          : Chip(
              key: const ValueKey('saved'),
              avatar: Icon(
                Icons.check_circle_outline,
                size: 14,
                color: Colors.green.shade600,
              ),
              label: Text(
                'Saved',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              backgroundColor: cs.surfaceContainerLow,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}
