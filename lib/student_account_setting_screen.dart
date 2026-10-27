import 'package:flutter/material.dart';

import 'auth_service_delete.dart';

import 'auth_screen.dart'; 

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // Logic for Notifications
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 4: NOTIFICATIONS CONTROL ---
              _buildSectionTitle("Notifications"),
              SwitchListTile(
                title: const Text("Push Notifications"),
                subtitle: const Text("Get instant alerts for new matches"),
                value: _pushNotifications,
                onChanged: (bool value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text("Email Alerts"),
                subtitle: const Text("Receive weekly roommate suggestions"),
                value: _emailAlerts,
                onChanged: (bool value) {
                  setState(() {
                    _emailAlerts = value;
                  });
                },
              ),
              const Divider(),

              // --- SECTION 5: MEMBERSHIP & TRUST ---
              _buildSectionTitle("Membership & Trust"),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text("Subscription Plan"),
                subtitle: const Text("Free Version - Upgrade for more filters"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Subscription logic ithe yeil
                },
              ),
              const Divider(),

              // --- SECTION 6: LEGAL ---
              _buildSectionTitle("Legal"),
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text("Privacy Policy"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                onTap: () {
                  _showDeleteConfirmDialog();
                },
              ),
              
              const SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings Saved Successfully!")),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Save & Return to Dashboard", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User ne baher click kela tar dialog band nahi honar
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("Are you sure? Your RoomHive account and data will be permanently deleted. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Dialog band kara
              Navigator.pop(context); 
              
              try {
                
                final deleteService = AuthServiceDelete();
                
                
                await deleteService.deleteUserAccount();

                if (mounted) {
                  
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully. Redirecting..."), 
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString()}"), 
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}