class JamSession {
  const JamSession({
    required this.id,
    required this.userId,
    required this.name,
    this.sessionDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? sessionDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JamSession.fromMap(Map<String, dynamic> map) {
    return JamSession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      sessionDate: map['session_date'] != null
          ? DateTime.parse(map['session_date'] as String)
          : null,
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  JamSession copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? sessionDate,
    bool clearDate = false,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JamSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sessionDate: clearDate ? null : (sessionDate ?? this.sessionDate),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
