import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profile not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final nickname = data['nickname'] ?? 'User';
          final email = data['email'] ?? 'No email available';
          final phone = data['phone'] ?? 'No phone number';
          final postCount = data['postCount'] ?? 0;
          final verificationStatus = data['verificationStatus'] ?? 'none';

          final bool isVerified =
              verificationStatus == 'approved' ||
              verificationStatus == 'verified';

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const CircleAvatar(
                      radius: 60,
                      child: Icon(Icons.person, size: 60),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      nickname,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (isVerified)
                      const Chip(
                        label: Text("Verified User"),
                        backgroundColor: Colors.green,
                      ),

                    const SizedBox(height: 25),

                    const Divider(),

                    const SizedBox(height: 15),

                    _buildInfoRow(Icons.email, email),

                    const SizedBox(height: 15),

                    _buildInfoRow(Icons.phone, phone),

                    const SizedBox(height: 15),

                    _buildInfoRow(Icons.article, "Posts: $postCount"),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
