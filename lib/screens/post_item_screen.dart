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

  // ✅ profanity library
  final ProfanityFilter _profanityFilter = ProfanityFilter();

  File? selectedImage;

  double? latitude;
  double? longitude;
  String? pickedAddress;
  String? selectedEmirate;

  String status = 'Lost';
  bool isLoading = false;

  // 🔐 VERIFICATION
  String verificationStatus = 'none';
  bool verificationLoaded = false;

  // 🚫 VALIDATION (Description)
  String? _descriptionError;

  final List<String> emirates = const [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  final RegExp _uaePhoneRegex = RegExp(r'^(5[0-9]{8})$');

  int _countWords(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  // ✅ Link detection (safe)
  bool _containsLink(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('www.')) {
      return true;
    }

    final domainRegex = RegExp(r'\b[a-z0-9-]+\.[a-z]{2,}\b');
    return domainRegex.hasMatch(lower);
  }

  // ✅ Custom drug words (since this package version doesn't support addWords)
  static const List<String> _drugWords = [
    'coke',
    'cocaine',
    'heroin',
    'weed',
    'marijuana',
    'hash',
    'meth',
    'mdma',
    'ecstasy',
    'lsd',
  ];

  bool _containsDrugWord(String text) {
    final lower = text.toLowerCase();
    for (final w in _drugWords) {
      final re =
          RegExp(r'\b' + RegExp.escape(w) + r'\b', caseSensitive: false);
      if (re.hasMatch(lower)) return true;
    }
    return false;
  }

  bool _containsExplicitContent(String text) {
    return _profanityFilter.hasProfanity(text) || _containsDrugWord(text);
  }

  // Live validator
  void _validateDescription(String value) {
    final v = value.trim();

    String? err;
    if (v.isEmpty) {
      err = null; // required handled by validator
    } else if (_containsLink(v)) {
      err = 'Links are not allowed in the description.';
    } else if (_containsExplicitContent(v)) {
      err = 'No explicit or inappropriate words are allowed.';
    } else {
      err = null;
    }

    if (!mounted) return;
    setState(() => _descriptionError = err);
  }

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      verificationStatus = snap.data()?['verificationStatus'] ?? 'none';
    } catch (_) {
      verificationStatus = 'none';
    } finally {
      verificationLoaded = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    itemNameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    rewardController.dispose();
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

  /* ---------------- BLOCK DIALOG ---------------- */

  void _showBlockedDialog() {
    final message = verificationStatus == 'pending_review'
        ? 'Your identity verification is under review.\n\nYou can post once it is approved.'
        : 'You must verify your identity before posting items.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Posting Restricted'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /* ---------------- SUBMIT ---------------- */

  Future<void> _submitItem() async {
    if (!verificationLoaded) return;

    // 🚫 BLOCK
    if (verificationStatus != 'verified') {
      _showBlockedDialog();
      return;
    }

    if (isLoading) return;

    // Final content checks (blocks posting + shows red message)
    final desc = descriptionController.text.trim();
    _validateDescription(desc);
    if (_descriptionError != null) return;

    if (!_formKey.currentState!.validate()) return;

    if (pickedAddress == null || latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Post'),
        content: const Text(
          'Are you sure you want to post this item?\n\n'
          'Please double-check the details before continuing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _submitItemInternal();
  }

  Future<void> _submitItemInternal() async {
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
        'contactPhone': phoneController.text.trim().isEmpty
            ? null
            : '+971${phoneController.text.trim()}',
        'rewardAed': status == 'Lost' && rewardController.text.trim().isNotEmpty
            ? int.parse(rewardController.text.trim())
            : null,
        'emirate': selectedEmirate,
        'userId': user.uid,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'isClaimed': false,
        'claimedAt': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Item posted successfully'),
        ),
      );

      widget.onPostSuccess();
    } catch (_) {
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
      return const Center(child: CircularProgressIndicator());
    }

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
                    ? const Center(child: Icon(Icons.add_a_photo, size: 42))
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
              decoration: const InputDecoration(
                labelText: 'Item Name',
                helperText: 'Required · Max 20 words',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Item name is required';
                }
                if (_countWords(v) > 20) {
                  return 'Maximum 20 words allowed';
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
                helperText:
                    'Required · Max 100 words · No links · No explicit words',
                errorText: _descriptionError,
              ),
              onChanged: _validateDescription,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Description is required';
                }
                if (_countWords(v) > 100) {
                  return 'Maximum 100 words allowed';
                }
                if (_containsLink(v)) {
                  return 'Links are not allowed in the description.';
                }
                if (_containsExplicitContent(v)) {
                  return 'No explicit or inappropriate words are allowed.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            if (status == 'Lost')
              TextFormField(
                controller: rewardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reward (AED)',
                  helperText: 'Optional',
                ),
              ),

            const SizedBox(height: 16),

            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                prefixText: '+971 ',
                helperText: 'Optional · 5XXXXXXXX',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                return _uaePhoneRegex.hasMatch(v)
                    ? null
                    : 'Invalid UAE phone number';
              },
            ),

            const SizedBox(height: 20),

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
                text: selectedEmirate ?? 'Select location to detect emirate',
              ),
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
