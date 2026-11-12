import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final LinearGradient cardGradient;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.cardGradient,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandBlue = Color(0xFF1E3E62);
  static const Color brandAccent = Color(0xFF0077B6);

  bool _isUpdating = false;

  Future<void> _markAsSold() async {
    setState(() => _isUpdating = true);
    try {
      String bookId = widget.book['id'] ?? '';
      if (bookId.isNotEmpty) {
        await FirebaseDatabase.instance.ref().child('books').child(bookId).update({
          'isSold': true,
        });
        if (mounted) {
          setState(() {
            widget.book['isSold'] = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book marked as SOLD!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool isMyBook = widget.book['userId'] == currentUserId;
    bool isSold = widget.book['isSold'] == true;

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
        title: Text(
          widget.book['title'] ?? 'Book Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Banner Header Card
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: widget.cardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSold ? Icons.check_circle_rounded : Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSold ? 'SOLD OUT' : (widget.book['department'] ?? 'General'),
                                style: TextStyle(
                                  color: isSold ? Colors.redAccent : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Code: #${widget.book['bookCode'] ?? 'BOOK'}',
                              style: const TextStyle(color: brandNavy, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSold ? Colors.red.withOpacity(0.9) : Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isSold
                                  ? 'SOLD OUT'
                                  : (widget.book['price'] != null && widget.book['price'].toString().isNotEmpty
                                      ? 'PKR ${widget.book['price']}'
                                      : 'Free'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Main Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandNavy),
                        ),
                        const SizedBox(height: 8),
                        Text('Author: ${widget.book['author'] ?? 'Unknown'}', style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Department: ${widget.book['department'] ?? 'General'}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        const SizedBox(height: 6),
                        Text('Seller: ${widget.book['sellerName'] ?? 'Student'}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
                        const Text('Description / Condition', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandNavy)),
                        const SizedBox(height: 8),
                        Text(
                          widget.book['description'] != null && widget.book['description'].toString().isNotEmpty
                              ? widget.book['description']
                              : 'No additional description provided by the seller.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button (Mark as Sold for Seller / Chat for Buyer)
                  if (isMyBook)
                    Column(
                      children: [
                        if (isSold)
                          Container(
                            width: double.infinity,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red, width: 1.5),
                            ),
                            child: const Text(
                              'This Book is Marked as SOLD OUT',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _isUpdating ? null : _markAsSold,
                              icon: _isUpdating
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                              label: const Text(
                                'Mark as Sold',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    )
                  else if (!isSold)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: widget.book['userId'],
                                receiverName: widget.book['sellerName'],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                        label: const Text(
                          'Chat with Seller',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
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
}