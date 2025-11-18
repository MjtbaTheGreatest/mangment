import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const String secretKey = 'your-super-secret-key-change-this-2024';

// Middleware للتحقق من الـ token
Map<String, dynamic>? _verifyToken(Request request) {
  final authHeader = request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  try {
    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(secretKey));
    return jwt.payload as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}

// GET /api/products - جلب جميع المنتجات
Future<Response> getProducts(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final results = db.select('SELECT * FROM products ORDER BY created_at DESC');
    
    final products = results.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'cost_price': row['cost_price'] ?? 0,
      'sell_price': row['sell_price'] ?? 0,
      'category': row['category'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    }).toList();

    return Response.ok(
      json.encode({'products': products}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب المنتجات: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to fetch products', 'details': e.toString()}),
    );
  }
}

// GET /api/products/category/<category> - جلب المنتجات حسب الفئة
Future<Response> getProductsByCategory(Request request, Database db, String category) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final results = db.select(
      'SELECT * FROM products WHERE category = ? ORDER BY created_at DESC',
      [category],
    );
    
    final products = results.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'cost_price': row['cost_price'] ?? 0,
      'sell_price': row['sell_price'] ?? 0,
      'category': row['category'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    }).toList();

    return Response.ok(
      json.encode({'products': products}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب المنتجات حسب الفئة: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to fetch products by category', 'details': e.toString()}),
    );
  }
}

// POST /api/products - إضافة منتج جديد
Future<Response> createProduct(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
    
    final name = body['name'] as String?;
    final costPrice = body['cost_price'] as num?;
    final sellPrice = body['sell_price'] as num?;
    final category = body['category'] as String?;

    if (name == null || name.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'اسم المنتج مطلوب'}),
      );
    }

    if (category == null || category.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'الفئة مطلوبة'}),
      );
    }

    final now = DateTime.now().toIso8601String();
    
    // التأكد من القيم الرقمية
    final finalCostPrice = costPrice ?? 0;
    final finalSellPrice = sellPrice ?? 0;

    db.execute(
      '''
      INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [name, finalCostPrice, finalSellPrice, category, now, now],
    );

    // جلب آخر منتج تم إضافته
    final result = db.select('SELECT * FROM products ORDER BY id DESC LIMIT 1');
    
    if (result.isEmpty) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to retrieve created product'}),
      );
    }

    final row = result.first;
    final product = {
      'id': row['id'],
      'name': row['name'],
      'cost_price': row['cost_price'] ?? 0,
      'sell_price': row['sell_price'] ?? 0,
      'category': row['category'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    };

    print('✅ تم إضافة منتج جديد: ${product['name']}');

    return Response.ok(
      json.encode({'success': true, 'message': 'تم إضافة المنتج بنجاح', 'product': product}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إضافة المنتج: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to create product', 'details': e.toString()}),
    );
  }
}

// PUT /api/products/<id> - تحديث منتج
Future<Response> updateProduct(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
    
    final name = body['name'] as String?;
    final costPrice = body['cost_price'] as num?;
    final sellPrice = body['sell_price'] as num?;
    final category = body['category'] as String?;

    if (name == null || name.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'اسم المنتج مطلوب'}),
      );
    }

    if (category == null || category.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'الفئة مطلوبة'}),
      );
    }

    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      UPDATE products 
      SET name = ?, cost_price = ?, sell_price = ?, category = ?, updated_at = ?
      WHERE id = ?
      ''',
      [name, costPrice, sellPrice, category, now, id],
    );

    final result = db.select('SELECT * FROM products WHERE id = ?', [id]);
    
    if (result.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'المنتج غير موجود'}),
      );
    }

    final row = result.first;
    final product = {
      'id': row['id'],
      'name': row['name'],
      'cost_price': row['cost_price'] ?? 0,
      'sell_price': row['sell_price'] ?? 0,
      'category': row['category'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    };

    print('✅ تم تحديث المنتج: ${product['name']}');

    return Response.ok(
      json.encode({'message': 'تم تحديث المنتج بنجاح', 'product': product}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تحديث المنتج: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to update product', 'details': e.toString()}),
    );
  }
}

// DELETE /api/products/<id> - حذف منتج
Future<Response> deleteProduct(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final result = db.select('SELECT name FROM products WHERE id = ?', [id]);
    
    if (result.isEmpty) {
      return Response.notFound(
        json.encode({
          'success': false,
          'message': 'المنتج غير موجود'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final productName = result.first['name'];

    db.execute('DELETE FROM products WHERE id = ?', [id]);

    print('✅ تم حذف المنتج: $productName');

    return Response.ok(
      json.encode({
        'success': true,
        'message': 'تم حذف المنتج بنجاح'
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في حذف المنتج: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to delete product', 'details': e.toString()}),
    );
  }
}
