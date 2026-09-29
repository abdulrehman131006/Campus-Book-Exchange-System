import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  bool _isLoading = false;

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

  Future<void> _submitBook() async {
    String title = _titleController.text.trim();
    String author = _authorController.text.trim();
    String price = _priceController.text.trim();
    String desc = _descController.text.trim();

    if (title.isEmpty || author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Title and Author name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      String userId = user?.uid ?? 'guest';
      String sellerName = user?.email?.split('@')[0] ?? 'Student';

      DatabaseReference newBookRef = FirebaseDatabase.instance.ref().child('books').push();
      String bookId = newBookRef.key ?? '';

      await newBookRef.set({
        'title': title,
        'author': author,
        'price': price.isEmpty ? 'Free' : price,
        'department': _selectedDepartment,
        'description': desc,
        'userId': userId,
        'sellerName': sellerName,
        'bookCode': bookId.substring(0, bookId.length > 5 ? 5 : bookId.length).toUpperCase(),
        'createdAt': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book listed successfully!')),
        );
        _titleController.clear();
        _authorController.clear();
        _priceController.clear();
        _descController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Decor Layer
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
          Positioned(
            bottom: 40,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandBlue.withValues(alpha: 0.15),
              ),
            ),
          ),

          // Scrollable Form Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sell or Share a Book',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandNavy),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Book Title',
                        isDense: true,
                        prefixIcon: const Icon(Icons.book_rounded, color: brandAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _authorController,
                      decoration: InputDecoration(
                        labelText: 'Author Name',
                        isDense: true,
                        prefixIcon: const Icon(Icons.person_rounded, color: brandAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Price (PKR) - Leave empty if free',
                        isDense: true,
                        prefixIcon: const Icon(Icons.attach_money_rounded, color: brandAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Compact Limited Dropdown Menu
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      isExpanded: true,
                      menuMaxHeight: 250, // Popup menu max height fix
                      borderRadius: BorderRadius.circular(16),
                      decoration: InputDecoration(
                        labelText: 'Department',
                        isDense: true,
                        prefixIcon: const Icon(Icons.school_rounded, color: brandAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: _departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(
                            dept,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: brandNavy),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDepartment = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description / Condition',
                        alignLabelWithHint: true,
                        isDense: true,
                        prefixIcon: const Icon(Icons.description_rounded, color: brandAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Post Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}