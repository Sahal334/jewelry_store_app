import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jewelry_store_app/product_list_screen.dart';
import 'package:jewelry_store_app/services/hive_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await HiveService.init(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jewelry Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ProductListScreen(),
    );
  }
}
