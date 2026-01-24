// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'map_picker_screen.dart';

class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditItemScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController locationController;

  File? newImage;
  late final String emirate;

  late bool isClaimed;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['itemName']);
    descController =
        TextEditingController(text: widget.data['description']);
    locationController =
        TextEditingController(text: widget.data['location']);
    emirate = widget.data['emirate'];
    isClaimed = widget.data['isClaimed'] == true;
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        locationController.text = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl = widget.data['imageUrl'];

    if (newImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('items/${widget.docId}.jpg');
      await ref.putFile(newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.docId)
        .update({
      'itemName': nameController.text.trim(),
      'description': descController.text.trim(),
      'location': locationController.text.trim(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Future<void> _markAsClaimed() async {
    await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.docId)
        .update({
      'isClaimed': true,
      'claimedAt': Timestamp.now(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 🖼 IMAGE
            if (newImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    Image.file(newImage!, height: 220, fit: BoxFit.cover),
              )
            else if (widget.data['imageUrl'] != null &&
                widget.data['imageUrl'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.data['imageUrl'],
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),

            TextButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Change Image'),
              onPressed: _pickImage,
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            const SizedBox(height: 16),

            // 📍 LOCATION (MAP PICKER)
            TextFormField(
              controller: locationController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Location',
                suffixIcon: Icon(Icons.map),
              ),
              onTap: _openMapPicker,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            // 🏙 EMIRATE (LOCKED)
            TextFormField(
              initialValue: emirate,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Emirate',
                helperText: 'Emirate cannot be changed',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ MARK AS CLAIMED
            if (!isClaimed)
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Claimed'),
                  onPressed: _markAsClaimed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
