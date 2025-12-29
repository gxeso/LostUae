import 'package:flutter/material.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String status;
  final String itemName;
  final String location;
  final String time;
  final String description;
  final String? imageUrl;

  const ItemDetailsScreen({
    super.key,
    required this.status,
    required this.itemName,
    required this.location,
    required this.time,
    required this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLost = status == 'Lost';

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Item Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Chip(
            label: Text(status, style: const TextStyle(color: Colors.white)),
            backgroundColor: isLost ? Colors.red : Colors.green,
          ),

          const SizedBox(height: 24),

          Text(
            itemName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 6),
              Text(location),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.grey),
              const SizedBox(width: 6),
              Text(time),
            ],
          ),

          const SizedBox(height: 32),

          const Text(
            'Description',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(description, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 24),

          // 🖼 IMAGE (OPTIONAL)
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
