import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  final Color themeColor = const Color(0xFFFF5A5F);

  // ⚡ Student ne Final Confirm kelyavar database update karayche function
  Future<void> finalizeBooking(BuildContext context, String bookingId, String roomName, String ownerId, String studentName) async {
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Owner ID missing in booking data.")),
      );
      return;
    }

    try {
      // 1. Booking Status database madhe 'Finalized' kara
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'studentFinalConfirmed': true,
        'status': 'Finalized', 
      });

      // 2. 🔥 FIXED PATH & ENGLISH CONTENT: Owner chya notifications madhye English entry purn keli
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .collection('notifications')
          .add({
        'title': 'Booking Finalized! 🎉',
        'desc': '$studentName has selected your room "$roomName" as their final choice!', 
        'message': '$studentName has selected your room "$roomName" as their final choice!',
        'type': 'booking', 
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Room Finalized successfully! Owner notified. 🎉")),
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
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('studentId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("No bookings yet 😕", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // Approved kiwa Finalized bookings filter kara (Lower & Upper case safe handles)
          var allDocs = snapshot.data!.docs;
          var bookings = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String stat = (data['status'] ?? '').toString().toLowerCase();
            return stat == 'approved' || stat == 'confirmed' || stat == 'finalized';
          }).toList();

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gpp_maybe_rounded, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("No approved bookings yet 😕", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          // 🔥 FIXED LOGIC: Check kara ki list madhye konti room aadhi pasun FINALIZED jhalee aahe ka?
          bool hasAnyRoomFinalized = bookings.any((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['studentFinalConfirmed'] == true || (data['status'] ?? '').toString().toLowerCase() == 'finalized';
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var data = bookings[index];
              Map<String, dynamic> map = data.data() as Map<String, dynamic>;

              String bookingId = data.id;
              String roomName = map['roomName']?.toString() ?? "Room";
              int rent = int.tryParse(map['rent']?.toString() ?? "0") ?? 0;
              String status = map['status'] ?? "pending";
              
              String ownerId = map['ownerId']?.toString() ?? ""; 
              String studentName = map['studentName']?.toString() ?? map['name']?.toString() ?? "Student"; 
              bool isFinalized = map['studentFinalConfirmed'] ?? false;

              // 🔥 जर आधीच दुसरी कोणती रूम फायनल झाली असेल आणि ही रूम फायनल नसेल, तर आपण या कार्डचा लुक चेंज करूया
              bool shouldHideButton = hasAnyRoomFinalized && !isFinalized;

              Color statusColor = isFinalized ? Colors.purple : (shouldHideButton ? Colors.grey : Colors.green);
              IconData statusIcon = isFinalized ? Icons.verified_rounded : (shouldHideButton ? Icons.lock_outline : Icons.check_circle_rounded);

              return Opacity(
                opacity: shouldHideButton ? 0.6 : 1.0, // 💡 जुन्या किंवा इतर कार्ड्सना फिकट लुक दिला
                child: Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: shouldHideButton ? 0 : 3, 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: statusColor, width: 5), 
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// ROOM NAME
                                    Text(
                                      roomName,
                                      style: const TextStyle(
                                        fontSize: 17, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    /// RENT
                                    Row(
                                      children: [
                                        Text(
                                          "₹$rent",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: shouldHideButton ? Colors.grey : themeColor,
                                          ),
                                        ),
                                        Text(
                                          " / month",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              /// STATUS BADGE
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      isFinalized ? "FINALIZED" : (shouldHideButton ? "EXPIRED" : status.toUpperCase()),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // 🛑 "Final Confirm" button logic with English Dialog
                          // 🔥 जर पूर्ण स्क्रीनवर एकही रूम फायनल झालेली नसेल, तरच बटन दिसेल
                          if (!hasAnyRoomFinalized) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(color: Colors.grey[200], height: 1),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text("Confirm Room?", style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: const Text("Are you sure you want to finalize this room? A final confirmation notification will be sent to the owner."), // 🔥 English Description
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text("Cancel", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            finalizeBooking(context, bookingId, roomName, ownerId, studentName);
                                          },
                                          child: const Text("Yes, Finalize", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                                label: const Text("Final Confirm Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ]
                        ],
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