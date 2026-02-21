/// Detects guitar chord lines and chord-sheet structure in plain text.
class ChordDetector {
  // Matches standard guitar chord names:
  // Root: A-G, optional sharp/flat (#/b),
  // optional quality: m, M, maj, min, aug, dim, sus, add,
  // optional number: 2,4,5,6,7,9,11,13,
  // optional slash bass: /A-G with optional #/b
  static final _chordPattern = RegExp(
    r'^[A-G][#b]?(m|M|maj|min|aug|dim|sus|add)?[0-9]*(\/[A-G][#b]?)?$',
  );

  /// Returns `true` if [line] looks like a chord line.
  ///
  /// A line is a chord line when ≥50% of its space-separated tokens match
  /// the chord pattern and there are at least 2 tokens (to avoid treating
  /// single letters like "A" in lyrics as chord lines).
  static bool isChordLine(String line) {
    final tokens = line
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.length < 2) return false;
    final chordCount =
        tokens.where((t) => _chordPattern.hasMatch(t)).length;
    return chordCount / tokens.length >= 0.5;
  }

  /// Returns `true` if [text] looks like a chord sheet overall.
  ///
  /// Threshold: ≥15% of non-empty lines are chord lines.
  static bool looksLikeChordSheet(String text) {
    final lines = text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return false;
    final chordLineCount = lines.where(isChordLine).length;
    return chordLineCount / lines.length >= 0.15;
  }
}
