import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key});

  // --- Firebase Data Update Function ---
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
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A5F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
        centerTitle: true,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Displaying tiles: Only Name and Age pass 'true' for editability
                _buildInfoCard(context, "Name", "name", userData['name'] ?? "N/A", Icons.person_outline, true),
                _buildInfoCard(context, "Email", "email", userData['email'] ?? "N/A", Icons.email_outlined, false),
                _buildInfoCard(context, "Gender", "gender", userData['gender'] ?? "N/A", Icons.wc, false),
                _buildInfoCard(context, "College", "college", userData['college'] ?? "N/A", Icons.school_outlined, false),
                _buildInfoCard(context, "Age", "age", "${userData['age'] ?? 'N/A'} Years", Icons.cake_outlined, true),
                _buildInfoCard(context, "ID Type", "idType", userData['idType'] ?? "N/A", Icons.badge_outlined, false),
                _buildInfoCard(context, "Food Preference", "foodHabit", userData['foodHabit'] ?? "N/A", Icons.restaurant, false),
                
                const SizedBox(height: 20),
                const Text("Tip: Only Name and Age are editable", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String fieldKey, String value, IconData icon, bool isEditable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Material( // Added Material to handle ink effect better
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // Strict check: if not editable, onTap is null (disables click effect)
          onTap: isEditable 
              ? () => _showEditDialog(context, title, fieldKey, value.replaceAll(" Years", "")) 
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF5A5F), size: 24),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Show edit icon ONLY if the field is editable
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
