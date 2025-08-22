import 'dart:typed_data';

import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class BarcodeUtils {
  static Future<Uint8List> generateQrCodeImage(String data) async {
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
    );

    final picture = qrPainter.toPicture(200);
    final image = await picture.toImage(200, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
