import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guide_me/Register.dart';
import 'package:guide_me/admin/adminpage.dart';
import 'package:guide_me/forgotpassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'dart:io' show Platform; // Untuk Platform detection
import 'Home.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Method untuk mendeteksi platform
  String _getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'unknown';
    }
  }

  // Method untuk memeriksa apakah owner bisa login di platform ini
  bool _isOwnerAllowedOnPlatform() {
    String platform = _getCurrentPlatform();

    // Konfigurasi platform yang diizinkan untuk owner
    // Ubah sesuai kebutuhan bisnis Anda
    List<String> allowedPlatforms = [
      'web', // Web browser
      'windows', // Desktop Windows
      'macos', // Desktop macOS
      'linux', // Desktop Linux
      'android', // Mobile Android (DITAMBAHKAN)
      'ios', // Mobile iOS (DITAMBAHKAN)
    ];

    return allowedPlatforms.contains(platform);
  }

  Future<void> _checkEmailVerification(String userId) async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'emailVerified': true},
        );
        print("Status emailVerified berhasil diperbarui di Firestore!");
      } catch (e) {
        print("Gagal memperbarui emailVerified: $e");
      }
    } else {
      print("Email belum diverifikasi atau user null!");
    }
  }

  Future<void> _saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', role);
      print("User role saved to SharedPreferences: $role");
    } catch (e) {
      print("Error saving user role to SharedPreferences: $e");
    }
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password harus diisi!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        if (!user!.emailVerified) {
          await _auth.signOut();
          _showError('Email belum diverifikasi! Silakan cek email Anda.');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await _checkEmailVerification(user.uid);
        _redirectUser(user);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e.code == 'invalid-email') {
        _showError('Format email tidak valid!');
      } else if (e.code == 'user-not-found') {
        _showError('Email tidak terdaftar!');
      } else if (e.code == 'wrong-password') {
        _showError('Password salah!');
      } else {
        _showError('Email atau password salah!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Terjadi kesalahan, coba lagi.');
    }
  }

  void _redirectUser(User user) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        String currentPlatform = _getCurrentPlatform();

        print("User logged in with role: $role on platform: $currentPlatform");

        if (role == 'admin') {
          await _saveUserRole(role);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
        } else if (role == 'Owner') {
          // PERBAIKAN: Cek apakah owner diizinkan di platform ini
          if (_isOwnerAllowedOnPlatform()) {
            await _saveUserRole(role);

            // Arahkan ke halaman yang sesuai untuk owner
            // Anda bisa membuat halaman khusus owner atau gunakan AdminPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else {
            // Jika masih ingin membatasi di platform tertentu
            await _auth.signOut();
            setState(() {
              _isLoading = false;
            });
            _showError(
              'Akses owner dibatasi untuk platform $currentPlatform. Silakan gunakan web browser.',
            );
            return;
          }
        } else if (role == 'user') {
          await _saveUserRole(role);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          await _auth.signOut();
          setState(() {
            _isLoading = false;
          });
          _showError('Role pengguna tidak valid!');
        }
      } else {
        _showError('User data tidak ditemukan!');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in _redirectUser: $e");
      _showError('Terjadi kesalahan saat mengambil data pengguna!');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Login Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _emailController.clear();
                  _passwordController.clear();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.grey[300]),

          Container(
            width: double.infinity,
            height: 300,
            decoration: const BoxDecoration(
              color: Color(0xFF5ABB4D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            ),
          ),

          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/logo5.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),

          Positioned(
            top: 160,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "WELCOME BACK",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            top: 220,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5ABB4D),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Register()),
                      );
                    },
                    child: const Text("Create New Account"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
