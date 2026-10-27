import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentOwnerId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Bookings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: currentOwnerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No bookings found",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          var bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var data = bookings[index];

              return BookingCard(
                bookingId: bookings[index].id,
                roomId: data['roomId'] ?? '',
                name: data['studentName'] ?? '',
                property: data['roomName'] ?? '',
                status: data['status'] ?? 'pending',
                date: '',
              );
            },
          );
        },
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String bookingId;
  final String roomId;
  final String name;
  final String property;
  final String status;
  final String date;

  const BookingCard({
    super.key,
    required this.bookingId,
    required this.roomId,
    required this.name,
    required this.property,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (status.toLowerCase()) {
      case "approved":
      case "confirmed":
        statusColor = Colors.green;
        break;

      case "rejected":
      case "cancelled":
        statusColor = Colors.red;
        break;

      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.black54),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  property,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                if (status.toLowerCase() == "pending") ...[
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () async {
                          try {
                            DocumentSnapshot bookingDoc =
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(bookingId)
                                    .get();

                            // Double approve se bachne ke liye
                            if ((bookingDoc['status'] ?? '') == 'approved') {
                              return;
                            }

                            DocumentSnapshot roomDoc =
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(roomId)
                                    .get();

                            int availableSpots =
                                roomDoc['availableSpots'] ?? 0;

                            if (availableSpots <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No beds available"),
                                ),
                              );
                              return;
                            }

                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(bookingId)
                                .update({
                              'status': 'approved',
                            });

                            await FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(roomId)
                                .update({
                              'availableSpots': FieldValue.increment(-1),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Booking approved"),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                              ),
                            );
                          }
                        },
                        child: const Text("Approve"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({
                            'status': 'rejected',
                          });
                        },
                        child: const Text("Reject"),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}