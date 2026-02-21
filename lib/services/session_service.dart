import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_model.dart';
import '../models/session_song_model.dart';

class SessionService {
  const SessionService(this._client);

  final SupabaseClient _client;

  // ─── Sessions CRUD ────────────────────────────────────────────────────────

  Future<List<JamSession>> fetchSessions(String userId) async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('user_id', userId)
        .order('session_date', ascending: true, nullsFirst: false);
    return (data as List).map((e) => JamSession.fromMap(e)).toList();
  }

  Future<JamSession> createSession({
    required String userId,
    required String name,
    DateTime? sessionDate,
    String notes = '',
  }) async {
    final data = await _client
        .from('sessions')
        .insert({
          'user_id': userId,
          'name': name,
          if (sessionDate != null)
            'session_date': sessionDate.toIso8601String().substring(0, 10),
          'notes': notes,
        })
        .select()
        .single();
    return JamSession.fromMap(data);
  }

  Future<void> updateSession({
    required String sessionId,
    String? name,
    DateTime? sessionDate,
    bool clearDate = false,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (clearDate) {
      updates['session_date'] = null;
    } else if (sessionDate != null) {
      updates['session_date'] = sessionDate.toIso8601String().substring(0, 10);
    }
    if (notes != null) updates['notes'] = notes;
    await _client.from('sessions').update(updates).eq('id', sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('sessions').delete().eq('id', sessionId);
  }

  // ─── Session Songs (Setlist) ──────────────────────────────────────────────

  Future<List<SessionSong>> fetchSessionSongs(String sessionId) async {
    final data = await _client
        .from('session_songs')
        .select()
        .eq('session_id', sessionId)
        .order('sort_order', ascending: true);
    return (data as List).map((e) => SessionSong.fromMap(e)).toList();
  }

  Future<void> addSongToSession({
    required String userId,
    required String sessionId,
    required String documentId,
    int sortOrder = 0,
  }) async {
    await _client.from('session_songs').upsert({
      'session_id': sessionId,
      'document_id': documentId,
      'user_id': userId,
      'sort_order': sortOrder,
    });
  }

  Future<void> removeSongFromSession({
    required String sessionId,
    required String documentId,
  }) async {
    await _client
        .from('session_songs')
        .delete()
        .eq('session_id', sessionId)
        .eq('document_id', documentId);
  }

  Future<void> upsertSessionSongOrder({
    required String userId,
    required String sessionId,
    required List<String> documentIds,
  }) async {
    final rows = documentIds.asMap().entries.map((e) => {
          'session_id': sessionId,
          'document_id': e.value,
          'user_id': userId,
          'sort_order': e.key,
        }).toList();
    await _client.from('session_songs').upsert(rows);
  }
}
