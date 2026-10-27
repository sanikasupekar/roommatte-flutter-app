import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommatte/chat_screen.dart';

class MyRoommateScreen extends StatelessWidget {
  const MyRoommateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Roommate"),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(currentUserId)
            .get(),
        builder: (context, mySnapshot) {

          if (mySnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!mySnapshot.hasData || mySnapshot.data!.data() == null) {
            return const Center(child: Text("No data found"));
          }

          var myData =
              mySnapshot.data!.data() as Map<String, dynamic>;

          ///  SAFE CHECK
          if (!myData.containsKey('roommateId') ||
              myData['roommateId'] == null ||
              myData['roommateId'].toString().isEmpty) {
            return const Center(
              child: Text(
                "No roommate yet 😢",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          String roommateId = myData['roommateId'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('students')
                .doc(roommateId)
                .get(),
            builder: (context, roommateSnapshot) {

              if (roommateSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (!roommateSnapshot.hasData ||
                  roommateSnapshot.data!.data() == null) {
                return const Center(
                    child: Text("Roommate data not found"));
              }

              var data = roommateSnapshot.data!.data()
                  as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    const SizedBox(height: 20),

                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 50),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      data['name'] ?? "No Name",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text("Gender: ${data['gender'] ?? '-'}"),
                    Text("Sleep: ${data['sleepSchedule'] ?? '-'}"),
                    Text("Food: ${data['foodHabit'] ?? '-'}"),
                    Text("Cleanliness: ${data['cleanlinessLevel'] ?? '-'}"),
                    Text("Social: ${data['socialNature'] ?? '-'}"),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                roommateId: roommateId,
                              ),
                            ),
                          );
                        },
                        child: const Text("Chat"),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}