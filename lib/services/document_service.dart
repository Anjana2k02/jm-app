import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_model.dart';

class DocumentService {
  DocumentService(this._client);

  final SupabaseClient _client;

  Future<List<AppDocument>> fetchDocuments(String userId) async {
    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return response.map<AppDocument>((row) {
      return AppDocument.fromMap(row);
    }).toList();
  }

  Future<AppDocument> createDocument({
    required String userId,
    required String title,
  }) async {
    print(
      'DocumentService: Creating document with userId=$userId, title=$title',
    );

    final payload = {'user_id': userId, 'title': title, 'content': const []};
    print('DocumentService: Payload = $payload');

    try {
      final response = await _client
          .from('documents')
          .insert(payload)
          .select()
          .single();

      print('DocumentService: Success! Response: $response');
      return AppDocument.fromMap(response);
    } catch (e) {
      print('DocumentService: Error creating document: $e');
      rethrow;
    }
  }

  Future<void> updateDocument({
    required String documentId,
    required String title,
    required List<dynamic> content,
  }) async {
    await _client
        .from('documents')
        .update({
          'title': title,
          'content': content,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', documentId);
  }

  Future<void> deleteDocument(String documentId) async {
    await _client.from('documents').delete().eq('id', documentId);
  }
}
