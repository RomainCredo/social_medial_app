import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Updated method signature to accept raw bytes (works on Web, iOS, Android, Desktop)
  Future<String> uploadPostImage({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final String fullFileName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final Reference ref = _storage.ref().child(
            'posts/$userId/$fullFileName',
          );

      // Use putData for Web & Mobile compatibility
      // 'uploadTask' is created without 'await'
      final UploadTask uploadTask = ref.putData(imageBytes);

      // 'await' returns the TaskSnapshot
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL directly from snapshot reference
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw StorageException(_messageFor(e));
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw StorageException(_messageFor(e));
    }
  }

  String _messageFor(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return 'You do not have permission to upload that file.';
      case 'canceled':
        return 'The upload was cancelled.';
      case 'object-not-found':
        return 'That file no longer exists.';
      case 'quota-exceeded':
        return 'Storage quota exceeded. Please try again later.';
      case 'retry-limit-exceeded':
        return 'The upload took too long. Please try again.';
      default:
        return 'Upload failed. Please try again.';
    }
  }
}

class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => message;
}