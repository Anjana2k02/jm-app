import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> uploadImage({
    required String userId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = _fileExtension(file.name);
    final path = '$userId/${_uuid.v4()}.$extension';

    await _client.storage
        .from('doc-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: file.mimeType ?? 'application/octet-stream',
          ),
        );

    return _client.storage.from('doc-images').getPublicUrl(path);
  }

  String _fileExtension(String name) {
    final parts = name.split('.');
    if (parts.length < 2) {
      return 'jpg';
    }
    return parts.last.toLowerCase();
  }
}
