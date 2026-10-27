import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roommatte/aboutroomhive.dart';

import 'package:roommatte/add_listing_screen.dart';
import 'package:roommatte/availability_screen.dart';
import 'package:roommatte/earnings_screen.dart';
import 'package:roommatte/notification_screen.dart';
import 'package:roommatte/owner_profile_screen1.dart';
import 'package:roommatte/owner_booking_requests_screen.dart';
import 'package:roommatte/auth_screen.dart';
import 'package:roommatte/supportchatscreen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final Color themeColor = const Color(0xFFFF5A5F);
  int currentIndex = 0;

  User? get user => FirebaseAuth.instance.currentUser;
  File? profileImage;

  @override
  Widget build(BuildContext context) {
    final ownerId = user?.uid;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            homeScreen(ownerId),
            const OwnerBookingRequestsScreen(),
            moreScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          selectedItemColor: themeColor,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
          ],
        ),
      ),
    );
  }

  // ================= HOME =================
  Widget homeScreen(String ownerId) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Owner Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          //  FIXED: Realtime unread sub-collection target code identifier badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('owners')
                .doc(ownerId)
                .collection('notifications')
                .where('isRead', isEqualTo: false) // Unread requests trigger count
                .snapshots(),
            builder: (context, snap) {
              int count = snap.hasData ? snap.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: themeColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          count.toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    )
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerProfileScreen()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Business Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .where('ownerId', isEqualTo: ownerId)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final totalListings = docs.length;

                return Row(
                  children: [
                    _buildStatCard(
                      "Total Listings",
                      totalListings.toString(),
                      Icons.list_alt,
                      Colors.blue,
                      () {},
                    ),

                    const SizedBox(width: 10),

                    _buildStatCard(
                      "New Bookings",
                      "View",
                      Icons.pending_actions,
                      Colors.orange,
                      () {
                        setState(() {
                          currentIndex = 1;
                        });
                      },
                    ),

                    const SizedBox(width: 10),

                    _buildStatCard(
                      "Earnings",
                      "₹0",
                      Icons.account_balance_wallet,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EarningsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvailabilityScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text("MANAGE AVAILABILITY"),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "My Listings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .where('ownerId', isEqualTo: ownerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!.docs;

                if (rooms.isEmpty) {
                  return const Text("No listings added yet");
                }

                return Column(
                  children: rooms.map((room) {
                    final data = room.data() as Map<String, dynamic>;
                    final docId = room.id;

                    List images = [];
                    if (data["imageUrls"] is List) {
                      images = data["imageUrls"];
                    }

                    String img = images.isNotEmpty ? images[0] : "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image, size: 60),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data["name"] ?? ""),
                                    Text(data["roomType"] ?? ""),
                                  ],
                                ),
                              ),

                              Text(
                                "₹${data["rent"] ?? ""}",
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddListingScreen(
                                          existingData: data,
                                          docId: docId,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text("EDIT"),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('rooms')
                                        .doc(docId)
                                        .delete();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Deleted Successfully"),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text("DELETE"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddListingScreen(docId: ""),
            ),
          );
        },
        backgroundColor: themeColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("ADD NEW LISTING"),
      ),
    );
  }

  // ================= MORE (RESTORED) =================
  Widget moreScreen() {
    final user = FirebaseAuth.instance.currentUser;

    Future<void> pickProfileImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        profileImage = File(picked.path);

        String fileName = "profile/${user!.uid}.jpg";
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(profileImage!);
        String url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('owners')
            .doc(user.uid)
            .update({"profileImage": url});

        setState(() {
  profileImage = File(picked.path);
});
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("More"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              currentIndex = 0;
            });
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          GestureDetector(
            onTap: pickProfileImage,
            child: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection("owners")
      .doc(user!.uid)
      .get(),
  builder: (context, snapshot) {
    String imageUrl = "";

    if (snapshot.hasData && snapshot.data!.exists) {
      imageUrl = snapshot.data!["profileImage"] ?? "";
    }

    return CircleAvatar(
      radius: 40,
      backgroundImage: profileImage != null
          ? FileImage(profileImage!)
          : (imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null) as ImageProvider?,
      child: (profileImage == null && imageUrl.isEmpty)
          ? Text(
              user.email![0].toUpperCase(),
            )
          : null,
    );
  },
),
          ),

          const SizedBox(height: 10),
          Text(user?.email ?? "No Email"),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.green),
            title: const Text("Aadhaar Verification"),
            subtitle: const Text(
              "Status: VERIFIED",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Edit Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.book),
            title: const Text("Bookings"),
            onTap: () {
              setState(() {
                currentIndex = 1;
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text("Support Chatbot"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportChatScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About RoomHive"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutRoomHiveScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}