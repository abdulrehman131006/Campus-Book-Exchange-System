import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_book_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'chats_list_screen.dart';
import 'ai_chatbot_screen.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('books');

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ValueNotifier<bool> _isNavCompact = ValueNotifier<bool>(false);

  double _scrollDeltaAccumulator = 0.0;
  static const double _scrollThreshold = 15.0;

  String _searchQuery = '';
  String _selectedDeptFilter = 'Filters';
  String _selectedSortOption = 'Sort By';

  List<Map<String, String>> _unreadNotifications = [
    {
      'senderId': 'user_1',
      'senderName': 'Ali Ahmed',
      'lastMessage': 'Is the C++ textbook still available?',
      'time': '10m ago',
    },
    {
      'senderId': 'user_2',
      'senderName': 'Sara Khan',
      'lastMessage': 'Can you reduce the price to PKR 500?',
      'time': '1h ago',
    },
  ];

  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandAccent = Color(0xFF0077B6);

  final List<String> _deptFilterOptions = [
    'Filters',
    'All',
    'Computer Science',
    'Software Engineering',
    'Artificial Intelligence',
    'Cyber Security',
    'Electrical & Computer Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Management Sciences / BBA',
    'Accounting & Finance',
    'Humanities / English',
    'Mathematics',
    'Physics',
    'Biosciences / Bioinformatics',
    'Architecture & Design',
    'Other / General',
  ];

  final List<String> _sortOptions = [
    'Sort By',
    'Newest First',
    'Oldest First',
    'Price: Low to High',
    'Price: High to Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _isNavCompact.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));
  }

  LinearGradient _getCardGradient(int index) {
    List<List<Color>> gradients = [
      [const Color(0xFF0F2027), const Color(0xFF2C5364)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
      [const Color(0xFFD31027), const Color(0xFFEA384D)],
      [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
    ];
    List<Color> selected = gradients[index % gradients.length];
    return LinearGradient(
      colors: selected,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  double _parsePrice(dynamic priceVal) {
    if (priceVal == null) return 0.0;
    if (priceVal is num) return priceVal.toDouble();
    
    String str = priceVal.toString();
    RegExp regExp = RegExp(r'\d+(\.\d+)?');
    Iterable<Match> matches = regExp.allMatches(str);
    
    if (matches.isNotEmpty) {
      return double.tryParse(matches.first.group(0) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  void _showNotificationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Unseen Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brandNavy,
                      ),
                    ),
                    if (_unreadNotifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _unreadNotifications.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All', style: TextStyle(color: brandAccent, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_unreadNotifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.mark_email_read_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('No new unseen messages', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _unreadNotifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      var item = _unreadNotifications[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: brandAccent.withOpacity(0.2),
                          child: Text(
                            item['senderName']![0],
                            style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          item['senderName']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandNavy),
                        ),
                        subtitle: Text(
                          item['lastMessage']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          item['time']!,
                          style: const TextStyle(fontSize: 10, color: brandAccent, fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _unreadNotifications.removeAt(index);
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: item['senderId']!,
                                receiverName: item['senderName']!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksFeed() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE2E8F0), Color(0xFFDCEBFA), Color(0xFFCBE3FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0077B6).withOpacity(0.12),
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00B4D8).withOpacity(0.10),
            ),
          ),
        ),

        NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification.metrics.pixels <= 0) {
              if (_isNavCompact.value) {
                _isNavCompact.value = false;
              }
              _scrollDeltaAccumulator = 0.0;
              return false;
            }

            if (scrollNotification is ScrollUpdateNotification) {
              final delta = scrollNotification.scrollDelta ?? 0.0;

              if ((delta > 0 && _scrollDeltaAccumulator < 0) || (delta < 0 && _scrollDeltaAccumulator > 0)) {
                _scrollDeltaAccumulator = 0.0;
              }

              _scrollDeltaAccumulator += delta;

              if (_scrollDeltaAccumulator > _scrollThreshold && !_isNavCompact.value) {
                _isNavCompact.value = true;
                _scrollDeltaAccumulator = 0.0;
              } else if (_scrollDeltaAccumulator < -_scrollThreshold && _isNavCompact.value) {
                _isNavCompact.value = false;
                _scrollDeltaAccumulator = 0.0;
              }
            }
            return false;
          },
          child: Column(
            children: [
              // ANIMATED COMPACT SEARCH BAR
              ValueListenableBuilder<bool>(
                valueListenable: _isNavCompact,
                builder: (context, isCompact, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.fromLTRB(
                      isCompact ? 40 : 16,
                      12,
                      isCompact ? 40 : 16,
                      6,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 8,
                            vertical: isCompact ? 2 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.30),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.70),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).requestFocus(_searchFocusNode);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: isCompact ? 34 : 40,
                                  height: isCompact ? 34 : 40,
                                  decoration: const BoxDecoration(
                                    color: brandAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: isCompact ? 18 : 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.toLowerCase().trim();
                                    });
                                  },
                                  style: const TextStyle(
                                    color: brandNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search books, authors, courses...',
                                    hintStyle: TextStyle(
                                      color: brandNavy.withOpacity(0.45),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    fillColor: Colors.transparent,
                                    filled: false,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: brandNavy),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              Expanded(
                child: StreamBuilder(
                  stream: _dbRef.onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: brandNavy));
                    }

                    List<Map<String, dynamic>> filteredBooks = [];

                    if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                      Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      List<Map<String, dynamic>> booksList = [];

                      map.forEach((key, value) {
                        String sellerName = 'Unknown';
                        if (value['sellerName'] != null && value['sellerName'].toString().trim().isNotEmpty) {
                          sellerName = value['sellerName'].toString().trim();
                        } else if (value['userName'] != null && value['userName'].toString().trim().isNotEmpty) {
                          sellerName = value['userName'].toString().trim();
                        } else if (value['userEmail'] != null && value['userEmail'].toString().contains('@')) {
                          sellerName = value['userEmail'].toString().split('@').first;
                        }

                        booksList.add({
                          'id': key.toString(),
                          'title': value['title'] ?? 'Untitled',
                          'author': value['author'] ?? 'Unknown Author',
                          'department': value['department'] ?? 'General',
                          'price': value['price'] ?? 'Free',
                          'description': value['description'] ?? '',
                          'userId': value['userId'] ?? '',
                          'sellerName': sellerName,
                          'bookCode': value['bookCode'] ?? key.toString().substring(0, key.toString().length > 5 ? 5 : key.toString().length).toUpperCase(),
                          'createdAt': value['createdAt'] ?? 0,
                        });
                      });

                      filteredBooks = booksList.where((book) {
                        String title = book['title'].toString().toLowerCase();
                        String author = book['author'].toString().toLowerCase();
                        String dept = book['department'].toString();
                        String code = book['bookCode'].toString().toLowerCase();

                        bool matchesSearch = title.contains(_searchQuery) ||
                            author.contains(_searchQuery) ||
                            code.contains(_searchQuery);
                        bool matchesDept = _selectedDeptFilter == 'Filters' || _selectedDeptFilter == 'All' || dept == _selectedDeptFilter;

                        return matchesSearch && matchesDept;
                      }).toList();

                      if (_selectedSortOption == 'Price: Low to High') {
                        filteredBooks.sort((a, b) {
                          double pA = _parsePrice(a['price']);
                          double pB = _parsePrice(b['price']);
                          return pA.compareTo(pB);
                        });
                      } else if (_selectedSortOption == 'Price: High to Low') {
                        filteredBooks.sort((a, b) {
                          double pA = _parsePrice(a['price']);
                          double pB = _parsePrice(b['price']);
                          return pB.compareTo(pA);
                        });
                      } else if (_selectedSortOption == 'Oldest First') {
                        filteredBooks.sort((a, b) {
                          int tA = (a['createdAt'] is int) ? a['createdAt'] : 0;
                          int tB = (b['createdAt'] is int) ? b['createdAt'] : 0;
                          return tA.compareTo(tB);
                        });
                      } else if (_selectedSortOption == 'Newest First') {
                        filteredBooks.sort((a, b) {
                          int tA = (a['createdAt'] is int) ? a['createdAt'] : 0;
                          int tB = (b['createdAt'] is int) ? b['createdAt'] : 0;
                          return tB.compareTo(tA);
                        });
                      }
                    }

                    return RefreshIndicator(
                      color: brandAccent,
                      backgroundColor: Colors.white,
                      onRefresh: _handleRefresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CUI BOOK STORE',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                          color: brandNavy,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Find your next book',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: brandAccent.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),

                                  GestureDetector(
                                    onTap: _showNotificationBottomSheet,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.40),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.70),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              const Icon(
                                                Icons.notifications_none_rounded,
                                                color: brandNavy,
                                                size: 24,
                                              ),
                                              if (_unreadNotifications.isNotEmpty)
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    constraints: const BoxConstraints(
                                                      minWidth: 16,
                                                      minHeight: 16,
                                                    ),
                                                    child: Text(
                                                      '${_unreadNotifications.length}',
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
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
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.50),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: PopupMenuButton<String>(
                                              offset: const Offset(0, 42),
                                              constraints: const BoxConstraints(maxHeight: 280),
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              onSelected: (String val) {
                                                setState(() {
                                                  _selectedDeptFilter = val;
                                                });
                                              },
                                              itemBuilder: (BuildContext context) {
                                                return _deptFilterOptions.map((String option) {
                                                  return PopupMenuItem<String>(
                                                    value: option,
                                                    height: 38,
                                                    child: Text(
                                                      option,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: option == 'Filters' ? Colors.grey[600] : brandNavy,
                                                        fontWeight: option == 'Filters' ? FontWeight.w500 : FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _selectedDeptFilter,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _selectedDeptFilter == 'Filters' ? Colors.grey[600] : brandNavy,
                                                          fontWeight: _selectedDeptFilter == 'Filters' ? FontWeight.w500 : FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const Icon(Icons.tune_rounded, color: brandNavy, size: 18),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.50),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: PopupMenuButton<String>(
                                              offset: const Offset(0, 42),
                                              constraints: const BoxConstraints(maxHeight: 240),
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              onSelected: (String val) {
                                                setState(() {
                                                  _selectedSortOption = val;
                                                });
                                              },
                                              itemBuilder: (BuildContext context) {
                                                return _sortOptions.map((String option) {
                                                  return PopupMenuItem<String>(
                                                    value: option,
                                                    height: 38,
                                                    child: Text(
                                                      option,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: option == 'Sort By' ? Colors.grey[600] : brandNavy,
                                                        fontWeight: option == 'Sort By' ? FontWeight.w500 : FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }).toList();
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _selectedSortOption,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _selectedSortOption == 'Sort By' ? Colors.grey[600] : brandNavy,
                                                          fontWeight: _selectedSortOption == 'Sort By' ? FontWeight.w500 : FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const Icon(Icons.sort_rounded, color: brandAccent, size: 18),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (filteredBooks.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[500]),
                                    const SizedBox(height: 10),
                                    Text('No books found.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.67,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    var book = filteredBooks[index];
                                    bool isMyBook = book['userId'] == _auth.currentUser?.uid;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookDetailScreen(
                                              book: book,
                                              cardGradient: _getCardGradient(index),
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(22),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(22),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(22),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        gradient: _getCardGradient(index),
                                                      ),
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.all(12),
                                                              decoration: BoxDecoration(
                                                                color: Colors.white.withOpacity(0.25),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons.auto_stories_rounded,
                                                                color: Colors.white,
                                                                size: 30,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                              child: Text(
                                                                book['department'],
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          book['price'] != null && book['price'].toString().isNotEmpty
                                                              ? 'PKR ${book['price']}'
                                                              : 'Free',
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.95),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '#${book['bookCode']}',
                                                          style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 9),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            book['title'],
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandNavy),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Author: ${book['author']}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Seller: ${book['sellerName']}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                                          ),
                                                        ],
                                                      ),
                                                      isMyBook
                                                          ? Container(
                                                              width: double.infinity,
                                                              height: 32,
                                                              alignment: Alignment.center,
                                                              decoration: BoxDecoration(
                                                                color: Colors.amber.withOpacity(0.2),
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              child: const Text('Your Listing', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                                                            )
                                                          : Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    'PKR ${book['price']}',
                                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4CAF50)),
                                                                  ),
                                                                ),
                                                                InkWell(
                                                                  onTap: () {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (_) => ChatScreen(
                                                                          receiverId: book['userId'],
                                                                          receiverName: book['sellerName'],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  child: Container(
                                                                    width: 38,
                                                                    height: 38,
                                                                    decoration: BoxDecoration(
                                                                      gradient: const LinearGradient(
                                                                        colors: [brandNavy, brandAccent],
                                                                      ),
                                                                      shape: BoxShape.circle,
                                                                      boxShadow: [
                                                                        BoxShadow(
                                                                          color: brandAccent.withOpacity(0.3),
                                                                          blurRadius: 6,
                                                                          offset: const Offset(0, 2),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
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
                                      ),
                                    );
                                  },
                                  childCount: filteredBooks.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetOptions = <Widget>[
      _buildBooksFeed(),
      const ChatsListScreen(),
      const AddBookScreen(),
      const AIChatbotScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _isNavCompact,
        builder: (context, isCompact, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.fromLTRB(
              isCompact ? 50 : 16,
              0,
              isCompact ? 50 : 16,
              18,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: isCompact ? 6 : 8,
                    horizontal: isCompact ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Books', isCompact),
                      _buildNavItem(1, Icons.forum_outlined, Icons.forum_rounded, 'Chats', isCompact),
                      _buildNavItem(2, Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Sell/Share', isCompact),
                      _buildNavItem(3, Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI Helper', isCompact),
                      _buildNavItem(4, Icons.account_circle_outlined, Icons.account_circle_rounded, 'Profile', isCompact),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, bool isCompact) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isSelected ? (isCompact ? 38 : 42) : (isCompact ? 32 : 36),
            height: isSelected ? (isCompact ? 38 : 42) : (isCompact ? 32 : 36),
            decoration: BoxDecoration(
              color: isSelected ? brandAccent : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: brandAccent.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : brandNavy.withOpacity(0.85),
              size: isSelected ? (isCompact ? 20 : 22) : (isCompact ? 18 : 20),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? brandAccent : brandNavy.withOpacity(0.85),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}