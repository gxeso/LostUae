import 'package:flutter/material.dart';

class EmptyMyPosts extends StatelessWidget {
  final VoidCallback onCreate;

  const EmptyMyPosts({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 90, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No items posted yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Lost something or found an item?\nPost it here to help others.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Post your first item'),
                onPressed: onCreate, // ✅ switch tab
              ),
            ),
          ],
        ),
      ),
    );
  }
}
