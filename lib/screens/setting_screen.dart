import 'package:flutter/material.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'privacy_policy_screen.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  

  Widget _item(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'),iconTheme: IconThemeData(color: Colors.white),),
      body: ListView(
        children: [
          _item(context, Icons.email, 'Change Email', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen()))),
          _item(context, Icons.lock, 'Change Password', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
          _item(context, Icons.privacy_tip, 'Privacy Policy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
          _item(context, Icons.delete_forever, 'Delete Account', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen()))),
        ],
      ),
    );
  }
}
