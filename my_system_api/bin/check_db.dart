import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open('database.db');
  
  print('=== التحقق من القسم 3 ===');
  
  // 1. التحقق من القسم نفسه
  final categories = db.select('SELECT * FROM custom_categories WHERE id = 3');
  print('\n📁 بيانات القسم:');
  for (final row in categories) {
    print('  ID: ${row['id']}');
    print('  Name: ${row['name']}');
    print('  User ID: ${row['user_id']}');
  }
  
  // 2. التحقق من المنتجات المرتبطة
  final products = db.select('SELECT * FROM custom_category_products WHERE category_id = 3');
  print('\n📦 المنتجات في القسم:');
  if (products.isEmpty) {
    print('  ❌ لا توجد منتجات!');
  } else {
    for (final row in products) {
      print('  Category ID: ${row['category_id']}, Product ID: ${row['product_id']}');
    }
  }
  
  // 3. عرض كل محتوى الجدول
  final allProducts = db.select('SELECT * FROM custom_category_products');
  print('\n📋 جميع المنتجات في الجداول:');
  if (allProducts.isEmpty) {
    print('  ❌ الجدول فارغ تماماً!');
  } else {
    for (final row in allProducts) {
      print('  Category ${row['category_id']} -> Product ${row['product_id']}');
    }
  }
  
  db.dispose();
}
