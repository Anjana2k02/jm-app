class SessionSong {
  const SessionSong({
    required this.sessionId,
    required this.documentId,
    required this.sortOrder,
  });

  final String sessionId;
  final String documentId;
  final int sortOrder;

  factory SessionSong.fromMap(Map<String, dynamic> map) {
    return SessionSong(
      sessionId: map['session_id'] as String,
      documentId: map['document_id'] as String,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
