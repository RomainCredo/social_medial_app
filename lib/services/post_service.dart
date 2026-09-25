import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _db.collection('posts');

  Future<void> createPost({
    required String text,
    String? imageUrl,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw PostException('You must be signed in to create a post.');
    }

    try {
      await _postsRef.add({
        'authorId': user.uid,
        'authorEmail': user.email ?? 'Unknown',
        'text': text,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    }
  }

  Stream<List<Post>> watchPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map(Post.fromFirestore).toList();
    });
  }

  Future<void> updatePost({
    required String postId,
    required String newText,
  }) async {
    try {
      await _postsRef.doc(postId).update({'text': newText});
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postsRef.doc(postId).delete();
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    }
  }

  String _messageFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'Please check your internet connection and try again.';
      case 'not-found':
        return 'That post no longer exists.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class PostException implements Exception {
  final String message;

  const PostException(this.message);

  @override
  String toString() => message;
}
