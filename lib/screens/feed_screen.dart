// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? selectedStatus;
  String? selectedEmirate;
  String searchText = '';

  final TextEditingController searchController = TextEditingController();

  final List<String> emirates = const [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('items');

    if (selectedStatus != null) {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    if (selectedEmirate != null) {
      query = query.where('emirate', isEqualTo: selectedEmirate);
    }

    return query.orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔍 SEARCH BAR
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search items',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterSheet,
              ),
            ],
          ),
        ),

        // 📰 FEED
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery().snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    (data['itemName'] ?? '').toString().toLowerCase();
                return name.contains(searchText);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text('No matching items found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;

                  return FeedItemCard(
                    itemId: docs[index].id,
                    userId: data['userId'],
                    status: data['status'],
                    isClaimed: data['isClaimed'] == true,
                    itemName: data['itemName'],
                    location:
                        data['locationName'] ?? data['location'] ?? '',
                    emirate: data['emirate'],
                    time: _formatTime(data['createdAt']),
                    imageUrl: data['imageUrl'],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text('Status'),
                  Wrap(
                    spacing: 8,
                    children: ['Lost', 'Found'].map((status) {
                      return ChoiceChip(
                        label: Text(status),
                        selected: selectedStatus == status,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedStatus = selected ? status : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text('Emirate'),
                  Wrap(
                    spacing: 8,
                    children: emirates.map((emirate) {
                      return ChoiceChip(
                        label: Text(emirate),
                        selected: selectedEmirate == emirate,
                        onSelected: (selected) {
                          setModalState(() {
                            selectedEmirate = selected ? emirate : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          selectedStatus = null;
                          selectedEmirate = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               FEED CARD                                    */
/* -------------------------------------------------------------------------- */

class FeedItemCard extends StatelessWidget {
  final String itemId;
  final String userId;
  final String status;
  final bool isClaimed;
  final String itemName;
  final String location;
  final String emirate;
  final String time;
  final String? imageUrl;

  const FeedItemCard({
    super.key,
    required this.itemId,
    required this.userId,
    required this.status,
    required this.isClaimed,
    required this.itemName,
    required this.location,
    required this.emirate,
    required this.time,
    this.imageUrl,
  });

  Color _statusColor(BuildContext context) {
    if (isClaimed) {
      return Theme.of(context).disabledColor;
    }
    if (status == 'Lost') {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  String _statusText() {
    if (isClaimed) return 'CLAIMED';
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailsScreen(itemId: itemId),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STATUS + EMIRATE + USERNAME
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        emirate,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      _UsernameChip(userId: userId),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 💰 REWARD (ADDED)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .doc(itemId)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final data =
                          snap.data!.data() as Map<String, dynamic>;
                      final reward = data['rewardAed'];

                      if (reward == null) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Reward: AED $reward',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          USERNAME CHIP (SMALL)                              */
/* -------------------------------------------------------------------------- */

class _UsernameChip extends StatelessWidget {
  final String userId;

  const _UsernameChip({required this.userId});

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
          nickname,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        );
      },
    );
  }
}

