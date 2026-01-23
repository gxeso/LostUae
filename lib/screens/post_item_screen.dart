// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'map_picker_screen.dart';

class PostItemScreen extends StatefulWidget {
  final VoidCallback onPostSuccess;

  const PostItemScreen({
    super.key,
    required this.onPostSuccess,
  });

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final itemNameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();

  File? selectedImage;

  double? latitude;
  double? longitude;
  String? pickedAddress;
  String? selectedEmirate;

  String status = 'Lost';
  bool isLoading = false;

  final List<String> emirates = const [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void dispose() {
    itemNameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /* ---------------- IMAGE PICK ---------------- */

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  /* ---------------- IMAGE UPLOAD ---------------- */

  Future<String?> _uploadImage(String uid) async {
    if (selectedImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('items/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(
      selectedImage!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  /* ---------------- SUBMIT ITEM ---------------- */

  Future<void> _submitItem() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (pickedAddress == null || latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
        ),
      );
      return;
    }

    if (selectedEmirate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to detect emirate. Please choose a valid UAE location.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final imageUrl = await _uploadImage(user.uid);

      await FirebaseFirestore.instance.collection('items').add({
        'status': status,
        'itemName': itemNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'locationName': pickedAddress,
        'latitude': latitude,
        'longitude': longitude,
        'contactPhone': phoneController.text.trim(),
        'emirate': selectedEmirate,
        'userId': user.uid,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'isClaimed': false,
        'claimedAt': null,
      });

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Item posted successfully'),
        ),
      );

      widget.onPostSuccess();
    } on FirebaseException catch (e) {
      setState(() => isLoading = false);

      if (e.code == 'permission-denied') {
        const waitMinutes = 10;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Posting limit reached. Please wait $waitMinutes minutes before posting again.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post item. Please try again.'),
          ),
        );
      }
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(14),
                  image: selectedImage != null
                      ? DecorationImage(
                          image: FileImage(selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedImage == null
                    ? const Center(
                        child: Icon(Icons.add_a_photo, size: 42),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                DropdownMenuItem(value: 'Found', child: Text('Found')),
              ],
              onChanged: (v) => setState(() => status = v!),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Pick exact location'),
              subtitle: Text(
                locationController.text.isEmpty
                    ? 'Tap to choose on map'
                    : locationController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );

                if (result != null) {
                  setState(() {
                    pickedAddress = result['name'];
                    latitude = result['lat'];
                    longitude = result['lng'];
                    locationController.text = result['name'];

                    if (result['emirate'] != null &&
                        emirates.contains(result['emirate'])) {
                      selectedEmirate = result['emirate'];
                    }
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Detected Emirate',
                prefixIcon: Icon(Icons.map),
              ),
              controller: TextEditingController(
                text: selectedEmirate ??
                    'Select location to detect emirate',
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitItem,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
