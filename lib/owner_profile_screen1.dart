import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roommatte/auth_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final Color themeColor = const Color(0xFFFF5A5F);

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController businessController = TextEditingController();

  String nationality = "Indian";

  File? imageFile;
  String imageUrl = "";

  final user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOAD DATA =================
  Future<void> loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection("owners")
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      phoneController.text = data["phone"] ?? "";

      // ✅ FIX: business / pg / name mismatch safe handling
      businessController.text =
          data["business"] ?? data["pgName"] ?? data["businessName"] ?? "";

      nationality = data["nationality"] ?? "Indian";
      imageUrl = data["profileImage"] ?? "";
    }

    setState(() {
      isLoading = false;
    });
  }

  // ================= PICK IMAGE =================
  // ================= PICK IMAGE =================
Future<void> pickImage() async {
  final picked =
      await ImagePicker().pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  setState(() {
    imageFile = File(picked.path);
  });

  try {
    String url = await uploadToCloudinary(picked);

    imageUrl = url;

    await FirebaseFirestore.instance
        .collection("owners")
        .doc(user!.uid)
        .set({
      "profileImage": url,
    }, SetOptions(merge: true));

    setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Image Upload Failed ❌ $e")),
    );
  }
}
// ================= CLOUDINARY UPLOAD =================
Future<String> uploadToCloudinary(XFile imageFile) async {
  final url = Uri.parse(
    "https://api.cloudinary.com/v1_1/dl33js9oj/image/upload",
  );

  var request = http.MultipartRequest('POST', url);

  request.fields['upload_preset'] = 'room_upload';

  if (kIsWeb) {
    var bytes = await imageFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ),
    );
  } else {
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );
  }

  var response = await request.send();

  var responseData = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    var data = jsonDecode(responseData);

    return data["secure_url"];
  } else {
    throw Exception("Cloudinary Upload Failed");
  }
}

  // ================= UPDATE FIELD =================
  Future<void> updateField(String key, dynamic value) async {
    await FirebaseFirestore.instance
        .collection("owners")
        .doc(user!.uid)
        .set({key: value}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Owner Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // ================= PROFILE IMAGE =================
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,

                          backgroundImage: imageFile != null
    ? FileImage(imageFile!)
    : imageUrl.isNotEmpty
        ? NetworkImage(imageUrl)
        : null,

                          child: (imageFile == null && imageUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.grey)
                              : null,
                        ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 18),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    user!.displayName ?? "Owner",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  Text(user!.email ?? ""),

                  const SizedBox(height: 20),

                  // ================= PHONE =================
                  _buildEditField(
                    "Phone",
                    phoneController,
                    Icons.phone,
                    (val) => updateField("phone", val),
                  ),

                  // ================= NATIONALITY =================
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonFormField(
                      value: nationality,
                      items: const [
                        DropdownMenuItem(
                            value: "Indian", child: Text("Indian")),
                        DropdownMenuItem(
                            value: "Other", child: Text("Other")),
                      ],
                      onChanged: (val) {
                        setState(() {
                          nationality = val.toString();
                        });
                        updateField("nationality", val);
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.flag),
                        border: InputBorder.none,
                        labelText: "Nationality",
                      ),
                    ),
                  ),

                  // ================= BUSINESS =================
                  _buildEditField(
                    "Business / PG Name",
                    businessController,
                    Icons.business,
                    (val) => updateField("business", val),
                  ),

                  const SizedBox(height: 20),

                  // ================= LOGOUT =================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("LOGOUT"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ================= FIELD WIDGET =================
  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
    Function(String) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(icon),
          border: InputBorder.none,
          labelText: label,
        ),
      ),
    );
  }
}