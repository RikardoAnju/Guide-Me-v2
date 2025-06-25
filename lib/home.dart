import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guide_me/Login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guide_me/eventpage.dart';
import 'destinasipage.dart';
import 'galeripage.dart';
import 'requestRole.dart';
import 'discusspage.dart';
import 'tambah_destinasi.dart';
import 'Profile.dart';
import 'dart:async';
import 'app_colors.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        canvasColor: const Color(0xFFEEEEEE),
      ),
      home: const HomePage(),
    );
  }
}

class NotificationsUser extends StatelessWidget {
  const NotificationsUser({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi Pengguna"),
        backgroundColor: const Color(0xFF5ABB4D),
      ),
      body: const Center(
        child: Text(
          "Tidak ada notifikasi baru.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  //Controller and Key
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // State variables
  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;
  bool _showAppBarTitle = false;
  int _currentCarouselIndex = 0;
  Timer? _timer;
  bool _isSearchFocused = false;
  bool _hasSearchText = false;
  int _unreadNotifications = 0;
  String? _selectedCategory;

  // Data
  final List<Map<String, String>> _carouselItems = [
    {
      'image': 'assets/images/slider1.png',
      'title': 'Welcome to Batam',
      'description': 'Discover the beauty of the island',
    },
    {
      'image': 'assets/images/slider2.png',
      'title': 'Mega Wisata Ocarina',
      'description': 'Explore our premium attractions',
    },
    {
      'image': 'assets/images/slider3.png',
      'title': 'Pantai Nongsa',
      'description': 'Enjoy the pristine beaches',
    },
  ];

  final List<Map<String, dynamic>> _kategoridestinasi = [
    {'name': 'Pantai', 'icon': Icons.beach_access_rounded},
    {'name': 'Café', 'icon': Icons.coffee_rounded},
    {'name': 'Park', 'icon': Icons.nature_people_rounded},
    {'name': 'Mall', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Hotel', 'icon': Icons.hotel_rounded},
    {'name': 'Historical', 'icon': Icons.museum_rounded},
    {'name': 'Kuliner', 'icon': Icons.food_bank_rounded},
  ];

  final List<Map<String, dynamic>> _kategorievent = [
    {'name': 'Bazzar', 'icon': Icons.ramen_dining_rounded},
    {'name': 'Music', 'icon': Icons.music_note_rounded},
    {'name': 'Religi', 'icon': Icons.church_rounded},
    {'name': 'kultur', 'icon': Icons.theater_comedy},
    {'name': 'sport', 'icon': Icons.sports_baseball_rounded},
    {'name': 'sosial', 'icon': Icons.auto_stories_rounded},
    {'name': 'Edukasi', 'icon': Icons.school},
  ];

  final List<Map<String, dynamic>> _destinations = [
    // Popular destinations
    {
      'title': "Mega Wisata Ocarina",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'location': 'Batam',
      'isPopular': true,
    },
    {
      'title': "Pantai Nongsa",
      'image': "assets/images/slider3.png",
      'rating': 4.7,
      'category': 'Pantai',
      'location': 'Batam',
      'isPopular': true,
    },
    {
      'title': "Jembatan Barelang",
      'image': "assets/images/slider1.png",
      'rating': 4.9,
      'location': 'Batam',
      'isPopular': true,
    },
    {
      'title': "Nagoya Hill Mall",
      'image': "assets/images/slider2.png",
      'rating': 4.6,
      'category': 'Mall',
      'location': 'Batam',
      'isPopular': true,
    },

    {
      'title': "Welcome Monument",
      'image': "assets/images/slider1.png",
      'rating': 4.5,
      'location': 'Batam',
      'isPopular': false,
    },
    {
      'title': "Harbor Bay",
      'image': "assets/images/slider3.png",
      'rating': 4.4,
      'location': 'Batam',
      'isPopular': false,
    },
    {
      'title': "Joyful Café",
      'image': "assets/images/slider1.png",
      'rating': 4.7,
      'location': 'Batam',
      'isPopular': false,
    },
    {
      'title': "Mercure Hotel",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Hotel',
      'location': 'Batam',
      'isPopular': false,
    },
  ];

  final List<Map<String, dynamic>> _events = [
    // Popular event
    {
      'title': "Konser Blackpink",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'location': 'Batam',
    },
    {
      'title': "Rumah Dhafin",
      'image': "assets/images/slider3.png",
      'rating': 4.7,
      'category': 'Kultur',
      'location': 'Batam',
    },
    {
      'title': "Jembatan Rikardo",
      'image': "assets/images/slider1.png",
      'rating': 4.9,
      'category': 'Religi',
      'location': 'Batam',
    },
    {
      'title': "Konser King Arif",
      'image': "assets/images/slider2.png",
      'rating': 4.6,
      'category': 'Music',
      'location': 'Batam',
    },
    {
      'title': "Welcome To Piayu",
      'image': "assets/images/slider1.png",
      'rating': 4.5,
      'location': 'Batam',
      'price': "Rp 110K",
    },
    {
      'title': "Kapal Laud",
      'image': "assets/images/slider3.png",
      'rating': 4.4,
      'location': 'Batam',
      'price': "Rp 510K",
    },
    {
      'title': "Sinaga Café",
      'image': "assets/images/slider1.png",
      'rating': 4.7,
      'location': 'Batam',
    },
    {
      'title': "Habil besi",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Bazzar',
      'location': 'Batam',
      'price': "Rp 50K",
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkUserRole();
    _checkLoginStatus();
    _updateLastActive();
    _startActiveTimer();
    _fetchNotificationCount();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);
    _searchController.addListener(_onSearchTextChange);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchTextChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 150;
    if (showTitle != _showAppBarTitle && mounted) {
      setState(() => _showAppBarTitle = showTitle);
    }
  }

  Future<void> _checkUserRole() async {
    if (!mounted) return;
    String? role = await getUserRole();
    if (mounted) {
      setState(() => userRole = role);
    }
  }

  void _updateLastActive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'lastActive': FieldValue.serverTimestamp()},
      );
    }
  }

  void _startActiveTimer() {
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateLastActive(),
    );
  }

  Future<String?> getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return doc['role'];
    }
    return null;
  }

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() => _isLoggedIn = user != null);
    }
  }

  void _onSearchFocusChange() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _onSearchTextChange() {
    if (mounted) {
      setState(() {
        _hasSearchText = _searchController.text.isNotEmpty;
      });
    }
  }

  void _fetchNotificationCount() async {
    if (!_isLoggedIn) return;
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _unreadNotifications = 1;
      });
    }
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      _animationController.reverse();
    } else {
      _scaffoldKey.currentState?.openDrawer();
      _animationController.forward();
    }
  }

  List<Map<String, dynamic>> _getFilteredDestinations({
    required bool isPopular,
  }) {
    return _destinations.where((dest) {
      if (dest['isPopular'] != isPopular) return false;

      if (_selectedCategory == null) return true;

      return dest['category'] == _selectedCategory;
    }).toList();
  }

  List<Map<String, dynamic>> _getDestinationsByCategory() {
    if (_selectedCategory == null) {
      return [];
    }
    return _destinations.where((dest) {
      return dest['category'] == _selectedCategory;
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    return _events.where((event) {
      if (_selectedCategory == null) return true;

      return event['category'] == _selectedCategory;
    }).toList();
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
        curentindex: 1,
      ), // 1 = Home
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DestinasiPage()),
              );
            }),
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
            _isLoggedIn && userRole != "user"
                ? _buildDrawerItem(
                  Icons.tips_and_updates,
                  "Tambah Destinasi",
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TambahDestinasiPage(),
                      ),
                    );
                  },
                )
                : SizedBox.shrink(),
            if (_isLoggedIn && userRole != "owner")
              _buildDrawerItem(Icons.admin_panel_settings, "Request Role", () {
                Navigator.pushReplacement(
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

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 5),
          _buildCarousel(),
          _buildCategoriesSection(),
          _buildFilteredContent(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: grayColor,
      child: Row(
        children: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
              color: Colors.black,
            ),
            onPressed: _toggleDrawer,
          ),
          Expanded(
            child: TextField(
              controller: _searchController, // Terhubung ke controller
              focusNode: _searchFocusNode,
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                prefixIcon:
                    _isSearchFocused
                        ? null
                        : Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon:
                    _hasSearchText
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ),
          if (_isLoggedIn) ...[
            const SizedBox(width: 8),
            _buildNotificationIcon(),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return IconButton(
      onPressed: () {
        // Logika dipindahkan ke sini.
        if (_isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsUser()),
          );
          setState(() {
            _unreadNotifications = 0;
          });
        } else {
          // Tampilkan dialog jika pengguna belum login
          showDialog(
            context: context,
            builder:
                (BuildContext dialogContext) => AlertDialog(
                  title: const Text('Akses Ditolak'),
                  content: const Text(
                    'Silakan masuk terlebih dahulu untuk melihat notifikasi.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('OK'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
          );
        }
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.black54,
            size: 28,
          ),
          if (_isLoggedIn &&
              _unreadNotifications >
                  0) // Badge hanya muncul jika login DAN ada notif
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return Container(
      color: grayColor,
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 220.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    if (mounted) {
                      setState(() => _currentCarouselIndex = index);
                    }
                  },
                ),
                items:
                    _carouselItems.map((item) {
                      return Builder(
                        builder: (BuildContext context) {
                          return _buildCarouselItem(item);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                _carouselItems.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _currentCarouselIndex == entry.key
                              ? primaryColor
                              : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(Map<String, String> item) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              item['image']!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                        ),
                      ],
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

  Widget _buildCategoriesSection() {
    return Container(
      color: grayColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndividualCategoryList(
            "Kategori Destinasi",
            _kategoridestinasi,
          ),
          const SizedBox(height: 16),
          _buildIndividualCategoryList("Kategori Event", _kategorievent),
        ],
      ),
    );
  }

  Widget _buildIndividualCategoryList(
    String title,
    List<Map<String, dynamic>> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 85, // Tinggi tetap sama
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ), // Padding utama untuk list
            itemCount: categories.length,
            itemBuilder:
                (context, index) => _buildCategoryItem(categories[index]),
            separatorBuilder:
                (context, index) =>
                    const SizedBox(width: 12), // Jarak antar item
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['name'];
    return GestureDetector(
      // Menghapus AnimatedContainer untuk menghilangkan pergeseran
      onTap: () {
        if (mounted) {
          setState(() {
            // Jika kategori yang sama ditekan, unselect (kembali ke semua)
            if (_selectedCategory == category['name']) {
              _selectedCategory = null;
            } else {
              _selectedCategory = category['name'];
            }
          });
        }
      },
      child: Container(
        // Menggunakan Container untuk kontrol lebar dan margin
        width: 70, // Lebar item kategori disesuaikan
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ), // Padding vertikal di dalam item
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'],
              color: isSelected ? primaryColor : Colors.black87,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              category['name'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredContent() {
    bool isDestCategory = _kategoridestinasi.any(
      (cat) => cat['name'] == _selectedCategory,
    );
    bool isEventCategory = _kategorievent.any(
      (cat) => cat['name'] == _selectedCategory,
    );
    return Column(
      children: [
        if (_selectedCategory == null) ...[
          _buildDestinationSection(
            title: "Tempat Wisata Batam Terpopuler",
            icon: Icons.star,
            isPopular: true,
          ),
          _buildDestinationSection(
            title: "Tempat Wisata Lainnya",
            icon: Icons.location_on,
            isPopular: false,
          ),
          _buildEventSection(title: "Event Terbaru", icon: Icons.event),
        ] else if (isDestCategory) ...[
          _buildFilteredDestinationSection(),
        ] else if (isEventCategory) ...[
          _buildEventSection(
            title: "Event: $_selectedCategory",
            icon: Icons.event,
          ),
        ],
      ],
    );
  }

  Widget _buildFilteredDestinationSection() {
    final destinations = _getDestinationsByCategory();
    final categoryData = _kategoridestinasi.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
      orElse: () => {'icon': Icons.location_on}, // Fallback icon
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          color: grayColor,
          child: Row(
            children: [
              Icon(categoryData['icon'], color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                "Destinasi: $_selectedCategory",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              destinations.isEmpty
                  ? Center(
                    child: Text(
                      "Tidak ada destinasi dalam kategori ini.",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        child: DestinationCard(
                          title: destination['title'],
                          image: destination['image'],
                          rating: destination['rating'],
                          location: destination['location'],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEventSection({required String title, required IconData icon}) {
    final events = _getFilteredEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    primaryColor, // Changed from Colors.blue to primaryColor for consistency
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              events.isEmpty
                  ? Center(
                    child: Text(
                      "Tidak ada event dalam kategori ini.",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 16),
                        child: EventCard(
                          title: event['title'] ?? '',
                          image: event['image'] ?? '',
                          date: event['date'] ?? '',
                          location: event['location'] ?? '',
                          price: event['price'],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDestinationSection({
    required String title,
    required IconData icon,
    required bool isPopular,
  }) {
    final destinations = _getFilteredDestinations(isPopular: isPopular);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          color: grayColor,
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child:
              destinations.isEmpty
                  ? Center(
                    child: Text(
                      "No destinations in this category",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1.0,
                        child: Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: DestinationCard(
                            title: destination['title'],
                            image: destination['image'],
                            rating: destination['rating'],
                            location: destination['location'],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String image;
  final String date;
  final String location;
  final String? price;

  const EventCard({
    super.key,
    required this.title,
    required this.image,
    required this.date,
    required this.location,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.event, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Price Badge (top right)
            if (price != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    price!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Content (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            date,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DestinationCard extends StatelessWidget {
  final String title;
  final String image;
  final double rating;
  final String location;

  const DestinationCard({
    super.key,
    required this.title,
    required this.image,
    required this.rating,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.6),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final String? userRole;
  final int curentindex;

  const CustomBottomNavBar({super.key, this.userRole, this.curentindex = 1});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.curentindex;
  }

  void _onItemTapped(int index) {
    // Tidak ada perubahan state untuk menghilangkan animasi
    final currentUser = FirebaseAuth.instance.currentUser;

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const HomePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Login/Profile
        if (currentUser == null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const ProfileScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      height: 60,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF5ABB4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 0, "Home"),
          _buildNavItem(
            currentUser == null ? Icons.person : Icons.person,
            1,
            currentUser == null ? "Login" : "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: isSelected ? 30 : 28,
          ),
        ),
      ),
    );
  }
}
