import 'package:flutter_quill/quill_delta.dart';

import 'chord_detector.dart';

/// Converts clipboard plain text to a Quill [Delta] with chord-aware
/// monospace formatting.
///
/// Chord lines (and the lyric lines that immediately follow them) are
/// wrapped in `{'font': 'Courier New'}` to preserve alignment. A blank
/// line ends the chord block.
class ClipboardToDeltaConverter {
  static const _monoAttr = {'font': 'Courier New'};

  /// Converts [text] to a chord-aware [Delta].
  ///
  /// Lines are processed in order:
  /// - Empty lines → bare `\n`, resets chord-block state.
  /// - Chord lines → monospace text + `\n`, enters chord-block mode.
  /// - Non-chord lines inside a chord block → monospace text + `\n`
  ///   (to keep lyric lines aligned under chords).
  /// - All other lines → plain text + `\n`.
  static Delta fromPlainText(String text) {
    // Normalise Windows/old-Mac line endings.
    final lines =
        text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    final delta = Delta();
    bool inChordBlock = false;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        // Blank line ends the current chord block.
        inChordBlock = false;
        delta.insert('\n');
        continue;
      }

      final isChord = ChordDetector.isChordLine(line);
      if (isChord) inChordBlock = true;

      if (inChordBlock) {
        // Insert with monospace to preserve chord / lyric alignment.
        delta.insert(line, _monoAttr);
      } else {
        delta.insert(line);
      }
      delta.insert('\n');
    }

    return delta;
  }
}
