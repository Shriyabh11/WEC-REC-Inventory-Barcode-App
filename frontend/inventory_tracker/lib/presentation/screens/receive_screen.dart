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

  void _receiveItem(BuildContext context) {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }
    
    context.read<ProductBloc>().add(ReceiveItemEvent(
      productId: _selectedProduct!.id,
    ));
  }
  
  void _showBarcodeDisplayScreen(Map<String, dynamic> response) async {
    final qrImageBytes = await BarcodeUtils.generateQrCodeImage(response['barcode_data']);
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
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductsLoadedState && state.barcodeResponse != null) {
          _showBarcodeDisplayScreen(state.barcodeResponse!);
          // Once the response is handled, reset the barcodeResponse to avoid re-triggering
          context.read<ProductBloc>().add(FetchProductsEvent()); 
        } else if (state is ProductErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Select a product to receive:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: RadioListTile<ProductEntity>(
                          value: product,
                          groupValue: _selectedProduct,
                          onChanged: (value) => setState(() => _selectedProduct = value),
                          title: Text(product.name),
                          subtitle: Text('Current Stock: ${product.quantity}'),
                          secondary: product.isLowStock
                              ? const Icon(Icons.warning, color: Colors.orange)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedProduct == null) ? null : () => _receiveItem(context),
                      child: const Text('Generate Barcode & Receive Item'),
                    ),
                  ),
                ),
              ],
            );
          }
          return Container();
        },
      ),
    );
  }
}