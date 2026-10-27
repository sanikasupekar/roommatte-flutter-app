import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const ListingDetailsScreen({super.key, required this.property});

  final Color themeColor = const Color(0xFFFF5A5F);

  // --- NAVIN LOGIC FUNCTION (Added with Student Name for better Owner visibility) ---
  Future<void> _handleBooking(BuildContext context, String roomId, String ownerId, String currentUserId, String roomName, int roomRent) async {
    try {
      // 🔥 FIXED: collection('users') badlun direct collection('students') kela aahe jene karun khre naav bhetel
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('students').doc(currentUserId).get();
      String studentName = "Anonymous Student";
      
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('name')) {
          studentName = userData['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? "Student";
        } else {
          studentName = FirebaseAuth.instance.currentUser?.displayName ?? "Student";
        }
      }

      // Step 2: Bookings collection madhye entry karane
      await FirebaseFirestore.instance.collection('bookings').add({
        'roomId': roomId,
        'ownerId': ownerId, // Navin room add kartana save kelelyach ownerId ithe yeto
        'studentId': currentUserId,
        'studentName': studentName, 
        'roomName': roomName,
        'rent': roomRent,
        'status': "pending",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Step 3: Owner la notification pathavne
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .collection('notifications')
          .add({
        'title': 'New Booking Request! 🏠',
        'desc': '$studentName is interested in $roomName',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'booking_request', // Scenario 3 target standard code identifier
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Request Sent to Owner ✅")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List images = property['imageUrls'] ?? [];

    String imageUrl = "";
    if (images.isNotEmpty && images[0] != null) {
      imageUrl = images[0].toString();
    }

    String name = property['name']?.toString() ?? "No Name";
    String rent = property['rent']?.toString() ?? "0";
    String location = property['location']?.toString() ?? "No Location";
    String description =
        property['description']?.toString() ?? "No description available";

    String roomId = property['roomId'] ?? ''; 
    String ownerId = property['ownerId'] ?? ''; 

    String currentUserId =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "₹$rent / month",
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _feature(Icons.wifi, "WiFi"),
                      _feature(Icons.ac_unit, "AC"),
                      _feature(Icons.restaurant, "Food"),
                      _feature(Icons.local_laundry_service, "Laundry"),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Description",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
                    style: const TextStyle(
                        color: Colors.grey, height: 1.5),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            )
          ],
        ),
      ),

      ///  SMART BUTTON (Logic fully integrated with your existing StreamBuilder)
      bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .snapshots(),
        builder: (context, roomSnapshot) {

          if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
            return const SizedBox();
          }

          var roomData =
              roomSnapshot.data!.data() as Map<String, dynamic>;

          int availableSpots =
              roomData['availableSpots'] ?? 0;
          String roomName = roomData['name'] ?? "Room";
          
          int roomRent = 0;
          if (roomData['rent'] != null) {
            roomRent = int.tryParse(roomData['rent'].toString()) ?? 0;
          }

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('bookings') 
                .where('roomId', isEqualTo: roomId)
                .where('studentId', isEqualTo: currentUserId)
                .get(),
            builder: (context, bookingSnapshot) {

              bool alreadyRequested =
                  bookingSnapshot.hasData &&
                      bookingSnapshot.data!.docs.isNotEmpty;

              String buttonText = "BOOK NOW";
              bool isDisabled = false;

              if (availableSpots <= 0) {
                buttonText = "FULL";
                isDisabled = true;
              } else if (alreadyRequested) {
                buttonText = "REQUESTED";
                isDisabled = true;
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDisabled
                          ? Colors.grey
                          : themeColor,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    onPressed: isDisabled
                        ? null
                        : () {
                            // 🔥 FIXED: Pratham 'property' check kara, jar nsel tar 'roomData' (Firestore) madhun explicit ownerId dakhva
                            String finalOwnerId = ownerId.isNotEmpty 
                                ? ownerId 
                                : (roomData['ownerId']?.toString() ?? '');

                            if (finalOwnerId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Error: Owner ID not found! ❌")),
                              );
                              return;
                            }
                            _handleBooking(context, roomId, finalOwnerId, currentUserId, roomName, roomRent);
                          },
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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

  Widget _feature(IconData icon, String text) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(icon, color: Colors.black),
        ),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 250,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}