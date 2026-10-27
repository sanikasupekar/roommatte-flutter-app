import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerBookingRequestsScreen extends StatefulWidget {
  const OwnerBookingRequestsScreen({super.key});

  @override
  State<OwnerBookingRequestsScreen> createState() =>
      _OwnerBookingRequestsScreenState();
}

class _OwnerBookingRequestsScreenState
    extends State<OwnerBookingRequestsScreen> {
  final Color themeColor = const Color(0xFFFF5A5F);

  User? get user => FirebaseAuth.instance.currentUser;

  // 🔥 UPDATED FUNCTION WITH INTEGRATED STUDENT NOTIFICATION LOGIC
  Future<void> updateBooking(
    String bookingId,
    String status,
    String roomId,
    String studentId, // 👈 Included Parameter
    String roomName,  // 👈 Included Parameter
  ) async {
    if (roomId.isEmpty && status == "accepted") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Room ID missing for this booking ❌"),
        ),
      );
      return;
    }

    try {
      // 1. Update status inside bookings collection
      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(bookingId)
          .update({"status": status == "accepted" ? "approved" : "rejected"});

      // 2.  Jevha Owner request ACCEPT karel, teha student la dynamic entry sub-collection trigger dene
      if (status == "accepted") {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .collection('notifications')
            .add({
          'title': 'Booking Approved! 🎉',
          'desc': 'Owner has accepted your request for $roomName.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'booking_approved',
        });

        // Existing Transaction logic for spots reduction
        DocumentReference roomRef = FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentSnapshot roomSnap = await transaction.get(roomRef);

          if (roomSnap.exists) {
            int currentSpots = 0;

            var rawSpots = roomSnap['availableSpots'];
            if (rawSpots is int) {
              currentSpots = rawSpots;
            } else if (rawSpots is String) {
              currentSpots = int.tryParse(rawSpots) ?? 0;
            }

            if (currentSpots > 0) {
              transaction.update(roomRef, {'availableSpots': currentSpots - 1});
            }
          }
        });
      } 
      // 3.  Jevha owner request REJECT karel, teha student la safe message pathavne
      else if (status == "rejected") {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .collection('notifications')
            .add({
          'title': 'Request Update ⚠️',
          'desc': 'Your booking request for $roomName was declined.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'booking_rejected',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Booking ${status == 'accepted' ? 'Accepted' : 'Rejected'} ✅",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = user?.uid;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Booking Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("ownerId", isEqualTo: ownerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No booking requests yet 📭"));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;

              final String status = data["status"] ?? "pending";
              final String roomName = data["roomName"] ?? "Unknown Room";
              final String roomId = data["roomId"] ?? "";
              final String bookingId = bookings[index].id;

              final String? storedName = data["studentName"];
              final String studentId = data["studentId"] ?? "";

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: storedName != null
                                ? Text(
                                    storedName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection("students")
                                        .doc(studentId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      String name = "Loading...";

                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
                                        name = snapshot.data!["name"] ?? "Student";
                                      }

                                      return Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          const Icon(Icons.home_work_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(roomName),
                        ],
                      ),

                      const Divider(height: 30),

                      if (status == "pending")
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                //  FIXED: Passed studentId and roomName to notify the student on accept
                                onPressed: () => updateBooking(
                                  bookingId,
                                  "accepted",
                                  roomId,
                                  studentId,
                                  roomName,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("ACCEPT"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                //  FIXED: Passed studentId and roomName to notify the student on reject
                                onPressed: () => updateBooking(
                                  bookingId,
                                  "rejected",
                                  roomId,
                                  studentId,
                                  roomName,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("REJECT"),
                              ),
                            ),
                          ],
                        )
                      else
                        Text("Status: ${status.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case "approved":
      case "accepted":
        color = Colors.green;
        break;
      case "rejected":
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}