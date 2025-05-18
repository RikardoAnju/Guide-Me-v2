import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guide_me/home.dart';

class TambahDestinasiPage extends StatefulWidget {
  const TambahDestinasiPage({super.key});

  @override
  State<TambahDestinasiPage> createState() => TambahDestinasiPageState();
}

class TambahDestinasiPageState extends State<TambahDestinasiPage> {
  // Form controllers
  final TextEditingController _namaDestinasiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaTiketController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // User data
  String _username = '';
  String _email = '';
  String _userId = '';

  // Destination image data
  File? _destinasiImage;
  Uint8List? _destinasiBytes;
  String? _destinasiFileName;

  // State tracking
  bool _isLoading = false;
  bool _hasPendingRequest = false;
  bool _isDestinasiFree = false; // New state for tracking free destinations
  String? _pendingRequestId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkExistingRequests();
  }

  @override
  void dispose() {
    _namaDestinasiController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _hargaTiketController.dispose();
    super.dispose();
  }

  // Load current user data
  void _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final data = doc.data();

      if (data != null) {
        setState(() {
          _username = data['username'] ?? '';
          _email = data['email'] ?? '';
          _userId = currentUser.uid;
        });
      }
    }
  }

  // Check if user already has a pending request
  void _checkExistingRequests() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('destinasi_requests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _hasPendingRequest = true;
          _pendingRequestId = querySnapshot.docs[0].id;
        });
      }
    } catch (e) {
      _showSnackBar('Error checking existing requests: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pick destination image
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _destinasiFileName = result.files.single.name;
          if (kIsWeb) {
            _destinasiBytes = result.files.single.bytes!;
          } else {
            _destinasiImage = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  // Upload destination image to Firebase Storage
  Future<String?> _uploadImageToStorage() async {
    try {
      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Create a unique filename using timestamp and original filename
      final filename = 'destinasi_${DateTime.now().millisecondsSinceEpoch}_$_destinasiFileName';
      final storageRef = FirebaseStorage.instance.ref().child('destinasi_images/$filename');

      // Set metadata with custom claims if needed
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': currentUser.uid,
          'uploadTime': DateTime.now().toString(),
        },
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(_destinasiBytes!, metadata);
      } else {
        uploadTask = storageRef.putFile(_destinasiImage!, metadata);
      }

      // Handle potential errors during upload
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.state == TaskState.error) {
          _showSnackBar('Terjadi kesalahan saat mengunggah gambar', isError: true);
        }
      });

      // Await upload completion
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error detail: $e');
      throw Exception('Error uploading image: $e');
    }
  }

  // Submit the request
  void _submitRequest() async {
    // Check for pending request
    if (_hasPendingRequest) {
      _showSnackBar(
        'Anda sudah memiliki permintaan destinasi yang sedang ditinjau.',
        isError: true,
      );
      return;
    }

    // Validate form and image
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_destinasiImage == null && _destinasiBytes == null) {
      _showSnackBar('Harap upload foto destinasi terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Ensure user is authenticated before proceeding
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        _showSnackBar('Anda perlu login terlebih dahulu', isError: true);
        return;
      }
      
      // Check Firebase Storage permissions
      try {
        // Upload destination image
        final String? imageDownloadUrl = await _uploadImageToStorage();
        if (imageDownloadUrl == null) {
          throw Exception('Gagal mengupload gambar destinasi');
        }

        // Calculate price (0 if free, otherwise parse from controller)
        final double hargaTiket = _isDestinasiFree 
          ? 0.0 
          : double.tryParse(_hargaTiketController.text.trim()) ?? 0.0;

        // Add destination request to Firestore
        final docRef = await FirebaseFirestore.instance.collection('destinasi_requests').add({
          'namaDestinasi': _namaDestinasiController.text.trim(),
          'lokasi': _lokasiController.text.trim(),
          'deskripsi': _deskripsiController.text.trim(),
          'hargaTiket': hargaTiket,
          'isFree': _isDestinasiFree, // Add isFree flag to database
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrl': imageDownloadUrl,
          'userId': _userId,
          'username': _username,
          'email': _email,
        });

        setState(() {
          _isLoading = false;
          _hasPendingRequest = true;
          _pendingRequestId = docRef.id;
        });

        _showSnackBar(
          'Permintaan destinasi berhasil dikirim! Kami akan memproses dalam 1-3 hari kerja.',
          isError: false,
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      } catch (e) {
        if (e.toString().contains('firebase_storage/unauthorized')) {
          _showSnackBar(
            'Akses storage ditolak. Pastikan Anda memiliki izin untuk mengunggah gambar.',
            isError: true
          );
        } else {
          _showSnackBar('Gagal mengirim permintaan: $e', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show SnackBar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E7D32), size: 20),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        title: Text(
          'Tambah Destinasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _hasPendingRequest
              ? _buildPendingRequestView()
              : _buildRequestForm(),
    );
  }

  // Build the pending request view
  Widget _buildPendingRequestView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFFFBC02D),
                    size: 60,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Permintaan Sedang Ditinjau',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Anda sudah memiliki permintaan destinasi yang sedang dalam proses peninjauan. Silakan tunggu hingga admin meninjau permintaan Anda.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Proses peninjauan biasanya membutuhkan waktu 1-3 hari kerja.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'KEMBALI KE BERANDA',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the request form
  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildHeaderCard(),
            const SizedBox(height: 24),
            
            // Form fields
            _buildFormSection(
              title: 'Informasi Destinasi',
              icon: Icons.place_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _namaDestinasiController,
                    label: 'Nama Destinasi',
                    hint: 'Masukkan nama destinasi wisata',
                    icon: Icons.tour_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama destinasi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lokasiController,
                    label: 'Lokasi',
                    hint: 'Masukkan alamat lengkap destinasi',
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lokasi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Checkbox for free destination
                  Row(
                    children: [
                      Checkbox(
                        value: _isDestinasiFree,
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (value) {
                          setState(() {
                            _isDestinasiFree = value ?? false;
                            // Clear harga tiket if marked as free
                            if (_isDestinasiFree) {
                              _hargaTiketController.clear();
                            }
                          });
                        },
                      ),
                      Text(
                        'Destinasi Gratis (Tidak Berbayar)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Only show harga tiket field if not free
                  if (!_isDestinasiFree)
                    _buildTextField(
                      controller: _hargaTiketController,
                      label: 'Harga Tiket (Rp)',
                      hint: 'Contoh: 25000',
                      icon: Icons.monetization_on_outlined,
                      validator: (value) {
                        if (!_isDestinasiFree) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tiket tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Harga tiket harus berupa angka';
                          }
                        }
                        return null;
                      },
                    ),
                  if (!_isDestinasiFree)
                    const SizedBox(height: 16),
                    
                  _buildTextField(
                    controller: _deskripsiController,
                    label: 'Deskripsi',
                    hint: 'Jelaskan tentang destinasi wisata Anda',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi tidak boleh kosong';
                      }
                      if (value.length < 20) {
                        return 'Deskripsi terlalu pendek (min 20 karakter)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Destination image upload section
            _buildFormSection(
              title: 'Upload Foto Destinasi',
              icon: Icons.image_outlined,
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_destinasiImage == null && _destinasiBytes == null)
                          ? Colors.grey.shade300
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                  child: (_destinasiImage != null || _destinasiBytes != null)
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.memory(_destinasiBytes!, fit: BoxFit.cover, width: double.infinity)
                                  : Image.file(_destinasiImage!, fit: BoxFit.cover, width: double.infinity),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _destinasiImage = null;
                                    _destinasiBytes = null;
                                    _destinasiFileName = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, size: 36, color: Color(0xFF2E7D32)),
                            const SizedBox(height: 12),
                            Text(
                              'Tap untuk upload foto destinasi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            if (_destinasiFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'File: $_destinasiFileName',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF2E7D32),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 32),
            
            // Terms and conditions notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFAED581)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dengan mengirim permintaan ini, Anda menyetujui bahwa data yang diberikan akan digunakan untuk proses verifikasi destinasi.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF558B2F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'KIRIM PERMINTAAN',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build header card
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tambah Destinasi Wisata',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan lengkapi data berikut untuk mengajukan permintaan penambahan destinasi wisata baru. Permintaan akan diproses dalam 1-3 hari kerja.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Build form section with title
  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
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
                Icon(icon, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // Build text field with label
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
}