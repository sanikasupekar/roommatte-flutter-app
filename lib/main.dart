import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:roommatte/splash_screen.dart';

import 'onboarding_screen.dart' show OnboardingScreen;
import 'student_dashboard.dart'; 
import 'owner_dashboard.dart';      
import 'role_selection_screen.dart'; 
import 'firebase_options.dart';

// --- NOTIFICATION SERVICE (New User Joined Logic) ---
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
            'title': "New Student Joined! 🏠",
            'desc': "$newUserName has just joined RoomHive. Check their profile for matching!",
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'senderId': newUserUid,
          });
        }
      }
      
      await batch.commit();
      await studentsCollection.doc(newUserUid).update({'hasSentNotif': true});
      debugPrint("Welcome notifications sent successfully.");
    } catch (e) {
      debugPrint("Error sending welcome notifications: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(const RoomHiveApp());
}

class RoomHiveApp extends StatelessWidget {
  const RoomHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomHive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // --- TULA HAVI TASHI ORIGINAL BRIGHT UI PERAT SET KELI ---
        primaryColor: const Color(0xFFFF5A5F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5A5F)),
        inputDecorationTheme: InputDecorationTheme(
          floatingLabelStyle: const TextStyle(color: Color(0xFFFF5A5F)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 2),
          ),
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const OnboardingScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? "";

          if (role == "student") {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('students').doc(user.uid).get(),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
                  var studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
                  
                  // WELCOME NOTIFICATION LOGIC
                  if (studentData['hasSentNotif'] == null || studentData['hasSentNotif'] == false) {
                    NotificationService.sendNewUserJoinedNotification(
                      studentData['name'] ?? "A New Student", 
                      user.uid
                    );
                  }

                  return const StudentDashboard();
                } else {
                  return const RoleSelectionScreen();
                }
              },
            );
          } else if (role == "owner") {
            return const OwnerDashboard();
          }
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
