// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';

class PassportVerificationScreen extends StatefulWidget {
  const PassportVerificationScreen({super.key});

  @override
  State<PassportVerificationScreen> createState() =>
      _PassportVerificationScreenState();
}

class _PassportVerificationScreenState
    extends State<PassportVerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  File? passportImage;
  bool isVerifying = false;

  String verificationStatus = 'none';
  bool verificationLoaded = false;

  static const double CONFIDENCE_THRESHOLD = 0.5;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    verificationStatus = doc.data()?['verificationStatus'] ?? 'none';
    verificationLoaded = true;

    if (mounted) setState(() {});
  }

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> _pickFromCamera() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) setState(() => passportImage = File(picked.path));
  }

  Future<void> _pickFromGallery() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => passportImage = File(picked.path));
  }

  /* ---------------- VERIFY ---------------- */

  Future<void> _verify() async {
    if (passportImage == null || verificationStatus == 'verified') return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => isVerifying = true);

    try {
      final uri = Uri.parse(
        'https://id-passport-ai-4991329968.us-central1.run.app/verify-emirates-id',
      );

      final Uint8List imageBytes = await passportImage!.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'imageBase64': base64Image}),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception('Verification failed');
      }

      final double confidence =
          (data['data']?['overallConfidence'] as num?)?.toDouble() ?? 0.0;

      final bool isAutoVerified = confidence > CONFIDENCE_THRESHOLD;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'verificationStatus':
            isAutoVerified ? 'verified' : 'pending_review',
        'role': isAutoVerified ? 'user' : 'guest',
        'verificationConfidence': confidence,
        'verificationData': data['data'],
        'verifiedAt': Timestamp.now(),
      });

      verificationStatus =
          isAutoVerified ? 'verified' : 'pending_review';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              isAutoVerified ? Colors.green : Colors.orange,
          content: Text(
            isAutoVerified
                ? 'Verification successful ✅'
                : 'Verification under review ⏳',
          ),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(toggleTheme: () {}, isDarkMode: false),
        ),
        (route) => false,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Verification failed. Please try again later.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  /* ---------------- CONTINUE AS GUEST ---------------- */

  Future<void> _continueAsGuest() async {
    if (verificationStatus == 'verified') return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'role': 'guest',
      'verificationStatus': 'none',
    });

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HomeScreen(toggleTheme: () {}, isDarkMode: false),
      ),
      (route) => false,
    );
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    if (!verificationLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isVerified = verificationStatus == 'verified';

    return Scaffold(
      appBar: AppBar(title: const Text('Passport Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verify your identity',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (isVerified)
              const Text(
                'Your account is verified ✅',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const Text(
                'Verification is required to post items on LostUAE.',
              ),

            const SizedBox(height: 20),

            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                image: passportImage != null
                    ? DecorationImage(
                        image: FileImage(passportImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: passportImage == null
                  ? const Center(child: Text('Add passport image'))
                  : null,
            ),

            const SizedBox(height: 16),

            if (!isVerified)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      onPressed: _pickFromCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Upload'),
                      onPressed: _pickFromGallery,
                    ),
                  ),
                ],
              ),

            const Spacer(),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isVerified || isVerifying || passportImage == null
                    ? null
                    : _verify,
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify Passport'),
              ),
            ),

            if (!isVerified) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _continueAsGuest,
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
