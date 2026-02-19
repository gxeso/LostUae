import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeService {

  /// lostuae://profile/{userId}
  static String generateQRCodeURL(String userId) {
    return 'lostuae://profile/$userId';
  }

  static Future<Uint8List?> generateQRCodeImage({
    required String userId,
    required int size,
  }) async {
    try {
      final qrCodeUrl = generateQRCodeURL(userId);

      final imageData = await QrPainter(
        data: qrCodeUrl,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(size.toDouble());

      return imageData?.buffer.asUint8List();
    } catch (e) {
      print('QR generation error: $e');
      return null;
    }
  }
}
