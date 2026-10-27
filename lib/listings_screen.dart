import 'package:flutter/material.dart';

class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  final Color themeColor = const Color(0xFFFF5A5F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          "Total Listings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListingCard(
            name: "Rahul Sharma",
            property: "Green Valley PG",
            type: "2 Sharing",
            price: "₹8,500/mo",
            status: "Booked",
          ),
          ListingCard(
            name: "Amit Patil",
            property: "Sunlight Rooms",
            type: "Single Room",
            price: "₹12,000/mo",
            status: "Booked",
          ),
        ],
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final String name;
  final String property;
  final String type;
  final String price;
  final String status;

  const ListingCard({
    super.key,
    required this.name,
    required this.property,
    required this.type,
    required this.price,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor =
        status == "Booked" ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [

          // 👤 Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.black54),
          ),

          const SizedBox(width: 12),

          // 📄 Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(property,
                    style: const TextStyle(color: Colors.grey)),
                Text(type,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          // 💰 + Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
