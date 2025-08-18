import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    _ProductListScreen(),
    ReceiveScreen(),
    const DispatchScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Receive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Dispatch',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _ProductListScreen extends StatefulWidget {
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
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ProductErrorState) {
          return Center(child: Text(state.message));
        }

        if (state is ProductsLoadedState) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(FetchProductsEvent());
            },
            child: Column(
              children: [
                if (state.alerts.isNotEmpty)
                  _buildAlertsSection(state.alerts),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Products',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showCreateProductDialog(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('Current Stock: ${product.quantity}'),
                        trailing: product.isLowStock
                            ? const Icon(Icons.warning, color: Colors.orange)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildAlertsSection(List<ProductEntity> alerts) {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Low Stock Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...alerts.map((alert) => Text(
            '${alert.name}: ${alert.quantity} of ${alert.threshold}',
            style: TextStyle(color: Colors.orange.shade800),
          )),
        ],
      ),
    );
  }

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final thresholdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name*'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: thresholdController,
                  decoration: const InputDecoration(labelText: 'Threshold'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name is required')));
                  return;
                }
                
                final name = nameController.text;
                final description = descriptionController.text;
                final threshold = int.tryParse(thresholdController.text) ?? 0;

                context.read<ProductBloc>().add(CreateProductEvent(
                  name: name,
                  description: description,
                  threshold: threshold,
                ));
                
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
