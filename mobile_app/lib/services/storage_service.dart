import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
  }

  Future<String> uploadImage({
    required String storagePath,
    required XFile file,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeForPath(file.name);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  /// Uploads when possible; returns null on failure (e.g. Storage not configured).
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

  String _contentTypeForPath(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
