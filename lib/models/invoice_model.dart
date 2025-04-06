import 'package:hive/hive.dart';
 part 'invoice_model.g.dart';

@HiveType(typeId: 1)
class Invoice extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String customerName;

  @HiveField(3)
  String? customerPhone;

  @HiveField(4)
  String? customerEmail;

  @HiveField(5)
  List<InvoiceItem> items;

  @HiveField(6)
  double subtotal;

  @HiveField(7)
  double taxAmount;

  @HiveField(8)
  double discountAmount;

  @HiveField(9)
  double total;

  @HiveField(10)
  String? notes;

  Invoice({
    required this.id,
    required this.date,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    this.notes,
  });
}

@HiveType(typeId: 2)
class InvoiceItem {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double tax;

  @HiveField(5)
  double discount;

  @HiveField(6)
  double subtotal;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.tax,
    required this.discount,
    required this.subtotal,
  });
}