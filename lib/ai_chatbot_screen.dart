import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _booksDbRef = FirebaseDatabase.instance.ref().child('books');
  late DatabaseReference _aiChatDbRef;

  // AAPKI GEMINI API KEY
  static const String _apiKey = 'AQ.Ab8RN6KKBzTtPUMC9J4Jc-X9K1R5xB4ON0JTQH27JjSYhYtypQ';

  // Strictly active models list
  final List<String> _models = [
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-1.5-flash',
  ];

  @override
  void initState() {
    super.initState();
    String userId = _auth.currentUser?.uid ?? 'guest_user';
    _aiChatDbRef = FirebaseDatabase.instance.ref().child('ai_chats').child(userId);
    _loadAndCleanOldChatHistory();
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      int hour = dt.hour;
      int minute = dt.minute;
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      String minuteStr = minute < 10 ? '0$minute' : '$minute';
      return '$hour:$minuteStr $period';
    } catch (e) {
      return '';
    }
  }

  // 24 Hours Auto-Delete logic
  Future<void> _loadAndCleanOldChatHistory() async {
    try {
      DataSnapshot snapshot = await _aiChatDbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        int now = DateTime.now().millisecondsSinceEpoch;
        const int twentyFourHoursInMs = 24 * 60 * 60 * 1000;

        List<Map<String, dynamic>> validMessages = [];

        map.forEach((key, value) {
          int messageTime = value['timestamp'] ?? 0;
          if (now - messageTime > twentyFourHoursInMs) {
            _aiChatDbRef.child(key).remove();
          } else {
            validMessages.add({
              'role': value['role'] ?? 'user',
              'text': value['text'] ?? '',
              'timestamp': messageTime,
            });
          }
        });

        validMessages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

        if (mounted) {
          setState(() {
            _messages.clear();
            for (var item in validMessages) {
              _messages.add({
                'role': item['role'],
                'text': item['text'],
                'timestamp': item['timestamp'],
              });
            }
          });
        }
      }
    } catch (e) {
      print("Error loading AI history: $e");
    }
  }

  Future<String> _fetchCurrentAvailableBooksContext() async {
    try {
      DataSnapshot snapshot = await _booksDbRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        return "CURRENTLY LISTED BOOKS IN APP: No books are listed right now.";
      }

      Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
      List<String> booksSummaryList = [];

      map.forEach((key, value) {
        String title = value['title'] ?? 'Untitled';
        String author = value['author'] ?? 'Unknown Author';
        String dept = value['department'] ?? 'General';
        String price = value['price'] ?? 'Free';
        
        booksSummaryList.add("- Title: '$title', Author: '$author', Department: '$dept', Price: '$price'");
      });

      return "CURRENTLY LISTED BOOKS IN APP DATABASE:\n${booksSummaryList.join('\n')}";
    } catch (e) {
      return "CURRENTLY LISTED BOOKS IN APP DATABASE: Unable to fetch live database context.";
    }
  }

  // Fallback local intelligent response generator
  String _generateLocalFallbackResponse(String userText, String booksContext) {
    String lower = userText.toLowerCase();
    if (lower.contains('hi') || lower.contains('hello') || lower.contains('hy') || lower.contains('hey')) {
      return "Hello! I am your Campus AI Assistant. Ask me about available textbooks in COMSATS or course guidance!";
    }
    
    if (lower.contains('calculus') || lower.contains('cal') || lower.contains('math')) {
      if (booksContext.toLowerCase().contains('calculus')) {
        return "Yes! Calculus textbook is currently available in the app. Check the Books tab or contact the seller directly!";
      } else {
        return "Calculus textbook is currently not listed by any seller on the app. Recommended syllabus book: 'Calculus by Thomas Finney'.";
      }
    }

    return "I am specialized in COMSATS academics and Campus Book Exchange app support. Please check the 'Books' tab for active listings or ask course textbook queries!";
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'timestamp': currentTimestamp,
      });
      _isLoading = true;
    });
    _controller.clear();

    await _aiChatDbRef.push().set({
      'role': 'user',
      'text': text,
      'timestamp': ServerValue.timestamp,
    });

    String availableBooksContext = await _fetchCurrentAvailableBooksContext();

    String systemInstruction = '''
You are "Campus AI Assistant", a dedicated AI helper for COMSATS University students using the Campus Book Exchange app.

$availableBooksContext

STRICT INSTRUCTIONS:
1. Check the CURRENTLY LISTED BOOKS above when a user asks about available books.
2. If matched, give Title, Author, Department, and Price.
3. If not matched, state it's currently unavailable and suggest the COMSATS syllabus reference book.
4. ONLY answer queries related to COMSATS courses, textbooks, academic guidance, and app support. Decline unrelated queries politely.
5. Keep answers concise and helpful.
''';

    bool success = false;
    String aiReply = '';
    String fullPrompt = "$systemInstruction\n\nUser Question: $text";

    // Attempt API calls with active models
    for (String model in _models) {
      for (int attempt = 0; attempt < 2; attempt++) { // Retry loop for 503 errors
        try {
          final url = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

          final body = jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": fullPrompt}
                ]
              }
            ]
          });

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            aiReply = data['candidates'][0]['content']['parts'][0]['text'] ?? '';
            if (aiReply.isNotEmpty) {
              success = true;
              break;
            }
          } else if (response.statusCode == 503) {
            await Future.delayed(const Duration(milliseconds: 800)); // Small wait on high demand
          }
        } catch (e) {
          // Ignore and continue
        }
      }
      if (success) break;
    }

    // Use intelligent fallback if API endpoints are busy
    if (!success || aiReply.isEmpty) {
      aiReply = _generateLocalFallbackResponse(text, availableBooksContext);
    }

    int aiTimestamp = DateTime.now().millisecondsSinceEpoch;

    if (mounted) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': aiReply,
          'timestamp': aiTimestamp,
        });
      });
    }

    await _aiChatDbRef.push().set({
      'role': 'ai',
      'text': aiReply,
      'timestamp': ServerValue.timestamp,
    });

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearChatHistory() async {
    await _aiChatDbRef.remove();
    if (mounted) {
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Chat history cleared!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF002147);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: navyBlue.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, color: navyBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Campus AI Assistant (Auto-deletes in 24h)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: navyBlue),
                  ),
                ),
                if (_messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                    tooltip: 'Clear Chat History',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Chat'),
                          content: const Text('Are you sure you want to clear AI conversation history?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearChatHistory();
                              },
                              child: const Text('Clear', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Ask AI if any textbook (e.g. Calculus, Physics, OOP) is currently available in the campus database!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['role'] == 'user';
                      String formattedTime = _formatTime(msg['timestamp']);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? navyBlue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                              ),
                              if (formattedTime.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: navyBlue),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about available books or courses...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: navyBlue,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}