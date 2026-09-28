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

  @override
  Widget build(BuildContext context) {
    const navyBlue = Color(0xFF002147);
    String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      body: StreamBuilder(
        stream: _dbRef.child('chats').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text('No conversations yet.', style: TextStyle(color: Colors.grey)),
            );
          }

          Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<Map<String, dynamic>> myChats = [];

          map.forEach((roomId, roomData) {
            if (roomId.toString().contains(currentUserId) && roomData['meta'] != null) {
              var meta = roomData['meta'];
              myChats.add({
                'roomId': roomId,
                'bookTitle': meta['bookTitle'] ?? 'Book',
                'bookId': meta['bookId'] ?? '',
                'user1_id': meta['user1_id'],
                'user1_name': meta['user1_name'] ?? 'User',
                'user2_id': meta['user2_id'],
                'user2_name': meta['user2_name'] ?? 'User',
                'lastMessage': meta['lastMessage'] ?? '',
                'lastTimestamp': meta['lastTimestamp'] ?? 0,
              });
            }
          });

          if (myChats.isEmpty) {
            return const Center(
              child: Text('No active chats found.', style: TextStyle(color: Colors.grey)),
            );
          }

          // Sort chats by latest message
          myChats.sort((a, b) => (b['lastTimestamp'] as int).compareTo(a['lastTimestamp'] as int));

          return ListView.builder(
            itemCount: myChats.length,
            itemBuilder: (context, index) {
              var chat = myChats[index];

              bool isUser1 = chat['user1_id'] == currentUserId;
              String otherUserName = isUser1 ? chat['user2_name'] : chat['user1_name'];
              String otherUserId = isUser1 ? chat['user2_id'] : chat['user1_id'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: navyBlue,
                    child: Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  title: Text(
                    otherUserName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: navyBlue),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book: ${chat['bookTitle']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
                      ),
                      Text(
                        chat['lastMessage'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          sellerId: otherUserId,
                          bookTitle: chat['bookTitle'],
                          bookId: chat['bookId'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}