import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_tracker/domain/entities/alert_entity.dart';
import 'package:inventory_tracker/domain/entities/product_entity.dart';
import 'package:inventory_tracker/presentation/bloc/auth/auth_bloc.dart';
import 'package:inventory_tracker/presentation/bloc/product/product_bloc.dart';
import 'package:inventory_tracker/presentation/screens/dispatch_screen.dart';
import 'package:inventory_tracker/presentation/screens/receive_screen.dart';

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

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductErrorState) {
          return Center(
            child: Text(
              state.message,
              style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.error),
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
                if (state.alerts.isNotEmpty) _buildAlertsSection(context, state.alerts),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Inventory',
                        style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
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
                            style: theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
                Icon(Icons.warning_rounded, color: theme.colorScheme.onErrorContainer),
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
                  style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onErrorContainer),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductEntity product) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${product.quantity}', style: theme.textTheme.bodyMedium),
            if (product.isLowStock)
              Text('Threshold: ${product.threshold}', style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.error)),
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

  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create New Product', style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g., Laptop, T-shirt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description Field
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional: Product details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Threshold Field
                TextFormField(
                  controller: thresholdController,
                  decoration: InputDecoration(
                    labelText: 'Threshold',
                    hintText: 'Optional: Low stock alert number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
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
                onPressed: isLoading ? null : () {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text;
                    final description = descriptionController.text;
                    final threshold = int.tryParse(thresholdController.text) ?? 0;

                    context.read<ProductBloc>().add(CreateProductEvent(
                      name: name,
                      description: description,
                      threshold: threshold,
                    ));
                    
                    Navigator.pop(context);
                  }
                },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              );
            },
          ),
        ],
      );
    },
  );
}}