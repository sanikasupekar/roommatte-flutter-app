import 'dart:math'; // 🔥 MATH IMPORT FOR COSINE SIMILARITY LOGIC
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoommatesScreen extends StatelessWidget {
  const RoommatesScreen({super.key});

  // --- 🔥 UNIFORM VECTOR ENCODING LOGIC FROM DASHBOARD ---
  List<double> encodePrefs(Map<String, dynamic> prefs) {
    
    double gender = prefs["gender"] == "Male" ? 1.0 : 2.0;
    double food = prefs["foodHabit"] == "Veg" ? 1.0 : 2.0;
    double sleep = prefs["sleepSchedule"] == "Early" ? 1.0 : 2.0;
    double clean = (prefs["cleanlinessLevel"] ?? 3).toDouble();
    double study = prefs["studyPreference"] == "Group" ? 1.0 : 2.0;
    double budget = (prefs["budgetLevel"] ?? 3).toDouble();
    double social = prefs["socialNature"] == "Extrovert" ? 1.0 : 2.0;
    return [gender, food, sleep, clean, study, budget, social];
  }

  // --- 🔥 DYNAMIC COSINE SIMILARITY ALGORITHM FOR ACCURATE MATCH % ---
  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    double magA = 0;
    double magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    
    double similarity = dot / (sqrt(magA) * sqrt(magB));
    
    
    if (similarity > 1.0) similarity = 1.0;
    if (similarity < 0.0) similarity = 0.0;
    
    return similarity;
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Roommates"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(currentUserId)
            .get(),
        builder: (context, mySnapshot) {
          if (!mySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var myData = mySnapshot.data!.data() as Map<String, dynamic>? ?? {};
          
          String myActualGender = (myData['gender'] ?? (myData['preferences'] != null ? myData['preferences']['gender'] : 'Female')).toString().trim();

          var myPrefs = myData['preferences'] as Map<String, dynamic>? ?? {};
          List<double> myVector = encodePrefs(myPrefs);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs;
              List<Map<String, dynamic>> matchedUsers = [];

              for (var user in users) {
                if (user.id == currentUserId) continue; 

                var data = user.data() as Map<String, dynamic>;
                if (data.isEmpty) continue;

                var otherPrefs = data['preferences'] as Map<String, dynamic>? ?? {};

                String otherActualGender = (data['gender'] ?? (otherPrefs['gender'] ?? 'Male')).toString().trim();

                //  STRICT GENDER FILTER
                if (otherActualGender.toLowerCase() != myActualGender.toLowerCase()) {
                  continue; 
                }

                List<double> otherVector = encodePrefs(otherPrefs);
                double similarity = cosineSimilarity(myVector, otherVector);
                
                
                int matchPercent = (similarity.isNaN || similarity.isInfinite) ? 0 : (similarity * 100).toInt();

                matchedUsers.add({
                  "data": data,
                  "match": matchPercent,
                  "userId": user.id,
                });
              }

              ///  SORT BY CALCULATED REAL-TIME MATCH % (DESCENDING) -
              matchedUsers.sort((a, b) => b['match'].compareTo(a['match']));

              if (matchedUsers.isEmpty) {
                return const Center(
                  child: Text("No compatible roommates found for your gender yet.", style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: matchedUsers.length,
                itemBuilder: (context, index) {
                  var item = matchedUsers[index];
                  var data = item['data'];
                  int match = item['match'];
                  var otherPrefs = data['preferences'] as Map<String, dynamic>? ?? {};

                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person),
                      ),
                      title: Text(data['name'] ?? "No Name"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Gender: ${data['gender'] ?? otherPrefs['gender'] ?? '-'}"),
                          Text("Sleep: ${otherPrefs['sleepSchedule'] ?? data['sleepSchedule'] ?? data['sleep'] ?? '-'}"),
                          Text("Food: ${otherPrefs['foodHabit'] ?? data['foodHabit'] ?? data['food'] ?? '-'}"),
                          Text("Match Score: $match%"),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: match >= 80
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$match%",
                          style: TextStyle(
                              color: match >= 80 ? Colors.green : Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        var currentOtherPrefs = data['preferences'] as Map<String, dynamic>? ?? {};

                        String sleep = (data['sleepSchedule'] ?? currentOtherPrefs['sleepSchedule'] ?? data['sleep'] ?? currentOtherPrefs['sleep'] ?? '-').toString();
                        String food = (data['foodHabit'] ?? currentOtherPrefs['foodHabit'] ?? data['food'] ?? currentOtherPrefs['food'] ?? '-').toString();
                        String cleanliness = (data['cleanlinessLevel'] ?? currentOtherPrefs['cleanlinessLevel'] ?? data['cleanliness'] ?? currentOtherPrefs['cleanliness'] ?? '-').toString();
                        String social = (data['socialNature'] ?? currentOtherPrefs['socialNature'] ?? data['social'] ?? currentOtherPrefs['social'] ?? '-').toString();
                        String study = (data['studyPreference'] ?? currentOtherPrefs['studyPreference'] ?? data['study'] ?? currentOtherPrefs['study'] ?? '-').toString();
                        String budget = (data['budgetLevel'] ?? currentOtherPrefs['budgetLevel'] ?? data['budget'] ?? currentOtherPrefs['budget'] ?? '-').toString();

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            title: Text(
                              data['name'] ?? "No Name",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Gender: ${data['gender'] ?? currentOtherPrefs['gender'] ?? '-'}"),
                                const SizedBox(height: 8),
                                Text("Sleep Schedule: $sleep"),
                                const SizedBox(height: 5),
                                Text("Food Habit: $food"),
                                const SizedBox(height: 5),
                                Text("Cleanliness: $cleanliness"),
                                const SizedBox(height: 5),
                                Text("Social Nature: $social"),
                                const SizedBox(height: 5),
                                Text("Study Preference: $study"),
                                const SizedBox(height: 5),
                                Text("Budget Level: $budget"),
                                const Divider(height: 20),
                                Text(
                                  "Match: $match%",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F), fontSize: 16),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close", style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5A5F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('roommate_requests')
                                      .add({
                                    "from": currentUserId,
                                    "to": item['userId'],
                                    "name": myData['name'] ?? "",
                                    "match": match,
                                    "status": "pending",
                                    "createdAt": FieldValue.serverTimestamp(),
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('students')
                                      .doc(item['userId'])
                                      .collection('notifications')
                                      .add({
                                    'title': "New Roommate Request! 🤝",
                                    'desc': "${myData['name']} has sent you a roommate request.",
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'isRead': false,
                                    'senderId': currentUserId,
                                    'type': 'request_received'
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Roommate request sent ✅")),
                                    );
                                  }
                                },
                                child: const Text("Request", style: TextStyle(color: Colors.white)),
                                                            ),
                            ],
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
    );
  }
}
