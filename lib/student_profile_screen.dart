import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileSetup extends StatefulWidget {
  const StudentProfileSetup({super.key});

  @override
  State<StudentProfileSetup> createState() => _StudentProfileSetupState();
}

class _StudentProfileSetupState extends State<StudentProfileSetup> {
  final Color themeColor = const Color(0xFFFF5A5F);
  final _formKey = GlobalKey<FormState>(); 
  int _currentStep = 0;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();

  // ID Proof Types
  String _selectedIdType = 'Aadhaar Card';
  final List<String> _idTypes = [
    'Aadhaar Card',
    'PAN Card',
    'College ID',
    'Voter ID'
  ];

  bool _isUploading = false;

  // Lifestyle Attributes
  String? gender; 
  String foodType = "Veg"; 
  double sleepSchedule = 1;
  double cleanliness = 3;
  RangeValues budget = const RangeValues(7000, 15000);
  bool smokingDrinking = false;
  double socialActivity = 1; 
  String studyPreference = "Solo"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile Setup",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isUploading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
        key: _formKey, 
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_formKey.currentState!.validate()) {
                setState(() => _currentStep++);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all mandatory basic fields *")),
                );
              }
            } else if (_currentStep == 1) {
              if (gender == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select your Gender *")),
                );
              } else {
                _submitProfile();
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: details.onStepContinue,
                  child: Text(
                    _currentStep == 1 ? "FINISH & SAVE" : "CONTINUE",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
          steps: [
            // STEP 1: BASIC DETAILS
            Step(
              isActive: _currentStep >= 0,
              title: const Text("Basic"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Full Name *", _nameController, Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildTextField("Age *", _ageController, Icons.calendar_today, keyboard: TextInputType.number),
                  const SizedBox(height: 15),
                  _buildTextField("College / Company *", _collegeController, Icons.school_outlined),
                  const SizedBox(height: 20),
                  const Text("Identity Verification *",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedIdType,
                        isExpanded: true,
                        items: _idTypes.map((String type) {
                          return DropdownMenuItem<String>(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIdType = value!;
                            _idNumberController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildIdField(),
                ],
              ),
            ),

            // STEP 2: LIFESTYLE
            Step(
              isActive: _currentStep >= 1,
              title: const Text("Lifestyle"),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Roommate Preferences",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  _buildLabel("Gender *"),
                  _buildChips(["Male", "Female"], gender, (val) => setState(() => gender = val)),
                  _buildLabel("Food Preference *"), 
                  _buildChips(["Veg", "Non-Veg", "Eggetarian"], foodType, (val) => setState(() => foodType = val!)),
                  _buildLabel("Sleeping Schedule"),
                  _buildSlider(sleepSchedule, 1, 2, (v) => setState(() => sleepSchedule = v)),
                  _buildLabel("Cleanliness Level"),
                  _buildSlider(cleanliness, 1, 5, (v) => setState(() => cleanliness = v)),
                  _buildLabel("Social Nature"),
                  _buildChips(["Introvert", "Extrovert"], socialActivity == 1 ? "Introvert" : "Extrovert", (val) {
                    setState(() => socialActivity = val == "Introvert" ? 1 : 2);
                  }),
                  _buildLabel("Study Preference"),
                  _buildChips(["Solo", "Group"], studyPreference, (val) => setState(() => studyPreference = val!)),
                  _buildLabel("Budget Range"),
                  RangeSlider(
                    values: budget,
                    min: 2000,
                    max: 30000,
                    divisions: 28,
                    activeColor: themeColor,
                    labels: RangeLabels("₹${budget.start.round()}", "₹${budget.end.round()}"),
                    onChanged: (val) => setState(() => budget = val),
                  ),
                  SwitchListTile(
                    title: const Text("Smoking / Drinking"),
                    value: smokingDrinking,
                    activeColor: themeColor,
                    onChanged: (val) => setState(() => smokingDrinking = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIRESTORE SAVE LOGIC
  Future<void> _submitProfile() async {
    setState(() => _isUploading = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String userEmail = FirebaseAuth.instance.currentUser!.email ?? "";

      // Realtime data saving in 'students' collection
      await FirebaseFirestore.instance.collection('students').doc(userId).set({
        "userId": userId,
        "email": userEmail,
        "name": _nameController.text.trim(),
        "age": _ageController.text.trim(),
        "college": _collegeController.text.trim(),
        "idType": _selectedIdType,
        "idNumber": _idNumberController.text.trim(),

        // ML & Profile DATA
        "gender": gender,
        "foodHabit": foodType,
        "sleepSchedule": sleepSchedule == 1 ? "Early" : "Late",
        "cleanlinessLevel": cleanliness.round(),
        "studyPreference": studyPreference,
        "budgetLevel": ((budget.start + budget.end) / 2 ~/ 5000).clamp(1, 5),
        "socialNature": socialActivity == 1 ? "Introvert" : "Extrovert",
        "smokingDrinking": smokingDrinking,

        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved ✅")),
        );
        // Direct navigation to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentDashboard()),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error saving profile ❌")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI Helpers ---

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: (value) => (value == null || value.trim().isEmpty) ? "This field is mandatory" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIdField() {
    return TextFormField(
      controller: _idNumberController,
      keyboardType: _selectedIdType == 'Aadhaar Card' ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (value == null || value.isEmpty) return "ID Number is required";
        if (_selectedIdType == 'Aadhaar Card' && value.length != 12) return "Aadhaar must be 12 digits";
        return null;
      },
      decoration: InputDecoration(
        labelText: "Enter $_selectedIdType Number *",
        prefixIcon: Icon(Icons.verified_user_outlined, color: themeColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 15, bottom: 5),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _buildChips(List<String> opts, String? selected, Function(String?) onSelect) {
    return Wrap(
      spacing: 10,
      children: opts.map((o) {
        return ChoiceChip(
          label: Text(o),
          selected: selected == o,
          selectedColor: themeColor.withOpacity(0.2),
          onSelected: (s) => onSelect(o),
        );
      }).toList(),
    );
  }

  Widget _buildSlider(double val, double min, double max, Function(double) onChange) {
    return Slider(
      value: val,
      min: min,
      max: max,
      divisions: (max - min).toInt(),
      activeColor: themeColor,
      onChanged: onChange,
    );
  }
}