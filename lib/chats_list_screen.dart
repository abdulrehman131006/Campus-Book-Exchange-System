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
  static const Color brandBlue = Color(0xFF1E3E62);
  static const Color brandAccent = Color(0xFF0077B6);

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Background Decor
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
                color: brandAccent.withOpacity(0.18),
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

              Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<Map<String, String>> myChats = [];

              map.forEach((chatRoomId, value) {
                if (chatRoomId.toString().contains(currentUserId)) {
                  List<String> parts = chatRoomId.toString().split('_');
                  String otherUserId = parts.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => '',
                  );

                  if (otherUserId.isNotEmpty) {
                    myChats.add({
                      'chatRoomId': chatRoomId.toString(),
                      'otherUserId': otherUserId,
                    });
                  }
                }
              });

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
                  String otherUserId = myChats[index]['otherUserId']!;

                  return FutureBuilder(
                    future: _dbRef.child('users').child(otherUserId).get(),
                    builder: (context, AsyncSnapshot<DataSnapshot> userSnapshot) {
                      String name = 'COMSATS Student';
                      if (userSnapshot.hasData && userSnapshot.data?.value != null) {
                        Map<dynamic, dynamic> userData = userSnapshot.data!.value as Map<dynamic, dynamic>;
                        name = userData['name'] ?? 'COMSATS Student';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
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
                          subtitle: const Text('Tap to open conversation'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: brandAccent),
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