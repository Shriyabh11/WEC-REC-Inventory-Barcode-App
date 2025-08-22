import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarcodeDisplayScreen extends StatelessWidget {
  final String barcodeData;
  final String qrImage;
  final String productName;
  final int newQuantity;

  const BarcodeDisplayScreen({
    super.key,
    required this.barcodeData,
    required this.qrImage,
    required this.productName,
    required this.newQuantity,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: barcodeData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List imageBytes = base64Decode(qrImage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generated Barcode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Image.memory(
                      imageBytes,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'New Stock Count:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$newQuantity',
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Barcode Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        barcodeData,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Barcode Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
