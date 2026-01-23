// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

        final time =
            createdAt != null ? _formatTime(createdAt) : '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Item Details'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // 🔴 STATUS CHIP
              Chip(
                label: Text(
                  isClaimed ? 'CLAIMED' : status,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: isClaimed
                    ? Colors.grey
                    : status == 'Lost'
                        ? Colors.red
                        : Colors.green,
              ),

              const SizedBox(height: 16),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // 📍 LOCATION
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.map_outlined,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(emirate),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(time),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Description',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(description),

              const SizedBox(height: 24),

              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(height: 24),

              // ✅ MARK AS CLAIMED
              if (isOwner && !isClaimed)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon:
                        const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Claimed'),
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
                          content:
                              Text('Item marked as claimed'),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // 🔗 SIMILAR ITEMS
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
          style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('matched')
              .where('sourceId',
                  isEqualTo: currentItemId)
              .snapshots(),
          builder: (context, sourceSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('matched')
                  .where('targetId',
                      isEqualTo: currentItemId)
                  .snapshots(),
              builder: (context, targetSnap) {
                if (!sourceSnap.hasData ||
                    !targetSnap.hasData) {
                  return const CircularProgressIndicator();
                }

                final allDocs = [
                  ...sourceSnap.data!.docs,
                  ...targetSnap.data!.docs,
                ];

                if (allDocs.isEmpty) {
                  return const Text(
                    'No similar items found yet.',
                    style: TextStyle(color: Colors.grey),
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
                        (data['score'] as num?)?.toDouble() ??
                            0.0;

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

/* ========================================================================== */
/*                            SIMILAR ITEM CARD                               */
/* ========================================================================== */

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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(name),
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

/* ========================================================================== */
/*                             SCORE CIRCLE                                   */
/* ========================================================================== */

class SimilarityCircle extends StatelessWidget {
  final double score;

  const SimilarityCircle({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 3),
        color: Colors.blue.withOpacity(0.08),
      ),
      alignment: Alignment.center,
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
