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

// GET /api/orders - جلب جميع الطلبات
Future<Response> getOrders(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final results = db.select('SELECT * FROM orders WHERE archived = 0 ORDER BY created_at DESC');
    
    final orders = results.map((row) => {
      'id': row['id'],
      'product_id': row['product_id'],
      'product_name': row['product_name'],
      'customer_name': row['customer_name'],
      'customer_phone': row['customer_phone'],
      'cost': row['cost'],
      'price': row['price'],
      'profit': row['profit'],
      'payment_method': row['payment_method'],
      'status': row['status'],
      'category': row['category'],
      'employee_username': row['employee_username'],
      'notes': row['notes'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    }).toList();

    return Response.ok(
      json.encode({'orders': orders}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب الطلبات: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to fetch orders', 'details': e.toString()}),
    );
  }
}

// POST /api/orders - إضافة طلب جديد
Future<Response> createOrder(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
    
    final productId = body['product_id'] as int?;
    final productName = body['product_name'] as String?;
    final customerName = body['customer_name'] as String?;
    final customerPhone = body['customer_phone'] as String?;
    final cost = body['cost'] as num?;
    final price = body['price'] as num?;
    final profit = body['profit'] as num?;
    final paymentMethod = body['payment_method'] as String?;
    final category = body['category'] as String?;
    final employeeUsername = body['employee_username'] as String?;
    final notes = body['notes'] as String?;

    if (productName == null || productName.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'اسم المنتج مطلوب'}),
      );
    }

    if (customerName == null || customerName.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'اسم الزبون مطلوب'}),
      );
    }

    if (price == null || price <= 0) {
      return Response.badRequest(
        body: json.encode({'error': 'سعر البيع مطلوب'}),
      );
    }

    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      INSERT INTO orders (
        product_id, product_name, customer_name, customer_phone,
        cost, price, profit, payment_method, status, category,
        employee_username, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        productId ?? 0,
        productName,
        customerName,
        customerPhone ?? '',
        cost ?? 0,
        price,
        profit ?? 0,
        paymentMethod ?? 'زين كاش',
        'مكتمل',
        category ?? 'غير محدد',
        employeeUsername ?? 'unknown',
        notes ?? '',
        now,
        now,
      ],
    );

    // جلب آخر طلب تم إضافته
    final result = db.select('SELECT * FROM orders ORDER BY id DESC LIMIT 1');
    
    if (result.isEmpty) {
      return Response.internalServerError(
        body: json.encode({'error': 'Failed to retrieve created order'}),
      );
    }

    final row = result.first;
    final order = {
      'id': row['id'],
      'product_id': row['product_id'],
      'product_name': row['product_name'],
      'customer_name': row['customer_name'],
      'customer_phone': row['customer_phone'],
      'cost': row['cost'],
      'price': row['price'],
      'profit': row['profit'],
      'payment_method': row['payment_method'],
      'status': row['status'],
      'category': row['category'],
      'employee_username': row['employee_username'],
      'notes': row['notes'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    };

    print('✅ تم إضافة طلب جديد: ${order['product_name']} - ${order['customer_name']}');

    return Response.ok(
      json.encode({'message': 'تم تسجيل الطلب بنجاح', 'order': order}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إضافة الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to create order', 'details': e.toString()}),
    );
  }
}

// PUT /api/orders/<id> - تعديل كامل للطلب
Future<Response> updateOrder(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
    
    // التحقق من وجود الطلب
    final existingOrder = db.select('SELECT * FROM orders WHERE id = ?', [id]);
    if (existingOrder.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'الطلب غير موجود'}),
      );
    }

    // استخراج البيانات من الطلب
    final productName = body['product_name'] as String?;
    final customerName = body['customer_name'] as String?;
    final customerPhone = body['customer_phone'] as String?;
    final cost = body['cost'] as num?;
    final price = body['price'] as num?;
    final paymentMethod = body['payment_method'] as String?;
    final status = body['status'] as String?;
    final notes = body['notes'] as String?;

    // حساب الربح
    final profit = (price ?? 0) - (cost ?? 0);
    final now = DateTime.now().toIso8601String();

    // تحديث الطلب
    db.execute(
      '''
      UPDATE orders 
      SET product_name = ?, 
          customer_name = ?, 
          customer_phone = ?, 
          cost = ?, 
          price = ?, 
          profit = ?,
          payment_method = ?, 
          status = ?,
          notes = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        productName,
        customerName,
        customerPhone,
        cost,
        price,
        profit,
        paymentMethod,
        status,
        notes,
        now,
        id,
      ],
    );

    print('✅ تم تعديل الطلب #$id: $productName - $customerName');

    return Response.ok(
      json.encode({'message': 'تم تعديل الطلب بنجاح', 'success': true}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تعديل الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to update order', 'details': e.toString()}),
    );
  }
}

// PUT /api/orders/<id>/status - تحديث حالة الطلب فقط
Future<Response> updateOrderStatus(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (status == null || status.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'الحالة مطلوبة'}),
      );
    }

    final now = DateTime.now().toIso8601String();

    db.execute(
      '''
      UPDATE orders 
      SET status = ?, updated_at = ?
      WHERE id = ?
      ''',
      [status, now, id],
    );

    final result = db.select('SELECT * FROM orders WHERE id = ?', [id]);
    
    if (result.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'الطلب غير موجود'}),
      );
    }

    print('✅ تم تحديث حالة الطلب #$id إلى: $status');

    return Response.ok(
      json.encode({'message': 'تم تحديث حالة الطلب بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تحديث الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to update order', 'details': e.toString()}),
    );
  }
}

// DELETE /api/orders/<id> - حذف طلب
Future<Response> deleteOrder(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final result = db.select('SELECT product_name, customer_name FROM orders WHERE id = ?', [id]);
    
    if (result.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'الطلب غير موجود'}),
      );
    }

    final productName = result.first['product_name'];
    final customerName = result.first['customer_name'];

    db.execute('DELETE FROM orders WHERE id = ?', [id]);

    print('✅ تم حذف الطلب: $productName - $customerName');

    return Response.ok(
      json.encode({'message': 'تم حذف الطلب بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في حذف الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to delete order', 'details': e.toString()}),
    );
  }
}

// GET /api/orders/statistics - إحصائيات الطلبات
Future<Response> getOrdersStatistics(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final totalOrders = db.select('SELECT COUNT(*) as count FROM orders WHERE archived = 0').first['count'];
    final completedOrders = db.select('SELECT COUNT(*) as count FROM orders WHERE status = "مكتمل" AND archived = 0').first['count'];
    final cancelledOrders = db.select('SELECT COUNT(*) as count FROM orders WHERE status = "ملغي" AND archived = 0').first['count'];
    
    final totalRevenue = db.select('SELECT SUM(price) as total FROM orders WHERE status = "مكتمل" AND archived = 0').first['total'] ?? 0;
    final totalProfit = db.select('SELECT SUM(profit) as total FROM orders WHERE status = "مكتمل" AND archived = 0').first['total'] ?? 0;
    
    return Response.ok(
      json.encode({
        'total_orders': totalOrders,
        'completed_orders': completedOrders,
        'cancelled_orders': cancelledOrders,
        'total_revenue': totalRevenue,
        'total_profit': totalProfit,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب الإحصائيات: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to get statistics', 'details': e.toString()}),
    );
  }
}

// GET /api/orders/archived - جلب جميع الطلبات المؤرشفة
Future<Response> getArchivedOrders(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final results = db.select('SELECT * FROM orders WHERE archived = 1 ORDER BY created_at DESC');
    
    final orders = results.map((row) => {
      'id': row['id'],
      'product_id': row['product_id'],
      'product_name': row['product_name'],
      'customer_name': row['customer_name'],
      'customer_phone': row['customer_phone'],
      'cost': row['cost'],
      'price': row['price'],
      'profit': row['profit'],
      'payment_method': row['payment_method'],
      'status': row['status'],
      'category': row['category'],
      'employee_username': row['employee_username'],
      'notes': row['notes'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    }).toList();

    return Response.ok(
      json.encode(orders),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب الطلبات المؤرشفة: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to get archived orders', 'details': e.toString()}),
    );
  }
}

// POST /api/orders/:id/archive - أرشفة طلب
Future<Response> archiveOrder(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final orderId = int.parse(id);
    
    // التحقق من وجود الطلب
    final existing = db.select('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (existing.isEmpty) {
      return Response.notFound(json.encode({'error': 'Order not found'}));
    }

    // أرشفة الطلب
    db.execute('UPDATE orders SET archived = 1 WHERE id = ?', [orderId]);

    return Response.ok(
      json.encode({
        'success': true,
        'message': 'تم أرشفة الطلب بنجاح',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في أرشفة الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to archive order', 'details': e.toString()}),
    );
  }
}

// POST /api/orders/:id/unarchive - إلغاء أرشفة طلب
Future<Response> unarchiveOrder(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(json.encode({'error': 'Unauthorized'}));
  }

  try {
    final orderId = int.parse(id);
    
    // التحقق من وجود الطلب
    final existing = db.select('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (existing.isEmpty) {
      return Response.notFound(json.encode({'error': 'Order not found'}));
    }

    // إلغاء أرشفة الطلب
    db.execute('UPDATE orders SET archived = 0 WHERE id = ?', [orderId]);

    return Response.ok(
      json.encode({
        'success': true,
        'message': 'تم إلغاء أرشفة الطلب بنجاح',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إلغاء أرشفة الطلب: $e');
    return Response.internalServerError(
      body: json.encode({'error': 'Failed to unarchive order', 'details': e.toString()}),
    );
  }
}
