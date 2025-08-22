import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';

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

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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

  void _showSuccessDialog(String message, ProductEntity product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Dispatch Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text('Product: ${product.name}'),
            Text('New Quantity: ${product.quantity}'),
          ],
        ),
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

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Dispatch Failed'),
          ],
        ),
        content: Text(
          error.contains('already dispatched')
              ? 'This item has already been dispatched.'
              : 'Invalid barcode or item not found.',
        ),
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Manual Barcode Entry'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Enter Barcode',
              hintText: 'e.g., 1|1|abc-123',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a barcode';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
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
    final theme = Theme.of(context);

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (_isProcessing) {
          setState(() {
            _isProcessing = false;
          });
        }

        if (state is ProductActionSuccessState) {
          final updatedProduct = state.products.firstWhere(
            (product) =>
                product.items.any((item) => item.barcode == _scannedCode),
            orElse: () => const ProductEntity(
              id: 0,
              name: 'Unknown',
              quantity: 0,
              threshold: 0,
              description: '',
              isLowStock: false,
              items: [],
            ),
          );
          _showSuccessDialog(state.message, updatedProduct);
        } else if (state is ProductErrorState) {
          _showErrorDialog(state.message);
        }
      },
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_isProcessing) {
                      _handleScannedCode(barcodes.first.rawValue!, context);
                    }
                  },
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isProcessing ? 'Processing...' : 'Scan Barcode',
                      style: theme.textTheme.titleLarge!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
                if (_isProcessing)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_scannedCode != null && !_isProcessing)
                    Text(
                      'Last Scanned: $_scannedCode',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (_isProcessing)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Dispatching item...'),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessing ? null : _showManualEntryDialog,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Manual'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
