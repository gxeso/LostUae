// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:profanity_filter/profanity_filter.dart';

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
  final rewardController = TextEditingController();
  final emirateController = TextEditingController();

  final ProfanityFilter _profanityFilter = ProfanityFilter();

  File? selectedImage;

  double? latitude;
  double? longitude;
  String? pickedAddress;
  String? selectedEmirate;

  String status = 'Lost';
  bool isLoading = false;

  String verificationStatus = 'none';
  String accountStatus = '';
  bool verificationLoaded = false;

  String? _descriptionError;
  String? _itemNameError;

  final RegExp _uaePhoneRegex = RegExp(r'^(5[0-9]{8})$');

  /* ---------------- VALIDATION HELPERS ---------------- */

  bool _containsLink(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('www.')) return true;

    final domainRegex = RegExp(r'\b[a-z0-9-]+\.[a-z]{2,}\b');
    return domainRegex.hasMatch(lower);
  }

  bool _containsExplicitContent(String text) {
    return _profanityFilter.hasProfanity(text);
  }

  void _validateDescription(String value) {
    final v = value.trim();
    String? err;

    if (v.isEmpty) {
      err = null;
    } else if (_containsLink(v)) {
      err = 'Links are not allowed.';
    } else if (_containsExplicitContent(v)) {
      err = 'Inappropriate words detected.';
    }

    if (mounted) {
      setState(() => _descriptionError = err);
    }
  }

  void _validateItemName(String value) {
    final v = value.trim();
    String? err;

    if (v.isEmpty) {
      err = null;
    } else if (_containsExplicitContent(v)) {
      err = 'Inappropriate words detected.';
    }

    if (mounted) {
      setState(() => _itemNameError = err);
    }
  }

  /* ---------------- INIT ---------------- */

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    verificationStatus = snap.data()?['verificationStatus'] ?? 'none';
    accountStatus = snap.data()?['accountStatus'] ?? '';
    verificationLoaded = true;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    itemNameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    rewardController.dispose();
    emirateController.dispose();
    super.dispose();
  }

  /* ---------------- IMAGE ---------------- */

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (selectedImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('items/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(selectedImage!);
    return await ref.getDownloadURL();
  }

  /* ---------------- CONFIRM POST ---------------- */

  Future<void> _confirmPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            Text('Item: ${itemNameController.text.trim()}'),
            Text('Emirate: ${selectedEmirate ?? "Unknown"}'),
            if (rewardController.text.trim().isNotEmpty)
              Text('Reward: AED ${rewardController.text.trim()}'),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to publish this post?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitItem();
    }
  }

  /* ---------------- SUBMIT ---------------- */

 Future<void> _submitItem() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  setState(() => isLoading = true);

  try {
    // 🔥 ALWAYS fetch fresh status from Firestore
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final currentVerification = snap.data()?['verificationStatus'];
    final currentAccount = snap.data()?['accountStatus'] ?? '';

    // Block investigated users
    if (currentAccount == 'investigated') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been flagged. You cannot post items.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      setState(() => isLoading = false);
      return;
    }

    if (currentVerification != 'verified') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must verify before posting.')),
      );
      setState(() => isLoading = false);
      return;
    }

    final imageUrl = await _uploadImage(user.uid);

    await FirebaseFirestore.instance.collection('items').add({
      'status': status,
      'itemName': itemNameController.text.trim(),
      'description': descriptionController.text.trim(),
      'locationName': pickedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'contactPhone': phoneController.text.trim().isEmpty
          ? null
          : '+971${phoneController.text.trim()}',
      'rewardAed': rewardController.text.trim().isEmpty
          ? null
          : int.parse(rewardController.text.trim()),
      'emirate': selectedEmirate,
      'userId': user.uid,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
      'isClaimed': false,
    });

    widget.onPostSuccess();
  } catch (e) {
    print("POST ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to post item')),
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}
  /* ---------------- UI ---------------- */

@override
Widget build(BuildContext context) {
  if (!verificationLoaded) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return SafeArea(
    child: Material(
      color: Colors.transparent,
      child: Padding(
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
                          child: Icon(Icons.add_a_photo, size: 42))
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
                onChanged: (v) {
                  setState(() {
                    status = v!;
                    // Reward is only for Lost items — clear it when switching to Found
                    if (status == 'Found') {
                      rewardController.clear();
                    }
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  errorText: _itemNameError,
                ),
                onChanged: _validateItemName,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (_containsExplicitContent(v)) {
                    return 'Inappropriate words detected.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  errorText: _descriptionError,
                ),
                onChanged: _validateDescription,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (_containsLink(v)) return 'Links are not allowed.';
                  if (_containsExplicitContent(v)) {
                    return 'Inappropriate words detected.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Pick Location'),
                subtitle: Text(
                  locationController.text.isEmpty
                      ? 'Tap to choose on map'
                      : locationController.text,
                ),
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
                      selectedEmirate = result['emirate'];

                      locationController.text = pickedAddress!;
                      emirateController.text =
                          selectedEmirate ?? 'Unknown Emirate';
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: emirateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Detected Emirate',
                  prefixIcon: Icon(Icons.map),
                ),
              ),

              // Reward only applies to Lost items
              if (status == 'Lost') ...[
                const SizedBox(height: 16),

                TextFormField(
                  controller: rewardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reward (AED) - Optional',
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;

                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Enter valid amount';
                    }

                    if (parsed > 50000) {
                      return 'Reward too high';
                    }

                    return null;
                  },
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _confirmPost,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text('Post Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
