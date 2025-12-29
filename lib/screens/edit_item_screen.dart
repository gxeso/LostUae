import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  late TextEditingController nameController;
  late TextEditingController descController;

  File? newImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['itemName']);
    descController =
        TextEditingController(text: widget.data['description']);
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    String? imageUrl = widget.data['imageUrl'];

    if (newImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('item_images/${widget.docId}.jpg');

      await ref.putFile(newImage!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.docId)
        .update({
      'itemName': nameController.text.trim(),
      'description': descController.text.trim(),
      'imageUrl': imageUrl,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (newImage != null)
              Image.file(newImage!, height: 150)
            else if (widget.data['imageUrl'] != null)
              Image.network(widget.data['imageUrl'], height: 150),

            TextButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Change Image'),
              onPressed: _pickImage,
            ),

            TextField(controller: nameController),
            TextField(controller: descController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
