import 'dart:async';
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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ValueNotifier<bool> _isNavCompact = ValueNotifier<bool>(false);

  double _scrollDeltaAccumulator = 0.0;
  static const double _scrollThreshold = 15.0;

  String _searchQuery = '';
  String _selectedDeptFilter = 'Filters';
  String _selectedSortOption = 'Sort By';

  List _unreadNotifications = [];
  StreamSubscription<DatabaseEvent>? _chatsSubscription;

  final Map<String, String> _userNamesCache = {};

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

  final List _navItems = [
    {'icon': Icons.grid_view_outlined, 'activeIcon': Icons.grid_view_rounded, 'label': 'Books'},
    {'icon': Icons.forum_outlined, 'activeIcon': Icons.forum_rounded, 'label': 'Chats'},
    {'icon': Icons.add_circle_outline_rounded, 'activeIcon': Icons.add_circle_rounded, 'label': 'Sell/Share'},
    {'icon': Icons.smart_toy_outlined, 'activeIcon': Icons.smart_toy_rounded, 'label': 'AI Helper'},
    {'icon': Icons.account_circle_outlined, 'activeIcon': Icons.account_circle_rounded, 'label': 'Profile'},
  ];

  @override
  void initState() {
    super.initState();
    _listenToUnreadMessages();
  }

  void _listenToUnreadMessages() {
    String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    _chatsSubscription = _dbRef.child('chats').onValue.listen((event) async {
      if (!mounted) return;
      if (event.snapshot.value == null || event.snapshot.value is! Map) {
        setState(() {
          _unreadNotifications = [];
        });
        return;
      }

      Map<dynamic, dynamic> chatsMap = event.snapshot.value as Map<dynamic, dynamic>;
      List tempNotifications = [];

      for (var entry in chatsMap.entries) {
        String roomKey = entry.key.toString();
        if (roomKey.contains(currentUserId) && entry.value is Map) {
          List<String> parts = roomKey.split('_');
          String senderId = parts.firstWhere((id) => id != currentUserId, orElse: () => '');
          
          if (senderId.isNotEmpty) {
            Map<dynamic, dynamic> messagesMap = entry.value as Map<dynamic, dynamic>;
            var sortedEntries = messagesMap.entries.toList();
            sortedEntries.sort((a, b) {
              int tA = (a.value is Map && a.value['timestamp'] is int) ? a.value['timestamp'] : 0;
              int tB = (b.value is Map && b.value['timestamp'] is int) ? b.value['timestamp'] : 0;
              return tB.compareTo(tA);
            });

            if (sortedEntries.isNotEmpty) {
              var lastMsgData = sortedEntries.first.value;
              if (lastMsgData is Map && lastMsgData['senderId'] == senderId) {
                String msgText = lastMsgData['message']?.toString() ?? 'New message received';
                
                String senderName = 'COMSATS Student';
                DataSnapshot userSnap = await _dbRef.child('users').child(senderId).get();
                if (userSnap.value != null && userSnap.value is Map) {
                  var uData = userSnap.value as Map<dynamic, dynamic>;
                  senderName = uData['name'] ?? uData['fullName'] ?? 'COMSATS Student';
                }

                tempNotifications.add({
                  'senderId': senderId,
                  'senderName': senderName,
                  'lastMessage': msgText,
                  'time': 'Recent',
                });
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotifications = tempNotifications;
        });
      }
    });
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
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
    List gradients = [
      [const Color(0xFF0F2027), const Color(0xFF2C5364)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
      [const Color(0xFFD31027), const Color(0xFFEA384D)],
      [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
    ];
    List<Color> selected = List<Color>.from(gradients[index % gradients.length]);
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

  Widget _buildSellerNameWidget(String userId, String rawSellerName) {
    bool isEmailOrUsername = rawSellerName.contains('@') || RegExp(r'^[a-zA-Z]{2}\d+').hasMatch(rawSellerName);

    if (!isEmailOrUsername && rawSellerName.trim().isNotEmpty && rawSellerName != 'Unknown' && rawSellerName != 'COMSATS Student') {
      return Text(
        'Seller: $rawSellerName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
      );
    }

    if (_userNamesCache.containsKey(userId)) {
      return Text(
        'Seller: ${_userNamesCache[userId]}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
      );
    }

    return FutureBuilder<DataSnapshot>(
      future: _dbRef.child('users').child(userId).get(),
      builder: (context, snapshot) {
        String displayName = 'COMSATS Student';
        if (snapshot.hasData && snapshot.data?.value != null && snapshot.data!.value is Map) {
          var uData = snapshot.data!.value as Map<dynamic, dynamic>;
          displayName = uData['name'] ?? uData['fullName'] ?? 'COMSATS Student';
          _userNamesCache[userId] = displayName;
        }
        return Text(
          'Seller: $displayName',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
        );
      },
    );
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
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                      'Unread Notifications',
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
                      final item = _unreadNotifications[index] as Map;
                      String senderName = item['senderName']?.toString() ?? 'COMSATS Student';
                      String lastMessage = item['lastMessage']?.toString() ?? '';
                      String senderId = item['senderId']?.toString() ?? '';
                      String timeStr = item['time']?.toString() ?? 'Recent';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: brandAccent.withValues(alpha: 0.2),
                          child: Text(
                            senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandNavy),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          timeStr,
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
                                receiverId: senderId,
                                receiverName: senderName,
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
              color: const Color(0xFF0077B6).withValues(alpha: 0.12),
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
              color: const Color(0xFF00B4D8).withValues(alpha: 0.10),
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
              ValueListenableBuilder<bool>(
                valueListenable: _isNavCompact,
                builder: (context, isCompact, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.fromLTRB(
                      isCompact ? 36 : 16,
                      12,
                      isCompact ? 36 : 16,
                      6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 8 : 12,
                            vertical: isCompact ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FocusScope.of(context).requestFocus(_searchFocusNode);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: isCompact ? 34 : 38,
                                  height: isCompact ? 34 : 38,
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
                                      color: brandNavy.withValues(alpha: 0.45),
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
                  stream: _dbRef.child('books').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: brandNavy));
                    }

                    List filteredBooks = [];

                    if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                      Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      List booksList = [];

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
                          'isSold': value['isSold'] == true,
                          'createdAt': value['createdAt'] ?? 0,
                        });
                      });

                      filteredBooks = booksList.where((book) {
                        bool isNotSold = book['isSold'] != true;
                        String title = book['title'].toString().toLowerCase();
                        String author = book['author'].toString().toLowerCase();
                        String dept = book['department'].toString();
                        String code = book['bookCode'].toString().toLowerCase();

                        bool matchesSearch = title.contains(_searchQuery) ||
                            author.contains(_searchQuery) ||
                            code.contains(_searchQuery);
                        bool matchesDept = _selectedDeptFilter == 'Filters' || _selectedDeptFilter == 'All' || dept == _selectedDeptFilter;

                        return isNotSold && matchesSearch && matchesDept;
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
                                          color: brandAccent.withValues(alpha: 0.85),
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
                                            color: Colors.white.withValues(alpha: 0.40),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.70),
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
                                      color: Colors.white.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.50),
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
                                              color: Colors.white.withValues(alpha: 0.50),
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
                                    final book = filteredBooks[index] as Map;
                                    bool isMyBook = book['userId'] == _auth.currentUser?.uid;

                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookDetailScreen(
                                              book: Map<String, dynamic>.from(book),
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
                                              color: Colors.black.withValues(alpha: 0.05),
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
                                                                color: Colors.white.withValues(alpha: 0.25),
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
                                                                book['department']?.toString() ?? 'General',
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
                                                          color: Colors.black.withValues(alpha: 0.7),
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
                                                          color: Colors.white.withValues(alpha: 0.95),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          '#${book['bookCode'] ?? 'BOOK'}',
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
                                                            book['title']?.toString() ?? 'Untitled',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandNavy),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Author: ${book['author'] ?? 'Unknown'}',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          _buildSellerNameWidget(
                                                            book['userId']?.toString() ?? '',
                                                            book['sellerName']?.toString() ?? '',
                                                          ),
                                                        ],
                                                      ),
                                                      isMyBook
                                                          ? Container(
                                                              width: double.infinity,
                                                              height: 32,
                                                              alignment: Alignment.center,
                                                              decoration: BoxDecoration(
                                                                color: Colors.amber.withValues(alpha: 0.2),
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
                                                                  onTap: () async {
                                                                    String receiverId = book['userId']?.toString() ?? '';
                                                                    String sellerName = book['sellerName']?.toString() ?? '';

                                                                    // Dynamic name resolver from Firebase node
                                                                    if (sellerName.isEmpty || sellerName == 'COMSATS Student' || sellerName.contains('@') || sellerName == 'Unknown') {
                                                                      try {
                                                                        DataSnapshot snap = await FirebaseDatabase.instance.ref().child('users').child(receiverId).get();
                                                                        if (snap.exists && snap.value is Map) {
                                                                          var uData = snap.value as Map<dynamic, dynamic>;
                                                                          sellerName = uData['name'] ?? uData['fullName'] ?? sellerName;
                                                                        }
                                                                      } catch (_) {}
                                                                    }

                                                                    if (context.mounted) {
                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (_) => ChatScreen(
                                                                            receiverId: receiverId,
                                                                            receiverName: sellerName,
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
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
                                                                          color: brandAccent.withValues(alpha: 0.3),
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
    List widgetOptions = [
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
        child: widgetOptions[_selectedIndex] as Widget,
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
                  color: Colors.black.withValues(alpha: 0.06),
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
                    color: Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70),
                      width: 1.5,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double itemWidth = constraints.maxWidth / _navItems.length;
                      final double circleSize = isCompact ? 38.0 : 42.0;

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            left: (_selectedIndex * itemWidth) + (itemWidth - circleSize) / 2,
                            top: isCompact ? 0 : 2,
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                color: brandAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: brandAccent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Row(
                            children: List.generate(_navItems.length, (index) {
                              bool isSelected = _selectedIndex == index;
                              var navItem = _navItems[index] as Map;
                              IconData currentIcon = (isSelected ? navItem['activeIcon'] : navItem['icon']) as IconData;
                              String currentLabel = navItem['label'].toString();

                              return SizedBox(
                                width: itemWidth,
                                child: GestureDetector(
                                  onTap: () => _onItemTapped(index),
                                  behavior: HitTestBehavior.opaque,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: circleSize,
                                        height: circleSize,
                                        child: Center(
                                          child: Icon(
                                            currentIcon,
                                            color: isSelected ? Colors.white : brandNavy.withValues(alpha: 0.85),
                                            size: isSelected ? (isCompact ? 20 : 22) : (isCompact ? 18 : 20),
                                          ),
                                        ),
                                      ),
                                      if (!isCompact) ...[
                                        const SizedBox(height: 2),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 200),
                                          style: TextStyle(
                                            color: isSelected ? brandAccent : brandNavy.withValues(alpha: 0.85),
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          ),
                                          child: Text(currentLabel),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}