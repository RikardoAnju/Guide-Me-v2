import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guide_me/home.dart';
import 'discusspage.dart';
import 'package:guide_me/eventpage.dart';
import 'package:guide_me/galeripage.dart';
import './app_colors.dart';
import 'requestRole.dart';
import 'tambah_destinasi.dart';

class DestinasiPage extends StatefulWidget {
  const DestinasiPage({super.key});
  @override
  State<DestinasiPage> createState() => _DestinasiPageState();
}

class _DestinasiPageState extends State<DestinasiPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;

  final List<Map<String, Object>> destinasiList = const [
    // Pastikan jalur gambar adalah aset lokal yang benar
    {
      'title': "Jembatan Barelang",
      'image': "assets/images/slider1.png",
      'rating': 4.9,
      'location': 'Batam',
      'description':
          "Jembatan Barelang adalah rangkaian enam jembatan yang menghubungkan Batam dengan beberapa pulau kecil seperti Rempang dan Galang. Pembangunan jembatan ini dimulai pada tahun 1992 dan selesai pada tahun 1998. Jembatan ini menjadi salah satu ikon wisata Batam. Barelang, yang Galang, Pembangunan jembatan ini merupakan bagian dari pengembangan wilayah Batam sebagai kawasan industri dan pariwisata. Dengan panjang total sekitar 2 kilometer, jembatan ini menawarkan pemandangan laut yang indah dan menjadi tempat favorit untuk berfoto. Pengunjung dapat menikmati sunset yang memukau dari atas jembatan ini. Jembatan ini juga menjadi saksi bisu perkembangan kota Batam dari masa ke masa.",
      'open_hours': 'Buka 24 Jam',
      'price_range': 'Gratis',
    },
    {
      'title': "Welcome To Batam",
      'image': "assets/images/slider3.png",
      'rating': 4.7,
      'location': 'Batam',
      'description':
          'Monumen ikonik yang menyambut pengunjung ke Batam. Tempat populer untuk berfoto.',
      'open_hours': 'Buka 24 Jam',
      'price_range': 'Gratis',
    },
    {
      'title': "Mega Wisata Ocarina",
      'image': "assets/images/slider2.png", // Contoh aset lokal
      'rating': 4.8,
      'location': 'Batam',
      'description':
          'Taman hiburan keluarga dengan berbagai wahana dan pemandangan laut.',
      'open_hours': '09:00 - 18:00',
      'price_range': 'Rp 20.000 - Rp 50.000',
    },
    {
      'title': "Welcome Monument",
      'image': "assets/images/slider1.png", // Contoh aset lokal
      'rating': 4.5,
      'location': 'Batam',
      'description': 'Monumen selamat datang yang megah di Batam.',
      'open_hours': 'Buka 24 Jam',
      'price_range': 'Gratis',
    },
    {
      'title': "Harbor Bay",
      'image': "assets/images/slider3.png", // Contoh aset lokal
      'rating': 4.4,
      'location': 'Batam',
      'description':
          'Pelabuhan utama dengan banyak restoran dan pemandangan laut.',
      'open_hours': '08:00 - 22:00',
      'price_range': 'Bervariasi',
    },
    {
      'title': "Joyful Café",
      'image': "assets/images/slider1.png", // Contoh aset lokal
      'rating': 4.7,
      'location': 'Batam',
      'description':
          'Kafe nyaman dengan suasana yang menyenangkan dan pilihan kopi yang beragam.',
      'open_hours': '10:00 - 23:00',
      'price_range': 'Rp 25.000 - Rp 75.000',
    },
    {
      'title': "Mercure Hotel",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Hotel',
      'location': 'Batam',
      'description':
          'Hotel bintang empat dengan fasilitas lengkap dan lokasi strategis.',
      'open_hours': 'Buka 24 Jam',
      'price_range': 'Mulai dari Rp 500.000',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted) setState(() => userRole = doc.data()?['role'] as String?);
    }
  }

  Future<void> _checkLoginStatus() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() => _isLoggedIn = user != null);
        if (user != null)
          _checkUserRole();
        else
          setState(() => userRole = null);
      }
    });
  }

  void _toggleDrawer() {
    final isDrawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (isDrawerOpen) {
      _scaffoldKey.currentState?.closeDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: grayColor,
      onDrawerChanged: (isDrawerOpen) {
        if (isDrawerOpen)
          _animationController.forward();
        else
          _animationController.reverse();
      },
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        userRole: userRole,
        curentindex: 0,
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [_buildScrollableHeader(), _buildDestinationGrid()],
        ),
      ),
    );
  }

  Widget _buildScrollableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: _toggleDrawer,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Destinasi',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDestinationGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Jelajahi Destinasi Wisata Kota Batam',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: destinasiList.length,
            itemBuilder: (context, index) {
              final destinasi = destinasiList[index];
              return _buildDestinasiCard(context, destinasi);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinasiCard(
    BuildContext context,
    Map<String, Object> destinasi,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinasiDetailPage(destinasi: destinasi),
          ),
        );
      },
      child: DestinationCard(
        title: destinasi['title'] as String,
        image: destinasi['image'] as String,
        rating: destinasi['rating'] as double,
        location: destinasi['location'] as String,
      ),
    );
  }

  Widget _buildDrawer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Drawer(
        backgroundColor: grayColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    'assets/images/logo1.png',
                    width: 123,
                    height: 120,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            _buildDrawerItem(Icons.map_outlined, "Destinasi", () {
              Navigator.pop(context);
            }, isSelected: true),
            _buildDrawerItem(Icons.event, "Event", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Eventpage()),
              );
            }),
            _buildDrawerItem(Icons.image, "Galeri", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Galeripage()),
              );
            }),
            _buildDrawerItem(Icons.forum_outlined, "Forum Diskusi", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DiscussPage()),
              );
            }),
            if (_isLoggedIn && userRole != "user")
              _buildDrawerItem(Icons.tips_and_updates, "Tambah Destinasi", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TambahDestinasiPage(),
                  ),
                );
              }),
            if (_isLoggedIn && userRole != "owner")
              _buildDrawerItem(Icons.admin_panel_settings, "Request Role", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestRolePage()),
                );
              }),
            if (userRole == "owner")
              _buildDrawerItem(Icons.calendar_today, "Add Event", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : Colors.black54),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      tileColor: isSelected ? primaryColor.withOpacity(0.1) : null,
      onTap: onTap,
    );
  }
}

class DestinasiDetailPage extends StatefulWidget {
  final Map<String, Object> destinasi;
  const DestinasiDetailPage({super.key, required this.destinasi});

  @override
  _DestinasiDetailPageState createState() => _DestinasiDetailPageState();
}

class _DestinasiDetailPageState extends State<DestinasiDetailPage>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _showFullDescription = false;
  bool _isBoxVisible = false;
  Timer? _imageSliderTimer;
  late AnimationController _overlayController;
  late AnimationController _slideController;
  late Animation<double> _overlayAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showDetailPopup = false;

  late List<String> _images;
  late List<String> _galleryImages;

  final List<Review> _reviews = [
    Review(
      name: "Kevin Panjaitan",
      rating: 5,
      comment:
          "Tempat yang sangat indah dan menakjubkan. Pemandangan yang luar biasa!",
      timeAgo: "3 minggu lalu",
      avatar:
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face",
    ),
    Review(
      name: "AnindyaSeima",
      rating: 4,
      comment:
          "Sangat bertema dengan alam dan nuansa pegunungan di sekitar. Sangat cocok untuk healing dan refreshing bersama keluarga.",
      timeAgo: "2 minggu lalu",
      avatar:
          "https://images.unsplash.com/photo-1494790108755-2616b612b5bc?w=100&h=100&fit=crop&crop=face",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _images = [widget.destinasi['image'] as String];
    _galleryImages = [widget.destinasi['image'] as String];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isBoxVisible = true;
        });
      }
    });
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isBoxVisible = true;
        });
      }
    });
    _startImageSlider();
  }

  @override
  void dispose() {
    _imageSliderTimer?.cancel();
    _pageController.dispose();
    _overlayController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startImageSlider() {
    _imageSliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      int nextPage = _currentImageIndex + 1;
      if (nextPage >= _images.length) {
        nextPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImagePopup() {
    setState(() {
      _showDetailPopup = true;
    });
    _overlayController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _hideImagePopup() {
    _slideController.reverse().then((_) {
      _overlayController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showDetailPopup = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSlide(
                      offset:
                          _isBoxVisible ? Offset.zero : const Offset(0, 0.1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: _isBoxVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: _buildGlassmorphismInfoBox(),
                      ),
                    ),
                    _buildMapSection(),
                    _buildGallerySection(),
                    _buildRatingSection(),
                    _buildReviewsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          // Popup overlay
          if (_showDetailPopup) _buildImagePopupOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showBookingDialog();
        },
        label: const Text(
          'Pesan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildImagePopupOverlay() {
    return AnimatedBuilder(
      animation: _overlayAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * _overlayAnimation.value),
          child: Stack(
            children: [
              // Tap to close overlay
              GestureDetector(
                onTap: _hideImagePopup,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
              // Main popup content
              SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.9,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background image that fills the entire popup
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: Image.asset(
                            widget.destinasi['image'] as String,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradient overlay for text readability
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black54,
                                Colors.black87,
                              ],
                              stops: [0.3, 0.7, 1.0],
                            ),
                          ),
                        ),
                        // Top section with handle bar and close button
                        Column(
                          children: [
                            // Handle bar
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Close button
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: _hideImagePopup,
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bottom content with text overlay
                        Positioned(
                          bottom: 80,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.destinasi['title'] as String,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Description
                              Text(
                                widget.destinasi['description'] as String? ??
                                    "Jembatan Barelang Batam adalah ikon arsitektur yang menghubungkan tujuh pulau di sekitar Kota Batam, Indonesia. Dibangun sebagai proyek simbolik untuk memperkuat kemerdekaan Indonesia, jembatan ini memberikan akses vital antar-pulau di Kepulauan Riau. Terdiri dari enam jembatan utama dengan panjang total lebih dari 2 kilometer, Jembatan Barelang menawarkan pemandangan menakjubkan dari atas Selat Singapura. Setiap jembatan memiliki karakteristik unik dan gaya arsitektur yang memukau. Selain sebagai jalur penghubung, Jembatan Barelang juga menjadi objek wisata populer di Batam, menarik wisatawan dengan keindahan alam sekitarnya dan kegiatan olahraga air di bawahnya. Tempat ini menjadi titik favorit untuk mengabadikan momen indah dan menikmati suasananya yang tenang.",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.5,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Floating buy button
              SlideTransition(
                position: _slideAnimation,
                child: Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        _hideImagePopup();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          _showBookingDialog();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Pesan Sekarang',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: _showImagePopup,
                  child: Image.asset(
                    _images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.destinasi['title'] as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.destinasi['open_hours'] as String? ??
                            'Buka 24 Jam',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    _images.asMap().entries.map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentImageIndex == entry.key
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.destinasi['location'] as String,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.attach_money, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              widget.destinasi['price_range'] as String? ?? 'Gratis',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.destinasi['category'] as String? ?? 'Destinasi Objek Wisata',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionContent() {
    String description =
        widget.destinasi['description'] as String? ??
        "Jembatan Barelang adalah rangkaian enam jembatan yang menghubungkan Batam dengan beberapa pulau kecil seperti Rempang dan Galang. Pembangunan jembatan ini dimulai pada tahun 1992 dan selesai pada tahun 1998. Jembatan ini menjadi salah satu ikon wisata Batam. Barelang, yang Galang, Pembangunan jembatan ini merupakan bagian dari pengembangan wilayah Batam sebagai kawasan industri dan pariwisata. Dengan panjang total sekitar 2 kilometer, jembatan ini menawarkan pemandangan laut yang indah dan menjadi tempat favorit untuk berfoto. Pengunjung dapat menikmati sunset yang memukau dari atas jembatan ini. Jembatan ini juga menjadi saksi bisu perkembangan kota Batam dari masa ke masa.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Text(
              _showFullDescription
                  ? description
                  : "${description.substring(0, description.length > 200 ? 200 : description.length)}${description.length > 200 ? "..." : ""}",
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _showFullDescription = !_showFullDescription;
              });
            },
            child: Text(
              _showFullDescription
                  ? 'Lihat lebih sedikit'
                  : 'Lihat selengkapnya',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'Peta Lokasi',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 100,
                    child: _buildMapMarker(
                      widget.destinasi['location'] as String,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(String name, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 4),
        Icon(Icons.location_on, color: color, size: 24),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Galeri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  height: 210,
                  margin: const EdgeInsets.only(right: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () => _showImageDialog(_galleryImages[index]),
                      child: Image.asset(
                        // Menggunakan Image.asset
                        _galleryImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Dan Ulasan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                (widget.destinasi['rating'] as double?)?.toStringAsFixed(1) ??
                    '0.0', // Rating dinamis
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.8),
                    _buildRatingBar(4, 0.6),
                    _buildRatingBar(3, 0.3),
                    _buildRatingBar(2, 0.1),
                    _buildRatingBar(1, 0.05),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              // Pastikan rating adalah double atau default ke 0.0 jika null
              final double currentRating =
                  (widget.destinasi['rating'] as double?) ?? 0.0;
              return Icon(
                index < currentRating.floor() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$rating',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _reviews.map((review) => _buildReviewItem(review)).toList(),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismInfoBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDestinationInfoContent(),
                const SizedBox(height: 12),
                _buildDescriptionContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDialog() {
    // Implementation for booking dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pesan Tiket'),
          content: const Text('Fitur pemesanan akan segera tersedia!'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Center'),
          content: const Text('Hubungi: +62 778 123456'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement call functionality
              },
              child: const Text('Panggil'),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(String imagePath) {
    // Implementation for image dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(child: Image.asset(imagePath));
      },
    );
  }
}

class Review {
  final String name;
  final int rating;
  final String comment;
  final String timeAgo;
  final String avatar;

  Review({
    required this.name,
    required this.rating,
    required this.comment,
    required this.timeAgo,
    required this.avatar,
  });
}
