import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jewelry_store_app/models/product_model.dart';
import 'package:jewelry_store_app/services/hive_services.dart';
import 'package:uuid/uuid.dart';
  File? imageFile;
class ProductAddEditScreen extends StatefulWidget {
  final Product? product;

  const ProductAddEditScreen({Key? key, this.product}) : super(key: key);

  @override
  _ProductAddEditScreenState createState() => _ProductAddEditScreenState();
}

class _ProductAddEditScreenState extends State<ProductAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stockController = TextEditingController();
  final _taxController = TextEditingController();
  final _discountController = TextEditingController();

  String _category = 'Rings';
  String? _imagePath;
  
  List<String> _categories = [
    'Rings', 'Necklaces', 'Earrings', 'Bracelets', 'Watches', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _stockController.text = widget.product!.stockQuantity.toString();
      _taxController.text = widget.product!.tax.toString();
      _discountController.text = widget.product!.discount.toString();
      _category = widget.product!.category;
      _imagePath = widget.product!.imagePath;
      if (_imagePath != null) {
        imageFile = File(_imagePath!);
      }
    } else {
      _taxController.text = '0.0';
      _discountController.text = '0.0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      
      final product = Product(
        id: widget.product?.id ?? const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        category: _category,
        description: _descriptionController.text,
        tax: double.parse(_taxController.text),
        discount: double.parse(_discountController.text),
        stockQuantity: int.parse(_stockController.text),
        imagePath: _imagePath,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.product == null) {
        await HiveService.addProduct(product);
      } else {
        await HiveService.updateProduct(product);
      }


      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text('Add Image'),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                            child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _category = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _taxController,
                        decoration: const InputDecoration(
                          labelText: 'Tax (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter tax';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        decoration: const InputDecoration(
                          labelText: 'Discount (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter discount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.product == null ? 'Add Product' : 'Update Product',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}