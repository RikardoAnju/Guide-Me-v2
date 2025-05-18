import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Kelolahuser extends StatefulWidget {
  const Kelolahuser({super.key});

  @override
  State<Kelolahuser> createState() => _KelolahUserPageState();
}

class _KelolahUserPageState extends State<Kelolahuser> {
  List<UserData> users = [];
  bool isLoading = true;
  // Track if we're already connected to Firestore to avoid enabling network multiple times
  bool isNetworkEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> _enableNetwork() async {
    if (!isNetworkEnabled) {
      try {
        await FirebaseFirestore.instance.enableNetwork();
        isNetworkEnabled = true;
      } catch (e) {
        print('Failed to enable network: $e');
        // Continue anyway since we might already be connected
      }
    }
  }

  Future<void> fetchUsers() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      await _enableNetwork();
      
      // Use a single instance of FirebaseFirestore to avoid target ID conflicts
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('role_requests').get();

      final List<UserData> loadedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserData(
          id: doc.id,
          userId: data['userId'] ?? '',
          username: data['username'] ?? 'No Name',
          email: data['email'] ?? '',
          role: data['role'] ?? 'User',
          createdAt: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate().toString()
              : '',
          destinationName: data['destinationName'] ?? '',
          ktpUrl: data['ktpUrl'] ?? '',
          status: data['status'] ?? '',
        );
      }).toList();

      if (mounted) {
        setState(() {
          users = loadedUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: users.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada permintaan peran',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: users.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return _buildUserCard(users[index]);
                              },
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Kelola Pengguna',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 15,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserData user) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username and role badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: user.role == 'Admin'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: user.role == 'Admin' ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email_outlined, user.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined,
                'Created: ${user.createdAt}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  icon: Icons.visibility,
                  label: 'Lihat',
                  color: Colors.amber[700],
                  background: Colors.amber.withOpacity(0.1),
                  onTap: () => _showUserDetailModal(user),
                ),
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.delete,
                  label: 'Hapus',
                  color: Colors.red[700],
                  background: Colors.red.withOpacity(0.1),
                  onTap: () => _confirmRejectUser(context, user.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color? color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Add confirmation dialog to avoid accidental deletion
  Future<void> _confirmRejectUser(BuildContext context, String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menolak permintaan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _rejectUser(requestId);
    }
  }

  void _showUserDetailModal(UserData user) {
    final scaffoldContext = context;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (modalContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalContext).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detail Pengguna",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 24),
              
              // Content - Scrollable
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User basic info Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.green.withOpacity(0.1),
                                    child: Text(
                                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailItem(
                                icon: Icons.business,
                                title: "Destination Name",
                                value: user.destinationName,
                              ),
                              _buildDetailItem(
                                icon: Icons.badge,
                                title: "Current Role",
                                value: user.role,
                              ),
                              _buildDetailItem(
                                icon: Icons.calendar_today,
                                title: "Created at",
                                value: user.createdAt,
                              ),
                              _buildDetailItem(
                                icon: Icons.verified_user,
                                title: "Status",
                                value: user.status,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // KTP Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.perm_identity, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "KTP Image",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              child: user.ktpUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: user.ktpUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Tidak dapat memuat gambar",
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 150,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Tidak ada gambar KTP",
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _approveUser(user);
                            Navigator.pop(modalContext);
                          } catch (e) {
                            Navigator.pop(modalContext);
                            _showErrorSnackbar(scaffoldContext, 'Gagal menyetujui permintaan: $e');
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Setujui Owner"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _rejectUser(user.id);
                            Navigator.pop(modalContext);
                          } catch (e) {
                            Navigator.pop(modalContext);
                            _showErrorSnackbar(scaffoldContext, 'Gagal menolak permintaan: $e');
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text("Tolak"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : "-",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(UserData user) async {
    if (!mounted) return;
    
    try {
      await _enableNetwork();
      
      // Use a WriteBatch for atomicity
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      
      // 1. Update user's role in the 'users' collection
      if (user.userId.isNotEmpty) {
        final userRef = firestore.collection('users').doc(user.userId);
        batch.update(userRef, {'role': 'Owner'});
      }
      
      // 2. Delete the request from 'role_requests' collection
      final requestRef = firestore.collection('role_requests').doc(user.id);
      batch.delete(requestRef);
      
      // 3. Add to notifications collection
      final notifRef = firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': user.userId,
        'title': 'Permintaan Peran Disetujui',
        'message': 'Permintaan peran Owner Anda telah disetujui.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'role_approval',
      });
      
      // Commit the batch
      await batch.commit();
      
      // Show success message and refresh the user list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan berhasil disetujui'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        fetchUsers();
      }
    } catch (e) {
      print('❌ Error approving user: $e');
      if (mounted) {
        _showErrorSnackbar(context, 'Gagal menyetujui permintaan');
      }
      rethrow; // Rethrow to handle in the caller
    }
  }

  Future<void> _rejectUser(String requestId) async {
    if (!mounted) return;
    
    try {
      await _enableNetwork();
      
      // Get the user request first to capture the userId for notification
      final firestore = FirebaseFirestore.instance;
      final requestDoc = await firestore.collection('role_requests').doc(requestId).get();
      final requestData = requestDoc.data();
      final userId = requestData?['userId'] ?? '';
      
      // Use a WriteBatch for atomicity
      final batch = firestore.batch();
      
      // 1. Delete the request from 'role_requests' collection
      final requestRef = firestore.collection('role_requests').doc(requestId);
      batch.delete(requestRef);
      
      // 2. Add to notifications collection if we have a userId
      if (userId.isNotEmpty) {
        final notifRef = firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': userId,
          'title': 'Permintaan Peran Ditolak',
          'message': 'Maaf, permintaan peran Owner Anda telah ditolak.',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'role_rejection',
        });
      }
      
      // Commit the batch
      await batch.commit();
      
      // Show success message and refresh the user list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan berhasil ditolak'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        fetchUsers();
      }
    } catch (e) {
      print('❌ Error rejecting user: $e');
      if (mounted) {
        _showErrorSnackbar(context, 'Gagal menolak permintaan');
      }
      rethrow; // Rethrow to handle in the caller
    }
  }
}

class UserData {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String role;
  final String createdAt;
  final String destinationName;
  final String ktpUrl;
  final String status;

  UserData({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.destinationName,
    required this.ktpUrl,
    required this.status,
  });
}