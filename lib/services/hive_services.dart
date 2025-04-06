import 'package:hive_flutter/hive_flutter.dart';
import 'package:jewelry_store_app/models/invoice_model.dart';
import 'package:jewelry_store_app/models/product_model.dart';
import 'package:path_provider/path_provider.dart';


class HiveService {
  static const String productBoxName = 'products';
  static const String invoiceBoxName = 'invoices';

  // Initialize Hive
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // Register adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(InvoiceAdapter());
    Hive.registerAdapter(InvoiceItemAdapter());
    
    // Open boxes
    await Hive.openBox<Product>(productBoxName);
    await Hive.openBox<Invoice>(invoiceBoxName);
  }

  // Product CRUD Operations
  static Future<String> addProduct(Product product) async {
    final box = Hive.box<Product>(productBoxName);
    await box.put(product.id, product);
    return product.id;
  }

  static Future<void> updateProduct(Product product) async {
    final box = Hive.box<Product>(productBoxName);
    await box.put(product.id, product);
  }

  static Future<void> deleteProduct(String id) async {
    final box = Hive.box<Product>(productBoxName);
    await box.delete(id);
  }

  static List<Product> getAllProducts() {
    final box = Hive.box<Product>(productBoxName);
    return box.values.toList();
  }

  static Product? getProductById(String id) {
    final box = Hive.box<Product>(productBoxName);
    return box.get(id);
  }

  // Invoice Operations
  static Future<String> saveInvoice(Invoice invoice) async {
    final box = Hive.box<Invoice>(invoiceBoxName);
    await box.put(invoice.id, invoice);
    return invoice.id;
  }

  static List<Invoice> getAllInvoices() {
    final box = Hive.box<Invoice>(invoiceBoxName);
    return box.values.toList();
  }

  static Invoice? getInvoiceById(String id) {
    final box = Hive.box<Invoice>(invoiceBoxName);
    return box.get(id);
  }

  static Future<void> deleteInvoice(String id) async {
    final box = Hive.box<Invoice>(invoiceBoxName);
    await box.delete(id);
  }
}