// © 2026 Project LostUAE

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/lost_report_model.dart';
import '../../services/certificate_service.dart';
import '../../services/mock_payment_service.dart';

class UnlockChatScreen extends StatefulWidget {
  final String caseId;

  const UnlockChatScreen({super.key, required this.caseId});

  @override
  State<UnlockChatScreen> createState() => _UnlockChatScreenState();
}

class _UnlockChatScreenState extends State<UnlockChatScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  int _unlockCount = 0;
  List<LostReportModel> _lostReports = [];
  String? _itemCategory;
  String? _selectedReportId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        CertificateService.getUserUnlockCount(),
        CertificateService.getUserLostReports(),
        CertificateService.getItemCategoryForCase(widget.caseId),
      ]);

      if (mounted) {
        setState(() {
          _unlockCount = results[0] as int;
          _lostReports = results[1] as List<LostReportModel>;
          _itemCategory = results[2] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load data. Please try again.');
      }
    }
  }

  // ─────────────────────────────────────────────
  // Unlock action
  // ─────────────────────────────────────────────
  Future<void> _onUnlockPressed() async {
    if (_selectedReportId == null) {
      _showErrorSnackBar('Please select a lost report to proceed.');
      return;
    }

    // Show loading dialog
    _showLoadingDialog();

    try {
      final result = await CertificateService.processUnlockWithPayment(
        caseId: widget.caseId,
        lostReportId: _selectedReportId!,
        unlockCount: _unlockCount,
      );

      // Dismiss loading dialog
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (result.success) {
        _showSuccessDialog(result.certificateCode ?? '');
      } else {
        _handleErrorCode(result.errorCode ?? 'unknown', result.errorMessage ?? '');
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    }
  }

  // ─────────────────────────────────────────────
  // Error code handler
  // ─────────────────────────────────────────────
  void _handleErrorCode(String code, String message) {
    String title;
    String body;

    switch (code) {
      case 'category_mismatch':
        title = 'Category Mismatch';
        body =
            'Your selected lost report category does not match the item category. '
            'Please select a report with the correct category.';
        break;
      case 'rate_limit_exceeded':
        title = 'Too Many Attempts';
        body =
            'You have exceeded the maximum number of unlock attempts. '
            'Please wait a moment before trying again.';
        break;
      case 'payment_required':
        title = 'Payment Required';
        body =
            'A payment of ${MockPaymentService.unlockPrice} ${MockPaymentService.currency} '
            'is required to unlock this chat.';
        break;
      case 'payment_failed':
        title = 'Payment Failed';
        body = 'Your payment could not be processed. Please try again.';
        break;
      default:
        title = 'Unlock Failed';
        body = message.isNotEmpty ? message : 'Unable to unlock chat. Please try again.';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dialogs
  // ─────────────────────────────────────────────
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Processing unlock request...')),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String certificateCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Chat Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your chat has been successfully unlocked.'),
            if (certificateCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Certificate Code:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                certificateCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // go back to chat
            },
            child: const Text('Go to Chat'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Button label
  // ─────────────────────────────────────────────
  String get _buttonLabel {
    if (_unlockCount == 0) {
      return 'Unlock Chat (Free First Time)';
    }
    return 'Pay ${MockPaymentService.unlockPrice.toStringAsFixed(0)} '
        '${MockPaymentService.currency} & Unlock Chat';
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Chat'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Chat is Locked',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'To unlock this chat, select one of your lost reports below. '
                  'The report category must match the item category'
                  '${_itemCategory != null ? ' (${ _itemCategory!})' : ''}.',
                  style: const TextStyle(fontSize: 13),
                ),
                if (_unlockCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'A payment of ${MockPaymentService.unlockPrice.toStringAsFixed(0)} '
                    '${MockPaymentService.currency} is required for subsequent unlocks.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Lost reports list ──
          const Text(
            'Select a Lost Report:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),

          if (_lostReports.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'You have no lost reports.\n'
                  'Please submit a lost report first to unlock this chat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _lostReports.length,
                itemBuilder: (context, index) {
                  final report = _lostReports[index];
                  final isSelected = _selectedReportId == report.reportId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.green
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Radio<String>(
                        value: report.reportId,
                        groupValue: _selectedReportId,
                        onChanged: (val) {
                          setState(() => _selectedReportId = val);
                        },
                        activeColor: Colors.green,
                      ),
                      title: Text(
                        report.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: ${report.category}'),
                          Text('Location: ${report.locationName}, ${report.emirate}'),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        setState(() => _selectedReportId = report.reportId);
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // ── Unlock button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedReportId != null ? _onUnlockPressed : null,
              icon: Icon(
                _unlockCount == 0 ? Icons.lock_open : Icons.payment,
              ),
              label: Text(_buttonLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
