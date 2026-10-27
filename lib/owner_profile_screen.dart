import 'package:flutter/material.dart';
import 'package:roommatte/owner_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerProfileSetup extends StatefulWidget {
  const OwnerProfileSetup({super.key});

  @override
  State<OwnerProfileSetup> createState() => _OwnerProfileSetupState();
}

class _OwnerProfileSetupState extends State<OwnerProfileSetup> {
  final Color themeColor = const Color(0xFFFF5A5F);
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  String? selectedIdType;

  Future<void> _saveOwnerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    // 🔥 SAFE USER CHECK
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in ❌")),
      );
      return;
    }

    // 🔥 FIX: prevent null type error
    if (selectedIdType == null || selectedIdType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Identity Proof ❌")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(user.uid)
          .set({
        "ownerId": user.uid,
        "name": _nameController.text.trim(),
        "businessName": _businessNameController.text.trim(),
        "phone": _phoneController.text.trim(),

        // 🔥 SAFE NON-NULL VALUES
        "idType": selectedIdType!,
        "idNumber": _idController.text.trim(),

        "email": user.email ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Owner Profile Saved ✅")),
      );

      // 🔥 SAFE NAVIGATION (avoid crash)
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OwnerDashboard(),
          ),
        );
      });

    } catch (e) {
      print("🔥 FIRESTORE ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildTextField(
                    label: "Full Name *",
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hint: "Enter your name",
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    label: "Business / PG Name *",
                    controller: _businessNameController,
                    icon: Icons.business_outlined,
                    hint: "e.g. Green Valley PG",
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    label: "Contact Number *",
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: "10-digit mobile number",
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }
                      if (value.length != 10) {
                        return "Must be 10 digits";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: selectedIdType,
                    decoration: InputDecoration(
                      labelText: "Identity Proof *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Aadhaar",
                          child: Text("Aadhaar Card")),
                      DropdownMenuItem(
                          value: "PAN",
                          child: Text("PAN Card")),
                      DropdownMenuItem(
                          value: "Voter",
                          child: Text("Voter ID")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedIdType = value;
                        _idController.clear();
                      });
                    },
                    validator: (value) =>
                        value == null ? "Select ID type" : null,
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "ID Number *",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }

                      if (selectedIdType == "Aadhaar" &&
                          value.length != 12) {
                        return "Aadhaar must be 12 digits";
                      }

                      if ((selectedIdType == "PAN" ||
                              selectedIdType == "Voter") &&
                          value.length != 10) {
                        return "Must be 10 digits";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: isLoading ? null : _saveOwnerProfile,
                      child: const Text(
                        "SAVE & CONTINUE",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator ??
              (value) =>
                  value == null || value.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: themeColor),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}