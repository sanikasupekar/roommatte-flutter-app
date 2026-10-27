import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartMatchScreen extends StatelessWidget {
  const SmartMatchScreen({super.key});

  /// CONVERT DATA → VECTOR
  List<double> getVector(Map data) {
    return [
      data['gender'] == "Male" ? 1 : 0,
      data['sleepSchedule'] == "Night" ? 1 : 0,
      data['foodHabit'] == "Veg" ? 1 : 0,
      (data['cleanlinessLevel'] ?? 1).toDouble(),
      data['socialNature'] == "Extrovert" ? 1 : 0,
    ];
  }

  /// COSINE SIMILARITY
  double cosineSimilarity(List<double> A, List<double> B) {
    double dot = 0;
    double magA = 0;
    double magB = 0;

    for (int i = 0; i < A.length; i++) {
      dot += A[i] * B[i];
      magA += A[i] * A[i];
      magB += B[i] * B[i];
    }

    if (magA == 0) magA = 1;
    if (magB == 0) magB = 1;

    return dot / (sqrt(magA) * sqrt(magB));
  }

  /// ROOMMATE MATCH (AI)
  int calculateRoommateMatch(Map me, Map other) {
    var v1 = getVector(me);
    var v2 = getVector(other);

    double similarity = cosineSimilarity(v1, v2);
    return (similarity * 100).toInt();
  }

  /// 🏠 ROOM MATCH
  int calculateRoomScore(Map me, Map room) {
    int score = 0;

    int budget = me['budget'] ?? 0;
    int rent = room['rent'] ?? 0;

    if (rent <= budget) score += 50;
    if (room['availableSpots'] > 0) score += 50;

    return score;
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("AI Smart Match 🤖")),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .get(),
        builder: (context, mySnapshot) {

          if (!mySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var myData =
              mySnapshot.data!.data() as Map<String, dynamic>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .snapshots(),
            builder: (context, roomSnapshot) {

              if (!roomSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var rooms = roomSnapshot.data!.docs;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .snapshots(),
                builder: (context, userSnapshot) {

                  if (!userSnapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var users = userSnapshot.data!.docs;

                  List<Map<String, dynamic>> matches = [];

                  for (var room in rooms) {
                    var roomData =
                        room.data() as Map<String, dynamic>;

                    int roomScore =
                        calculateRoomScore(myData, roomData);

                    if (roomScore == 0) continue;

                    for (var user in users) {
                      var userData =
                          user.data() as Map<String, dynamic>;

                      if (userData['userId'] == uid) continue;

                      int mateScore =
                          calculateRoommateMatch(myData, userData);

                      /// FINAL SCORE (AI COMBINED)
                      int totalScore =
                          (mateScore * 0.7 + roomScore * 0.3).toInt();

                      matches.add({
                        "room": roomData,
                        "user": userData,
                        "score": totalScore,
                      });
                    }
                  }

                  /// SORT BEST FIRST
                  matches.sort((a, b) =>
                      b['score'].compareTo(a['score']));

                  if (matches.isEmpty) {
                    return const Center(
                        child: Text("No matches found 😕"));
                  }

                  var topMatches = matches.take(10).toList();

                  return ListView.builder(
                    itemCount: topMatches.length,
                    itemBuilder: (context, index) {

                      var item = topMatches[index];
                      var room = item['room'];
                      var user = item['user'];
                      int score = item['score'];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              /// SCORE
                              Text(
                                "🔥 $score% Match",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// ROOM
                              Text(
                                "🏠 ${room['name'] ?? 'Room'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text("₹${room['rent']} / month"),

                              const SizedBox(height: 10),

                              /// ROOMMATE
                              Text(
                                "👤 ${user['name'] ?? 'User'}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10),

                              /// MATCH REASONS
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (room['rent'] <=
                                      (myData['budget'] ?? 0))
                                    const Text("✔ Budget match"),
                                  if (user['foodHabit'] ==
                                      myData['foodHabit'])
                                    const Text("✔ foodhabit"),
                                  if (user['sleepSchedule'] ==
                                      myData['sleepSchedule'])
                                    const Text("✔ Same sleepSchedule"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}