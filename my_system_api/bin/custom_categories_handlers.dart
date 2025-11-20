import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

const String secretKey = 'your-super-secret-key-change-this-2024';

// Middleware للتحقق من الـ token
Map<String, dynamic>? _verifyToken(Request request) {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(secretKey));
    return jwt.payload;
  } catch (e) {
    print('خطأ في التحقق من التوكن: $e');
    return null;
  }
}

/// GET /api/custom-categories - الحصول على الأقسام المخصصة للمستخدم
Future<Response> getCustomCategories(Request request, Database db) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];

  try {
    final categories = db.select('''
      SELECT 
        cc.*,
        COUNT(ccp.product_id) as products_count
      FROM custom_categories cc
      LEFT JOIN custom_category_products ccp ON cc.id = ccp.category_id
      WHERE cc.user_id = ?
      GROUP BY cc.id
      ORDER BY cc.created_at DESC
    ''', [userId]);

    final categoriesList = categories.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'user_id': row['user_id'],
      'products_count': row['products_count'],
      'created_at': row['created_at'],
    }).toList();

    return Response.ok(
      json.encode({'success': true, 'categories': categoriesList}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في جلب الأقسام المخصصة: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// POST /api/custom-categories - إنشاء قسم مخصص جديد
Future<Response> createCustomCategory(Request request, Database db) async {
  print('📥 طلب إنشاء قسم جديد');
  
  final payload = _verifyToken(request);
  if (payload == null) {
    print('❌ فشل التحقق من التوكن');
    return Response.forbidden(json.encode({'success': false, 'message': 'غير مصرح'}));
  }

  final userId = payload['id'];
  print('✅ المستخدم: $userId');
  
  final body = await request.readAsString();
  print('📝 البيانات المستلمة: $body');
  
  final data = json.decode(body);
  final name = data['name'];

  if (name == null || name.trim().isEmpty) {
    print('❌ اسم القسم فارغ');
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'اسم القسم مطلوب'}),
    );
  }

  try {
    db.execute('''
      INSERT INTO custom_categories (user_id, name, created_at)
      VALUES (?, ?, datetime('now'))
    ''', [userId, name]);

    final categoryId = db.lastInsertRowId;
    print('✅ تم إنشاء القسم بنجاح - ID: $categoryId');

    final response = json.encode({
      'success': true,
      'message': 'تم إنشاء القسم بنجاح',
      'category': {
        'id': categoryId,
        'name': name,
        'user_id': userId,
      },
    });
    
    print('📤 الاستجابة: $response');
    
    return Response.ok(
      response,
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إنشاء القسم: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم: $e'}),
    );
  }
}

/// DELETE /api/custom-categories/:id - حذف قسم مخصص
Future<Response> deleteCustomCategory(Request request, Database db, String categoryId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];

  try {
    // التحقق من أن القسم يخص المستخدم
    final category = db.select(
      'SELECT * FROM custom_categories WHERE id = ? AND user_id = ?',
      [int.parse(categoryId), userId],
    );

    if (category.isEmpty) {
      return Response.notFound(
        json.encode({'success': false, 'message': 'القسم غير موجود'}),
      );
    }

    // حذف القسم (CASCADE سيحذف المنتجات المرتبطة تلقائياً)
    db.execute('DELETE FROM custom_categories WHERE id = ?', [int.parse(categoryId)]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم حذف القسم بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في حذف القسم: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// GET /api/custom-categories/:id/products - الحصول على منتجات قسم معين
Future<Response> getCategoryProducts(Request request, Database db, String categoryId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  try {
    final products = db.select(
      'SELECT product_id FROM custom_category_products WHERE category_id = ?',
      [int.parse(categoryId)],
    );

    final productIds = products.map((row) => row['product_id']).toList();

    return Response.ok(
      json.encode({'success': true, 'product_ids': productIds}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في جلب منتجات القسم: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// POST /api/custom-categories/:id/products - إضافة منتج إلى قسم
Future<Response> addProductToCategory(Request request, Database db, String categoryId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];
  final body = await request.readAsString();
  final data = json.decode(body);
  final productId = data['product_id'];

  if (productId == null) {
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'معرف المنتج مطلوب'}),
    );
  }

  try {
    // التحقق من أن القسم يخص المستخدم
    final category = db.select(
      'SELECT * FROM custom_categories WHERE id = ? AND user_id = ?',
      [int.parse(categoryId), userId],
    );

    if (category.isEmpty) {
      return Response.forbidden(
        json.encode({'success': false, 'message': 'غير مصرح'}),
      );
    }

    // التحقق من عدم وجود المنتج مسبقاً
    final existing = db.select(
      'SELECT * FROM custom_category_products WHERE category_id = ? AND product_id = ?',
      [int.parse(categoryId), productId],
    );

    if (existing.isNotEmpty) {
      return Response.ok(
        json.encode({'success': true, 'message': 'المنتج موجود مسبقاً'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // إضافة المنتج
    db.execute('''
      INSERT INTO custom_category_products (category_id, product_id, added_at)
      VALUES (?, ?, datetime('now'))
    ''', [int.parse(categoryId), productId]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم إضافة المنتج بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في إضافة المنتج: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// DELETE /api/custom-categories/:id/products/:productId - إزالة منتج من قسم
Future<Response> removeProductFromCategory(
  Request request,
  Database db,
  String categoryId,
  String productId,
) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];

  try {
    // التحقق من أن القسم يخص المستخدم
    final category = db.select(
      'SELECT * FROM custom_categories WHERE id = ? AND user_id = ?',
      [int.parse(categoryId), userId],
    );

    if (category.isEmpty) {
      return Response.forbidden(
        json.encode({'success': false, 'message': 'غير مصرح'}),
      );
    }

    // إزالة المنتج
    db.execute(
      'DELETE FROM custom_category_products WHERE category_id = ? AND product_id = ?',
      [int.parse(categoryId), int.parse(productId)],
    );

    return Response.ok(
      json.encode({'success': true, 'message': 'تم إزالة المنتج بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في إزالة المنتج: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// GET /api/custom-categories/settings - الحصول على إعدادات الأقسام
Future<Response> getCustomCategoriesSettings(Request request, Database db) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];

  try {
    final settings = db.select(
      'SELECT share_with_employees FROM custom_categories_settings WHERE user_id = ?',
      [userId],
    );

    final shareWithEmployees = settings.isNotEmpty 
      ? settings.first['share_with_employees'] == 1
      : false;

    return Response.ok(
      json.encode({
        'success': true,
        'share_with_employees': shareWithEmployees,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في جلب الإعدادات: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// PUT /api/custom-categories/settings - تحديث إعدادات الأقسام
Future<Response> updateCustomCategoriesSettings(Request request, Database db) async {
  print('📥 طلب تحديث إعدادات المشاركة');
  
  final payload = _verifyToken(request);
  if (payload == null) {
    print('❌ فشل التحقق من التوكن');
    return Response.forbidden(json.encode({'success': false, 'message': 'غير مصرح'}));
  }

  final userId = payload['id'];
  print('✅ المستخدم: $userId');
  
  final body = await request.readAsString();
  print('📝 البيانات المستلمة: $body');
  
  final data = json.decode(body);
  final shareWithEmployees = data['share_with_employees'] ?? false;
  print('🔄 قيمة المشاركة الجديدة: $shareWithEmployees');

  try {
    // التحقق من وجود إعدادات
    final existing = db.select(
      'SELECT * FROM custom_categories_settings WHERE user_id = ?',
      [userId],
    );

    if (existing.isEmpty) {
      // إنشاء إعدادات جديدة
      print('➕ إنشاء إعدادات جديدة');
      db.execute('''
        INSERT INTO custom_categories_settings (user_id, share_with_employees)
        VALUES (?, ?)
      ''', [userId, shareWithEmployees ? 1 : 0]);
    } else {
      // تحديث الإعدادات
      print('🔄 تحديث الإعدادات الموجودة');
      db.execute('''
        UPDATE custom_categories_settings 
        SET share_with_employees = ?
        WHERE user_id = ?
      ''', [shareWithEmployees ? 1 : 0, userId]);
    }

    print('✅ تم تحديث الإعدادات بنجاح');
    
    return Response.ok(
      json.encode({'success': true, 'message': 'تم تحديث الإعدادات بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تحديث الإعدادات: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم: $e'}),
    );
  }
}

/// GET /api/custom-categories/all - الحصول على جميع الأقسام (للمدير فقط)
Future<Response> getAllCustomCategories(Request request, Database db) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final role = payload['role'];
  if (role != 'admin') {
    return Response.forbidden(
      json.encode({'success': false, 'message': 'غير مصرح'}),
    );
  }

  try {
    final categories = db.select('''
      SELECT 
        cc.*,
        u.name as user_name,
        u.username,
        s.share_with_employees,
        COUNT(ccp.product_id) as products_count
      FROM custom_categories cc
      JOIN users u ON cc.user_id = u.id
      LEFT JOIN custom_categories_settings s ON cc.user_id = s.user_id
      LEFT JOIN custom_category_products ccp ON cc.id = ccp.category_id
      GROUP BY cc.id
      ORDER BY cc.created_at DESC
    ''');

    final categoriesList = categories.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'user_id': row['user_id'],
      'user_name': row['user_name'],
      'username': row['username'],
      'share_with_employees': row['share_with_employees'] == 1,
      'products_count': row['products_count'],
      'created_at': row['created_at'],
    }).toList();

    return Response.ok(
      json.encode({'success': true, 'categories': categoriesList}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('خطأ في جلب جميع الأقسام: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}
