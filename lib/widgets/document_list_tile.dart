import 'package:flutter/material.dart';

import '../models/document_model.dart';
import '../utils/haptics.dart';
import 'song_type_icon.dart';

// Accent colours per type
const Color _kSongAccent = Color(0xFF7C3AED); // violet / purple
const Color _kMedleyAccent = Color(0xFF2563EB); // blue

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isMedley = document.songType == SongType.medley;
    final accent = isMedley ? _kMedleyAccent : _kSongAccent;

    // Background
    final selectedBg = isDark
        ? accent.withValues(alpha: 0.28)
        : accent.withValues(alpha: 0.18);
    final unselectedBg = isDark
        ? accent.withValues(alpha: 0.07)
        : accent.withValues(alpha: 0.04);

    // Border
    final selectedBorderColor = isDark
        ? accent.withValues(alpha: 0.90)
        : accent.withValues(alpha: 0.80);
    final unselectedBorderColor = accent.withValues(
      alpha: isDark ? 0.30 : 0.22,
    );

    return Semantics(
      label: document.title,

      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedBorderColor : unselectedBorderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticsManager.songSelectedFeedback();
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: SizedBox(
                height: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // -- Type icon --
                    SongTypeIcon(
                      type: document.songType,
                      size: 18,
                      color: isSelected
                          ? accent
                          : accent.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 10),

                    // -- Title + timestamp --
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            document.title.isEmpty
                                ? 'Untitled'
                                : document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? cs.onSurface
                                  : cs.onSurface.withValues(alpha: 0.88),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -- Key + Duration column --
                    if (document.songKey != null ||
                        document.durationLabel != null) ...[
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (document.songKey != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: isSelected ? 0.20 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                document.songKey!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : accent.withValues(alpha: 0.85),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          if (document.durationLabel != null) ...[
                            if (document.songKey != null)
                              const SizedBox(height: 3),
                            Text(
                              document.durationLabel!,
                              style: TextStyle(
                                fontSize: 10,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.70,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

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
      ),
    );
  }
}
