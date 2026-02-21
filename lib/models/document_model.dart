enum SongType {
  song,
  medley;

  static SongType fromString(String? value) =>
      value == 'medley' ? SongType.medley : SongType.song;
}

class AppDocument {
  const AppDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.songType = SongType.song,
    this.songKey,
    this.bpm,
    this.durationSeconds,
  });

  final String id;
  final String userId;
  final String title;
  final List<dynamic> content;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether this document is a regular song or a medley.
  final SongType songType;

  /// Musical key of the song (e.g. "A", "F#m", "Bb").
  final String? songKey;

  /// Beats per minute.
  final int? bpm;

  /// Total song duration in seconds.
  final int? durationSeconds;

  // ─── Derived helpers ────────────────────────────────────────────────────────

  /// Duration formatted as "Xm Ys", or null if not set.
  String? get durationLabel {
    if (durationSeconds == null || durationSeconds! <= 0) return null;
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  // ─── copyWith ───────────────────────────────────────────────────────────────

  AppDocument copyWith({
    String? title,
    List<dynamic>? content,
    DateTime? updatedAt,
    SongType? songType,
    String? songKey,
    int? bpm,
    int? durationSeconds,
    bool clearSongKey = false,
    bool clearBpm = false,
    bool clearDuration = false,
  }) {
    return AppDocument(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songType: songType ?? this.songType,
      songKey: clearSongKey ? null : (songKey ?? this.songKey),
      bpm: clearBpm ? null : (bpm ?? this.bpm),
      durationSeconds:
          clearDuration ? null : (durationSeconds ?? this.durationSeconds),
    );
  }

  // ─── fromMap ────────────────────────────────────────────────────────────────

  factory AppDocument.fromMap(Map<String, dynamic> map) {
    return AppDocument(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: (map['title'] as String?) ?? 'Untitled',
      content: (map['content'] as List<dynamic>?) ?? const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      songType: SongType.fromString(map['song_type'] as String?),
      songKey: map['song_key'] as String?,
      bpm: map['bpm'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
    );
  }
}
