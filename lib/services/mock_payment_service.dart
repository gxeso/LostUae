// © 2026 Project LostUAE

class MockPaymentService {
  static const double unlockPrice = 70.0;
  static const String currency = 'AED';

  static Future<bool> processPayment() async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  static bool isPaymentRequired(int unlockCount) {
    return unlockCount > 0;
  }

  static double getUnlockPrice() {
    return unlockPrice;
  }
}
