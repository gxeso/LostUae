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
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController locationController;

  File? newImage;
  String? selectedEmirate;

  final List<String> emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['itemName']);
    descController =
        TextEditingController(text: widget.data['description']);
    locationController =
        TextEditingController(text: widget.data['location']);
    selectedEmirate = widget.data['emirate'];
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl = widget.data['imageUrl'];

    // 🖼 Upload new image if selected
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
      'emirate': selectedEmirate,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 🖼 IMAGE PREVIEW
              if (newImage != null)
                Image.file(newImage!, height: 180, fit: BoxFit.cover)
              else if (widget.data['imageUrl'] != null &&
                  widget.data['imageUrl'].toString().isNotEmpty)
                Image.network(
                  widget.data['imageUrl'],
                  height: 180,
                  fit: BoxFit.cover,
                ),

              TextButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('Change Image'),
                onPressed: _pickImage,
              ),

              const SizedBox(height: 16),

              // 🏷 ITEM NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // 📝 DESCRIPTION
              TextFormField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),

              const SizedBox(height: 16),

              // 📍 LOCATION
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              // 🏙 EMIRATE
              DropdownButtonFormField<String>(
                value: selectedEmirate,
                decoration: const InputDecoration(
                  labelText: 'Emirate',
                ),
                items: emirates
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedEmirate = v),
                validator: (v) =>
                    v == null ? 'Please select an emirate' : null,
              ),

              const SizedBox(height: 32),

              // 💾 SAVE BUTTON
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
