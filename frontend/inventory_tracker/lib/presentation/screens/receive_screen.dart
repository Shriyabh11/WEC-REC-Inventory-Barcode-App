import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/core/utils/barcode_utils.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:inventory_tracker/presentation/screens/barcode_display_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  _ReceiveScreenState createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  ProductEntity? _selectedProduct;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(FetchProductsEvent());
  }

  void _receiveItem(BuildContext context) {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    context.read<ProductBloc>().add(
          ReceiveItemEvent(
            productId: _selectedProduct!.id,
          ),
        );
  }

  void _showBarcodeDisplayScreen(Map<String, dynamic> response) async {
    final qrImageBytes =
        await BarcodeUtils.generateQrCodeImage(response['barcode_data']);
    final qrImageBase64 = base64Encode(qrImageBytes);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeDisplayScreen(
          barcodeData: response['barcode_data'],
          qrImage: qrImageBase64,
          productName: response['product_name'],
          newQuantity: response['new_quantity'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoadedState && state.barcodeResponse != null) {
          _showBarcodeDisplayScreen(state.barcodeResponse!);
        } else if (state is ProductErrorState) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductErrorState) {
            return Center(child: Text(state.message));
          }

          if (state is ProductsLoadedState) {
            final products = state.products;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select a product to receive:',
                    style: theme.textTheme.titleLarge!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            'No products available to receive.',
                            style: theme.textTheme.titleMedium!.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5)),
                          ),
                        )
                      : ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildProductRadioTile(context, product);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedProduct == null ||
                              state is ProductLoadingState)
                          ? null
                          : () => _receiveItem(context),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Generate Barcode & Receive Item'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProductRadioTile(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<ProductEntity>(
        value: product,
        groupValue: _selectedProduct,
        onChanged: (value) => setState(() => _selectedProduct = value),
        title: Text(product.name,
            style: theme.textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text('Current Stock: ${product.quantity}',
            style: theme.textTheme.bodyMedium),
        secondary: product.isLowStock
            ? Icon(Icons.warning_rounded, color: theme.colorScheme.error)
            : null,
      ),
    );
  }
}
