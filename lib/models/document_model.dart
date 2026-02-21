class AppDocument {
  const AppDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final List<dynamic> content;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppDocument copyWith({
    String? title,
    List<dynamic>? content,
    DateTime? updatedAt,
  }) {
    return AppDocument(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppDocument.fromMap(Map<String, dynamic> map) {
    return AppDocument(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: (map['title'] as String?) ?? 'Untitled',
      content: (map['content'] as List<dynamic>?) ?? const [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
