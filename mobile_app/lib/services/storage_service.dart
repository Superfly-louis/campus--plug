import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static const String _cloudName = 'dfvv7uvxh';
  static const String _uploadPreset = 'campus--plug';
  static final Uri _uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
  );

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  /// Uploads [file] to Cloudinary (unsigned) and returns `secure_url`.
  ///
  /// [storagePath] is retained for call-site compatibility (previously a
  /// Firebase Storage object path). It is not sent to Cloudinary — unsigned
  /// presets often disallow client-set `public_id` / `folder`.
  Future<String> uploadImage({
    required String storagePath,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';

    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Image upload failed (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Image upload returned an unexpected response');
    }

    final secureUrl = decoded['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw Exception('Image upload response missing secure_url');
    }

    return secureUrl;
  }

  /// Uploads when possible; returns null on failure (network, timeout, API error).
  Future<String?> tryUploadImage({
    required String storagePath,
    required XFile file,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      return await uploadImage(storagePath: storagePath, file: file).timeout(
        timeout,
      );
    } catch (_) {
      return null;
    }
  }
}
