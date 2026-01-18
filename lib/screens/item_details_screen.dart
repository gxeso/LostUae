// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('OPENED ITEM ID: $itemId');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
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
        final location = data['location'] ?? '';
        final emirate = data['emirate'] ?? '';
        final description = data['description'] ?? '';
        final imageUrl = data['imageUrl'];
        final createdAt = data['createdAt'] as Timestamp?;

        final time = createdAt != null ? _formatTime(createdAt) : '';

        final isLost = status == 'Lost';

        return Scaffold(
          appBar: AppBar(title: const Text('Item Details'),
          iconTheme: IconThemeData(color: Colors.white),),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Chip(
                label: Text(status, style: const TextStyle(color: Colors.white)),
                backgroundColor: isLost ? Colors.red : Colors.green,
              ),

              const SizedBox(height: 16),

              Text(
                name,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.place, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(location),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

              const SizedBox(height: 32),

              SimilarItemsSection(currentItemId: itemId),
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

/* -------------------------------------------------------------------------- */
/*                               SIMILAR ITEMS                                */
/* -------------------------------------------------------------------------- */

class SimilarItemsSection extends StatelessWidget {
  final String currentItemId;

  const SimilarItemsSection({super.key, required this.currentItemId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    final sourceStream = firestore
        .collection('matched')
        .where('sourceId', isEqualTo: currentItemId)
        .snapshots();

    final targetStream = firestore
        .collection('matched')
        .where('targetId', isEqualTo: currentItemId)
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Items',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: sourceStream,
          builder: (context, sourceSnap) {
            if (!sourceSnap.hasData) {
              return const CircularProgressIndicator();
            }

            return StreamBuilder<QuerySnapshot>(
              stream: targetStream,
              builder: (context, targetSnap) {
                if (!targetSnap.hasData) {
                  return const CircularProgressIndicator();
                }

                final allDocs = [
                  ...sourceSnap.data!.docs,
                  ...targetSnap.data!.docs,
                ];

                debugPrint(
                    'SIMILAR MATCHES FOUND: ${allDocs.length}');

                if (allDocs.isEmpty) {
                  return const Text(
                    'No similar items found yet.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  children: allDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

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

/* -------------------------------------------------------------------------- */
/*                            SIMILAR ITEM CARD                               */
/* -------------------------------------------------------------------------- */

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
        // 🔴 HARD GUARD
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('⚠️ Missing item for similar match: $itemId');
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
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
                  builder: (_) => ItemDetailsScreen(itemId: itemId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


/* -------------------------------------------------------------------------- */
/*                             BLUE SCORE CIRCLE                               */
/* -------------------------------------------------------------------------- */

class SimilarityCircle extends StatelessWidget {
  final double score;

  const SimilarityCircle({super.key, required this.score});

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
