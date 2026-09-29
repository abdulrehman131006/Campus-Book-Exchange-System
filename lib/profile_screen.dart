import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedDept = 'Computer Science';
  bool _isSaving = false;

  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandBlue = Color(0xFF1E3E62);
  static const Color brandAccent = Color(0xFF0077B6);

  final List<String> _departments = [
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DataSnapshot snapshot = await _dbRef.child('users').child(user.uid).get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text = data['name'] ?? (user.email?.split('@')[0] ?? '');
            _phoneController.text = data['phone'] ?? '';
            if (data['department'] != null && _departments.contains(data['department'])) {
              _selectedDept = data['department'];
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _nameController.text = user.email?.split('@')[0] ?? 'Student';
          });
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _dbRef.child('users').child(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _selectedDept,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteBookListing(String bookId) async {
    try {
      await _dbRef.child('books').child(bookId).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book listing deleted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  // FAQ Modal Dialog
  void _showFAQsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.help_rounded, color: brandAccent),
                      SizedBox(width: 8),
                      Text(
                        'Frequently Asked Questions (FAQs)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandNavy),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        _FaqItem(
                          question: '1. How can I list a book for sale or exchange?',
                          answer: 'Go to the "Sell/Share" tab on the bottom navigation bar, fill in your book details (Title, Author, Department, Price, etc.), and tap submit to publish it instantly.',
                        ),
                        _FaqItem(
                          question: '2. Is this app only for COMSATS students?',
                          answer: 'Yes, this platform is specifically tailored for COMSATS University students to exchange and buy textbooks within the campus community safely.',
                        ),
                        _FaqItem(
                          question: '3. How do I contact the seller?',
                          answer: 'Click on any book card to open its detail view, then tap the "Chat with Seller" button to start a direct real-time chat with them.',
                        ),
                        _FaqItem(
                          question: '4. How can I edit or delete my book listing?',
                          answer: 'Go to your Profile tab, open "My Books", and you will see edit and delete icons right next to your listed items.',
                        ),
                        _FaqItem(
                          question: '5. What should I do if I forget my password?',
                          answer: 'You can use the password reset option on the login screen, or reach out to the campus support desk for assistance.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBookDialog(Map<String, dynamic> book) {
    final titleCtrl = TextEditingController(text: book['title']);
    final authorCtrl = TextEditingController(text: book['author']);
    final priceCtrl = TextEditingController(text: book['price'] == 'Free' ? '' : book['price'].toString());
    final descCtrl = TextEditingController(text: book['description'] ?? '');
    String editDept = _departments.contains(book['department']) ? book['department'] : 'Computer Science';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Book Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandNavy),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: authorCtrl,
                    decoration: InputDecoration(
                      labelText: 'Author',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (PKR)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: editDept,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => editDept = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        String newTitle = titleCtrl.text.trim();
                        String newAuthor = authorCtrl.text.trim();
                        String newPrice = priceCtrl.text.trim();

                        if (newTitle.isEmpty || newAuthor.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Title and Author cannot be empty')),
                          );
                          return;
                        }

                        await _dbRef.child('books').child(book['id']).update({
                          'title': newTitle,
                          'author': newAuthor,
                          'price': newPrice.isEmpty ? 'Free' : newPrice,
                          'department': editDept,
                          'description': descCtrl.text.trim(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Book updated successfully!')),
                          );
                        }
                      },
                      child: const Text('Update Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyListingsTab() {
    String currentUserId = _auth.currentUser?.uid ?? '';

    return StreamBuilder(
      stream: _dbRef.child('books').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: brandNavy));
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_add_outlined, size: 60, color: Colors.grey[500]),
                const SizedBox(height: 10),
                const Text('You have not listed any books yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> myBooks = [];

        map.forEach((key, value) {
          if (value['userId'] == currentUserId) {
            myBooks.add({
              'id': key.toString(),
              'title': value['title'] ?? 'Untitled',
              'author': value['author'] ?? 'Unknown',
              'department': value['department'] ?? 'General',
              'price': value['price'] ?? 'Free',
              'description': value['description'] ?? '',
            });
          }
        });

        if (myBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_add_outlined, size: 60, color: Colors.grey[500]),
                const SizedBox(height: 10),
                const Text('You have not listed any books yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: myBooks.length,
          itemBuilder: (context, index) {
            var book = myBooks[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.book_rounded, color: brandNavy),
                ),
                title: Text(
                  book['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: brandNavy, fontSize: 15),
                ),
                subtitle: Text('Author: ${book['author']} • PKR ${book['price']}', style: const TextStyle(color: Colors.black54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: brandAccent),
                      onPressed: () => _showEditBookDialog(book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Listing'),
                            content: const Text('Are you sure you want to delete this book listing?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteBookListing(book['id']);
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Student Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandNavy),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: brandAccent),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.black87),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: const Icon(Icons.phone_outlined, color: brandAccent),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDept,
              decoration: InputDecoration(
                labelText: 'Department',
                prefixIcon: const Icon(Icons.school_outlined, color: brandAccent),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontSize: 12, color: Colors.black87)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDept = val);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    User? user = _auth.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: brandAccent),
                  title: const Text('University Email', style: TextStyle(color: brandNavy)),
                  subtitle: Text(user?.email ?? 'N/A', style: const TextStyle(color: Colors.black54)),
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined, color: brandAccent),
                  title: Text('Account Status', style: TextStyle(color: brandNavy)),
                  subtitle: Text('COMSATS Student Verified', style: TextStyle(color: Colors.black54)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: brandAccent),
                  title: const Text('Help & Support', style: TextStyle(color: brandNavy)),
                  subtitle: const Text('Frequently Asked Questions (FAQs)', style: TextStyle(color: Colors.black54)),
                  onTap: _showFAQsDialog, // Click karte hi FAQs popup open hoga
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Logout Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await _auth.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    String userEmail = user?.email ?? 'student@comsats.edu.pk';
    String initial = userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return Scaffold(
      body: Stack(
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

          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: brandNavy,
                      child: Text(
                        initial,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : 'COMSATS Student',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: brandNavy),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: brandAccent,
                  labelColor: brandNavy,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: 'My Books'),
                    Tab(icon: Icon(Icons.edit_note_rounded, size: 20), text: 'Edit Profile'),
                    Tab(icon: Icon(Icons.settings_outlined, size: 20), text: 'Settings'),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _tabController.index,
                  children: [
                    _buildMyListingsTab(),
                    _buildEditProfileTab(),
                    _buildSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widget for FAQ List items
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B192C)),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.3),
          ),
        ],
      ),
    );
  }
}