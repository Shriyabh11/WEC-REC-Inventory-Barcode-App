import 'package:flutter/material.dart';

import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  _DispatchScreenState createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _scannedCode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
  }

  Future<void> _handleScannedCode(String code, BuildContext context) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedCode = code;
    });

    _scannerController.stop();

    context.read<ProductBloc>().add(DispatchItemEvent(barcodeData: code));
  }


  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Dispatch Failed'),
        content: Text(error.contains('already dispatched') 
                      ? 'This item has already been dispatched'
                      : 'Invalid barcode or item not found'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _scannedCode = null;
    });
    _scannerController.start();
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Barcode Entry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Barcode',
            hintText: 'e.g., 1|1|abc-123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _handleScannedCode(controller.text, context);
              }
            },
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoadedState) {
          // This state is emitted on a successful dispatch (due to FetchProductsEvent)
          // We can't get the specific response here, so we need to
          // show a generic success dialog or refactor the bloc further.
          // For now, let's assume success and close the dialog
          if (_isProcessing) {
             _resetScanner();
          }
        } else if (state is ProductErrorState) {
          if (_isProcessing) {
            _showErrorDialog(context, state.message);
          }
        }
      },
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && !_isProcessing) {
                  _handleScannedCode(barcodes.first.rawValue!, context);
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_scannedCode != null)
                    Text('Scanned: $_scannedCode', style: const TextStyle(fontFamily: 'monospace')),
                  if (_isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Processing...'),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scannerController.toggleTorch,
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Toggle Flash'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showManualEntryDialog,
                          icon: const Icon(Icons.edit),
                          label: const Text('Manual Entry'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
