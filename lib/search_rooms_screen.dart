import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roommatte/listing_details_screen.dart';

class SearchRoomsScreen extends StatelessWidget {
  const SearchRoomsScreen({super.key});

  final Color themeColor = const Color(0xFFFF5A5F);

  /// ENCODE FUNCTION
  List<double> encodePrefs(Map<String, dynamic> prefs) {
    double gender = prefs["gender"] == "Male" ? 0 : 1;
    double food = prefs["foodHabit"] == "Veg" ? 0 : 1;
    double sleep = prefs["sleepSchedule"] == "Early" ? 0 : 1;
    double clean = (prefs["cleanlinessLevel"] ?? 3).toDouble();
    double study = prefs["studyPreference"] == "Group" ? 0 : 1;
    double budget = (prefs["budgetLevel"] ?? 3).toDouble();
    double social = prefs["socialNature"] == "Extrovert" ? 0 : 1;

    return [gender, food, sleep, clean, study, budget, social];
  }

  /// COSINE SIMILARITY
  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    double magA = 0;
    double magB = 0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }

    // Safety check for division by zero
    if (magA == 0 || magB == 0) return 0;

    return dot / (sqrt(magA) * sqrt(magB));
  }

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Search Rooms", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // FIXED: collection('users') badlun collection('students') kele aahe
        future: FirebaseFirestore.instance
            .collection('students')
            .doc(userId)
            .get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("User preferences not found"));
          }

          Map<String, dynamic> userData =
              userSnapshot.data!.data() as Map<String, dynamic>;

          List<double> userVector = encodePrefs(userData);

          // FIXED REALTIME WISHLIST TRACKING IN SEARCH LAYOUT
          
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('students').doc(userId).snapshots(),
            builder: (context, currentStudentSnap) {
              if (!currentStudentSnap.hasData || !currentStudentSnap.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }
              
              var currentStudentData = currentStudentSnap.data!.data() as Map<String, dynamic>;
              List currentWishlist = currentStudentData['wishlist'] ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .snapshots(),
                builder: (context, snapshot) {
                  ///  Loading
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  ///  Error
                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong"));
                  }

                  ///  Empty
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No rooms available 😕"));
                  }

                  final rooms = snapshot.data!.docs;

                  ///  MATCH CALCULATION + STORE
                  List<Map<String, dynamic>> roomList = [];

                  for (var doc in rooms) {
                    final rawData = doc.data();
                    if (rawData == null) continue;

                    final data = rawData as Map<String, dynamic>;

                    if (data['preferences'] == null) continue;

                    List<double> roomVector =
                        encodePrefs(data['preferences']);

                    double score =
                        cosineSimilarity(userVector, roomVector);

                    int matchPercent = (score * 100).toInt();

                    // ---  DATA INTEGRITY: Ensuring ownerId and roomId are stored in the local map ---
                    data['roomId'] = doc.id; 
                    data['ownerId'] = data['ownerId'] ?? ''; 

                    roomList.add({
                      "id": doc.id, // Variable tracking mapping identifier
                      "data": data,
                      "match": matchPercent,
                    });
                  }

                  ///  SORT BEST MATCH FIRST
                  roomList.sort((a, b) => b['match'].compareTo(a['match']));

                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: roomList.length,
                    itemBuilder: (context, index) {
                      final String rId = roomList[index]["id"];
                      final data = roomList[index]["data"];
                      final match = roomList[index]["match"];

                      bool isLiked = currentWishlist.contains(rId);

                      ///  SAFE DATA
                      String name = data['name']?.toString() ?? "No Name";
                      String price = data['rent']?.toString() ?? "0";
                      String location =
                          data['location']?.toString() ?? "No Location";

                      /// ✅ SAFE IMAGE
                      String image = "";
                      if (data['imageUrls'] != null &&
                          data['imageUrls'] is List &&
                          data['imageUrls'].isNotEmpty &&
                          data['imageUrls'][0] != null) {
                        image = data['imageUrls'][0].toString();
                      }

                      return GestureDetector(
                        onTap: () {
                          //  ACCURATE LOGIC: Creating a clean property map to pass
                          // This ensures that when Sanika clicks, Shri's ownerId goes to the next screen.
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListingDetailsScreen(property: Map<String, dynamic>.from(data)),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                  offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ///  IMAGE CARD WITH REALTIME FLOATING LIKE ICON
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _placeholder(),
                                          )
                                        : _placeholder(),
                                  ),
                                  // 🔥 FIXED REAL-TIME WISHLIST LIKE TRIGGER
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (isLiked) {
                                          await FirebaseFirestore.instance.collection('students').doc(userId).update({
                                            'wishlist': FieldValue.arrayRemove([rId])
                                          });
                                        } else {
                                          await FirebaseFirestore.instance.collection('students').doc(userId).update({
                                            'wishlist': FieldValue.arrayUnion([rId])
                                          });
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.white.withOpacity(0.9),
                                        child: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: themeColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              /// 📄 DETAILS
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    /// 🏠 NAME + PRICE
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "₹$price",
                                          style: TextStyle(
                                            color: themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    /// 📍 LOCATION
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 14,
                                            color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          location,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    /// 🧠 MATCH %
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Match: $match%",
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Text("Best Choice", style: TextStyle(color: Colors.green, fontSize: 10)),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    /// ⭐ FEATURES
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _chip("AC"),
                                        const SizedBox(width: 5),
                                        _chip("Food"),
                                        const SizedBox(width: 5),
                                        _chip("WiFi"),
                                      ],
                                    )
                                  ],
                                ),
                              )
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

  ///  CHIP
  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }

  ///  PLACEHOLDER
  Widget _placeholder() {
    return Container(
      height: 180,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}
