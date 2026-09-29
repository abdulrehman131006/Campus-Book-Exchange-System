import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';
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

  String _searchQuery = '';
  String _selectedDeptFilter = 'All';

  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandBlue = Color(0xFF1E3E62);
  static const Color brandAccent = Color(0xFF0077B6);

  final List<String> _deptFilterOptions = [
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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

  Widget _buildBooksFeed() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE2E8F0), Color(0xFFEDF2F7), Color(0xFFCBD5E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -30,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandAccent.withValues(alpha: 0.18),
            ),
          ),
        ),
        StreamBuilder(
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
                booksList.add({
                  'id': key.toString(),
                  'title': value['title'] ?? 'Untitled',
                  'author': value['author'] ?? 'Unknown Author',
                  'department': value['department'] ?? 'General',
                  'price': value['price'] ?? 'Free',
                  'description': value['description'] ?? '',
                  'userId': value['userId'] ?? '',
                  'sellerName': value['sellerName'] ?? 'Seller',
                  'bookCode': value['bookCode'] ?? key.toString().substring(0, key.toString().length > 5 ? 5 : key.toString().length).toUpperCase(),
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
                bool matchesDept = _selectedDeptFilter == 'All' || dept == _selectedDeptFilter;

                return matchesSearch && matchesDept;
              }).toList();
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search title, author, or code...',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: brandAccent),
                              filled: true,
                              fillColor: const Color(0xFFF1F5F9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Filter Dept: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: brandNavy, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300, width: 0.8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDeptFilter,
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: brandNavy),
                                      items: _deptFilterOptions.map((dept) {
                                        return DropdownMenuItem(
                                          value: dept,
                                          child: Text(
                                            dept,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: brandNavy, fontWeight: FontWeight.w600),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _selectedDeptFilter = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (filteredBooks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
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
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
                                                                color: brandAccent.withValues(alpha: 0.4),
                                                                blurRadius: 8,
                                                                offset: const Offset(0, 3),
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
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetOptions = <Widget>[
      _buildBooksFeed(),
      const AddBookScreen(),
      const ChatsListScreen(),
      const AIChatbotScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandNavy, brandBlue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Campus Book Exchange', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Logout', style: TextStyle(color: brandNavy, fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          color: brandNavy,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: brandNavy.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Books'),
                _buildNavItem(1, Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Sell/Share'),
                _buildNavItem(2, Icons.forum_outlined, Icons.forum_rounded, 'Chats'),
                _buildNavItem(3, Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI Helper'),
                _buildNavItem(4, Icons.account_circle_outlined, Icons.account_circle_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _selectedIndex == index;
    const Color activeColor = Color(0xFF00B4D8);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: Offset(0, isSelected ? -10 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSelected ? 48 : 38,
                height: isSelected ? 48 : 38,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: isSelected ? 24 : 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.white60,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}