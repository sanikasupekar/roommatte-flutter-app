import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart'; 
import 'student_dashboard.dart'; 
import 'owner_dashboard.dart'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _obscurePassword = true;

  static const themeColor = Color(0xFFFF5A5F);

  // --- SIGNUP NOTIFICATION HELPER FUNCTION ---
  Future<void> notifyOldUsersAboutNewStudent(String newStudentName, String newStudentId) async {
    final studentsRef = FirebaseFirestore.instance.collection('students');
    final allStudents = await studentsRef.get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in allStudents.docs) {
      if (doc.id != newStudentId) {
        DocumentReference notifRef = studentsRef
            .doc(doc.id)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'title': 'New Student Joined! 🏠',
          'desc': '$newStudentName just joined RoomHive.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_user',
        });
      }
    }
    await batch.commit();
  }

  // --- SUBMIT AUTH (Login & Signup Logic) ---
  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // --- LOGIN LOGIC ---
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (mounted) {
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            String role = userData['role'] ?? "";

            if (role == "student") {
              DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();
              if (studentDoc.exists) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboard()));
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
              }
            } else if (role == "owner") {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboard()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
            }
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
          }
        }

        _showSnackBar("Login Successful!", Colors.green);

      } else {
        // --- SIGNUP LOGIC ---
      
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String userId = userCredential.user!.uid;
        String newUserName = _nameController.text.trim();

        
        try {
          
          await FirebaseFirestore.instance.collection('users').doc(userId).set({
            "userId": userId,
            "name": newUserName,
            "email": _emailController.text.trim(),
            "createdAt": DateTime.now(),
            "role": "", 
          });

          
          await notifyOldUsersAboutNewStudent(newUserName, userId);

        } catch (databaseError) {
          
          print("Firestore Operations Safe-Caught Error: $databaseError");
        }
        
        _showSnackBar("Account Created Successfully!", Colors.green);

        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Error";
      if (e.code == 'user-not-found') message = "User not found";
      if (e.code == 'wrong-password') message = "Wrong password";
      if (e.code == 'email-already-in-use') message = "Email already exists";
      if (e.code == 'weak-password') message = "Weak password";
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar("Something went wrong", Colors.red);
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: themeColor),
              ),
            
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    const Center(
                      child: Icon(Icons.home_work_rounded, size: 80, color: themeColor),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isLogin ? "Welcome Back!" : "Create Account",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),

                    Text(
                      isLogin
                          ? "Sign in to continue RoomHive"
                          : "Fill the details to get started",
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    const SizedBox(height: 40),

                    if (!isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Full Name"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter name" : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Email Address"),
                      validator: (v) =>
                          v == null || !v.contains("@") ? "Enter valid email" : null,
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? "Min 6 characters" : null,
                    ),

                    if (isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
  
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _submitAuth,
                        child: Text(isLogin ? "LOGIN" : "SIGN UP"),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(
                          isLogin
                              ? "Don't have an account? Sign Up"
                              : "Already have an account? Login",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}