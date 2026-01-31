// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_posts_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onCreatePost;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    required this.onCreatePost,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final nickname = data['nickname'] ?? 'No nickname';
          final email = data['email'] ?? '';
          final phone = data['phone'] ?? 'Not provided';
          final postCount = data['postCount'] ?? 0;

          final verificationStatus =
              data['verificationStatus'] ?? 'none';

          final bool isVerified =
              verificationStatus == 'approved' ||
              verificationStatus == 'verified';

          final bool isPending =
              verificationStatus == 'pending_review';

          final String roleLabel =
              isVerified ? 'Verified User' : 'Guest';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                /* ================= AVATAR ================= */

                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    if (isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Tooltip(
                          message: 'Verified account',
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                _VerificationStatusChip(
                  isVerified: isVerified,
                  isPending: isPending,
                ),

                const SizedBox(height: 20),

                /* ================= PENDING BANNER ================= */

                if (isPending)
                  _PendingVerificationBanner(),

                const SizedBox(height: 24),

                /* ================= STATS ================= */

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      label: 'Posts',
                      value: postCount.toString(),
                    ),
                    _StatItem(
                      label: 'Status',
                      value: isVerified
                          ? 'Verified'
                          : isPending
                              ? 'Pending'
                              : 'Unverified',
                    ),
                    _StatItem(
                      label: 'Role',
                      value: roleLabel,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /* ================= ACTIONS ================= */

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyPostsScreen(
                                onCreatePost: onCreatePost,
                              ),
                            ),
                          );
                        },
                        child: const Text('My Posts'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isVerified ? onCreatePost : null,
                        child: const Text('New Post'),
                      ),
                    ),
                  ],
                ),

                if (!isVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      isPending
                          ? 'You can post once verification is approved.'
                          : 'Verify your identity to create posts.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                /* ================= INFO ================= */

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      _InfoRow(label: 'Email', value: email),
                      _Divider(),
                      _InfoRow(label: 'Phone', value: phone),
                      _Divider(),
                      _InfoRow(label: 'User ID', value: user.uid),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /* ================= LOGOUT ================= */

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(
                            toggleTheme: toggleTheme,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ========================================================================== */
/*                               STATUS WIDGETS                               */
/* ========================================================================== */

class _VerificationStatusChip extends StatelessWidget {
  final bool isVerified;
  final bool isPending;

  const _VerificationStatusChip({
    required this.isVerified,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (isVerified) {
      color = Colors.green;
      text = 'Verified';
      icon = Icons.verified;
    } else if (isPending) {
      color = Colors.orange;
      text = 'Verification Pending';
      icon = Icons.hourglass_top;
    } else {
      color = Colors.redAccent;
      text = 'Unverified';
      icon = Icons.info_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(text),
      backgroundColor: color,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PendingVerificationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: const [
          Icon(Icons.hourglass_top, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your identity is under review. '
              'You’ll be notified once verification is complete.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/*                               UI HELPERS                                   */
/* ========================================================================== */

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.6,
      color: Theme.of(context).dividerColor,
    );
  }
}
