import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// 🔥 Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddListingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;
  final String? docId; // 🔥 ADD

  const AddListingScreen({super.key, this.existingData, this.docId});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController bedsController = TextEditingController();

  String roomType = "Single";
  List<String> accessories = [];

  final List<String> accessoryOptions = [
    "WiFi",
    "AC",
    "Parking",
    "Laundry",
    "Food",
  ];

  // preferences
  String? prefGender;
  String? prefFood;
  String? prefSleep;
  double cleanlinessLevel = 3;
  String? studyPref;
  double budgetLevel = 3;
  String? socialNature;

  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) {
      final data = widget.existingData!;

      nameController.text = data["name"] ?? "";
      descController.text = data["description"] ?? "";
      rentController.text = data["rent"]?.toString() ?? "";
      depositController.text = data["deposit"]?.toString() ?? "";
      locationController.text = data["location"] ?? "";
      bedsController.text = data["beds"]?.toString() ?? "";

      roomType = data["roomType"] ?? "Single";
      accessories = List<String>.from(data["accessories"] ?? []);

      final prefs = data["preferences"] ?? {};

      prefGender = prefs["gender"];
      prefFood = prefs["foodHabit"];
      prefSleep = prefs["sleepSchedule"];
      studyPref = prefs["studyPreference"];
      socialNature = prefs["socialNature"];

      cleanlinessLevel = (prefs["cleanlinessLevel"] ?? 3).toDouble();
      budgetLevel = (prefs["budgetLevel"] ?? 3).toDouble();
    }
  }

  Future<void> pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage(imageQuality: 80);

    if (images != null) {
      setState(() => selectedImages = images);
    }
  }

  Future<void> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => selectedImages.add(image));
    }
  }

  // --- NEW ROOM NOTIFICATION HELPER FUNCTION ---
  Future<void> notifyAllStudentsAboutNewRoom(String roomName, String location, String roomId) async {
    final studentsRef = FirebaseFirestore.instance.collection('students');
    final allStudents = await studentsRef.get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in allStudents.docs) {
      DocumentReference notifRef = studentsRef
          .doc(doc.id)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'title': 'New Room Available! 🏠',
        'desc': '$roomName is now available at $location.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'new_room',
        'roomId': roomId,
      });
    }
    await batch.commit();
  }

  // 🔥 HIGH-PERFORMANCE GEOCALCULATION API:
  Future<Map<String, double>> _getCoordinatesFromAddress(String address) async {
    try {
      
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1");

      final response = await http.get(url, headers: {
        'User-Agent': 'RoomHive_Flutter_App' 
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);
          return {"latitude": lat, "longitude": lon};
        }
      }
    } catch (e) {
      debugPrint("OSM Geocoding Error: $e");
    }
    
    return {"latitude": 18.4635, "longitude": 73.8344};
  }

  Future<void> saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedImages.isEmpty && widget.existingData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Photos mandatory आहेत ❌")));
      return;
    }

    if (prefGender == null ||
        prefFood == null ||
        prefSleep == null ||
        studyPref == null ||
        socialNature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Roommate preferences mandatory आहेत ❌")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      String ownerId = FirebaseAuth.instance.currentUser!.uid;

      List<String> imageUrls = [];

      if (widget.existingData != null) {
        imageUrls = List<String>.from(widget.existingData!["imageUrls"] ?? []);
      }

      for (var img in selectedImages) {
        String url = await uploadToCloudinary(img);
        imageUrls.add(url);
      }

      Map<String, dynamic> prefs = {
        "gender": prefGender,
        "foodHabit": prefFood,
        "sleepSchedule": prefSleep,
        "cleanlinessLevel": cleanlinessLevel,
        "studyPreference": studyPref,
        "budgetLevel": budgetLevel,
        "socialNature": socialNature,
      };

      // 🔥 REAL-TIME DYNAMIC GEO-EXTRACTION
      
      String addressInput = locationController.text.trim();
      Map<String, double> coords = await _getCoordinatesFromAddress(addressInput);
      
      double targetLatitude = coords["latitude"]!;
      double targetLongitude = coords["longitude"]!;

      if (widget.docId != null && widget.docId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.docId)
            .update({
              "name": nameController.text,
              "description": descController.text,
              "roomType": roomType,
              "accessories": accessories,
              "rent": int.parse(rentController.text),
              "deposit": int.parse(depositController.text),
              "location": locationController.text,
              "latitude": targetLatitude,  // 🔥 Saved as Dynamic Double parsed type
              "longitude": targetLongitude, // 🔥 Saved as Dynamic Double parsed type
              "beds": int.parse(bedsController.text),
             
              "preferences": prefs,
              "imageUrls": imageUrls,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Listing Updated ✅")));
      } else {
        var roomRef = FirebaseFirestore.instance.collection('rooms').doc();

        await roomRef.set({
          "roomId": roomRef.id,
          "ownerId": ownerId,
          "name": nameController.text,
          "description": descController.text,
          "roomType": roomType,
          "accessories": accessories,
          "rent": int.parse(rentController.text),
          "deposit": int.parse(depositController.text),
          "location": locationController.text,
          "latitude": targetLatitude,  // 🔥 Saved as Dynamic Double parsed type
          "longitude": targetLongitude, // 🔥 Saved as Dynamic Double parsed type
          "beds": int.parse(bedsController.text),
          "availableSpots": int.parse(bedsController.text),
          "preferences": prefs,
          "imageUrls": imageUrls,
          "timestamp": FieldValue.serverTimestamp(),
        });

        await notifyAllStudentsAboutNewRoom(
          nameController.text, 
          locationController.text, 
          roomRef.id
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Room Added ✅")));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload Failed ❌ $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅🔥 FIXED CLOUDINARY FUNCTION ONLY
  Future<String> uploadToCloudinary(XFile imageFile) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/dl33js9oj/image/upload",
      );

      var request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = 'room_upload';

      if (kIsWeb) {
        var bytes = await imageFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var data = jsonDecode(responseData);

        if (data['secure_url'] == null) {
          throw Exception("Cloudinary URL missing");
        }

        return data['secure_url'];
      } else {
        print("Cloudinary Error: $responseData");
        throw Exception("Upload failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Upload Exception: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null ? "Edit Listing" : "Add Listing",
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Apartment Name *",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Description *",
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  DropdownButtonFormField(
                    value: roomType,
                    items: ["Single", "Double", "Sharing"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => roomType = value!),
                    decoration: const InputDecoration(labelText: "Room Type *"),
                  ),
                  TextFormField(
                    controller: rentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Rent *"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Deposit *"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "Location *",
                      hintText: "E.g. Narhe, Pune" 
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: bedsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Beds *"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  const Text("Roommate Preferences *"),
                  DropdownButtonFormField(
                    hint: const Text("Gender *"),
                    value: prefGender,
                    items: ["Male", "Female"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => prefGender = val),
                  ),
                  DropdownButtonFormField(
                    hint: const Text("Food Habit *"),
                    value: prefFood,
                    items: ["Veg", "Non-Veg"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => prefFood = val),
                  ),
                  DropdownButtonFormField(
                    hint: const Text("Sleep Schedule *"),
                    value: prefSleep,
                    items: ["Early", "Late"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => prefSleep = val),
                  ),
                  DropdownButtonFormField(
                    hint: const Text("Study Preference *"),
                    value: studyPref,
                    items: ["Group", "Solo"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => studyPref = val),
                  ),
                  DropdownButtonFormField(
                    hint: const Text("Social Nature *"),
                    value: socialNature,
                    items: ["Extrovert", "Introvert"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => socialNature = val),
                  ),
                  const SizedBox(height: 20),
                  const Text("Photos *"),
                  ElevatedButton(
                    onPressed: pickImages,
                    child: const Text("Add Photos"),
                  ),
                  const SizedBox(height: 10),
                  selectedImages.isEmpty
                      ? const Text("Photos required ❌")
                      : const Text("Images selected ✅"),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveRoom,
                      child: const Text("Submit Listing"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}