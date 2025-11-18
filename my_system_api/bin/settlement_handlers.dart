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

// GET /api/settlements/employee-stats - إحصائيات الموظف للتحاسب
Future<Response> getEmployeeSettlementStats(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
  }

  try {
    final userId = user['id'] is int ? user['id'] as int : int.tryParse(user['id'].toString()) ?? 0;
    final username = user['username'] as String?;
    
    if (username == null || username.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Username not found in token'}),
      );
    }
    
    // جلب جميع الطلبات (المؤرشفة وغير المؤرشفة) للموظف 
    // التي لم يتم تحاسبها بعد (غير مرتبطة بتحاسب معلق أو مقبول)
    final orders = db.select('''
      SELECT o.* FROM orders o
      WHERE o.employee_username = ?
      AND o.id NOT IN (
        SELECT so.order_id FROM settlement_orders so
        INNER JOIN settlements s ON so.settlement_id = s.id
        WHERE s.status IN ('pending', 'approved')
      )
      ORDER BY o.created_at DESC
    ''', [username]);

    // حساب الإحصائيات
    double totalSales = 0;
    double totalProfit = 0;
    int ordersCount = 0;
    Map<String, double> dailySales = {};
    List<Map<String, dynamic>> todayOrders = [];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    for (var order in orders) {
      final orderDate = DateTime.parse(order['created_at'] as String);
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      
      // فقط الطلبات من الشهر الحالي
      if (orderDate.isAfter(firstDayOfMonth) || orderDate.isAtSameMomentAs(firstDayOfMonth)) {
        final sellPrice = (order['price'] as num?)?.toDouble() ?? 0.0;
        final profit = (order['profit'] as num?)?.toDouble() ?? 0.0;
        
        totalSales += sellPrice;
        totalProfit += profit;
        ordersCount++;
        
        // تجميع المبيعات اليومية
        final dayKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
        dailySales[dayKey] = (dailySales[dayKey] ?? 0) + sellPrice;
        
        // الطلبات اليوم فقط
        if (orderDay.isAtSameMomentAs(today)) {
          todayOrders.add({
            'id': order['id'],
            'product_name': order['product_name'],
            'price': order['price'],
            'profit': order['profit'],
            'payment_method': order['payment_method'],
            'created_at': order['created_at'],
          });
        }
      }
    }

    // حساب مبلغ العمولة لكل طلب من قبل المدير
    final commissionPerOrder = await _getEmployeeCommissionPerOrder(db, userId);
    
    // حساب العمولة على أساس عدد الطلبات × المبلغ لكل طلب
    final estimatedCommission = ordersCount * commissionPerOrder;

    return Response.ok(
      jsonEncode({
        'success': true,
        'stats': {
          'totalSales': totalSales,
          'totalProfit': totalProfit,
          'ordersCount': ordersCount,
          'dailySales': dailySales,
          'todayOrders': todayOrders,
          'commissionRate': commissionPerOrder, // المبلغ لكل طلب
          'estimatedCommission': estimatedCommission,
          'monthYear': '${now.year}-${now.month}',
        }
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to load stats: $e'}),
    );
  }
}

// GET /api/settlements/commission-per-order/:userId - جلب مبلغ العمولة لكل طلب
Future<double> _getEmployeeCommissionPerOrder(Database db, int userId) async {
  try {
    final result = db.select(
      'SELECT commission_rate FROM employee_commissions WHERE user_id = ?',
      [userId],
    );
    
    if (result.isNotEmpty) {
      return (result.first['commission_rate'] as num?)?.toDouble() ?? 500.0;
    }
    return 500.0; // المبلغ الافتراضي لكل طلب (500 دينار)
  } catch (e) {
    return 500.0;
  }
}

// POST /api/settlements/request - طلب تحاسب جديد
Future<Response> createSettlementRequest(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
  }

  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final userId = user['id'] is int ? user['id'] as int : int.tryParse(user['id'].toString()) ?? 0;
    
    if (userId == 0) {
      return Response.badRequest(
        body: jsonEncode({'error': 'User ID not found'}),
      );
    }
    
    final totalOrders = data['totalOrders'] as int;
    final totalSales = data['totalSales'] as num;
    final commissionRate = data['commissionRate'] as num;
    final commissionAmount = data['commissionAmount'] as num;
    
    final username = user['username'] as String?;
    if (username == null || username.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Username not found in token'}),
      );
    }

    // التحقق من عدم وجود طلب تحاسب معلق
    final pendingCheck = db.select('''
      SELECT id FROM settlements 
      WHERE user_id = ? AND status = 'pending'
    ''', [userId]);

    if (pendingCheck.isNotEmpty) {
      return Response(400, body: jsonEncode({
        'success': false,
        'error': 'لديك طلب تحاسب معلق بالفعل. يرجى انتظار الموافقة عليه أولاً',
        'hasPending': true
      }));
    }

    // جلب معرفات جميع الطلبات للموظف (المؤرشفة وغير المؤرشفة)
    // التي لم يتم تحاسبها بعد
    final orders = db.select('''
      SELECT id FROM orders 
      WHERE employee_username = ?
      AND id NOT IN (
        SELECT so.order_id FROM settlement_orders so
        INNER JOIN settlements s ON so.settlement_id = s.id
        WHERE s.status IN ('pending', 'approved')
      )
    ''', [username]);
    
    final orderIds = orders.map((row) => row['id'] as int).toList();

    // إنشاء طلب التحاسب
    db.execute('''
      INSERT INTO settlements (
        user_id, total_orders, total_sales, commission_rate, 
        commission_amount, status, created_at
      ) VALUES (?, ?, ?, ?, ?, 'pending', datetime('now'))
    ''', [userId, totalOrders, totalSales, commissionRate, commissionAmount]);

    final settlementId = db.lastInsertRowId;

    // ربط الطلبات بالتحاسب
    for (var orderId in orderIds) {
      db.execute('''
        INSERT INTO settlement_orders (settlement_id, order_id)
        VALUES (?, ?)
      ''', [settlementId, orderId]);
    }

    return Response.ok(
      jsonEncode({
        'message': 'تم إرسال طلب التحاسب بنجاح',
        'settlementId': settlementId
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to create settlement: $e'}),
    );
  }
}

// GET /api/settlements/my-history - سجل التحاسبات للموظف
Future<Response> getEmployeeSettlementHistory(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null) {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized'}));
  }

  try {
    final userId = user['id'] is int ? user['id'] as int : int.tryParse(user['id'].toString()) ?? 0;
    
    final settlements = db.select('''
      SELECT s.*, u.name as employee_name
      FROM settlements s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.user_id = ?
      ORDER BY s.created_at DESC
    ''', [userId]);

    final result = settlements.map((row) => {
      'id': row['id'],
      'totalOrders': row['total_orders'],
      'totalSales': row['total_sales'],
      'commissionRate': row['commission_rate'],
      'commissionAmount': row['commission_amount'],
      'status': row['status'],
      'rejectionReason': row['rejection_reason'],
      'createdAt': row['created_at'],
      'processedAt': row['processed_at'],
    }).toList();

    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to load history: $e'}),
    );
  }
}

// GET /api/settlements/manager/pending - طلبات التحاسب المعلقة (للمدير فقط)
Future<Response> getPendingSettlements(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final settlements = db.select('''
      SELECT s.*, u.name as employee_name, u.username
      FROM settlements s
      LEFT JOIN users u ON s.user_id = u.id
      WHERE s.status = 'pending'
      ORDER BY s.created_at ASC
    ''');

    final result = settlements.map((row) => {
      'id': row['id'],
      'userId': row['user_id'],
      'employeeName': row['employee_name'],
      'username': row['username'],
      'totalOrders': row['total_orders'],
      'totalSales': row['total_sales'],
      'commissionRate': row['commission_rate'],
      'commissionAmount': row['commission_amount'],
      'createdAt': row['created_at'],
    }).toList();

    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to load settlements: $e'}),
    );
  }
}

// GET /api/settlements/manager/all - جميع التحاسبات (للمدير فقط)
Future<Response> getAllSettlements(Request request, Database db) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final settlements = db.select('''
      SELECT s.*, u.name as employee_name, u.username
      FROM settlements s
      LEFT JOIN users u ON s.user_id = u.id
      ORDER BY s.created_at DESC
    ''');

    final result = settlements.map((row) => {
      'id': row['id'],
      'userId': row['user_id'],
      'employeeName': row['employee_name'],
      'username': row['username'],
      'totalOrders': row['total_orders'],
      'totalSales': row['total_sales'],
      'commissionRate': row['commission_rate'],
      'commissionAmount': row['commission_amount'],
      'status': row['status'],
      'rejectionReason': row['rejection_reason'],
      'createdAt': row['created_at'],
      'processedAt': row['processed_at'],
    }).toList();

    return Response.ok(
      jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to load settlements: $e'}),
    );
  }
}

// POST /api/settlements/manager/approve/:id - الموافقة على التحاسب
Future<Response> approveSettlement(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    // تحديث حالة التحاسب فقط (بدون أرشفة تلقائية)
    db.execute('''
      UPDATE settlements 
      SET status = 'approved', processed_at = datetime('now')
      WHERE id = ?
    ''', [int.parse(id)]);

    // ملاحظة: الطلبات تبقى في إدارة الطلبات ولا تُؤرشف إلا يدوياً
    // تم إزالة الأرشفة التلقائية للطلبات

    return Response.ok(
      jsonEncode({'message': 'تمت الموافقة على التحاسب بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to approve settlement: $e'}),
    );
  }
}

// POST /api/settlements/manager/reject/:id - رفض التحاسب
Future<Response> rejectSettlement(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final reason = data['reason'] as String? ?? 'لم يتم تحديد السبب';

    db.execute('''
      UPDATE settlements 
      SET status = 'rejected', rejection_reason = ?, processed_at = datetime('now')
      WHERE id = ?
    ''', [reason, int.parse(id)]);

    return Response.ok(
      jsonEncode({'message': 'تم رفض التحاسب'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to reject settlement: $e'}),
    );
  }
}

// PUT /api/settlements/manager/commission/:userId - تحديث نسبة عمولة الموظف
Future<Response> updateEmployeeCommission(Request request, Database db, String userId) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final commissionRate = data['commissionRate'] as num;

    if (commissionRate <= 0) {
      return Response(400, body: jsonEncode({
        'error': 'مبلغ العمولة يجب أن يكون أكبر من صفر'
      }));
    }

    // التحقق من وجود سجل سابق
    final existing = db.select(
      'SELECT id FROM employee_commissions WHERE user_id = ?',
      [int.parse(userId)],
    );

    if (existing.isNotEmpty) {
      db.execute('''
        UPDATE employee_commissions 
        SET commission_rate = ?, updated_at = datetime('now')
        WHERE user_id = ?
      ''', [commissionRate, int.parse(userId)]);
    } else {
      db.execute('''
        INSERT INTO employee_commissions (user_id, commission_rate, created_at, updated_at)
        VALUES (?, ?, datetime('now'), datetime('now'))
      ''', [int.parse(userId), commissionRate]);
    }

    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'تم تحديث مبلغ العمولة بنجاح'
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'success': false,
        'error': 'Failed to update commission: $e'
      }),
    );
  }
}

// GET /api/settlements/manager/commission/:userId - جلب نسبة عمولة الموظف
Future<Response> getEmployeeCommission(Request request, Database db, String userId) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final rate = await _getEmployeeCommissionPerOrder(db, int.parse(userId));
    
    return Response.ok(
      jsonEncode({
        'success': true,
        'commissionRate': rate
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'success': false,
        'error': 'Failed to get commission: $e'
      }),
    );
  }
}

// DELETE /api/settlements/manager/:id - حذف تحاسب (للمدير فقط)
Future<Response> deleteSettlement(Request request, Database db, String id) async {
  final user = _verifyToken(request);
  if (user == null || user['role'] != 'admin') {
    return Response.forbidden(jsonEncode({'error': 'Unauthorized - Manager only'}));
  }

  try {
    final settlementId = int.parse(id);
    
    // التحقق من وجود التحاسب
    final settlement = db.select(
      'SELECT id, status FROM settlements WHERE id = ?',
      [settlementId],
    );
    
    if (settlement.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'التحاسب غير موجود'}),
      );
    }

    // حذف العلاقات من settlement_orders أولاً
    db.execute('''
      DELETE FROM settlement_orders WHERE settlement_id = ?
    ''', [settlementId]);

    // حذف التحاسب
    db.execute('''
      DELETE FROM settlements WHERE id = ?
    ''', [settlementId]);

    return Response.ok(
      jsonEncode({
        'success': true,
        'message': 'تم حذف التحاسب بنجاح'
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'success': false,
        'error': 'Failed to delete settlement: $e'
      }),
    );
  }
}
