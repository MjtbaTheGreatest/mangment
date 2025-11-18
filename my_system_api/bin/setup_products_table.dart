import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Open database
  final dbPath = join(Directory.current.path, 'database.db');
  print('Opening database at: $dbPath');
  
  final db = await openDatabase(dbPath);

  // Create products table
  print('Creating products table...');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      cost_price REAL,
      sell_price REAL,
      category TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  // Check if table is empty
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM products')
  );

  if (count == 0) {
    print('Adding sample products...');
    
    // Add sample products
    await db.insert('products', {
      'name': 'PUBG Mobile',
      'cost_price': 4500,
      'sell_price': 5000,
      'category': 'ألعاب',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'name': 'Free Fire',
      'cost_price': 2700,
      'sell_price': 3000,
      'category': 'ألعاب',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'name': 'Netflix',
      'cost_price': 13500,
      'sell_price': 15000,
      'category': 'اشتراكات',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'name': 'Spotify',
      'cost_price': 7200,
      'sell_price': 8000,
      'category': 'اشتراكات',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'name': 'PSN Card',
      'cost_price': 22500,
      'sell_price': 25000,
      'category': 'ألعاب',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'name': 'iTunes',
      'cost_price': 9000,
      'sell_price': 10000,
      'category': 'اشتراكات',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    print('✅ Sample products added successfully!');
  } else {
    print('⚠️ Products table already has $count items');
  }

  // Display all products
  final products = await db.query('products');
  print('\n📦 Current Products:');
  for (var product in products) {
    print('  - ${product['name']} (${product['category']}) - ${product['sell_price']} د.ع');
  }

  await db.close();
  print('\n✅ Database setup completed!');
}
