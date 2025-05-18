import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guide_me/Login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'requestRole.dart';
import 'tambah_destinasi.dart';
import 'Profile.dart';
import 'dart:async';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Constants
  static const Color grayColor = Color(0xFFEEEEEE);
  static const Color primaryColor = Color(0xFF5ABB4D);

  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // State variables
  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;
  String? _userName;
  bool _showAppBarTitle = false;
  int _currentCarouselIndex = 0;
  String _selectedCategory = 'All';
  Timer? _timer;

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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Beach', 'icon': Icons.beach_access},
    {'name': 'Café', 'icon': Icons.coffee_rounded},
    {'name': 'Park', 'icon': Icons.nature_people_rounded},
    {'name': 'Mall', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Hotel', 'icon': Icons.hotel_rounded},
    {'name': 'History', 'icon': Icons.museum_rounded},
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
      'category': 'Beach',
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkUserRole();
    _checkLoginStatus();
    _fetchUserName();
    _updateLastActive();
    _startActiveTimer();
    _scrollController.addListener(_onScroll);
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

  Future<void> _fetchUserName() async {
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted) {
        setState(() => _userName = doc['username']);
      }
    }
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
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
    return _destinations
        .where(
          (dest) =>
              dest['isPopular'] == isPopular &&
              (_selectedCategory == 'All' ||
                  dest['category'] == _selectedCategory),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: grayColor,
      onDrawerChanged: (isOpen) {
        if (!isOpen) _animationController.reverse();
      },
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(userRole: userRole),
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
            _buildDrawerItem(Icons.map, "Destinasi", () {}),
            _buildDrawerItem(Icons.event, "Event", () {}),
            _buildDrawerItem(Icons.confirmation_number, "Tiket", () {}),
            _buildDrawerItem(Icons.image, "Galeri", () {}),
            _isLoggedIn && userRole != "user"
                ? _buildDrawerItem(Icons.tips_and_updates, "Tambah Destinasi", () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TambahDestinasiPage(),
                    ),
                  );
                })
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
            _buildDrawerItem(
              _isLoggedIn ? Icons.logout : Icons.login,
              _isLoggedIn ? "Keluar" : "Masuk",
              () async {
                if (_isLoggedIn) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    setState(() {
                      userRole = null;
                      _userName = null;
                    });
                  }
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 5),
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildCarousel(),
          _buildCategoriesSection(),
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
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    if (!_isLoggedIn || _userName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
      color: grayColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $_userName",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Welcome to GuideME",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF808080),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
          child: Text(
            "Categories",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(_categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['name'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(
        top: isSelected ? 0 : 8.0,
        bottom: isSelected ? 8.0 : 0,
      ),
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() => _selectedCategory = category['name']);
          }
        },
        child: Container(
          width: 85,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? primaryColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 8 : 4,
                      spreadRadius: isSelected ? 2 : 0,
                      offset:
                          isSelected ? const Offset(0, 3) : const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  category['icon'],
                  color:
                      isSelected ? Colors.white : primaryColor.withOpacity(0.8),
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['name'],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

  const CustomBottomNavBar({super.key, this.userRole});
  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final currentUser = FirebaseAuth.instance.currentUser;

    switch (index) {
      case 0:

        /// notifikasi
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 2:
        if (currentUser == null) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Akses Ditolak'),
                  content: const Text(
                    'Silakan login terlebih dahulu untuk mengakses profil.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NavItem> items = [];

    items.add(NavItem(icon: Icons.notifications, index: items.length));
    items.add(NavItem(icon: Icons.home, index: items.length));
    items.add(NavItem(icon: Icons.person, index: items.length));

    return Container(
      height: 60,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF5ABB4D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            items.map((item) {
              return _buildNavItem(item.icon, item.index);
            }).toList(),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      splashColor: Colors.white24,
      highlightColor: Colors.white30,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white24 : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 1.0, end: isSelected ? 1.2 : 1.0),
          duration: const Duration(milliseconds: 200),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Icon(icon, color: Colors.white, size: 28),
            );
          },
        ),
      ),
    );
  }
}

// Helper class to store icon data
class NavItem {
  final IconData icon;
  final int index;

  NavItem({required this.icon, required this.index});
}
