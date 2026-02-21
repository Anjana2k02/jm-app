import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/document_model.dart';

/// Displays the song.svg or medley.svg icon for the given [SongType].
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
    final asset = type == SongType.medley
        ? 'public/icon/medley.svg'
        : 'public/icon/song.svg';

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
