import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostItemScreen extends StatefulWidget {
  final VoidCallback onPostSuccess;

  const PostItemScreen({super.key, required this.onPostSuccess});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  File? selectedImage;

  final itemNameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();

  String status = 'Lost';
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

 Future<String> _uploadImage(String uid) async {
  final ref = FirebaseStorage.instance
      .ref()
      .child('items/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

  final uploadTask = ref.putFile(selectedImage!);

  // ⏱️ TIMEOUT SAFETY
  await uploadTask.timeout(
    const Duration(seconds: 20),
    onTimeout: () {
      throw Exception('Upload timeout');
    },
  );

  return await ref.getDownloadURL();
}


  Future<void> _submitItem() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String? imageUrl;

  // ✅ Upload image ONLY if user picked one
  if (selectedImage != null) {
    imageUrl = await _uploadImage(user.uid);
  }

  await FirebaseFirestore.instance.collection('items').add({
    'status': status,
    'itemName': itemNameController.text.trim(),
    'description': descriptionController.text.trim(),
    'location': locationController.text.trim(),
    'contactPhone': phoneController.text.trim(),
    'userId': user.uid,
    'imageUrl': imageUrl, // 🔥 NULL if no image
    'createdAt': FieldValue.serverTimestamp(),
  });

  setState(() => isLoading = false);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      backgroundColor: Colors.green,
      content: Text('Item posted successfully'),
    ),
  );

  widget.onPostSuccess(); // back to Feed
}

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
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  image: selectedImage != null
                      ? DecorationImage(
                          image: FileImage(selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: selectedImage == null
                    ? const Center(
                        child: Icon(Icons.add_a_photo, size: 40),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField(
              value: status,
              items: const [
                DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                DropdownMenuItem(value: 'Found', child: Text('Found')),
              ],
              onChanged: (v) => setState(() => status = v!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),

            TextFormField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),

            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Contact Phone'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : _submitItem,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Post Item'),
            ),
          ],
        ),
      ),
    );
  }
}
