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

  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

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

  Future<String> _getReceiverRealName() async {
    try {
      DataSnapshot snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.receiverId)
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        Map data = snapshot.value as Map;
        String name = data['name'] ?? data['fullName'] ?? '';
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}

    String fallback = widget.receiverName;
    if (fallback.contains('@')) {
      fallback = fallback.split('@')[0];
    }
    return fallback.isNotEmpty ? fallback : 'COMSATS Student';
  }

  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    String currentUserId = _auth.currentUser?.uid ?? '';
    _messageController.clear();

    DatabaseReference newMessageRef = _chatDbRef.push();
    await newMessageRef.set({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'message': text,
      'timestamp': ServerValue.timestamp,
    });
  }

  void _deleteSelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Are you sure you want to delete ${_selectedMessageIds.length} selected message(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                for (String id in _selectedMessageIds) {
                  await _chatDbRef.child(id).remove();
                }
                setState(() {
                  _selectedMessageIds.clear();
                  _isSelectionMode = false;
                });
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEntireChat(String currentName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Clear Entire Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Are you sure you want to delete all messages with $currentName? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _chatDbRef.remove();
                setState(() {
                  _selectedMessageIds.clear();
                  _isSelectionMode = false;
                });
              },
              child: const Text('Delete All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _toggleMessageSelection(String msgId) {
    setState(() {
      if (_selectedMessageIds.contains(msgId)) {
        _selectedMessageIds.remove(msgId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(msgId);
      }
    });
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) return '';
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

    return FutureBuilder<String>(
      future: _getReceiverRealName(),
      builder: (context, nameSnapshot) {
        String displayName = nameSnapshot.data ?? widget.receiverName;

        return Scaffold(
          backgroundColor: bgSurface,
          appBar: AppBar(
            backgroundColor: brandDarkNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedMessageIds.clear();
                      });
                    },
                  )
                : null,
            title: _isSelectionMode
                ? Text('${_selectedMessageIds.length} Selected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                : InkWell(
                    onTap: () => _deleteEntireChat(displayName),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            radius: 18,
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Text(
                                'Tap to clear chat',
                                style: TextStyle(fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  onPressed: _deleteSelectedMessages,
                  tooltip: 'Delete Selected Messages',
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70),
                  onPressed: () => _deleteEntireChat(displayName),
                  tooltip: 'Delete Entire Chat',
                ),
            ],
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
                          'Say hi to $displayName!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    }

                    List messagesList = [];
                    DataSnapshot dbSnapshot = snapshot.data!.snapshot;

                    if (dbSnapshot.value is Map) {
                      Map<dynamic, dynamic> map = dbSnapshot.value as Map<dynamic, dynamic>;
                      map.forEach((key, value) {
                        if (value is Map) {
                          messagesList.add({
                            'id': key.toString(),
                            'senderId': value['senderId']?.toString() ?? '',
                            'message': value['message']?.toString() ?? '',
                            'timestamp': value['timestamp'] ?? 0,
                          });
                        }
                      });
                    }

                    messagesList.sort((a, b) {
                      int t1 = a['timestamp'] is int ? a['timestamp'] : 0;
                      int t2 = b['timestamp'] is int ? b['timestamp'] : 0;
                      return t1.compareTo(t2);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messagesList.length,
                      itemBuilder: (context, index) {
                        final msg = messagesList[index];
                        final String msgId = msg['id'].toString();
                        final isMe = msg['senderId'] == currentUserId;
                        final isSelected = _selectedMessageIds.contains(msgId);
                        String formattedTime = _formatTime(msg['timestamp']);

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: GestureDetector(
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedMessageIds.add(msgId);
                                });
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleMessageSelection(msgId);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.shade100
                                    : (isMe ? brandDarkNavy : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(color: Colors.red, width: 1.5)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isSelectionMode) ...[
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 18,
                                      color: isSelected ? Colors.red : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg['message'],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.black87
                                                : (isMe ? Colors.white : brandDarkNavy),
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (formattedTime.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            formattedTime,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.grey[700]
                                                  : (isMe ? Colors.white70 : Colors.grey[500]),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
      },
    );
  }
}