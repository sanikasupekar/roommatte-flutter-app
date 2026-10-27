import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Color themeColor = const Color(0xFFFF5A5F);

  User? get user => FirebaseAuth.instance.currentUser;

  // 🔥 Single Notification Delete Karanyasathi Function
  Future<void> _deleteNotification(String userId, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection("owners")
          .doc(userId)
          .collection("notifications")
          .doc(docId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification deleted successfully"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = user?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("owners")
            .doc(userId)
            .collection("notifications")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications yet 🔔"));
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var doc = notifications[index];
              var data = doc.data() as Map<String, dynamic>;
              var docId = doc.id; // 🔥 Document ID isolated for delete mapping

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // 🔥 ICON
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIcon(data["type"]), color: themeColor),
                    ),

                    const SizedBox(width: 12),

                    // 🔥 TEXT DETAILS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data["title"] ?? "No Title",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data["desc"] ?? data["message"] ?? "New booking request received",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    //  FIXED: Cross (Close/Clear) symbol button for fast deletion
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () => _deleteNotification(userId, docId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  //  ICON BASED ON TYPE
  IconData _getIcon(String? type) {
    switch (type) {
      case "booking":
      case "booking_request":
        return Icons.book;
      case "chat":
        return Icons.chat;
      case "room":
        return Icons.home;
      case "signup":
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
}