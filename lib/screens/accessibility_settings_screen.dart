// © 2026 Project LostUAE
// Joint work – All rights reserved
// Unauthorized use prohibited

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show colorBlindModeNotifier;

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  bool _ttsEnabled = false;
  bool _largeTextEnabled = false;
  bool _colorBlindMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _ttsEnabled = prefs.getBool('ttsEnabled') ?? false;
      _largeTextEnabled = prefs.getBool('largeTextEnabled') ?? false;
      _colorBlindMode = prefs.getBool('colorBlindMode') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _onTtsChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ttsEnabled', value);
    if (!mounted) return;
    setState(() => _ttsEnabled = value);
  }

  Future<void> _onLargeTextChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('largeTextEnabled', value);
    if (!mounted) return;
    setState(() => _largeTextEnabled = value);
  }

  Future<void> _onColorBlindModeChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('colorBlindMode', value);
    // Update the global notifier so the filter is applied immediately
    // across the entire app without requiring a restart.
    colorBlindModeNotifier.value = value;
    if (!mounted) return;
    setState(() => _colorBlindMode = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over),
                  title: const Text('Enable Text-to-Speech'),
                  subtitle: const Text('Read item descriptions aloud'),
                  value: _ttsEnabled,
                  onChanged: _onTtsChanged,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.text_fields),
                  title: const Text('Enable Large Text Mode'),
                  subtitle: const Text(
                    'Increases text size throughout the app (restart required)',
                  ),
                  value: _largeTextEnabled,
                  onChanged: _onLargeTextChanged,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.color_lens),
                  title: const Text('Enable Color Blind Mode'),
                  subtitle: const Text(
                    'Adjust colors to improve visibility for color vision deficiencies',
                  ),
                  value: _colorBlindMode,
                  onChanged: _onColorBlindModeChanged,
                ),
              ],
            ),
    );
  }
}
