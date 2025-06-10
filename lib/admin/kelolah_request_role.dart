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
  
  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => isLoading = true);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('role_requests')
          .get(const GetOptions(source: Source.server));

      users = snapshot.docs.map((doc) => UserData.fromFirestore(doc)).toList();
      
      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      print('❌ Error fetching users: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showMessage('Gagal memuat data pengguna', false);
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
            Expanded(
              child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
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

  Widget _buildContent() {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada permintaan peran',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUsers,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      ),
    );
  }

  Widget _buildUserCard(UserData user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildRoleBadge(user.role),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email_outlined, user.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_outlined, 'Created: ${user.createdAt}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'Lihat',
                  color: Colors.amber[700]!,
                  onTap: () => _showUserDetailModal(user),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Hapus',
                  color: Colors.red[700]!,
                  onTap: () => _confirmRejectUser(user.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'Admin';
    return Container(
      decoration: BoxDecoration(
        color: (isAdmin ? Colors.green : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        role,
        style: TextStyle(
          color: isAdmin ? Colors.green : Colors.blue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
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

  Future<void> _confirmRejectUser(String requestId) async {
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
    
    if (confirm == true) await _rejectUser(requestId);
  }

  void _showUserDetailModal(UserData user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (modalContext) => _buildUserDetailModal(modalContext, user),
    );
  }

  Widget _buildUserDetailModal(BuildContext modalContext, UserData user) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(modalContext).size.height * 0.85,
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(modalContext),
                ),
              ],
            ),
          ),
          
          const Divider(height: 24),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  _buildUserInfoCard(user),
                  const SizedBox(height: 20),
                  _buildKTPCard(user),
                ],
              ),
            ),
          ),
          
          // Action buttons
          _buildActionButtons(modalContext, user),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(UserData user) {
    final details = [
      DetailItem(Icons.business, "Destination Name", user.destinationName),
      DetailItem(Icons.description, "Deskripsi", user.description),
      DetailItem(Icons.account_balance, "Bank", user.bankName),
      DetailItem(Icons.account_balance_wallet, "Nomor Rekening", user.accountNumber),
      DetailItem(Icons.badge, "Current Role", user.role),
      DetailItem(Icons.calendar_today, "Created at", user.createdAt),
      DetailItem(Icons.verified_user, "Status", user.status),
      DetailItem(Icons.location_pin, "Maps Url", user.mapsUrl),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...details.map((detail) => _buildDetailItem(detail)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(DetailItem detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(detail.icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.value.isNotEmpty ? detail.value : "-",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKTPCard(UserData user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            child: _buildKTPImage(user.ktpUrl),
          ),
        ],
      ),
    );
  }

  Widget _buildKTPImage(String ktpUrl) {
    if (ktpUrl.isEmpty) {
      return _buildPlaceholder("Tidak ada gambar KTP", Icons.image_not_supported);
    }

    return CachedNetworkImage(
      imageUrl: ktpUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => 
          _buildPlaceholder("Tidak dapat memuat gambar", Icons.broken_image),
    );
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Container(
      height: 150,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext modalContext, UserData user) {
    return Container(
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
              onPressed: () {
                Navigator.pop(modalContext);
                _approveUser(user);
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
              onPressed: () {
                Navigator.pop(modalContext);
                _rejectUser(user.id);
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
    );
  }

  Future<void> _approveUser(UserData user) async {
    if (!mounted) return;
    
    _showLoadingDialog();
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Add to owners collection
      final ownerRef = FirebaseFirestore.instance.collection('owners').doc();
      batch.set(ownerRef, user.toOwnerMap());
      
      // Update user role
      if (user.userId.isNotEmpty) {
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(user.userId),
          {'role': 'Owner'}
        );
      }
      
      // Delete request
      batch.delete(
        FirebaseFirestore.instance.collection('role_requests').doc(user.id)
      );
      
      // Add notification
      if (user.userId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance.collection('notifications').doc(),
          {
            'userId': user.userId,
            'title': 'Permintaan Peran Disetujui',
            'message': 'Permintaan peran Owner Anda telah disetujui.',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'role_approval',
          }
        );
      }
      
      await batch.commit();
      
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Permintaan berhasil disetujui', true);
        _fetchUsers();
      }
    } catch (e) {
      print('❌ Error approving user: $e');
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Gagal menyetujui permintaan', false);
      }
    }
  }

  Future<void> _rejectUser(String requestId) async {
    if (!mounted) return;
    
    _showLoadingDialog();
    
    try {
      // Get request data
      final requestDoc = await FirebaseFirestore.instance
          .collection('role_requests')
          .doc(requestId)
          .get();
      
      if (!requestDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
          _showMessage('Permintaan sudah tidak tersedia', false);
          _fetchUsers();
        }
        return;
      }
      
      final userId = requestDoc.data()?['userId'] ?? '';
      final batch = FirebaseFirestore.instance.batch();
      
      // Delete request
      batch.delete(
        FirebaseFirestore.instance.collection('role_requests').doc(requestId)
      );
      
      // Add rejection notification
      if (userId.isNotEmpty) {
        batch.set(
          FirebaseFirestore.instance.collection('notifications').doc(),
          {
            'userId': userId,
            'title': 'Permintaan Peran Ditolak',
            'message': 'Maaf, permintaan peran Owner Anda telah ditolak.',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'role_rejection',
          }
        );
      }
      
      await batch.commit();
      
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Permintaan berhasil ditolak', true);
        _fetchUsers();
      }
    } catch (e) {
      print('❌ Error rejecting user: $e');
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Gagal menolak permintaan', false);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showMessage(String message, bool isSuccess) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Helper classes for cleaner code structure
class DetailItem {
  final IconData icon;
  final String title;
  final String value;
  
  DetailItem(this.icon, this.title, this.value);
}

class UserData {
  final String id;
  final String userId;
  final String username;
  final String email;
  final String bankName;
  final String role;
  final String description;
  final String accountNumber;
  final String createdAt;
  final String mapsUrl;
  final String destinationName;
  final String ktpUrl;
  final String status;

  UserData({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.bankName,
    required this.accountNumber,
    required this.mapsUrl,
    required this.description,
    required this.destinationName,
    required this.createdAt,
    required this.ktpUrl,
    required this.status,
  });

  // Factory constructor for creating UserData from Firestore document
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'No Name',
      email: data['email'] ?? '',
      bankName: data['bankName'] ?? '',
      mapsUrl: data['mapsUrl'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      description: data['description'] ?? '',
      role: data['role'] ?? 'User',
      createdAt: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate().toString()
          : '',
      destinationName: data['destinationName'] ?? '',
      ktpUrl: data['ktpUrl'] ?? '',
      status: data['status'] ?? '',
    );
  }

  // Convert to map for owners collection
  Map<String, dynamic> toOwnerMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'bankName': bankName,
      'accountName': accountNumber,
      'destinationName': destinationName,
      'description': description,
      'mapsUrl': mapsUrl,
      'ktpUrl': ktpUrl,
      'approvedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    };
  }
}