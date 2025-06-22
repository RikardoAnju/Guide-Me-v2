import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Destinasi Wisata',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Roboto'),
      home: DestinationDetailPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DestinationDetailPage extends StatefulWidget {
  @override
  _DestinationDetailPageState createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage>
    with SingleTickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _showFullDescription = false;
  bool _isBoxVisible = false; // State untuk animasi
  Timer? _imageSliderTimer;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
    'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=800',
    'https://images.unsplash.com/photo-1464822759844-d150baec0151?w=800',
  ];

  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
    'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=400',
    'https://images.unsplash.com/photo-1464822759844-d150baec0151?w=400',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400',
  ];

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
    // Memicu animasi setelah frame pertama selesai dibangun
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // Latar belakang sedikit abu-abu
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Box dibungkus dengan widget animasi
                AnimatedSlide(
                  offset: _isBoxVisible ? Offset.zero : const Offset(0, 0.1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _isBoxVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: _buildGlassmorphismInfoBox(),
                  ),
                ),
                _buildMapSection(),
                _buildActionButtons(), // Tombol Call Center
                _buildGallerySection(),
                _buildRatingSection(),
                _buildReviewsSection(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showBookingDialog();
        },
        label: Text('Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(Icons.shopping_cart),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
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
                return Image.network(
                  _images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                    'Jembatan Barelang',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Buka 24 Jam',
                        style: TextStyle(color: Colors.white, fontSize: 14),
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
                        margin: EdgeInsets.symmetric(horizontal: 4),
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

  // Konten informasi destinasi tanpa padding eksternal
  Widget _buildDestinationInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Riau 2000 - Riau 2600',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.attach_money, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Text(
              'Rp 15.000 - Rp 25.000',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Destinasi Objek Wisata',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.directions,
              label: 'Directions',
              color: Colors.pink,
              onTap: () => _showDirectionsDialog(),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share,
              label: 'Share',
              color: Colors.blue,
              onTap: () => _showShareDialog(),
            ),
          ),
        ],
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Konten deskripsi tanpa padding eksternal
  Widget _buildDescriptionContent() {
    String description =
        "Jembatan Barelang adalah rangkaian enam jembatan yang menghubungkan Batam dengan beberapa pulau kecil seperti Rempang dan Galang. Pembangunan jembatan ini dimulai pada tahun 1992 dan selesai pada tahun 1998. Jembatan ini menjadi salah satu ikon wisata Batam. Barelang, yang Galang, Pembangunan jembatan ini merupakan bagian dari pengembangan wilayah Batam sebagai kawasan industri dan pariwisata. Dengan panjang total sekitar 2 kilometer, jembatan ini menawarkan pemandangan laut yang indah dan menjadi tempat favorit untuk berfoto. Pengunjung dapat menikmati sunset yang memukau dari atas jembatan ini. Jembatan ini juga menjadi saksi bisu perkembangan kota Batam dari masa ke masa.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tambahkan AnimatedSize di sini
          AnimatedSize(
            duration: const Duration(milliseconds: 300), // Durasi animasi
            curve: Curves.easeInOut, // Kurva animasi
            child: Text(
              _showFullDescription
                  ? description
                  : description.substring(0, 200) + "...",
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.justify,
            ),
          ), // Akhir AnimatedSize
          SizedBox(height: 8),
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
              style: TextStyle(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi', // Judul bagian Lokasi
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Ubah warna teks ke hitam
            ),
          ),

          SizedBox(height: 12),
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
                  // Placeholder untuk map
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey[600]),
                          SizedBox(height: 8),
                          Text(
                            'Peta Lokasi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Marker locations
                  Positioned(
                    top: 60,
                    left: 100,
                    child: _buildMapMarker('Batam', Colors.blue),
                  ),
                  Positioned(
                    top: 120,
                    right: 80,
                    child: _buildMapMarker('Galang', Colors.green),
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
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(height: 4),
        Icon(Icons.location_on, color: color, size: 24),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galeri', // Judul bagian Galeri
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Ubah warna teks ke hitam
            ),
          ),

          SizedBox(height: 12),
          Container(
            // Container untuk daftar galeri
            height: 220, // Tinggikan container lebih lanjut
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Tetap scroll horizontal
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 150, // Lebar gambar 150px
                  height: 210, // Tinggi gambar 210px
                  margin: EdgeInsets.only(
                    right: 16,
                  ), // Sesuaikan margin jika perlu
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap:
                          () => _showImageDialog(
                            _galleryImages[index],
                          ), // Tetap bisa tap untuk lihat gambar penuh
                      child: Image.network(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Dan Ulasan', // Judul bagian Rating Dan Ulasan
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Ubah warna teks ke hitam
            ),
          ),

          SizedBox(height: 16),
          Row(
            children: [
              Text(
                '4.9',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 20),
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
          SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < 4 ? Icons.star : Icons.star_border,
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
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$rating', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
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
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _reviews.map((review) => _buildReviewItem(review)).toList(),
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
          SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Widget baru untuk box glassmorphism
  Widget _buildGlassmorphismInfoBox() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ), // Margin untuk box keseluruhan
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Sudut melengkung
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Bayangan lembut
            blurRadius: 10,
            spreadRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        // Memastikan blur dan konten terpotong sesuai sudut
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          // Efek blur glassmorphism
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.4,
              ), // Opacity ditingkatkan untuk kontras
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ), // Border tipis
            ),
            padding: const EdgeInsets.all(20), // Padding internal untuk konten
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDestinationInfoContent(),
                SizedBox(height: 12), // Spasi antara info dan deskripsi
                _buildDescriptionContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pesan Tiket'),
          content: Text('Fitur pemesanan akan segera tersedia!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
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
          title: Text('Call Center'),
          content: Text('Hubungi: +62 778 123456'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement call functionality
              },
              child: Text('Panggil'),
            ),
          ],
        );
      },
    );
  }

  void _showDirectionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Petunjuk Arah'),
          content: Text('Membuka aplikasi maps...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bagikan'),
          content: Text('Bagikan destinasi ini ke media sosial'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement share functionality
              },
              child: Text('Bagikan'),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(child: Image.network(imageUrl, fit: BoxFit.contain)),
        );
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
