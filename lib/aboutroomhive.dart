import 'package:flutter/material.dart';

class AboutRoomHiveScreen extends StatelessWidget {
  const AboutRoomHiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "About RoomHive",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 App Title Section
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.home_work_rounded,
                    size: 80,
                    color: Color(0xFFFF5A5F),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "RoomHive",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Smart PG & Room Management App",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 Description
            const Text(
              "About App",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "RoomHive is a complete property management platform for owners. "
              "It helps you manage PGs, rooms, tenants, bookings, and availability "
              "from one simple dashboard.",
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),

            const SizedBox(height: 20),

            // 🔥 Features
            const Text(
              "Key Features",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildFeature("Add & manage room listings"),
            _buildFeature("Real-time booking requests"),
            _buildFeature("Owner dashboard analytics"),
            _buildFeature("Availability management"),
            _buildFeature("Secure Firebase authentication"),

            const SizedBox(height: 20),

            // 🔥 App Info
            const Text(
              "App Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildInfoRow("Version", "1.0.0"),
            _buildInfoRow("Platform", "Flutter"),
            _buildInfoRow("Database", "Firebase"),
            _buildInfoRow("Storage", "Firebase Storage"),

            const SizedBox(height: 20),

            // 🔥 Support
            const Text(
              "Support",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _buildInfoRow("Email", "support@roomhive.com"),
            _buildInfoRow("Phone", "+91 98765 43210"),

            const SizedBox(height: 30),

            Center(
              child: Text(
                "Made with ❤️ by RoomHive Team",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Feature Tile
  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // 🔥 Info Row
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}