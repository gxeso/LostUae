import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../qr system/qr_code_service.dart';

class QRCodeProfileScreen extends StatefulWidget {
  const QRCodeProfileScreen({super.key});

  @override
  State<QRCodeProfileScreen> createState() => _QRCodeProfileScreenState();
}

class _QRCodeProfileScreenState extends State<QRCodeProfileScreen> {
  late String userId;
  late String userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (mounted) {
        setState(() {
          userName = doc.data()?['nickname'] ?? 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data')),
        );
      }
    }
  }

  Future<void> _saveQRCode() async {
    try {
      final image = await QRCodeService.generateQRCodeImage(
        userId: userId,
        size: 500,
      );

      if (image == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate QR code')),
        );
        return;
      }

      // Save to downloads or documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/LostUAE-Profile-QR-$userId.png';
      final file = File(filePath);
      await file.writeAsBytes(image);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR code saved to: $filePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR code: $e')),
      );
    }
  }

  Future<void> _shareQRCode() async {
    try {
      final qrCodeUrl = QRCodeService.generateQRCodeURL(userId);
      
      await Share.share(
        'Check out my LostUAE profile! $qrCodeUrl',
        subject: 'My LostUAE Profile QR Code',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final qrCodeUrl = QRCodeService.generateQRCodeURL(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Profile QR Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Share this QR code for others to view your profile',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // 🔲 QR CODE CONTAINER
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: qrCodeUrl,
                size: 280,
                version: QrVersions.auto,
                embeddedImageStyle:
                    const QrEmbeddedImageStyle(size: Size(60, 60)),
              ),
            ),

            const SizedBox(height: 40),

            // 📱 PROFILE URL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile URL:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qrCodeUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🔘 ACTION BUTTONS
            ElevatedButton.icon(
              onPressed: _shareQRCode,
              icon: const Icon(Icons.share),
              label: const Text('Share QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _saveQRCode,
              icon: const Icon(Icons.download),
              label: const Text('Save QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 32),

            // ℹ️ INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 How to use your QR Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Print and stick it on your backpack or laptop\n'
                    '• Share digitally with friends\n'
                    '• When scanned, people will see your profile\n'
                    '• Perfect for lost items - if found, people can contact you',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}