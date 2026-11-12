import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  static const Color brandNavy = Color(0xFF0B192C);
  static const Color brandAccent = Color(0xFF0077B6);

  Future<String> _fetchUserName(String userId) async {
    try {
      DataSnapshot userSnap = await _dbRef.child('users').child(userId).get();
      if (userSnap.exists && userSnap.value is Map) {
        Map userData = userSnap.value as Map;
        String name = userData['name'] ?? userData['fullName'] ?? '';
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}
    return 'COMSATS Student';
  }

  void _confirmDeleteChat(String chatRoomId, String otherUserName) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Are you sure you want to delete the entire chat with $otherUserName?'),
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
                await _dbRef.child('chats').child(chatRoomId).remove();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat with $otherUserName deleted successfully.')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? '';

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

          StreamBuilder(
            stream: _dbRef.child('chats').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: brandNavy));
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[500]),
                      const SizedBox(height: 10),
                      Text('No chat conversations yet.', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                );
              }

              List myChats = [];
              Set<String> processedUsers = {};

              if (snapshot.data!.snapshot.value is Map) {
                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                map.forEach((chatRoomId, value) {
                  String roomStr = chatRoomId.toString();
                  if (roomStr.contains(currentUserId)) {
                    List<String> parts = roomStr.split('_');
                    String otherUserId = parts.firstWhere(
                      (id) => id != currentUserId,
                      orElse: () => '',
                    );

                    if (otherUserId.isNotEmpty && !processedUsers.contains(otherUserId)) {
                      processedUsers.add(otherUserId);
                      myChats.add({
                        'chatRoomId': roomStr,
                        'otherUserId': otherUserId,
                      });
                    }
                  }
                });
              }

              if (myChats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[500]),
                      const SizedBox(height: 10),
                      Text('No chat conversations yet.', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: myChats.length,
                itemBuilder: (context, index) {
                  final chatItem = myChats[index] as Map;
                  String chatRoomId = chatItem['chatRoomId'].toString();
                  String otherUserId = chatItem['otherUserId'].toString();

                  return FutureBuilder<String>(
                    future: _fetchUserName(otherUserId),
                    builder: (context, userSnapshot) {
                      String name = userSnapshot.data ?? 'COMSATS Student';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
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
                          onLongPress: () => _confirmDeleteChat(chatRoomId, name),
                          leading: CircleAvatar(
                            backgroundColor: brandNavy,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: brandNavy),
                          ),
                          subtitle: const Text('Tap to open • Press & hold to delete'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                onPressed: () => _confirmDeleteChat(chatRoomId, name),
                                tooltip: 'Delete Chat',
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: brandAccent),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  receiverId: otherUserId,
                                  receiverName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}