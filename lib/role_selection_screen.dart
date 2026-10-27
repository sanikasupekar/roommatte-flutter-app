import 'package:flutter/material.dart';
import 'package:roommatte/owner_profile_screen.dart';
import 'package:roommatte/student_profile_screen.dart';

// 🔥 Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole; // "Student" or "Owner"
  final Color themeColor = const Color(0xFFFF5A5F);
  bool isLoading = false;

  // 🔥 UPDATED FUNCTION
  Future<void> _onContinue() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a role to continue!"),
          backgroundColor: themeColor,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      String userId = FirebaseAuth.instance.currentUser!.uid;

      // 🔥 SAVE ROLE IN FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        "role": selectedRole!.toLowerCase(), // student / owner
      }, SetOptions(merge: true));

      // 🔥 NAVIGATION
      if (selectedRole == "Student") {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const StudentProfileSetup()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const OwnerProfileSetup()),
        );
      }
    } catch (e) {
      print("Error saving role: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong ❌")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  const Text(
                    "Who are you?",
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Select your role to give you a personalized experience.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 50),

                  // STUDENT
                  _buildRoleCard(
                    role: "Student",
                    description:
                        "Looking for accommodation and roommates.",
                    icon: Icons.school_rounded,
                    isSelected: selectedRole == "Student",
                    onTap: () => setState(() => selectedRole = "Student"),
                  ),

                  const SizedBox(height: 20),

                  // OWNER
                  _buildRoleCard(
                    role: "Owner",
                    description:
                        "Listing a property or mess service.",
                    icon: Icons.real_estate_agent_rounded,
                    isSelected: selectedRole == "Owner",
                    onTap: () => setState(() => selectedRole = "Owner"),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: isLoading ? null : _onContinue,
                      child: const Text(
                        "CONTINUE",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // 🔥 LOADING
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : themeColor,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? themeColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: themeColor),
          ],
        ),
      ),
    );
  }
}
