class Template {
  const Template({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: (map['name'] as String?) ?? 'Template',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
