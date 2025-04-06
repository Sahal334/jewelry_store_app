import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  @HiveField(5)
  double tax;

  @HiveField(6)
  double discount;

  @HiveField(7)
  int stockQuantity;

  @HiveField(8)
  String? imagePath;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.stockQuantity,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}