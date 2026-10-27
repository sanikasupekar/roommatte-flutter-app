import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String roommateId;

  const ChatScreen({super.key, required this.roommateId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? "";

  /// 🔑 CHAT ID
  String getChatId() {
    if (currentUserId.compareTo(widget.roommateId) > 0) {
      return "${widget.roommateId}_$currentUserId";
    } else {
      return "${currentUserId}_${widget.roommateId}";
    }
  }

  /// 📤 SEND MESSAGE
  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(getChatId())
        .collection('messages')
        .add({
      "text": _controller.text.trim(),
      "senderId": currentUserId,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    String chatId = getChatId();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),

      body: Column(
        children: [

          /// 💬 MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {

                    var data = messages[index].data()
                        as Map<String, dynamic>;

                    String text = data['text'] ?? "";
                    String senderId = data['senderId'] ?? "";

                    bool isMe = senderId == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green
                              : Colors.grey[300],
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✏️ INPUT
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}