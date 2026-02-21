import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/template_item.dart';
import '../models/template_model.dart';

class TemplateService {
  TemplateService(this._client);

  final SupabaseClient _client;

  Future<List<Template>> fetchTemplates(String userId) async {
    final response = await _client
        .from('templates')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return response.map<Template>((row) {
      return Template.fromMap(row);
    }).toList();
  }

  Future<Template> createTemplate({
    required String userId,
    required String name,
  }) async {
    final response = await _client
        .from('templates')
        .insert({'user_id': userId, 'name': name})
        .select()
        .single();

    return Template.fromMap(response);
  }

  Future<List<TemplateItem>> fetchTemplateItems(String templateId) async {
    final response = await _client
        .from('template_items')
        .select()
        .eq('template_id', templateId)
        .order('sort_order', ascending: true);

    return response.map<TemplateItem>((row) {
      return TemplateItem.fromMap(row);
    }).toList();
  }

  Future<void> upsertTemplateOrder({
    required String userId,
    required String templateId,
    required List<String> documentIds,
  }) async {
    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < documentIds.length; i++) {
      payload.add({
        'user_id': userId,
        'template_id': templateId,
        'document_id': documentIds[i],
        'sort_order': i,
      });
    }

    await _client
        .from('template_items')
        .upsert(payload, onConflict: 'template_id,document_id');
  }
}
