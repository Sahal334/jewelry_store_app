import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jewelry_store_app/invoice_preview_screen.dart';
import 'package:jewelry_store_app/models/invoice_model.dart';
import 'package:jewelry_store_app/models/product_model.dart';
import 'package:jewelry_store_app/services/hive_services.dart';
import 'package:jewelry_store_app/services/pdf_servies.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<InvoiceItem> _selectedItems = [];
  String _searchQuery = '';
  
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _notesController = TextEditingController();

  double _subtotal = 0.0;
  double _taxAmount = 0.0;
  double _discountAmount = 0.0;
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    final products = HiveService.getAllProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addProductToInvoice(Product product) {
    // Check if product has sufficient stock
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is out of stock')),
      );
      return;
    }
    
    // Check if product is already in the invoice
    int existingIndex = _selectedItems.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex >= 0) {
      // Check if there's enough stock for the increased quantity
      InvoiceItem existingItem = _selectedItems[existingIndex];
      if (existingItem.quantity + 1 > product.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${product.name}')),
        );
        return;
      }
      
      // Update quantity of existing item
      setState(() {
        final updatedItem = InvoiceItem(
          productId: existingItem.productId,
          productName: existingItem.productName,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          tax: existingItem.tax,
          discount: existingItem.discount,
          subtotal: (existingItem.quantity + 1) * existingItem.price * 
                    (1 - existingItem.discount / 100) * (1 + existingItem.tax / 100),
        );
        _selectedItems[existingIndex] = updatedItem;
      });
    } else {
      // Add new item
      final double itemSubtotal = product.price * (1 - product.discount / 100) * (1 + product.tax / 100);
      
      setState(() {
        _selectedItems.add(
          InvoiceItem(
            productId: product.id,
            productName: product.name,
            price: product.price,
            quantity: 1,
            tax: product.tax,
            discount: product.discount,
            subtotal: itemSubtotal,
          ),
        );
      });
    }
    
    _calculateTotals();
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      setState(() {
        _selectedItems.removeAt(index);
      });
    } else {
      // Get the product to check stock
      final item = _selectedItems[index];
      final product = _allProducts.firstWhere((p) => p.id == item.productId);
      
      if (quantity > product.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough stock for ${product.name}')),
        );
        return;
      }
      
      setState(() {
        final updatedItem = InvoiceItem(
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: quantity,
          tax: item.tax,
          discount: item.discount,
          subtotal: quantity * item.price * (1 - item.discount / 100) * (1 + item.tax / 100),
        );
        _selectedItems[index] = updatedItem;
      });
    }
    
    _calculateTotals();
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
    
    _calculateTotals();
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double taxAmount = 0.0;
    double discountAmount = 0.0;
    
    for (var item in _selectedItems) {
      subtotal += item.price * item.quantity;
      taxAmount += item.price * item.quantity * (item.tax / 100);
      discountAmount += item.price * item.quantity * (item.discount / 100);
    }
    
    setState(() {
      _subtotal = subtotal;
      _taxAmount = taxAmount;
      _discountAmount = discountAmount;
      _total = subtotal + taxAmount - discountAmount;
    });
  }

  void _clearBill() {
    setState(() {
      _selectedItems.clear();
      _subtotal = 0.0;
      _taxAmount = 0.0;
      _discountAmount = 0.0;
      _total = 0.0;
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerEmailController.clear();
      _notesController.clear();
    });
  }

  Future<void> _generateInvoice() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the bill')),
      );
      return;
    }
    
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name')),
      );
      return;
    }
    
    final invoice = Invoice(
      id: const Uuid().v4(),
      date: DateTime.now(),
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null,
      customerEmail: _customerEmailController.text.isNotEmpty ? _customerEmailController.text : null,
      items: _selectedItems,
      subtotal: _subtotal,
      taxAmount: _taxAmount,
      discountAmount: _discountAmount,
      total: _total,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    
    // Save invoice to Hive
    await HiveService.saveInvoice(invoice);
    
    // Generate PDF with error handling
    try {
      final pdfFile = await PdfService.generateInvoice(invoice);
      
      // Show preview
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoicePreviewScreen(invoice: invoice, pdfFile: pdfFile),
          ),
        ).then((_) {
          // Clear bill after successful generation
          _clearBill();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearBill,
            tooltip: 'Clear Bill',
          ),
        ],
      ),
      body: Row(
        children: [
          // Products selection - Left side
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () => _addProductToInvoice(product),
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          image: product.imagePath != null
                                              ? DecorationImage(
                                                  image: FileImage(File(product.imagePath!)),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: product.imagePath == null ? Colors.grey[300] : null,
                                        ),
                                        child: product.imagePath == null
                                            ? const Center(
                                                child: Icon(Icons.image, size: 40, color: Colors.grey),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stock: ${product.stockQuantity}',
                                            style: TextStyle(
                                              color: product.stockQuantity > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          
          // Invoice details - Right side
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _customerEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedItems.isEmpty
                      ? const Center(
                          child: Text('No items added to the bill'),
                        )
                      : ListView.builder(
                          itemCount: _selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = _selectedItems[index];
                            return BillingItem(
                              item: item,
                              onQuantityChanged: (quantity) =>
                                  _updateItemQuantity(index, quantity),
                              onDelete: () => _removeItem(index),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Subtotal:', '\$${_subtotal.toStringAsFixed(2)}'),
                      _buildSummaryRow('Tax:', '\$${_taxAmount.toStringAsFixed(2)}'),
                      _buildSummaryRow('Discount:', '- \$${_discountAmount.toStringAsFixed(2)}'),
                      const Divider(),
                      _buildSummaryRow(
                        'Total:',
                        '\$${_total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generateInvoice,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Generate Invoice',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Add the missing BillingItem widget
class BillingItem extends StatelessWidget {
  final InvoiceItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onDelete;

  const BillingItem({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${item.price.toStringAsFixed(2)}'),
                if (item.discount > 0)
                  Text(
                    '${item.discount}% off',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => onQuantityChanged(item.quantity - 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => onQuantityChanged(item.quantity + 1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}