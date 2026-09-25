import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../widgets/post_card.dart';
import '../widgets/banner_ad_widget.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  late final Stream<List<Post>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.watchPosts();
  }

  Future<void> _openCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  Future<void> _handleDelete(Post post) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently remove the post. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (post.imageUrl != null) {
        await _storageService.deleteImage(post.imageUrl!);
      }
      await _postService.deletePost(post.id);
    } on PostException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _handleEdit(Post post) async {
    final TextEditingController editController = TextEditingController(
      text: post.text,
    );

    final String? newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: editController,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, editController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (newText == null || newText.isEmpty) {
      return;
    }

    try {
      await _postService.updatePost(postId: post.id, newText: newText);
    } on PostException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Social Feed')),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load posts. Please check your '
                  'connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<Post> posts = snapshot.data ?? <Post>[];

          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forum_outlined, size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No posts yet.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to create the first post.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final Post post = posts[index];
              final bool isOwner = post.authorId == currentUid;

              return PostCard(
                post: post,
                isOwner: isOwner,
                onEdit: isOwner ? () => _handleEdit(post) : null,
                onDelete: isOwner ? () => _handleDelete(post) : null,
              );
            },
          );
        },
      ),
      // kIsWeb checks if running in Chrome/Web and disables AdMob banner safely
      bottomNavigationBar: kIsWeb ? null : const BannerAdWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        tooltip: 'Create post',
        child: const Icon(Icons.add),
      ),
    );
  }
}
