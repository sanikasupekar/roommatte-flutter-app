import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final Color themeColor = const Color(0xFFFF5A5F);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //  SEND NOTIFICATION TO ALL STUDENTS
  Future<void> sendNotificationToStudents(
      String roomName, bool isAvailable) async {
    final students = await _firestore.collection("students").get();

    for (var student in students.docs) {
      await _firestore.collection("notifications").add({
        "userId": student.id,
        "title": isAvailable ? "Room Available" : "Room Full",
        "message":
            "$roomName is now ${isAvailable ? "available" : "fully booked"}",
        "type": "room",
        "timestamp": FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔥 APPBAR
      appBar: AppBar(
        title: const Text(
          "Room Availability",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // 🔥 REALTIME ROOMS FROM FIRESTORE
      body: StreamBuilder(
        stream: _firestore
    .collection("rooms")
    .where("ownerId", isEqualTo: ownerId)
    .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                "No rooms available",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final data = room.data() as Map<String, dynamic>;

              int totalBeds = data["beds"] ?? 0;
              int availableSpots = data["availableSpots"] ?? 0;

              bool isAvailable = availableSpots > 0;

              return _buildRoomCard(
                room.id,
                data,
                isAvailable,
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 ROOM CARD
  Widget _buildRoomCard(
    String roomId,
    Map<String, dynamic> room,
    bool isAvailable,
  ) {
    int totalBeds = room["beds"] ?? 0;
    int availableSpots = room["availableSpots"] ?? 0;
    int occupiedBeds = totalBeds - availableSpots;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 🔹 ICON BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home_work, color: themeColor, size: 28),
            ),

            const SizedBox(width: 14),

            // 🔹 TEXT SECTION
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room["name"] ?? "Room",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    room["type"] ?? "Standard",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? "Available" : "Full",
                      style: TextStyle(
                        color:
                            isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Total Beds : $totalBeds",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),

                  Text(
                    "Occupied Beds : $occupiedBeds",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),

                  Text(
                    "Available Beds : $availableSpots",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 SWITCH (UI SAME)
            Column(
  children: [
    Icon(
      isAvailable ? Icons.check_circle : Icons.cancel,
      color: isAvailable ? Colors.green : Colors.red,
      size: 30,
    ),
    Text(
      isAvailable ? "Available" : "Full",
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}