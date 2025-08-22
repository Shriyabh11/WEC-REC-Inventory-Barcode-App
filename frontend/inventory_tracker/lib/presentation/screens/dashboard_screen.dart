import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:inventory_tracker/presentation/screens/dispatch_screen.dart';
import 'package:inventory_tracker/presentation/screens/receive_screen.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const _ProductListScreen(),
    const ReceiveScreen(),
    const DispatchScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Scanner',
          style: theme.textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: theme.colorScheme.primary,
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded),
            label: 'Receive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Dispatch',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
      ),
    );
  }
}

class _ProductListScreen extends StatefulWidget {
  const _ProductListScreen({super.key});

  @override
  __ProductListScreenState createState() => __ProductListScreenState();
}

class __ProductListScreenState extends State<_ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(FetchProductsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductCreatedState) {
          context.read<ProductBloc>().add(FetchProductsEvent());
        }
      },
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductErrorState) {
            return Center(
              child: Text(
                state.message,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.error),
              ),
            );
          }

          if (state is ProductsLoadedState) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductBloc>().add(FetchProductsEvent());
              },
              child: Column(
                children: [
                  if (state.alerts.isNotEmpty)
                    _buildAlertsSection(context, state.alerts),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Inventory',
                          style: theme.textTheme.headlineSmall!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          color: theme.colorScheme.primary,
                          onPressed: () => _showCreateProductDialog(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: state.products.isEmpty
                        ? Center(
                            child: Text(
                              'No products found. Tap "+" to add one!',
                              style: theme.textTheme.titleMedium!.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              final product = state.products[index];
                              return _buildProductCard(context, product);
                            },
                          ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<AlertEntity> alerts) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded,
                    color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts',
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alerts.map((alert) => Text(
                  '${alert.productName}: ${alert.currentQuantity} of ${alert.threshold}',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: theme.colorScheme.onErrorContainer),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);

    String? imageUrl;
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      if (product.imagePath!.startsWith('http')) {
        imageUrl = product.imagePath!;
      } else {
        imageUrl = 'http://10.0.2.2:5000/${product.imagePath!}';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: imageUrl != null
            ? Image.network(
                imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported,
                    size: 56,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
              )
            : Container(
                width: 56,
                height: 56,
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.image,
                    size: 32,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${product.quantity}',
                style: theme.textTheme.bodyMedium),
            if (product.isLowStock)
              Text('Threshold: ${product.threshold}',
                  style: theme.textTheme.bodySmall!
                      .copyWith(color: theme.colorScheme.error)),
          ],
        ),
        trailing: product.isLowStock
            ? Icon(Icons.warning_rounded, color: theme.colorScheme.error)
            : null,
      ),
    );
  }

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final thresholdController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    XFile? _selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Add New Product', style: theme.textTheme.titleLarge),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Name (mandatory)
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.label_important_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Description (mandatory)
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.description_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    // Threshold (mandatory)
                    TextFormField(
                      controller: thresholdController,
                      decoration: InputDecoration(
                        labelText: 'Low Stock Threshold *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Threshold is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Image Picker (mandatory)
                    OutlinedButton.icon(
                      icon: Icon(Icons.image, color: theme.colorScheme.primary),
                      label: Text(_selectedImage == null
                          ? 'Add Image'
                          : 'Change Image'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            _selectedImage = picked;
                          });
                        }
                      },
                    ),
                    if (_selectedImage == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0, left: 8.0),
                      ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  final isLoading = state is ProductLoadingState;
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            if (formKey.currentState!.validate() &&
                                _selectedImage != null) {
                              final name = nameController.text.trim();
                              final description =
                                  descriptionController.text.trim();
                              final threshold =
                                  int.tryParse(thresholdController.text) ?? 0;

                              context
                                  .read<ProductBloc>()
                                  .add(CreateProductEvent(
                                    name: name,
                                    description: description,
                                    threshold: threshold,
                                    imagePath: _selectedImage?.path,
                                  ));

                              Navigator.pop(context);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
