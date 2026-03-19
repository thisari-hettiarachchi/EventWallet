import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileImageStorageService {
  ProfileImageStorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const List<String> _bucketCandidates = ['profile-images', 'profile_images'];

  Future<String> uploadProfileImage({
    required String uid,
    required String role,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final extension = _safeExtension(image.path);
    final filePath =
        '$role/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

    StorageException? lastStorageError;

    for (final bucket in _bucketCandidates) {
      try {
        await _client.storage.from(bucket).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeFromExtension(extension),
            upsert: true,
          ),
        );

        return _client.storage.from(bucket).getPublicUrl(filePath);
      } on StorageException catch (e) {
        lastStorageError = e;

        final isBucketMissing =
            e.statusCode == '404' || e.message.toLowerCase().contains('bucket not found');
        if (isBucketMissing) {
          continue;
        }

        final isUnauthorized =
            e.statusCode == '403' || e.message.toLowerCase().contains('row-level security');
        if (isUnauthorized) {
          throw Exception(
            'Supabase storage denied upload (RLS) for bucket "$bucket".\n'
            'Please run the RLS policies SQL for the "anon" role in your Supabase dashboard.',
          );
        }

        rethrow;
      }
    }

    if (lastStorageError != null) {
      throw Exception(
        'Supabase bucket not found. Ensure you have created a bucket named "profile-images" '
        'in your Supabase Storage dashboard.\nOriginal error: ${lastStorageError.message}',
      );
    }

    throw Exception('Supabase upload failed for an unknown reason.');
  }

  Future<void> deleteProfileImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Supabase public URL structure: /storage/v1/object/public/bucket-name/file-path
      // We need the bucket-name and the file-path (everything after bucket-name)
      
      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex == -1 || pathSegments.length <= publicIndex + 2) {
        return;
      }

      final bucket = pathSegments[publicIndex + 1];
      final filePath = pathSegments.sublist(publicIndex + 2).join('/');

      await _client.storage.from(bucket).remove([filePath]);
    } catch (e) {
      // If deletion fails, we don't want to block the rest of the flow, 
      // but you might want to log it.
      debugPrint('Error deleting image: $e');
    }
  }

  String _safeExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) {
      return 'jpg';
    }

    final ext = path.substring(lastDot + 1).toLowerCase();
    return ext.isEmpty ? 'jpg' : ext;
  }

  String _contentTypeFromExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
