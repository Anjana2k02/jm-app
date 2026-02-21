import 'package:flutter/material.dart';

import '../models/document_model.dart';

/// Displays a music icon for the given [SongType].
/// Song → music_note, Medley → queue_music
class SongTypeIcon extends StatelessWidget {
  const SongTypeIcon({
    super.key,
    required this.type,
    this.size = 20.0,
    this.color,
  });

  final SongType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconData = type == SongType.medley
        ? Icons.queue_music
        : Icons.music_note;

    return Icon(
      iconData,
      size: size,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
