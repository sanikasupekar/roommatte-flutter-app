import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentBookingsScreen extends StatelessWidget {
  const StudentBookingsScreen({super.key});

  Color getStatusColor(String status) {
    if (status == "approved") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    String studentId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('studentId', isEqualTo: studentId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          var bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var data = bookings[index];

              /// ✅ SAFE DATA FETCH
              String status = data['status'] ?? "pending";
              String roomName = data['roomName'] ?? "Room";
              String rent = (data['rent'] ?? "0").toString();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(roomName),
                  subtitle: Text("₹$rent"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}