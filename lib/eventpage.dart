import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guide_me/galeripage.dart';
import './home.dart';
import 'discusspage.dart';
import 'destinasipage.dart';
import './app_colors.dart';
import 'requestRole.dart';
import 'tambah_destinasi.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, Object> event;
  const EventDetailPage({super.key, required this.event});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text("Detail untuk ${event['title']}")));
}

class Eventpage extends StatefulWidget {
  const Eventpage({super.key});
  @override
  State<Eventpage> createState() => _EventpageState();
}

class _EventpageState extends State<Eventpage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  String? userRole;
  bool _isLoggedIn = FirebaseAuth.instance.currentUser != null;

  final List<Map<String, Object>> eventList = const [
    {
      'title': "Jembatan Barelang",
      'image': "assets/images/slider1.png",
      'rating': 4.9,
      'location': 'Batam',
    },
    {
      'title': "Welcome To Batam",
      'image': "assets/images/slider3.png",
      'rating': 4.7,
      'location': 'Batam',
    },
    {
      'title': "Mega Wisata Ocarina",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'location': 'Batam',
    },
    {
      'title': "Welcome Monument",
      'image': "assets/images/slider1.png",
      'rating': 4.5,
      'location': 'Batam',
    },
    {
      'title': "Harbor Bay",
      'image': "assets/images/slider3.png",
      'rating': 4.4,
      'location': 'Batam',
    },
    {
      'title': "Joyful Café",
      'image': "assets/images/slider1.png",
      'rating': 4.7,
      'location': 'Batam',
    },
    {
      'title': "Mercure Hotel",
      'image': "assets/images/slider2.png",
      'rating': 4.8,
      'category': 'Hotel',
      'location': 'Batam',
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
        child: Column(children: [_buildScrollableHeader(), _buildEventGrid()]),
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
                'Event',
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

  Widget _buildEventGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Jelajahi Event Wisata Kota Batam',
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
            itemCount: eventList.length,
            itemBuilder: (context, index) {
              final destinasi = eventList[index];
              return _buildEventCard(context, destinasi);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, Object> event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      child: Card(),
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
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const DestinasiPage(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            _buildDrawerItem(Icons.event, "Event", () {
              Navigator.pop(context);
            }, isSelected: true),
            _buildDrawerItem(Icons.image, "Galeri", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const Galeripage(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            _buildDrawerItem(Icons.forum_outlined, "Forum Diskusi", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const DiscussPage(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            _buildDrawerItem(Icons.admin_panel_settings, "Request Role", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          RequestRolePage(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }),
            if (_isLoggedIn && userRole == "owner")
              _buildDrawerItem(Icons.tips_and_updates, "Tambah Destinasi", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            TambahDestinasiPage(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
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
