import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'qr system/qr_code_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
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
          final accountStatus = data['accountStatus'] ?? '';

          final bool isInvestigated = accountStatus == 'investigated';

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

                // ================= AVATAR =================

                Semantics(
                  label: 'Profile avatar for $nickname',
                  image: true,
                  child: Stack(
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
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  nickname,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                _VerificationStatusChip(
                  isVerified: isVerified,
                  isPending: isPending,
                  isInvestigated: isInvestigated,
                ),

                const SizedBox(height: 24),

                if (isInvestigated) _InvestigatedBanner(),
                if (isPending && !isInvestigated) _PendingVerificationBanner(),

                const SizedBox(height: 24),

                // ================= STATS =================

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

                // ================= ACCOUNT INFO =================

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
                      const Divider(height: 1),
                      _InfoRow(label: 'Phone', value: phone),
                      const Divider(height: 1),
                      _InfoRow(label: 'User ID', value: user.uid),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ================= QR CODE =================

                Semantics(
                  label: 'View my QR code',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('My QR Code'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QRCodeProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= LOGOUT =================

                Semantics(
                  label: 'Logout from account',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout from your account?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();

                          if (!context.mounted) return;
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
                        }
                      },
                    ),
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

/* ================= HELPER WIDGETS ================= */

class _VerificationStatusChip extends StatelessWidget {
  final bool isVerified;
  final bool isPending;
  final bool isInvestigated;

  const _VerificationStatusChip({
    required this.isVerified,
    required this.isPending,
    this.isInvestigated = false,
  });

  @override
  Widget build(BuildContext context) {
    // Investigated takes highest priority
    if (isInvestigated) {
      return const Chip(
        avatar: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
        label: Text('Investigated'),
        backgroundColor: Colors.deepOrange,
        labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }

    if (isVerified) {
      return const Chip(
        label: Text('Verified'),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    if (isPending) {
      return const Chip(
        label: Text('Verification Pending'),
        backgroundColor: Colors.orange,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    return const Chip(
      label: Text('Unverified'),
      backgroundColor: Colors.redAccent,
      labelStyle: TextStyle(color: Colors.white),
    );
  }
}

class _InvestigatedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel, color: Colors.deepOrange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your account has been flagged. Posting and chatting are disabled.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
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
      child: const Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your identity is under review.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
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
          Text(label),
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
