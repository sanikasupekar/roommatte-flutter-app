import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  Color get themeColor => const Color(0xFFFF5A5F);

  User? get user => FirebaseAuth.instance.currentUser;

  //  CALCULATE MONTHLY + YEARLY EARNINGS
  double calculateEarnings(List<QueryDocumentSnapshot> docs, int monthsBack) {
    final now = DateTime.now();

    double total = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      Timestamp ts = data["timestamp"];
      DateTime date = ts.toDate();

      if (now.difference(date).inDays <= monthsBack * 30) {
        total += (data["amount"] ?? 0).toDouble();
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = user?.uid;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          "Earnings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .where("ownerId", isEqualTo: ownerId)
            .where("status", isEqualTo: "paid")
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          double monthly = calculateEarnings(docs, 1);
          double yearly = calculateEarnings(docs, 12);
          double total = yearly;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 💰 TOTAL
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Earnings",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📊 MONTHLY
                _buildCard("This Month", monthly, Colors.blue),
                const SizedBox(height: 12),

                // 📊 YEARLY
                _buildCard("This Year", yearly, Colors.green),

                const SizedBox(height: 20),

                // 📄 TRANSACTIONS
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent Transactions",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),

                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return TransactionCard(
                    amount: "₹${data["amount"]}",
                    status: data["status"],
                    date: "Paid",
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔹 SMALL CARD
  Widget _buildCard(String title, double amount, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$title: ₹${amount.toStringAsFixed(0)}",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// 🔹 TRANSACTION CARD
class TransactionCard extends StatelessWidget {
  final String amount;
  final String status;
  final String date;

  const TransactionCard({
    super.key,
    required this.amount,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Color color = status == "Success" ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.currency_rupee, color: color),
          const SizedBox(width: 10),

          Expanded(
            child: Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Text(status, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
