import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'server.dart' as server;

/// إنشاء جدول طرق الدفع
void initializePaymentMethodsTable() {
  server.db!.execute('''
    CREATE TABLE IF NOT EXISTS payment_methods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      is_active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  
  // إضافة طرق الدفع الافتراضية (من الطرق المستخدمة فعلياً في النظام)
  final count = server.db!.select('SELECT COUNT(*) as count FROM payment_methods');
  if (count.first['count'] == 0) {
    final defaultMethods = ['زين كاش', 'آفدين', 'آسياسيل', 'نقدي'];
    for (var method in defaultMethods) {
      try {
        server.db!.execute(
          'INSERT INTO payment_methods (name) VALUES (?)',
          [method],
        );
      } catch (e) {
        print('⚠️ طريقة الدفع "$method" موجودة مسبقاً');
      }
    }
    print('✅ تم إنشاء جدول طرق الدفع مع البيانات الافتراضية');
  }
}

/// الحصول على جميع طرق الدفع
Future<Response> getAllPaymentMethods(Request request) async {
  try {
    final results = server.db!.select('''
      SELECT id, name, is_active, created_at 
      FROM payment_methods 
      WHERE is_active = 1
      ORDER BY created_at ASC
    ''');

    final methods = results.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'is_active': row['is_active'],
      'created_at': row['created_at'],
    }).toList();

    return Response.ok(
      json.encode({'methods': methods}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: json.encode({'error': 'فشل تحميل طرق الدفع: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// إضافة طريقة دفع جديدة
Future<Response> addPaymentMethod(Request request) async {
  try {
    final body = await request.readAsString();
    final data = json.decode(body);
    final name = data['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'يجب إدخال اسم طريقة الدفع'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // التحقق من عدم وجود طريقة بنفس الاسم
    final existing = server.db!.select(
      'SELECT id FROM payment_methods WHERE name = ?',
      [name],
    );

    if (existing.isNotEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'طريقة الدفع موجودة مسبقاً'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    server.db!.execute(
      'INSERT INTO payment_methods (name) VALUES (?)',
      [name],
    );

    final id = server.db!.lastInsertRowId;

    return Response.ok(
      json.encode({
        'message': 'تمت الإضافة بنجاح',
        'id': id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: json.encode({'error': 'فشل إضافة طريقة الدفع: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// تعديل طريقة دفع
Future<Response> updatePaymentMethod(Request request, String id) async {
  try {
    final body = await request.readAsString();
    final data = json.decode(body);
    final name = data['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'يجب إدخال اسم طريقة الدفع'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // التحقق من وجود الطريقة
    final existing = server.db!.select(
      'SELECT id FROM payment_methods WHERE id = ?',
      [int.parse(id)],
    );

    if (existing.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'طريقة الدفع غير موجودة'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // التحقق من عدم تكرار الاسم
    final duplicate = server.db!.select(
      'SELECT id FROM payment_methods WHERE name = ? AND id != ?',
      [name, int.parse(id)],
    );

    if (duplicate.isNotEmpty) {
      return Response.badRequest(
        body: json.encode({'error': 'الاسم مستخدم لطريقة دفع أخرى'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    server.db!.execute(
      'UPDATE payment_methods SET name = ? WHERE id = ?',
      [name, int.parse(id)],
    );

    return Response.ok(
      json.encode({'message': 'تم التعديل بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: json.encode({'error': 'فشل تعديل طريقة الدفع: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// حذف طريقة دفع
Future<Response> deletePaymentMethod(Request request, String id) async {
  try {
    // التحقق من وجود الطريقة
    final existing = server.db!.select(
      'SELECT id, name FROM payment_methods WHERE id = ?',
      [int.parse(id)],
    );

    if (existing.isEmpty) {
      return Response.notFound(
        json.encode({'error': 'طريقة الدفع غير موجودة'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // تعطيل بدلاً من الحذف للحفاظ على البيانات التاريخية
    server.db!.execute(
      'UPDATE payment_methods SET is_active = 0 WHERE id = ?',
      [int.parse(id)],
    );

    return Response.ok(
      json.encode({'message': 'تم الحذف بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: json.encode({'error': 'فشل حذف طريقة الدفع: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
