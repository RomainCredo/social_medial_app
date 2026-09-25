import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorEmail;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorEmail,
    required this.text,
    this.imageUrl,
    this.createdAt,
  });

  factory Post.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    return Post(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorEmail: data['authorEmail'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorEmail': authorEmail,
      'text': text,
      'imageUrl': imageUrl,
    };
  }
}
