// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat system/chat_screen.dart';
import 'chat system/chat_service.dart';
import 'utils/chat_utils.dart';
import 'edit_item_screen.dart';
import '../services/report_service.dart';
import '../utils/profanity_utils.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;
  final bool autoScrollToSimilarity;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
    this.autoScrollToSimilarity = false,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final GlobalKey _similarityKey = GlobalKey();

  // ── Accessibility: TTS ──────────────────────────────────────────────────────
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initAccessibility();
  }

  Future<void> _initAccessibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _ttsEnabled = prefs.getBool('ttsEnabled') ?? false;
    });
    if (_ttsEnabled) {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
    }
  }

  Future<void> _readDescription(String text) async {
    if (!_ttsEnabled) return;
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.autoScrollToSimilarity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _similarityKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Color _statusColor(BuildContext context, String status, bool isClaimed) {
    if (isClaimed) return Theme.of(context).disabledColor;
    if (status == 'Lost') return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .doc(widget.itemId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Item not found')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final status = data['status'] ?? '';
        final name = data['itemName'] ?? '';
        final location = data['locationName'] ?? data['location'] ?? '';
        final emirate = data['emirate'] ?? '';
        final description = data['description'] ?? '';
        final imageUrl = data['imageUrl'];
        final createdAt = data['createdAt'] as Timestamp?;
        final isClaimed = data['isClaimed'] == true;
        final ownerId = data['userId'];
        final reward = data['rewardAed'];

        final isOwner =
            currentUser != null && currentUser.uid == ownerId;

        final canChat =
            currentUser != null && !isOwner && !isClaimed;

        final time =
            createdAt != null ? _formatTime(createdAt) : '';

        final statusColor =
            _statusColor(context, status, isClaimed);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Item Details'),
            actions: [
              if (!isOwner)
                Semantics(
                  label: 'Report this item',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.flag, color: Colors.red),
                    tooltip: 'Report',
                    onPressed: () => _showReportDialog(
                      context,
                      widget.itemId,
                      ownerId,
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Semantics(
                  label: 'Image of $name',
                  image: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isClaimed ? 'CLAIMED' : status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              // 💰 REWARD (GREEN, AED)
              if (reward != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.monetization_on, color: Colors.green),
                      SizedBox(width: 6),
                    ],
                  ),
                ),

              if (reward != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Reward: AED $reward',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ITEM NAME
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              // 👤 USERNAME
              _PostedByUser(userId: ownerId),

              const SizedBox(height: 16),

              // INFO CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.place, text: location),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.map_outlined, text: emirate),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.access_time, text: time),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(description),

              if (_ttsEnabled) ...[
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Read item description aloud',
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Read Description'),
                    onPressed: () => _readDescription(description),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // CHAT BUTTON
              if (canChat)
                Semantics(
                  label: 'Chat with the owner of this item',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat with owner'),
                      onPressed: () async {
                        // Block investigated users from chatting
                        final allowed = await ReportService.canChat(currentUser.uid);
                        if (!allowed) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your account has been flagged. You cannot chat.',
                              ),
                              backgroundColor: Colors.deepOrange,
                            ),
                          );
                          return;
                        }

                        final caseId = buildCaseId(
                          widget.itemId,
                          currentUser.uid,
                          ownerId,
                        );

                        await createCaseAndChat(
                          caseId: caseId,
                          lostUserId:
                              status == 'Lost' ? ownerId : currentUser.uid,
                          foundUserId:
                              status == 'Lost' ? currentUser.uid : ownerId,
                          itemId: widget.itemId,
                          itemName: name,
                        );

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              caseId: caseId,
                              otherUserId: ownerId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // OWNER ACTIONS
              if (isOwner)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!isClaimed)
                          Semantics(
                            label: 'Mark this item as claimed',
                            button: true,
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                    Icons.check_circle_outline),
                                label: const Text('Mark as Claimed'),
                                onPressed: () async {
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                          'Mark as Claimed'),
                                      content: const Text(
                                        'Are you sure you want to mark this item as claimed? This action cannot be undone.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  ctx, false),
                                          child:
                                              const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  ctx, true),
                                          child:
                                              const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('items')
                                        .doc(widget.itemId)
                                        .update({
                                      'isClaimed': true,
                                      'claimedAt': Timestamp.now(),
                                    });

                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Item marked as claimed'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                        if (!isClaimed) const SizedBox(height: 12),

                        if (!isClaimed)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              icon:
                                  const Icon(Icons.edit_outlined),
                              label:
                                  const Text('Edit Item'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditItemScreen(
                                      docId: widget.itemId,
                                      data: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              if (!isClaimed)
                Container(
                  key: _similarityKey,
                  child: SimilarItemsSection(
                    currentItemId: widget.itemId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _formatTime(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _showReportDialog(BuildContext context, String itemId, String ownerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ReportForm(itemId: itemId, ownerId: ownerId),
    );
  }
}

/* ================= POSTED BY USER ================= */

class _PostedByUser extends StatelessWidget {
  final String userId;

  const _PostedByUser({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final nickname = data['nickname'] ?? 'User';

        return Text(
          'Posted by @$nickname',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        );
      },
    );
  }
}

/* ================= INFO ROW ================= */

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/* ================= REPORT FORM ================= */

class _ReportForm extends StatefulWidget {
  final String itemId;
  final String ownerId;

  const _ReportForm({
    required this.itemId,
    required this.ownerId,
  });

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedReportType = 'Spam';
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Spam',
    'Inappropriate Content',
    'Fake/Scam',
    'Harassment',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Report Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Report Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _reportTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReportType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Report Description',
                hintText: 'Please describe the issue (min 10 characters)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                if (ProfanityUtils.hasProfanity(value)) {
                  return 'Description contains inappropriate language';
                }
                if (ProfanityUtils.hasLinks(value)) {
                  return 'Links are not allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Report'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ReportService.submitReport(
        itemId: widget.itemId,
        ownerId: widget.ownerId,
        reportType: _selectedReportType,
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. You may have already reported this item.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

/* ========================================================================== */
/*                               SIMILAR ITEMS                                */
/* ========================================================================== */

class SimilarItemsSection extends StatelessWidget {
  final String currentItemId;

  const SimilarItemsSection({
    super.key,
    required this.currentItemId,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('matched')
              .where('sourceId', isEqualTo: currentItemId)
              .snapshots(),
          builder: (context, sourceSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('matched')
                  .where('targetId', isEqualTo: currentItemId)
                  .snapshots(),
              builder: (context, targetSnap) {
                if (!sourceSnap.hasData || !targetSnap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final allDocs = [
                  ...sourceSnap.data!.docs,
                  ...targetSnap.data!.docs,
                ];

                if (allDocs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No similar items found yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return Column(
                  children: allDocs.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final otherItemId =
                        data['sourceId'] == currentItemId
                            ? data['targetId']
                            : data['sourceId'];

                    final score =
                        (data['score'] as num?)?.toDouble() ?? 0.0;

                    return SimilarItemCard(
                      itemId: otherItemId,
                      score: score,
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}


class SimilarItemCard extends StatelessWidget {
  final String itemId;
  final double score;

  const SimilarItemCard({
    super.key,
    required this.itemId,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        final name = data['itemName'] ?? 'Unnamed item';
        final emirate = data['emirate'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(emirate),
            trailing: SimilarityCircle(score: score),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ItemDetailsScreen(itemId: itemId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
class SimilarityCircle extends StatelessWidget {
  final double score;

  const SimilarityCircle({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        color: color.withOpacity(0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}