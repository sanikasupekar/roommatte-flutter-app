import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Email pathvanyasathi function
  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@roomhive.com',
      queryParameters: {
        'subject': 'Support Request: [Write Your Query Here]',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    // RoomHive Theme Color
    const Color themeColor = Color(0xFFFF5A5F);

    return Scaffold(
      backgroundColor: Colors.white, // RoomHive Clean White Look
      appBar: AppBar(
        title: const Text(
          "Help & Support",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section 2: Contact Us (Email Only) ---
            const Text(
              "Contact Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.email, color: themeColor),
                ),
                title: const Text("Email Support", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("support@roomhive.com", style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: _launchEmail,
              ),
            ),

            const SizedBox(height: 30),

            // --- Section 3: Safety Guidelines ---
            const Text(
              "Safety Guidelines",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSafetyTile(
              themeColor,
              "Precautions before meeting",
              "Always choose a public place to meet a new roommate. It is better to bring a friend along for the first meeting.",
            ),
            _buildSafetyTile(
              themeColor,
              "Financial Safety",
              "Always verify listings thoroughly before making any transactions (like deposits) outside the app. Beware of fake listings.",
            ),
            _buildSafetyTile(
              themeColor,
              "Profile Verification",
              "Give preference to users with a verified badge. Make sure to get your own profile verified as well for better trust.",
            ),

            const SizedBox(height: 30),

            // --- Section 4: Report an Issue ---
            const Text(
              "Report an Issue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildReportTile(
              context,
              themeColor,
              "Report a User",
              "Report profiles for spam, fake information, or inappropriate behavior.",
              Icons.person_off_outlined,
            ),
            const SizedBox(height: 10),
            _buildReportTile(
              context,
              themeColor,
              "Report a Bug",
              "Let us know if the app crashes or if you encounter any technical problems.",
              Icons.bug_report_outlined,
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "RoomHive v1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSafetyTile(Color themeColor, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        shape: const Border(), // ExpansionTile chi default border kadhun takli
        leading: Icon(Icons.shield_outlined, color: themeColor, size: 22),
        title: Text(
          title, 
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)
        ),
        iconColor: themeColor,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 15, bottom: 15),
            child: Text(
              content, 
              style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14)
            ),
          )
        ],
      ),
    );
  }

  
  Widget _buildReportTile(BuildContext context, Color themeColor, String title, String sub, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Report feature coming soon!"),
              backgroundColor: themeColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}
