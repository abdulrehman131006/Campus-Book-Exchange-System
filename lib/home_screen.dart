import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';
import 'add_book_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'chats_list_screen.dart';
import 'ai_chatbot_screen.dart';

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

  Widget _buildBooksFeed() {
    const navyBlue = Color(0xFF002147);

    return Column(
      children: [
        // Search and Filter Bar Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          color: navyBlue.withOpacity(0.04),
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  prefixIcon: const Icon(Icons.search_rounded, color: navyBlue),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Department Dropdown Filter
              Row(
                children: [
                  const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDeptFilter,
                          isExpanded: true,
                          items: _deptFilterOptions.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(dept, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
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

        // Stream Feed
        Expanded(
          child: StreamBuilder(
            stream: _dbRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No books listed yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<dynamic> allBooks = map.values.toList();

              // Filter logic
              List<dynamic> filteredBooks = allBooks.where((book) {
                String title = (book['title'] ?? '').toString().toLowerCase();
                String author = (book['author'] ?? '').toString().toLowerCase();
                String dept = (book['department'] ?? '').toString();

                bool matchesSearch = title.contains(_searchQuery) || author.contains(_searchQuery);
                bool matchesDept = _selectedDeptFilter == 'All' || dept == _selectedDeptFilter;

                return matchesSearch && matchesDept;
              }).toList();

              if (filteredBooks.isEmpty) {
                return const Center(
                  child: Text('No books found matching your criteria.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  var book = filteredBooks[index];
                  bool isMyBook = book['userId'] == _auth.currentUser?.uid;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  book['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: navyBlue,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  book['price'] ?? 'Free',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Author: ${book['author'] ?? 'Unknown'}',
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(book['department'] ?? 'General', style: const TextStyle(fontSize: 12)),
                            backgroundColor: navyBlue.withOpacity(0.08),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (book['description'] != null && book['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              book['description'],
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                          const Divider(height: 20),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: isMyBook
                                ? const Text(
                                    'Listed by You',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  )
                                : ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: navyBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            sellerId: book['userId'],
                                            bookTitle: book['title'] ?? 'Book',
                                            bookId: book['bookId'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                    label: const Text('Chat with Seller'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF002147);

    List<Widget> widgetOptions = <Widget>[
      _buildBooksFeed(),
      const AddBookScreen(),
      const ChatsListScreen(),
      const AIChatbotScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Book Exchange', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: widgetOptions[_selectedIndex],
   bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed, // 4 items ke liye fixed smooth rehta hai
  items: const <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_rounded),
      label: 'Books',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle_outline_rounded),
      label: 'Sell / Share',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      label: 'Chats',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'AI Helper'),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      label: 'Profile',
    ),
  ],
  currentIndex: _selectedIndex,
  selectedItemColor: navyBlue,
  unselectedItemColor: Colors.grey,
  onTap: _onItemTapped,
),
    );
  }
}