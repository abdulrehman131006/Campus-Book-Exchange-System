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
  final List _messages = [];
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _booksDbRef = FirebaseDatabase.instance.ref().child('books');
  late DatabaseReference _aiChatDbRef;

  // Aap ki copied API Key
  static const String _apiKey = 'AQ.Ab8RN6JwQHwIKj19xbGB01To90hMT9f45-UazysX_sc502t0Cg';

  final List<String> _models = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandAccent = Color(0xFF0077B6);

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

  Future<void> _loadAndCleanOldChatHistory() async {
    try {
      DataSnapshot snapshot = await _aiChatDbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        int now = DateTime.now().millisecondsSinceEpoch;
        const int twentyFourHoursInMs = 24 * 60 * 60 * 1000;

        List tempMessages = [];

        map.forEach((key, value) {
          int messageTime = value['timestamp'] ?? 0;
          if (now - messageTime > twentyFourHoursInMs) {
            _aiChatDbRef.child(key).remove();
          } else {
            tempMessages.add({
              'role': value['role'] ?? 'user',
              'text': value['text'] ?? '',
              'timestamp': messageTime,
            });
          }
        });

        tempMessages.sort((a, b) => ((a as Map)['timestamp'] as int).compareTo((b as Map)['timestamp'] as int));

        if (mounted) {
          setState(() {
            _messages.clear();
            for (var item in tempMessages) {
              _messages.add({
                'role': (item as Map)['role'],
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

  Future<List> _getAvailableBooksFromDb() async {
    List booksList = [];
    try {
      DataSnapshot snapshot = await _booksDbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          booksList.add({
            'title': value['title']?.toString() ?? 'Untitled',
            'author': value['author']?.toString() ?? 'Unknown Author',
            'department': value['department']?.toString() ?? 'General',
            'price': value['price']?.toString() ?? 'Free',
            'sellerName': value['sellerName']?.toString() ?? 'Student',
            'bookCode': value['bookCode']?.toString() ?? '',
          });
        });
      }
    } catch (_) {}
    return booksList;
  }

  Future<String> _generateSmartFallbackResponse(String userText) async {
    String query = userText.toLowerCase().trim();
    List books = await _getAvailableBooksFromDb();

    List<String> queryWords = query
        .replaceAll(RegExp(r'(is|book|available|in|app|store|campus|the|please|tell|me|show|list|any|details)'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    bool isBookIntent = query.contains('book') || query.contains('available') || query.contains('price') || query.contains('seller') || query.contains('is');

    List matches = [];
    if (isBookIntent || queryWords.isNotEmpty) {
      matches = books.where((b) {
        Map bookMap = b as Map;
        String title = bookMap['title'].toString().toLowerCase();
        String author = bookMap['author'].toString().toLowerCase();
        String dept = bookMap['department'].toString().toLowerCase();

        return queryWords.any((word) {
          return title.contains(word) ||
                 author.contains(word) ||
                 dept.contains(word) ||
                 (word.length > 3 && title.startsWith(word.substring(0, 3)));
        });
      }).toList();
    }

    if (isBookIntent) {
      if (matches.isNotEmpty) {
        StringBuffer sb = StringBuffer("📚 Matching book(s) found in campus database:\n\n");
        for (var item in matches.take(3)) {
          Map b = item as Map;
          sb.writeln("📖 Title: ${b['title']}");
          sb.writeln("👤 Author: ${b['author']}");
          sb.writeln("💵 Price: PKR ${b['price']}");
          sb.writeln("🏬 Department: ${b['department']}\n");
        }
        sb.write("Check the 'Books' feed tab to contact the seller directly!");
        return sb.toString();
      } else {
        String searchedTerm = queryWords.isNotEmpty ? queryWords.join(' ') : userText;
        return "Currently, no book matching '$searchedTerm' is listed on the app. Check back later or ask in the student chat feed!";
      }
    }

    if (query == 'hi' || query == 'hello' || query == 'hey' || query.contains('assalam')) {
      return "Hello! I am your COMSATS Campus AI Assistant. Ask me about textbook availability, course topics, method explanations, or syllabus guidance!";
    }

    return "I am ready to assist with your studies! Ask me any course question, topic explanation, or book query.";
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

    List books = await _getAvailableBooksFromDb();
    String booksSummary = books.map((item) {
      Map b = item as Map;
      return "- Title: ${b['title']}, Author: ${b['author']}, Price: ${b['price']}, Dept: ${b['department']}";
    }).join("\n");

    String systemInstruction = '''
You are Campus AI Assistant, an expert universal academic tutor for COMSATS University Islamabad students across ALL departments (Computer Science, Software Engineering, Electrical, Civil, Mechanical, BBA, Accounting, Mathematics, Physics, Humanities, etc.).

Your Job:
1. Provide accurate, clear, and step-by-step academic guidance for ANY subject question, formula, topic explanation, or syllabus query.
2. If the student asks about book availability, search the CURRENTLY LISTED BOOKS database below and show exact matching results.

CURRENTLY LISTED BOOKS IN APP DATABASE:
$booksSummary
''';

    bool success = false;
    String aiReply = '';

    if (_apiKey.trim().isNotEmpty) {
      for (String model in _models) {
        try {
          final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": "$systemInstruction\n\nUser Question: $text"}
                  ]
                }
              ]
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            aiReply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
            if (aiReply.isNotEmpty) {
              success = true;
              break;
            }
          }
        } catch (_) {}
      }
    }

    if (!success || aiReply.isEmpty) {
      aiReply = await _generateSmartFallbackResponse(text);
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
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: brandNavy.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined, color: brandNavy),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Campus AI Assistant (Auto-deletes in 24h)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandNavy),
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
                                  'Ask AI about available textbooks, course topics, concepts, or academic guidance across all departments!',
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
                            final msg = _messages[index] as Map;
                            final isMe = msg['role'] == 'user';
                            String formattedTime = _formatTime(msg['timestamp']);

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe ? brandNavy : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text']?.toString() ?? '',
                                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
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
                    padding: EdgeInsets.all(6.0),
                    child: LinearProgressIndicator(color: brandNavy),
                  ),

                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(fontSize: 14, color: brandNavy),
                          decoration: InputDecoration(
                            hintText: 'Ask about any topic, subject, or book...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: brandNavy,
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
          ),
        ],
      ),
    );
  }
}