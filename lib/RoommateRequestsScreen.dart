import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoommateRequestsScreen extends StatelessWidget {
  const RoommateRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Roommate Requests"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('roommate_requests')
            .where('to', isEqualTo: currentUserId)
            .where('status', isEqualTo: "pending") //  ONLY PENDING
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No requests yet"));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {

              var data = requests[index];
              Map<String, dynamic> map =
                  data.data() as Map<String, dynamic>;

              String name = map['name'] ?? "User";
              int match = map['match'] ?? 0;

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  title: Text(name), //  NAME SHOW
                  subtitle: Text("Match: $match%"), //  MATCH SHOW

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      ///  ACCEPT
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.green),
                        onPressed: () async {

                          String fromUserId = map['from'];
                          String toUserId = map['to'];

                          //  update request
                          await FirebaseFirestore.instance
                              .collection('roommate_requests')
                              .doc(data.id)
                              .update({
                            "status": "accepted"
                          });

                          //  update current user
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(toUserId)
                              .update({
                            "roommateId": fromUserId
                          });

                          //  update other user
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(fromUserId)
                              .update({
                            "roommateId": toUserId
                          });

                          
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(fromUserId)
                              .collection('notifications')
                              .add({
                            'title': "Request Accepted! 🎉",
                            'desc': "Your roommate request was accepted. You can now chat!",
                            'timestamp': FieldValue.serverTimestamp(),
                            'isRead': false,
                            'senderId': toUserId,
                            'type': 'request_accepted'
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Roommate Connected 🎉")),
                            );
                          }
                        },
                      ),

                      ///  REJECT
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red),
                        onPressed: () async {
                          String fromUserId = map['from'];
                          
                          //  update request status
                          await FirebaseFirestore.instance
                              .collection('roommate_requests')
                              .doc(data.id)
                              .update({
                            "status": "rejected"
                          });

                          
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(fromUserId)
                              .collection('notifications')
                              .add({
                            'title': "Request Update ⚠️",
                            'desc': "Your roommate request was declined.",
                            'timestamp': FieldValue.serverTimestamp(),
                            'isRead': false,
                            'senderId': currentUserId,
                          });
                        },
                      ),
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
}
