// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat system/chat_screen.dart';
import 'chat system/chat_service.dart';
import 'utils/chat_utils.dart';


import 'edit_item_screen.dart';



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
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 24),

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

              const SizedBox(height: 16),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

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

              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(description),

              const SizedBox(height: 32),

              // 🗨 CHAT BUTTON (NON-OWNER ONLY)
              if (canChat)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with owner'),
                    onPressed: () async {
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
                          builder: (_) => ChatScreen(caseId: caseId),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // 🔒 OWNER ACTIONS
              if (isOwner)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (!isClaimed)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              icon:
                                  const Icon(Icons.check_circle_outline),
                              label:
                                  const Text('Mark as Claimed'),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('items')
                                    .doc(widget.itemId)
                                    .update({
                                  'isClaimed': true,
                                  'claimedAt': Timestamp.now(),
                                });

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Item marked as claimed'),
                                  ),
                                );
                              },
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
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
        const Text(
          'Similar Items',
          style: TextStyle(
            fontSize: 22,
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
