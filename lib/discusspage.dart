import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:path/path.dart' as p;

class DiscussPage extends StatefulWidget {
  const DiscussPage({Key? key}) : super(key: key);

  @override
  State<DiscussPage> createState() => _DiscussPageState();
}

class _DiscussPageState extends State<DiscussPage> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  String? currentUserName;
  String? currentUserProfileImageUrl;
  bool _isLoading = false;
  String _sortBy = 'timestamp';

  File? _selectedImage;
  String? _selectedGifUrl;

  final Color primaryColor = const Color(0xFF4CAF50);
  final Color grayColor = const Color(0xFFF5F5F5); // Keep this line
  final Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          currentUserName =
              userDoc['username'] ?? user.email?.split('@')[0] ?? 'Anonymous';
          currentUserProfileImageUrl = userDoc['profileImageUrl'] ?? null;
        });
      } catch (e) {
        setState(() {
          currentUserName = user?.email?.split('@')[0] ?? 'Anonymous';
          currentUserProfileImageUrl = null;
        });
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Akses Dibatasi'),
            content: const Text('Silakan login untuk berinteraksi di forum.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showCreatePostDialog() {
    if (currentUserId == null) {
      _showLoginDialog();
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Buat Postingan Baru'),
          content: TextField(
            controller: _postController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Apa yang ingin Anda diskusikan?',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: 500,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _postController.clear();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _createPost();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text(
                'Posting',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _createPost() async {
    if (currentUserId == null) {
      _showLoginDialog();
      return;
    }
    if (_postController.text.trim().isEmpty &&
        _selectedImage == null &&
        _selectedGifUrl == null)
      return;
    setState(() => _isLoading = true);
    String? imageUrl;
    // Upload image jika ada (baik File maupun Uint8List)
    if (_selectedImage != null || _selectedImageBytes != null) {
      imageUrl = await _uploadImage(_selectedImage, _selectedImageBytes);
    }
    try {
      await _firestore.collection('forum_posts').add({
        'content': _postController.text.trim(),
        'userId': currentUserId,
        'username': currentUserName,
        'profileImageUrl': currentUserProfileImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'gifUrl': _selectedGifUrl,
        'likedBy': [],
        'commentCount': 0,
      });
      _postController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null; // Clear bytes after post
        _selectedGifUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dikirim!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
    setState(() => _isLoading = false);
  }

  void _toggleLikePost(String postId, List<dynamic> likedBy) async {
    if (currentUserId == null) {
      _showLoginDialog();
      return;
    }
    final postRef = _firestore.collection('forum_posts').doc(postId);
    final isLiked = likedBy.contains(currentUserId);
    await postRef.update({
      'likedBy':
          isLiked
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
    });
  }

  void _showCommentsDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Komentar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('forum_posts')
                            .doc(postId)
                            .collection('comments')
                            .orderBy('timestamp', descending: false)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      // Ambil data snapshot dengan aman
                      final QuerySnapshot? commentsSnapshot = snapshot.data;
                      // Periksa jika tidak ada data atau data null atau daftar dokumen kosong
                      if (!snapshot.hasData ||
                          commentsSnapshot == null ||
                          commentsSnapshot.docs.isEmpty) {
                        // Jika snapshot.data null atau docs kosong, tampilkan "Belum ada komentar"
                        return const Center(child: Text('Belum ada komentar'));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var comment = snapshot.data!.docs[index];
                          return _buildCommentItem(postId, comment);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                _buildCommentInput(postId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentInput(String postId) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            enabled: currentUserId != null,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText:
                  currentUserId == null
                      ? 'Login untuk menulis komentar...'
                      : 'Tulis komentar...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              border: const OutlineInputBorder(),
            ),
            maxLength: 300,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed:
              currentUserId == null
                  ? () => _showLoginDialog()
                  : () => _addComment(postId),
          icon: Icon(Icons.send, color: primaryColor),
        ),
      ],
    );
  }

  void _addComment(String postId, {String? parentCommentId}) async {
    if (currentUserId == null) {
      _showLoginDialog();
      return;
    }
    if (_commentController.text.trim().isEmpty) return;
    final commentData = {
      'content': _commentController.text.trim(),
      'userId': currentUserId,
      'username': currentUserName,
      'profileImageUrl': currentUserProfileImageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likedBy': [],
      'replies': [],
      'parentCommentId': parentCommentId ?? null,
    };
    try {
      final commentsRef = _firestore
          .collection('forum_posts')
          .doc(postId)
          .collection('comments');
      await commentsRef.add(commentData);
      await _firestore.collection('forum_posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _toggleLikeComment(
    String postId,
    String commentId,
    List<dynamic> likedBy,
  ) async {
    if (currentUserId == null) {
      _showLoginDialog();
      return;
    }
    final commentRef = _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final isLiked = likedBy.contains(currentUserId);
    await commentRef.update({
      'likedBy':
          isLiked
              ? FieldValue.arrayRemove([currentUserId])
              : FieldValue.arrayUnion([currentUserId]),
    });
  }

  Widget _buildCommentItem(String postId, DocumentSnapshot comment) {
    final commentData = comment.data() as Map<String, dynamic>?;
    if (commentData == null) {
      // Handle case where comment data is null (e.g., deleted)
      return const SizedBox.shrink();
    }
    final likedBy = commentData['likedBy'] ?? [];
    final isLiked = likedBy.contains(currentUserId);
    String timeAgo = '';
    if (commentData['timestamp'] != null) {
      DateTime timestamp = (commentData['timestamp'] as Timestamp).toDate();
      timeAgo = _getTimeAgo(timestamp);
    }

    // Untuk reply section
    return StatefulBuilder(
      builder: (context, setStateSB) {
        bool showReplies = false;
        bool showReplyInput = false;
        final repliesStream =
            _firestore
                .collection('forum_posts')
                .doc(postId)
                .collection('comments')
                .doc(comment.id)
                .collection('replies')
                .orderBy('timestamp', descending: false)
                .snapshots();

        Widget replyInputWidget() {
          final replyController = TextEditingController();
          return Padding(
            padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Tulis balasan...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 300,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      currentUserId == null
                          ? () => _showLoginDialog()
                          : () async {
                            if (replyController.text.trim().isNotEmpty) {
                              await _firestore
                                  .collection('forum_posts')
                                  .doc(postId)
                                  .collection('comments')
                                  .doc(comment.id)
                                  .collection('replies')
                                  .add({
                                    'content': replyController.text.trim(),
                                    'userId': currentUserId,
                                    'username': currentUserName,
                                    'profileImageUrl':
                                        currentUserProfileImageUrl,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'likedBy': [],
                                  });
                              replyController.clear();
                              setStateSB(() {
                                showReplyInput = false;
                                showReplies = true;
                              });
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Kirim',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: repliesStream,
          builder: (context, snapshot) {
            // Ambil data snapshot balasan dengan aman
            final QuerySnapshot? repliesSnapshot = snapshot.data;
            // Hitung jumlah balasan, pastikan repliesSnapshot dan docs tidak null
            final replyCount =
                (repliesSnapshot != null && repliesSnapshot.docs.isNotEmpty)
                    ? repliesSnapshot.docs.length
                    : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: grayColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor,
                        backgroundImage:
                            commentData['profileImageUrl'] != null
                                ? NetworkImage(commentData['profileImageUrl'])
                                : null,
                        child:
                            commentData['profileImageUrl'] == null
                                ? Text(
                                  (commentData['username'] ?? 'A')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  commentData['username'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              commentData['content'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap:
                            currentUserId == null
                                ? () => _showLoginDialog()
                                : () => _toggleLikeComment(
                                  postId,
                                  comment.id,
                                  likedBy,
                                ),
                        child: Row(
                          children: [
                            // Ganti icon love menjadi icon like (thumb up)
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              color: isLiked ? Colors.blue : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${likedBy.length}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap:
                            currentUserId == null
                                ? () => _showLoginDialog()
                                : () {
                                  setStateSB(() {
                                    showReplyInput = !showReplyInput;
                                  });
                                },
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (replyCount > 0) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            setStateSB(() {
                              showReplies = !showReplies;
                            });
                          },
                          child: Text(
                            replyCount == 1
                                ? '1 balasan'
                                : '$replyCount balasan',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showReplyInput) replyInputWidget(),
                  if (showReplies && replyCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Gunakan null-aware operator untuk memastikan docs tidak null sebelum map
                        children:
                            (repliesSnapshot?.docs ?? []).map((replyDoc) {
                              final reply =
                                  replyDoc.data() as Map<String, dynamic>?;
                              if (reply == null) {
                                return const SizedBox.shrink();
                              }

                              String replyTimeAgo = '';
                              if (reply['timestamp'] != null) {
                                DateTime timestamp =
                                    (reply['timestamp'] as Timestamp).toDate();
                                replyTimeAgo = _getTimeAgo(timestamp);
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: primaryColor,
                                      backgroundImage:
                                          reply['profileImageUrl'] != null
                                              ? NetworkImage(
                                                reply['profileImageUrl'],
                                              )
                                              : null,
                                      child:
                                          reply['profileImageUrl'] == null
                                              ? Text(
                                                (reply['username'] ?? 'A')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                reply['username'] ??
                                                    'Anonymous',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                replyTimeAgo,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            reply['content'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostItem(DocumentSnapshot post) {
    var postData = post.data() as Map<String, dynamic>?;
    if (postData == null) {
      return const SizedBox.shrink();
    }
    List<dynamic> likedBy = postData['likedBy'] ?? [];
    bool isLiked = likedBy.contains(currentUserId);

    String timeAgo = '';
    if (postData['timestamp'] != null) {
      DateTime timestamp = (postData['timestamp'] as Timestamp).toDate();
      timeAgo = _getTimeAgo(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor,
                backgroundImage:
                    postData['profileImageUrl'] != null
                        ? NetworkImage(postData['profileImageUrl'])
                        : null,
                child:
                    postData['profileImageUrl'] == null
                        ? Text(
                          (postData['username'] ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              // Username dan waktu di tengah sejajar dengan avatar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              postData['username'] ?? 'Anonymous',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tambahkan jarak antara username dan isi post
          const SizedBox(height: 24),
          Text(
            postData['content'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (postData['imageUrl'] != null && postData['imageUrl'] != '')
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Image.network(
                      postData['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) => const SizedBox(),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap:
                        currentUserId == null
                            ? () => _showLoginDialog()
                            : () => _toggleLikePost(post.id, likedBy),
                    child: Row(
                      children: [
                        Icon(
                          Icons.thumb_up_outlined, // Upvote icon
                          color: isLiked ? Colors.pinkAccent : Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${likedBy.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => _showCommentsDialog(post.id),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${postData['commentCount'] ?? 0}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ...bisa tambahkan tombol lain di kanan jika perlu...
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Query _getPostsQuery() {
    if (_sortBy == 'timestamp') {
      return _firestore
          .collection('forum_posts')
          .orderBy('timestamp', descending: true);
    } else if (_sortBy == 'timestamp_lama') {
      return _firestore
          .collection('forum_posts')
          .orderBy('timestamp', descending: false);
    } else if (_sortBy == 'likedBy') {
      return _firestore
          .collection('forum_posts')
          .orderBy('likedBy', descending: true);
    }
    return _firestore
        .collection('forum_posts')
        .orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grayColor,
      appBar: AppBar(
        title: Text(
          'Forum Diskusi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTextStyle(
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
        child: Column(
          children: [
            _buildPostInputForm(),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('forum_posts').snapshots(),
              builder: (context, snapshot) {
                int totalComments = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data != null && data['commentCount'] != null) {
                      totalComments += (data['commentCount'] as int);
                    }
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    bottom: 24,
                    left: 14,
                    right: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 14),
                          Text(
                            '$totalComments Komentar',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Section filter sort
                      Row(
                        children: [
                          _buildSortButton(
                            'timestamp', // Nilai _sortBy untuk 'Terbaru'
                            'Terbaru',
                          ),
                          const SizedBox(width: 8),
                          _buildSortButton(
                            'timestamp_lama', // Nilai _sortBy untuk 'Terlama'
                            'Terlama',
                          ),
                          const SizedBox(width: 8),
                          _buildSortButton(
                            'likedBy', // Nilai _sortBy untuk 'Terpopuler'
                            'Terpopuler',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getPostsQuery().snapshots(),
                builder: (context, snapshot) {
                  // Tangani status loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Tangani status error
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  // Ambil data dari snapshot dengan aman
                  final QuerySnapshot? postsSnapshot = snapshot.data;

                  // Tangani status tidak ada data atau data kosong
                  if (postsSnapshot == null || postsSnapshot.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada postingan.\nMulai diskusi pertama Anda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: postsSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      return _buildPostItem(postsSnapshot.docs[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPostInputForm() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _postController,
            maxLines: 5,
            minLines: 2,
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Komen di mari...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              border: InputBorder.none,
              counterText: '',
            ),
            maxLength: 500,
            // Tidak perlu onChanged: setState atau FocusNode apapun di sini!
          ),
          // Icon gambar tampil di bawah form input jika ada gambar
          if (_selectedImage != null || _selectedImageBytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        _selectedImage != null
                            ? Image.file(
                              _selectedImage!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                            : Image.memory(
                              _selectedImageBytes!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Icon GIF dan Sticker tetap di bawah tombol gambar
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: Text(
                    'Gambar',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(90, 36),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickGif,
                  icon: const Icon(Icons.gif_box_outlined, color: Colors.white),
                  label: Text(
                    'GIF',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(70, 36),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickSticker,
                  icon: const Icon(
                    Icons.sticky_note_2_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Sticker',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(90, 36),
                  ),
                ),
                if (_selectedGifUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              _selectedGifUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap:
                                  () => setState(() => _selectedGifUrl = null),
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          'Kirim',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New variable to store image bytes for web
  Uint8List? _selectedImageBytes;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (UniversalPlatform.isWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImage = null; // Ensure File is null for web
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path);
          _selectedImageBytes = null; // Ensure bytes are null for non-web
        });
      }
    }
  }

  Future<String?> _uploadImage(File? imageFile, Uint8List? imageBytes) async {
    if (imageFile == null && imageBytes == null) return null;

    try {
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
          (imageFile != null ? p.extension(imageFile.path) : '.png');
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'post_images/$fileName',
      );

      if (imageFile != null)
        await storageRef.putFile(imageFile);
      else if (imageBytes != null)
        await storageRef.putData(imageBytes);

      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah gambar: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _pickGif() async {
    try {
      GiphyGif? gif = await GiphyGet.getGif(
        context: context,
        apiKey: "fRv0FYUCeGLferKRiqjh7zKiqN1GJ0SA",
        lang: "id", // Menggunakan string literal untuk kode bahasa
      );
      if (gif != null) {
        setState(() {
          _selectedGifUrl = gif.images?.original?.url;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil GIF: ${e.toString()}')),
      );
      setState(() {
        _selectedGifUrl = null;
      });
    }
  }

  Future<void> _pickSticker() async {
    try {
      GiphyGif? sticker = await GiphyGet.getGif(
        // Menggunakan getGif
        context: context,
        apiKey: "fRv0FYUCeGLferKRiqjh7zKiqN1GJ0SA",
        lang: "id",
      );
      if (sticker != null) {
        setState(() {
          _selectedGifUrl = sticker.images?.original?.url;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil Sticker: ${e.toString()}')),
      );
      setState(() {
        _selectedGifUrl = null;
      });
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Tambahkan di dalam _DiscussPageState:
  Widget _buildSortButton(
    String
    sortValue, // Mengganti 'value' menjadi 'sortValue' yang lebih deskriptif
    String label,
  ) {
    final bool isSelected = _sortBy == sortValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = sortValue; // Langsung gunakan sortValue sebagai _sortBy
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Colors
                        .black // Border juga hitam
                    : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
