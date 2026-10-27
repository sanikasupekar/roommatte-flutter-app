import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math'; // MATH IMPORT FOR COSINE SIMILARITY & DISTANCE LOGIC
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geolocator/geolocator.dart'; // Geolocator package standard clean call
import 'package:roommatte/RoommateRequestsScreen.dart';
import 'package:roommatte/auth_screen.dart';
import 'package:roommatte/my_bookings_screen.dart';
import 'package:roommatte/my_roommate_screen.dart';
import 'package:roommatte/roommates_screen.dart';
import 'package:roommatte/search_rooms_screen.dart';
import 'package:roommatte/smart_match_screen.dart';
import 'package:roommatte/student_account_setting_screen.dart';
import 'package:roommatte/help_support_screen.dart';
import 'package:roommatte/listing_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// --- LOGIC FUNCTIONS FOR MATCHING (FROM SEARCH SCREEN) ---
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
  return dot / (sqrt(magA) * sqrt(magB));
}

// 🗺️ DYNAMIC DISTANCE CALCULATION HELPER FUNCTION
double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
  var p = 0.017453292519943295;
  var c = cos;
  var a = 0.5 - c((endLat - startLat) * p)/2 + 
          c(startLat * p) * c(endLat * p) * (1 - c((endLng - startLng) * p))/2;
  return 12742 * asin(sqrt(a)); // Results directly in Kilometers
}

// --- REALTIME PERSONAL DETAILS PAGE ---
class PersonalDetailsPage extends StatelessWidget {
  const PersonalDetailsPage({super.key});

  Future<void> _showEditDialog(BuildContext context, String label, String fieldKey, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final user = FirebaseAuth.instance.currentUser;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Edit $label", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Enter new $label",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A5F)),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('students')
                      .doc(user?.uid)
                      .update({fieldKey: controller.text.trim()});
                  
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Personal Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No Profile Data Found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailTile(context, "Name", "name", userData['name'] ?? "N/A", Icons.person_outline, true),
                _buildDetailTile(context, "Email", "email", userData['email'] ?? "N/A", Icons.email_outlined, false),
                _buildDetailTile(context, "Gender", "gender", userData['gender'] ?? "N/A", Icons.wc, false),
                _buildDetailTile(context, "College", "college", userData['college'] ?? "N/A", Icons.school_outlined, false),
                _buildDetailTile(context, "Age", "age", "${userData['age'] ?? 'N/A'}", Icons.cake_outlined, true),
                _buildDetailTile(context, "ID Type", "idType", userData['idType'] ?? "N/A", Icons.badge_outlined, false),
                
                const SizedBox(height: 20),
                const Text("Tip: Only Name and Age are editable", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(BuildContext context, String label, String fieldKey, String value, IconData icon, bool isEditable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEditable 
              ? () => _showEditDialog(context, label, fieldKey, value.replaceAll(" Years", "")) 
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF5A5F), size: 22),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isEditable)
                  const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyRoomPage extends StatelessWidget {
  const MyRoomPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("My Room")));
}

// --- 🔥 WORKING WISHLIST SCREEN WITH CARD UI ---
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("My Wishlist", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          var studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
          List savedRoomIds = studentData['wishlist'] ?? [];

          if (savedRoomIds.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 15),
                  Text("Your Wishlist is empty!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, roomSnapshot) {
              if (!roomSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              var likedRooms = roomSnapshot.data!.docs.where((doc) => savedRoomIds.contains(doc.id)).toList();

              if (likedRooms.isEmpty) {
                return const Center(child: Text("Saved rooms are no longer available.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: likedRooms.length,
                itemBuilder: (context, index) {
                  var roomData = likedRooms[index].data() as Map<String, dynamic>;
                  String imageUrl = (roomData['imageUrls'] != null && roomData['imageUrls'].isNotEmpty)
                      ? roomData['imageUrls'][0]
                      : "https://via.placeholder.com/400";

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailsScreen(property: roomData))),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                            child: Image.network(imageUrl, width: 110, height: 100, fit: BoxFit.cover),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(roomData['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(roomData['location'] ?? "No Location", style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("₹${roomData['rent']}/mo", style: const TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold, fontSize: 14)),
                                      IconButton(
                                        icon: const Icon(Icons.favorite, color: Color(0xFFFF5A5F)),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('students').doc(uid).update({
                                            'wishlist': FieldValue.arrayRemove([likedRooms[index].id])
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

Widget buildProfileImage(String profilePic, {double size = 40}) {
  if (profilePic.isEmpty) {
    return Icon(Icons.person, size: size * 0.8, color: Colors.grey);
  }
  try {
    if (profilePic.startsWith('http')) {
      return Image.network(profilePic, fit: BoxFit.cover, width: size, height: size);
    } else {
      return Image.memory(
        base64Decode(profilePic),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: size * 0.8),
      );
    }
  } catch (e) {
    return Icon(Icons.person, size: size * 0.8);
  }
}

class NotificationService {
  static Future<void> sendNewUserJoinedNotification(String newUserName, String newUserUid) async {
    try {
      final studentsCollection = FirebaseFirestore.instance.collection('students');
      final allStudents = await studentsCollection.get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in allStudents.docs) {
        if (doc.id != newUserUid) {
          DocumentReference notifRef = studentsCollection
              .doc(doc.id)
              .collection('notifications')
              .doc(); 

          batch.set(notifRef, {
            'title': "New User Joined! 🏠",
            'desc': "$newUserName has just joined RoomHive. Check their profile!",
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'senderId': newUserUid,
            'type': 'new_user_joined'
          });
        }
      }
      
      await batch.commit();
      await studentsCollection.doc(newUserUid).update({'hasSentNotif': true});
    } catch (e) {
      debugPrint("Error sending notifications: $e");
    }
  }

  static Future<void> sendNewRoomNotification(String roomName, String location, String roomId) async {
    try {
      final studentsCollection = FirebaseFirestore.instance.collection('students');
      final allStudents = await studentsCollection.get();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in allStudents.docs) {
        DocumentReference notifRef = studentsCollection
            .doc(doc.id)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'title': "New Room Available! 🏠",
          'desc': "$roomName is now available at $location. Check it out!",
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_room_added',
          'roomId': roomId,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error sending room notifications: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RoomHive',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('students').doc(snapshot.data!.uid).get(),
            builder: (context, studentSnap) {
              if (studentSnap.connectionState == ConnectionState.done) {
                if (studentSnap.hasData && studentSnap.data!.exists) {
                  var data = studentSnap.data!.data() as Map<String, dynamic>;
                  if (data['hasSentNotif'] == null || data['hasSentNotif'] == false) {
                    NotificationService.sendNewUserJoinedNotification(
                      data['name'] ?? "A new student", 
                      snapshot.data!.uid
                    );
                  }
                  return const StudentDashboard();
                }
                return const AuthScreen(); 
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final Color themeColor = const Color(0xFFFF5A5F);
  final Timestamp? userCreatedAt; 
  const NotificationScreen({super.key, this.userCreatedAt});

  Future<void> _deleteNotification(String docId) async {
    String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (myUid.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(myUid)
          .collection('notifications')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    String myUid = FirebaseAuth.instance.currentUser?.uid ?? ""; 
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              var collection = FirebaseFirestore.instance
                  .collection('students')
                  .doc(myUid)
                  .collection('notifications');
              var snapshot = await collection.where('isRead', isEqualTo: true).get();
              for (var doc in snapshot.docs) {
                await doc.reference.delete();
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(myUid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No new notifications"));
          }
          return ListView.separated(
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
              String timeStr = date != null ? "${date.hour}:${date.minute}" : "Just now";
              
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotification(doc.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification removed")));
                },
                child: Container(
                  color: data['isRead'] == false ? themeColor.withOpacity(0.05) : Colors.transparent,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeColor,
                      child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    ),
                    title: Text(data['title'] ?? "Notification Update", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(data['desc'] ?? data['message'] ?? "New update received"),
                        const SizedBox(height: 5),
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => _deleteNotification(doc.id),
                    ),
                    onTap: () async {
                      await FirebaseFirestore.instance
                          .collection('students')
                          .doc(myUid)
                          .collection('notifications')
                          .doc(doc.id)
                          .update({'isRead': true});
                      
                      if (data['type'] == 'new_room_added' && data['roomId'] != null) {
                         var roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(data['roomId']).get();
                         if (roomDoc.exists && context.mounted) {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailsScreen(property: roomDoc.data()!)));
                         }
                      }
                    },
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

class IndividualChatScreen extends StatefulWidget {
  final String name;
  final String roommateId;
  const IndividualChatScreen({super.key, required this.name, required this.roommateId});
  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Color themeColor = const Color(0xFFFF5A5F);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId() {
    String currentUser = _auth.currentUser?.uid ?? "unknown";
    return currentUser.compareTo(widget.roommateId) > 0 
        ? "${widget.roommateId}_$currentUser" 
        : "${currentUser}_${widget.roommateId}";
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String msg = _messageController.text.trim();
    String myId = _auth.currentUser!.uid;
    _messageController.clear();
    await _firestore.collection('chats').doc(getChatId()).collection('messages').add({
      'text': msg,
      'senderId': myId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    try {
      DocumentSnapshot myDoc = await _firestore.collection('students').doc(myId).get();
      String myName = (myDoc.data() as Map<String, dynamic>)['name'] ?? "Someone";
      await _firestore.collection('students').doc(widget.roommateId).collection('notifications').add({
        'title': "New Message from $myName 💬",
        'desc': msg.length > 30 ? "${msg.substring(0, 30)}..." : msg, 
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'senderId': myId,
        'type': 'chat_message'
      });
    } catch (e) {
      debugPrint("Chat Notification Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('students').doc(widget.roommateId).snapshots(),
          builder: (context, snapshot) {
            String otherProfilePic = "";
            if (snapshot.hasData && snapshot.data!.exists) {
              otherProfilePic = (snapshot.data!.data() as Map<String, dynamic>)['profilePic'] ?? "";
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 18, 
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(child: buildProfileImage(otherProfilePic, size: 36)),
                ),
                const SizedBox(width: 10),
                Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            );
          }
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(getChatId())
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _auth.currentUser!.uid;
                    return _buildChatBubble(data['text'] ?? "", isMe);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: themeColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? themeColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }
}

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final Color themeColor = const Color(0xFFFF5A5F);
  bool _isUploading = false;

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        final Uint8List imageBytes = await pickedFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        await FirebaseFirestore.instance.collection('students').doc(uid).set({
          'profilePic': base64Image,
        }, SetOptions(merge: true));
        if (mounted) {
          setState(() { _isUploading = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Photo Updated!")));
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          setState(() { _isUploading = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        String college = "Sinhgad College";
        String profilePic = ""; 
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "User";
          college = data['college'] ?? "Sinhgad College";
          profilePic = data['profilePic'] ?? "";
        }
        return Scaffold(
          appBar: AppBar(title: const Text("My Profile"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
          body: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50, 
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(child: buildProfileImage(profilePic, size: 100)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _uploadImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: themeColor,
                          child: _isUploading 
                            ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Student | $college", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    _buildProfileTile(context, Icons.person_outline, "Personal Details", "Age, Gender, etc."),
                    _buildProfileTile(context, Icons.home_outlined, "My Room", "Not Assigned Yet"),
                    _buildProfileTile(context, Icons.settings_outlined, "Account Settings", "Privacy, Security"),
                    _buildProfileTile(context, Icons.help_outline, "Help & Support", "FAQs, Contact Us"),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red), 
                      title: const Text("Logout", style: TextStyle(color: Colors.red)), 
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      }
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, String subtitle) {
    return TypographyTileWidget(icon: icon, title: title, subtitle: subtitle);
  }
}

class TypographyTileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const TypographyTileWidget({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return TypographyTileWidgetInternal(icon: icon, title: title, subtitle: subtitle);
  }
}

class TypographyTileWidgetInternal extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const TypographyTileWidgetInternal({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF5A5F)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Widget target;
        if (title == "Personal Details") {
          target = const PersonalDetailsPage(); 
        } else if (title == "My Room") {
          target = const MyRoomPage();
        } else if (title == "Account Settings") {
          target = const AccountSettingsPage();
        } else if (title == "Help & Support") {
          target = const HelpSupportScreen();
        } else {
          target = Scaffold(appBar: AppBar(title: Text(title)));
        }
        Navigator.push(context, MaterialPageRoute(builder: (context) => target));
      },
    );
  }
}

class StudentDashboard extends StatefulWidget {
  final String? idType;
  final String? idNumber;
  const StudentDashboard({super.key, this.idType, this.idNumber});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final Color themeColor = const Color(0xFFFF5A5F);
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  double _sleepSchedule = 1; 
  double _socialActivity = 1; 
  double _cleanliness = 3;
  String _foodType = "Veg";
  RangeValues _currentRangeValues = const RangeValues(5000, 15000);
  String _selectedType = "PG";
  bool _isMapView = false;

  // REAL GPS SYNC CENTER POINT (Sinhgad Campus Default)
  double userLiveLatitude = 18.4635; 
  double userLiveLongitude = 73.8344;
  bool isLocationLoaded = false;

  final List<Marker> _osmMarkers = [
    Marker(
      point: const LatLng(18.5626, 73.9168),
      width: 80,
      height: 80,
      child: const Icon(Icons.location_on, color: Color(0xFFFF5A5F), size: 40),
    ),
    Marker(
      point: const LatLng(18.5590, 73.9032),
      width: 80,
      height: 80,
      child: const Icon(Icons.location_on, color: Color(0xFFFF5A5F), size: 40),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      if (mounted) {
        setState(() {
          userLiveLatitude = position.latitude;
          userLiveLongitude = position.longitude;
          isLocationLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error fetching core geolocator: $e");
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Advanced Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Budget Range (Monthly)", style: TextStyle(fontWeight: FontWeight.w600)),
                      Text("₹${_currentRangeValues.start.round()} - ₹${_currentRangeValues.end.round()}", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RangeSlider(
                    values: _currentRangeValues, min: 2000, max: 30000, divisions: 28, activeColor: themeColor,
                    labels: RangeLabels("₹${_currentRangeValues.start.round()}", "₹${_currentRangeValues.end.round()}"),
                    onChanged: (RangeValues values) {
                      setModalState(() => _currentRangeValues = values);
                      setState(() => _currentRangeValues = values);
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text("Accommodation Type", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: ["Hostel", "PG", "Mess"].map((type) => ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      selectedColor: themeColor.withOpacity(0.2),
                      onSelected: (bool selected) {
                        setModalState(() => _selectedType = type);
                        setState(() => _selectedType = type);
                      },
                    )).toList(), 
                  ),
                  const SizedBox(height: 35),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<DocumentSnapshot>(
      stream: uid.isEmpty ? null : FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = "User";
        String email = "User@email.com";
        String profilePic = "";
        String? idType;
        Timestamp? userCreatedAt;
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "User";
          email = data['email'] ?? "No Email";
          profilePic = data['profilePic'] ?? "";
          idType = data['idType'];
          userCreatedAt = data['createdAt'];
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text("RoomHive", style: TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .doc(uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snap) {
                  int count = snap.hasData ? snap.data!.docs.length : 0;
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => NotificationScreen(userCreatedAt: userCreatedAt))
                        ), 
                        icon: const Icon(Icons.notifications_none, color: Colors.black)
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8, top: 8,
                          child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text(count.toString(), style: const TextStyle(fontSize: 10, color: Colors.white))),
                        )
                    ],
                  );
                }
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileScreen())),
                  child: CircleAvatar(
                    radius: 18, 
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(child: buildProfileImage(profilePic, size: 36)), 
                  ),
                ),
              ),
            ],
          ),
          body: _buildBody(name, email, idType, profilePic), 
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoommatesScreen()));
              } else {
                setState(() => _currentIndex = index);
              }
            },
            selectedItemColor: themeColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: "Matches"), 
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome),label: "AI Match"),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "More"), 
            ],
          ),
        );
      }
    );
  }

  Widget _buildBody(String name, String email, String? idType, String profilePic) {
    switch (_currentIndex) {
      case 0: return _buildHomeDashboard(name, idType);
      case 1: return _buildMatchingSurvey();
      case 2: return const SmartMatchScreen();
      case 3: return _buildMoreTab(name, email, idType, profilePic); 
      default: return _buildHomeDashboard(name, idType);
    }
  }

  Widget _buildMoreTab(String name, String email, String? idType, String profilePic) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 45, 
                backgroundColor: Colors.grey[200],
                child: ClipOval(child: buildProfileImage(profilePic, size: 90)), 
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        _buildMoreTile(
          idType != null ? Icons.verified_user : Icons.gpp_maybe_outlined, 
          idType ?? "Verify Documents", 
          idType != null ? "Status: Verified ($idType)" : "Identity check pending", 
          () {
            if (idType == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Verification workflow can be updated from Profile Screen.")),
              );
            }
          },
          color: idType != null ? Colors.green : Colors.orange,
        ),
        
        _buildMoreTile(
          Icons.person_outline, 
          "Edit Profile", 
          "Change your basic account info", 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDetailsPage()));
          }
        ),
        
        _buildMoreTile(
          Icons.favorite_border, 
          "Wishlist", 
          "Your saved hostels & PGs", 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
          }
        ),
        
        _buildMoreTile(
          Icons.history,
          "My Bookings",
          "View past & active bookings",
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
          },
        ),
        
        _buildMoreTile(
          Icons.tune, 
          "Matching Preferences", 
          "Update your lifestyle preference survey data", 
          () {
            setState(() => _currentIndex = 1); 
          }
        ),
        
        _buildMoreTile(
          Icons.settings_outlined, 
          "Account Settings", 
          "Privacy and profile safety controls", 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
          }
        ),
        
        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
        
        _buildMoreTile(
          Icons.support_agent, 
          "Help & Support", 
          "FAQs, Chat Support & Contact Details", 
          () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
          }
        ),
        
        _buildMoreTile(
          Icons.info_outline, 
          "About RoomHive", 
          "Terms, Conditions & Version 1.0.0", 
          () {
            showAboutDialog(
              context: context,
              applicationName: "RoomHive",
              applicationVersion: "1.0.0",
              applicationIcon: const Icon(Icons.home, color: Color(0xFFFF5A5F)),
              children: [const Text("Find your perfect roommate & stay hassle-free.")],
            );
          }
        ),
        
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.logout, color: Colors.red),
          ),
          title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMoreTile(IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    return AppMoreTileWidget(icon: icon, title: title, subtitle: subtitle, onTap: onTap, color: color, themeColor: themeColor);
  }

  Widget _buildHomeDashboard(String name, String? idType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello, $name!", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Find your perfect roommate & stay.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {}); 
                    },
                    decoration: InputDecoration(
                      hintText: "Search PG, Hostels, Location...", 
                      prefixIcon: Icon(Icons.search, color: themeColor), 
                      border: InputBorder.none, 
                      contentPadding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(context), 
                child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.tune, color: Colors.white, size: 25)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isMapView = !_isMapView), 
            icon: Icon(_isMapView ? Icons.list : Icons.map_outlined), 
            label: Text(_isMapView ? "Switch to List View" : "Switch to Map View"), 
            style: OutlinedButton.styleFrom(foregroundColor: themeColor, side: BorderSide(color: themeColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))
          ),
          const SizedBox(height: 20),
          _isMapView 
              ? Container(
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(userLiveLatitude, userLiveLongitude), 
                        initialZoom: 14.0, 
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.roommatte',
                        ),
                        MarkerLayer(markers: [
                          ..._osmMarkers,
                          Marker(
                            point: LatLng(userLiveLatitude, userLiveLongitude),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 35), 
                          )
                        ]),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Top Matches for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    _buildTopMatchesList(),
                    const SizedBox(height: 25),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Nearby Accommodations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationList(),
                  ],
                ),
          const SizedBox(height: 25),
          const Text("Explore Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.2,
            children: [
              _buildActionCard("Search Rooms", Icons.search, Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchRoomsScreen()));
              }), 
              _buildActionCard("Roommate Requests", Icons.people_outline, Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoommateRequestsScreen()));
              }),
              _buildActionCard("My Bookings", Icons.payment, Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyBookingsScreen()));
              }), 
              _buildActionCard("My Roommate", Icons.person_pin, Colors.purple, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRoommateScreen()));
              })
            ],
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  // --- CERTIFIED REAL-TIME MATCH ALGORITHM WITH FULL PARSING NORMALIZATION ---
  Widget _buildTopMatchesList() {
    String myUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('students').doc(myUid).snapshots(),
      builder: (context, mySnap) {
        if (!mySnap.hasData || !mySnap.data!.exists) return const Center(child: CircularProgressIndicator());

        var myData = mySnap.data!.data() as Map<String, dynamic>? ?? {};
        
        // Normalize current user details parsing
        String myActualGender = (myData['gender'] ?? '').toString().trim().toLowerCase();
        var myPrefs = myData['preferences'] as Map<String, dynamic>? ?? {};
        
        String myFood = (myPrefs['foodHabit'] ?? myData['foodHabit'] ?? '').toString().trim().toLowerCase();
        String mySleep = (myPrefs['sleepSchedule'] ?? myData['sleepSchedule'] ?? '').toString().trim().toLowerCase();
        String mySocial = (myPrefs['socialNature'] ?? myData['socialNature'] ?? '').toString().trim().toLowerCase();
        int myClean = int.tryParse((myPrefs['cleanlinessLevel'] ?? myData['cleanlinessLevel'] ?? '3').toString()) ?? 3;
        String myStudy = (myPrefs['studyPreference'] ?? myData['studyPreference'] ?? '').toString().trim().toLowerCase();
        int myBudget = int.tryParse((myPrefs['budgetLevel'] ?? myData['budgetLevel'] ?? '3').toString()) ?? 3;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            List<Map<String, dynamic>> scoredStudents = [];

            for (var doc in snapshot.data!.docs) {
              if (doc.id == myUid) continue; 

              var otherData = doc.data() as Map<String, dynamic>;
              var otherPrefs = otherData['preferences'] as Map<String, dynamic>? ?? {};
              
              String otherActualGender = (otherData['gender'] ?? '').toString().trim().toLowerCase();

              // GENDER ENFORCEMENT: Male models map to Male, Female models map to Female
              if (otherActualGender != myActualGender) {
                continue; 
              }

              // Normalize target user values to prevent parsing leaks
              String otherFood = (otherPrefs['foodHabit'] ?? otherData['foodHabit'] ?? '').toString().trim().toLowerCase();
              String otherSleep = (otherPrefs['sleepSchedule'] ?? otherData['sleepSchedule'] ?? '').toString().trim().toLowerCase();
              String otherSocial = (otherPrefs['socialNature'] ?? otherData['socialNature'] ?? '').toString().trim().toLowerCase();
              int otherClean = int.tryParse((otherPrefs['cleanlinessLevel'] ?? otherData['cleanlinessLevel'] ?? '3').toString()) ?? 3;
              String otherStudy = (otherPrefs['studyPreference'] ?? otherData['studyPreference'] ?? '').toString().trim().toLowerCase();
              int otherBudget = int.tryParse((otherPrefs['budgetLevel'] ?? otherData['budgetLevel'] ?? '3').toString()) ?? 3;

              // roommates_screen math logic tracking
              int totalAttributes = 7;
              int matchedCount = 0;

              if (myActualGender == otherActualGender) matchedCount++;
              if (myFood == otherFood && myFood.isNotEmpty) matchedCount++;
              if (mySleep == otherSleep && mySleep.isNotEmpty) matchedCount++;
              if (myClean == otherClean) matchedCount++;
              if (myStudy == otherStudy && myStudy.isNotEmpty) matchedCount++;
              if (myBudget == otherBudget) matchedCount++;
              if (mySocial == otherSocial && mySocial.isNotEmpty) matchedCount++;

              // SCALE SCALE FORMULA:
              // Sagle attributes perfect match zale tar -> 100%
              // Fakt 1 parameter missed zala tar -> Direct strict scale assignment 90%
              int matchPercent;
              if (matchedCount == totalAttributes) {
                matchPercent = 100;
              } else if (matchedCount == (totalAttributes - 1)) {
                matchPercent = 90;
              } else {
                matchPercent = ((matchedCount / totalAttributes) * 100).toInt();
              }

              scoredStudents.add({
                "data": otherData,
                "score": matchPercent,
                "userId": doc.id,
              });
            }

            // Descending order sorting (Highest matching profiles on top index swap)
            scoredStudents.sort((a, b) => b['score'].compareTo(a['score']));
            var top3 = scoredStudents.take(3).toList();

            if (top3.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Text("No compatible roommates found for your preferences yet.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              );
            }

            return SizedBox(
              height: 165,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: top3.length,
                itemBuilder: (context, index) {
                  var student = top3[index]['data'];
                  int matchScore = top3[index]['score'];
                  String targetUserId = top3[index]['userId'];
                  String otherProfilePic = student['profilePic'] ?? "";

                  return GestureDetector(
                    onTap: () {
                      var currentOtherPrefs = student['preferences'] as Map<String, dynamic>? ?? {};

                      String sleep = (student['sleepSchedule'] ?? currentOtherPrefs['sleepSchedule'] ?? student['sleep'] ?? currentOtherPrefs['sleep'] ?? '-').toString();
                      String food = (student['foodHabit'] ?? currentOtherPrefs['foodHabit'] ?? student['food'] ?? currentOtherPrefs['food'] ?? '-').toString();
                      String cleanliness = (student['cleanlinessLevel'] ?? currentOtherPrefs['cleanlinessLevel'] ?? student['cleanliness'] ?? currentOtherPrefs['cleanliness'] ?? '-').toString();
                      String social = (student['socialNature'] ?? currentOtherPrefs['socialNature'] ?? student['social'] ?? currentOtherPrefs['social'] ?? '-').toString();
                      String study = (student['studyPreference'] ?? currentOtherPrefs['studyPreference'] ?? student['study'] ?? currentOtherPrefs['study'] ?? '-').toString();
                      String budget = (student['budgetLevel'] ?? currentOtherPrefs['budgetLevel'] ?? student['budget'] ?? currentOtherPrefs['budget'] ?? '-').toString();

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          title: Text(
                            student['name'] ?? "No Name",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Gender: ${student['gender'] ?? currentOtherPrefs['gender'] ?? '-'}"),
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
                                "Match: $matchScore%",
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
                                  "from": myUid,
                                  "to": targetUserId,
                                  "name": myData['name'] ?? "",
                                  "match": matchScore,
                                  "status": "pending",
                                  "createdAt": FieldValue.serverTimestamp(),
                                });

                                await FirebaseFirestore.instance
                                    .collection('students')
                                    .doc(targetUserId)
                                    .collection('notifications')
                                    .add({
                                  'title': "New Roommate Request! 🤝",
                                  'desc': "${myData['name']} has sent you a roommate request.",
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'isRead': false,
                                  'senderId': myUid,
                                  'type': 'request_received'
                                });

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Roommate request sent ✅")),
                                  );
                                }
                              },
                              child: const Text("Request", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(15), 
                        border: Border.all(color: Colors.grey[200]!)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30, 
                            backgroundColor: Colors.grey[100],
                            child: ClipOval(child: buildProfileImage(otherProfilePic, size: 60)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            student['name'] ?? "User", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$matchScore% Match", 
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // UPDATED REAL-TIME STORAGE AND FRESH REDIRECT VIA EMBEDDED PREFERENCES TRIGGER 
  Widget _buildMatchingSurvey() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Roommate Smart Matching", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Help us find your perfect match based on lifestyle.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          const Text("Sleeping Schedule", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _sleepSchedule, min: 1, max: 2, divisions: 1, activeColor: themeColor, onChanged: (v) => setState(() => _sleepSchedule = v)),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Early Bird"), Text("Night Owl")]),
          const SizedBox(height: 25),
          const Text("Social Activity", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _socialActivity, min: 1, max: 2, divisions: 1, activeColor: themeColor, onChanged: (v) => setState(() => _socialActivity = v)),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Introvert"), Text("Extrovert")]),
          const SizedBox(height: 25),
          const Text("Cleanliness Level", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _cleanliness, min: 1, max: 5, divisions: 4, activeColor: themeColor, label: _cleanliness.round().toString(), onChanged: (v) => setState(() => _cleanliness = v)),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Casual"), Text("Very Strict")]),
          const SizedBox(height: 25),
          const Text("Food Preference", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ["Veg", "Non-Veg", "Eggetarian"].map((food) => ChoiceChip(
              label: Text(food), selected: _foodType == food, selectedColor: themeColor.withOpacity(0.2),
              onSelected: (val) => setState(() => _foodType = food),
            )).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                if (uid.isEmpty) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Updating preferences & refreshing best matches...")),
                );

                // Convert matching sliders to exact string attributes standard alignment mapping rules
                String sleepText = _sleepSchedule == 1 ? "Early" : "Night";
                String socialText = _socialActivity == 1 ? "Introvert" : "Extrovert";

                try {
                  // Firestore local nested collection updates instantly
                  await FirebaseFirestore.instance.collection('students').doc(uid).set({
                    'preferences': {
                      'sleepSchedule': sleepText,
                      'socialNature': socialText,
                      'cleanlinessLevel': _cleanliness.round(),
                      'foodHabit': _foodType,
                    }
                  }, SetOptions(merge: true));

                  if (mounted) {
                    setState(() {
                      _currentIndex = 0; // Seamless refresh bounce directly to home screen
                    });
                  }
                } catch (e) {
                  debugPrint("Error writing preferences document snapshot: $e");
                }
              }, 
              child: const Text("FIND MATCHES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]), 
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center,)])
      ),
    );
  }

  Widget _buildRecommendationList() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String searchQuery = _searchController.text.trim().toLowerCase();

    return StreamBuilder<Position>(
      stream: Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, 
        ),
      ),
      builder: (context, geoSnapshot) {
        double currentLat = geoSnapshot.hasData ? geoSnapshot.data!.latitude : userLiveLatitude;
        double currentLng = geoSnapshot.hasData ? geoSnapshot.data!.longitude : userLiveLongitude;

        return StreamBuilder<DocumentSnapshot>(
          stream: uid.isEmpty ? null : FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            Map<String, dynamic>? userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            List savedWishlist = userData != null ? (userData['wishlist'] ?? []) : [];
            
            final Map<String, dynamic> myPrefs = userData != null
                ? Map<String, dynamic>.from(userData['preferences'] as Map<dynamic, dynamic>? ?? {})
                : <String, dynamic>{};
            List<double> userVector = encodePrefs(myPrefs);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<Map<String, dynamic>> roomList = [];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String roomId = doc.id;
                  
                  if (searchQuery.isNotEmpty) {
                    String roomLocation = (data['location'] ?? "").toString().toLowerCase();
                    String roomName = (data['name'] ?? "").toString().toLowerCase();
                    if (!roomLocation.contains(searchQuery) && !roomName.contains(searchQuery)) {
                      continue;
                    }
                  }

                  double roomLat = 18.5204;
                  double roomLng = 73.8567;

                  if (data.containsKey('latitude') && data['latitude'] != null) {
                    roomLat = (data['latitude'] as num).toDouble();
                  }
                  if (data.containsKey('longitude') && data['longitude'] != null) {
                    roomLng = (data['longitude'] as num).toDouble();
                  }

                  double distanceInKm = calculateDistance(currentLat, currentLng, roomLat, roomLng);

                  if (searchQuery.isEmpty && distanceInKm > 5.0) {
                    continue; 
                  }

                  if (data['preferences'] == null) continue;

                  List<double> roomVector = encodePrefs(data['preferences']);
                  double score = cosineSimilarity(userVector, roomVector);
                  int matchPercent = (score * 100).toInt();

                  roomList.add({
                    "id": roomId,
                    "data": data,
                    "match": matchPercent,
                    "distance": distanceInKm.toStringAsFixed(1), 
                  });
                }

                roomList.sort((a, b) => b['match'].compareTo(a['match']));
                final displayRooms = searchQuery.isEmpty ? roomList.take(3).toList() : roomList;

                if (displayRooms.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No Rooms found within 5km from your location 🔔", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                    ),
                  );
                }

                return SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, 
                    itemCount: displayRooms.length,
                    itemBuilder: (context, index) {
                      final String rId = displayRooms[index]["id"];
                      final itemData = displayRooms[index]["data"];
                      final match = displayRooms[index]["match"];
                      final distance = displayRooms[index]["distance"]; 
                      
                      bool isLiked = savedWishlist.contains(rId);
                      
                      String imageUrl = (itemData['imageUrls'] != null && itemData['imageUrls'].isNotEmpty) 
                          ? itemData['imageUrls'][0] 
                          : "https://via.placeholder.com/400";

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ListingDetailsScreen(property: itemData))),
                        child: Container(
                          width: 250, 
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(15), 
                            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15), 
                              gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (isLiked) {
                                        await FirebaseFirestore.instance.collection('students').doc(uid).update({
                                          'wishlist': FieldValue.arrayRemove([rId])
                                        });
                                      } else {
                                        await FirebaseFirestore.instance.collection('students').doc(uid).update({
                                          'wishlist': FieldValue.arrayUnion([rId])
                                        });
                                      }
                                    },
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white.withOpacity(0.9),
                                      child: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: const Color(0xFFFF5A5F),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end, 
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(itemData['name'] ?? "No Name", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text("₹${itemData['rent'] ?? 'N/A'}/month", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5)),
                                          child: Text("$match% Match", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFFF5A5F), borderRadius: BorderRadius.circular(5)),
                                          child: Text("$distance km away", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}

class AppMoreTileWidget extends StatelessWidget {
  const AppMoreTileWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    required this.themeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(color: (color ?? themeColor).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
        child: Icon(icon, color: color ?? themeColor)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}