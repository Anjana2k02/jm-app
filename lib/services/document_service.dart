import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_model.dart';

class DocumentService {
  DocumentService(this._client);

  final SupabaseClient _client;

  Future<List<AppDocument>> fetchDocuments(String userId) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return response.map<AppDocument>((row) => AppDocument.fromMap(row)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load documents: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load documents: $e');
    }
  }

  Future<AppDocument> createDocument({
    required String userId,
    required String title,
    SongType songType = SongType.song,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'title': title,
        'content': const [],
        'song_type': songType.name,
      };
      final response = await _client
          .from('documents')
          .insert(payload)
          .select()
          .single();
      return AppDocument.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create document: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  /// Saves the Quill content and title for a document.
  Future<void> updateDocument({
    required String documentId,
    required String title,
    required List<dynamic> content,
  }) async {
    try {
      await _client
          .from('documents')
          .update({
            'title': title,
            'content': content,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', documentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save document: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save document: $e');
    }
  }

  /// Saves song metadata fields (song_key, bpm, duration_seconds) without
  /// overwriting the Quill content.
  Future<void> updateSongMeta({
    required String documentId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _client
          .from('documents')
          .update({
            ...fields,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', documentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update song metadata: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update song metadata: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _client.from('documents').delete().eq('id', documentId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete document: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
