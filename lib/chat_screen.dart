import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late DatabaseReference _chatDbRef;
  late String _chatRoomId;

  static const Color brandDarkNavy = Color(0xFF002147);
  static const Color bgSurface = Color(0xFFF4F6F9);

  @override
  void initState() {
    super.initState();
    String currentUserId = _auth.currentUser?.uid ?? 'guest';
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');
    _chatDbRef = FirebaseDatabase.instance.ref().child('chats').child(_chatRoomId);
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    String currentUserId = _auth.currentUser?.uid ?? '';

    _chatDbRef.push().set({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': text,
      'timestamp': ServerValue.timestamp,
    });

    _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: brandDarkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              radius: 18,
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.receiverName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatDbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: brandDarkNavy));
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(
                    child: Text(
                      'Say hi to ${widget.receiverName}!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> messagesList = [];

                map.forEach((key, value) {
                  messagesList.add({
                    'id': key,
                    'senderId': value['senderId'] ?? '',
                    'message': value['message'] ?? '',
                    'timestamp': value['timestamp'] ?? 0,
                  });
                });

                messagesList.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messagesList.length,
                  itemBuilder: (context, index) {
                    final msg = messagesList[index];
                    final isMe = msg['senderId'] == currentUserId;
                    String formattedTime = _formatTime(msg['timestamp']);

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? brandDarkNavy : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'],
                              style: TextStyle(
                                color: isMe ? Colors.white : brandDarkNavy,
                                fontSize: 14,
                              ),
                            ),
                            if (formattedTime.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.grey[500],
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
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      filled: true,
                      fillColor: bgSurface,
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
                  backgroundColor: brandDarkNavy,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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