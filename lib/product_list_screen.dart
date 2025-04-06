import 'package:flutter/material.dart';
import 'package:jewelry_store_app/models/product_model.dart';
import 'package:jewelry_store_app/product_add_edit_screen.dart';
import 'package:jewelry_store_app/services/hive_services.dart';
import 'dart:io';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    final products = HiveService.getAllProducts();
    setState(() {
      _products = products;
      _filteredProducts = products;
      
      // Extract unique categories
      final categorySet = <String>{};
      for (var product in products) {
        categorySet.add(product.category);
      }
      _categories = ['All', ...categorySet.toList()];
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
      _applyFilters();
    }
  }

  void _deleteProduct(Product product) async {
    await HiveService.deleteProduct(product.id);
    _loadProducts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jewelry Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    onChanged: _onSearchChanged,
                    hintText: 'Search products...',
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Category'),
                  onChanged: _onCategoryChanged,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          _navigateToEditProduct(product);
                        },
                        onDelete: () {
                          _showDeleteConfirmation(product);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductAddEditScreen()),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _navigateToEditProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductAddEditScreen(product: product),
      ),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product);
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sort by Name (A-Z)'),
                onTap: () {
                  setState(() {
                    _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Sort by Name (Z-A)'),
                onTap: () {
                  setState(() {
                    _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Sort by Price (Low to High)'),
                onTap: () {
                  setState(() {
                    _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Sort by Price (High to Low)'),
                onTap: () {
                  setState(() {
                    _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final String hintText;

  const CustomSearchBar({
    Key? key,
    required this.onChanged,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
      ),
    );
  }
}


class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
   return Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: GestureDetector(
    onTap: onTap,

    child:Column(
      mainAxisSize: MainAxisSize.min, // ✨ prevents unbounded height
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: product.imagePath != null && product.imagePath!.isNotEmpty
              ? Image.file(
                  File(product.imagePath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                )
              : Container(
                  height: 120,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Remove Spacer and use SizedBox for spacing
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    )
  ),
);

  }
}