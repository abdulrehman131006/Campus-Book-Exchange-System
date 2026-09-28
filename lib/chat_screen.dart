import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String bookTitle;
  final String bookId;

  const ChatScreen({
    super.key,
    required this.sellerId,
    required this.bookTitle,
    required this.bookId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late String _chatRoomId;
  String _otherUserName = '';

  @override
  void initState() {
    super.initState();
    String currentUserId = _auth.currentUser?.uid ?? '';
    List<String> ids = [currentUserId, widget.sellerId];
    ids.sort();
    _chatRoomId = "${ids.join('_')}_${widget.bookId}";

    _fetchOtherUserDetails();
  }

  Future<void> _fetchOtherUserDetails() async {
    try {
      DataSnapshot snapshot = await _dbRef.child('users').child(widget.sellerId).get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
        String? name = userData['name'];
        String? email = userData['email'];

        if (mounted) {
          setState(() {
            if (name != null && name.trim().isNotEmpty) {
              _otherUserName = name;
            } else if (email != null && email.contains('@')) {
              _otherUserName = email.split('@')[0];
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
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

  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String currentUserName = currentUser.email?.split('@')[0] ?? 'User';
    try {
      DataSnapshot userSnap = await _dbRef.child('users').child(currentUser.uid).get();
      if (userSnap.exists && userSnap.value != null) {
        Map<dynamic, dynamic> userData = userSnap.value as Map<dynamic, dynamic>;
        if (userData['name'] != null && userData['name'].toString().trim().isNotEmpty) {
          currentUserName = userData['name'];
        }
      }
    } catch (e) {
      print("Error getting current user name: $e");
    }

    String finalOtherName = _otherUserName.isEmpty ? 'User' : _otherUserName;

    // Save Chat Metadata
    await _dbRef.child('chats').child(_chatRoomId).child('meta').set({
      'bookTitle': widget.bookTitle,
      'bookId': widget.bookId,
      'user1_id': currentUser.uid,
      'user1_name': currentUserName,
      'user2_id': widget.sellerId,
      'user2_name': finalOtherName,
      'lastMessage': text,
      'lastTimestamp': ServerValue.timestamp,
    });

    // Send Message
    _dbRef.child('chats').child(_chatRoomId).child('messages').push().set({
      'senderId': currentUser.uid,
      'message': text,
      'timestamp': ServerValue.timestamp,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF002147);
    String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _otherUserName.isEmpty
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Book: ${widget.bookTitle}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.child('chats').child(_chatRoomId).child('messages').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(
                    child: Text('Say Hi! Start conversation about this book.', style: TextStyle(color: Colors.grey)),
                  );
                }

                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<dynamic> messages = map.values.toList();

                messages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index];
                    bool isMe = msg['senderId'] == currentUserId;
                    String formattedTime = _formatTime(msg['timestamp']);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isMe ? navyBlue : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
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
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
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