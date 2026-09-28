import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedDepartment = 'Computer Science';
  bool _isLoading = false;

  // COMSATS Expanded Departments List
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

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _uploadBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String bookId = _dbRef.child('books').push().key ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _dbRef.child('books').child(bookId).set({
        'bookId': bookId,
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'price': _priceController.text.trim().isEmpty ? 'Free / Exchange' : 'Rs. ${_priceController.text.trim()}',
        'department': _selectedDepartment,
        'description': _descriptionController.text.trim(),
        'userId': user.uid,
        'userEmail': user.email,
        'postedAt': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book Listed Successfully!')),
        );
        _titleController.clear();
        _authorController.clear();
        _priceController.clear();
        _descriptionController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to list book: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF002147);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'List a Book for Sale or Exchange',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyBlue),
              ),
              const Text(
                'Fill in details to share with campus students',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Book Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Book Title',
                  prefixIcon: Icon(Icons.book, color: navyBlue),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter book title' : null,
              ),
              const SizedBox(height: 15),

              // Author Name
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author Name',
                  prefixIcon: Icon(Icons.person_outline, color: navyBlue),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter author name' : null,
              ),
              const SizedBox(height: 15),

              // Department Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  labelText: 'Department / Field',
                  prefixIcon: Icon(Icons.domain_rounded, color: navyBlue),
                ),
                items: _departments.map((dept) {
                  return DropdownMenuItem(value: dept, child: Text(dept));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDepartment = val);
                },
              ),
              const SizedBox(height: 15),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price in PKR (Leave empty if Free/Exchange)',
                  prefixIcon: Icon(Icons.sell_outlined, color: navyBlue),
                ),
              ),
              const SizedBox(height: 15),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (e.g., Condition, Edition)',
                  prefixIcon: Icon(Icons.description_outlined, color: navyBlue),
                ),
              ),
              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _uploadBook,
                        child: const Text('Post Book Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}