import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// التحقق من صحة الـ JWT token
Map<String, dynamic>? _verifyToken(Request request) {
  final authHeader = request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  final token = authHeader.substring(7);
  try {
    final jwt = JWT.verify(token, SecretKey('your-super-secret-key-change-this-2024'));
    final payload = jwt.payload as Map<String, dynamic>;
    
    // التحقق من انتهاء الصلاحية
    final exp = payload['exp'];
    if (exp != null && DateTime.now().millisecondsSinceEpoch > exp * 1000) {
      return null;
    }
    
    return payload;
  } catch (e) {
    print('❌ خطأ في فك تشفير JWT: $e');
    return null;
  }
}

/// GET /api/shared-games - الحصول على جميع الألعاب المشتركة
Future<Response> getSharedGames(Request request, Database db) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  try {
    final games = db.select('''
      SELECT 
        sg.*,
        u.name as creator_name,
        COUNT(sgc.id) as customers_count
      FROM shared_games sg
      LEFT JOIN users u ON sg.created_by = u.id
      LEFT JOIN shared_game_customers sgc ON sg.id = sgc.game_id
      GROUP BY sg.id
      ORDER BY sg.created_at DESC
    ''');

    final gamesList = games.map((row) {
      return {
        'id': row['id'],
        'game_name': row['game_name'],
        'email': row['email'],
        'password': row['password'],
        'max_users': row['max_users'],
        'notes': row['notes'],
        'created_at': row['created_at'],
        'creator_name': row['creator_name'],
        'customers_count': row['customers_count'],
      };
    }).toList();

    return Response.ok(
      json.encode({'success': true, 'games': gamesList}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب الألعاب: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// POST /api/shared-games - إنشاء لعبة مشتركة جديدة
Future<Response> createSharedGame(Request request, Database db) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userId = payload['id'];
  final body = await request.readAsString();
  final data = json.decode(body);

  final gameName = data['game_name'];
  final email = data['email'];
  final password = data['password'];
  final maxUsers = data['max_users'] ?? 1;
  final notes = data['notes'];

  if (gameName == null || gameName.toString().trim().isEmpty) {
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'اسم اللعبة مطلوب'}),
    );
  }

  try {
    print('📥 إنشاء لعبة مشتركة جديدة: $gameName');
    print('✅ المستخدم: $userId');

    db.execute('''
      INSERT INTO shared_games (game_name, email, password, max_users, notes, created_by)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [gameName, email, password, maxUsers, notes, userId]);

    final gameId = db.select('SELECT last_insert_rowid() as id').first['id'];
    print('✅ تم إنشاء اللعبة بنجاح - ID: $gameId');

    return Response.ok(
      json.encode({
        'success': true,
        'message': 'تم إنشاء اللعبة بنجاح',
        'game': {
          'id': gameId,
          'game_name': gameName,
          'email': email,
          'password': password,
          'max_users': maxUsers,
          'notes': notes,
        },
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إنشاء اللعبة: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم: $e'}),
    );
  }
}

/// GET /api/shared-games/:id/customers - الحصول على عملاء لعبة معينة
Future<Response> getGameCustomers(Request request, Database db, String gameId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  try {
    final customers = db.select('''
      SELECT * FROM shared_game_customers
      WHERE game_id = ?
      ORDER BY created_at DESC
    ''', [int.parse(gameId)]);

    final customersList = customers.map((row) {
      return {
        'id': row['id'],
        'game_id': row['game_id'],
        'customer_name': row['customer_name'],
        'device_name': row['device_name'],
        'amount_paid': row['amount_paid'],
        'purchase_date': row['purchase_date'],
        'notes': row['notes'],
        'created_at': row['created_at'],
        'created_by': row['created_by'],
      };
    }).toList();

    return Response.ok(
      json.encode({'success': true, 'customers': customersList}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في جلب العملاء: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// POST /api/shared-games/:id/customers - إضافة عميل إلى لعبة
Future<Response> addGameCustomer(Request request, Database db, String gameId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final createdBy = payload['name'] ?? payload['username'] ?? 'unknown';
  final body = await request.readAsString();
  final data = json.decode(body);

  final customerName = data['customer_name'];
  final deviceName = data['device_name'];
  final amountPaid = data['amount_paid'];
  final purchaseDate = data['purchase_date'];
  final notes = data['notes'];

  if (customerName == null || customerName.toString().trim().isEmpty) {
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'اسم الزبون مطلوب'}),
    );
  }

  try {
    // التحقق من عدم تجاوز العدد الأقصى
    final game = db.select('SELECT max_users FROM shared_games WHERE id = ?', [int.parse(gameId)]);
    if (game.isEmpty) {
      return Response.notFound(
        json.encode({'success': false, 'message': 'اللعبة غير موجودة'}),
      );
    }

    final maxUsers = game.first['max_users'] as int;
    final currentCount = db.select(
      'SELECT COUNT(*) as count FROM shared_game_customers WHERE game_id = ?',
      [int.parse(gameId)],
    ).first['count'] as int;

    if (currentCount >= maxUsers) {
      return Response.badRequest(
        body: json.encode({
          'success': false,
          'message': 'تم الوصول للحد الأقصى من المستخدمين ($maxUsers)',
        }),
      );
    }

    db.execute('''
      INSERT INTO shared_game_customers 
      (game_id, customer_name, device_name, amount_paid, purchase_date, notes, created_by)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [int.parse(gameId), customerName, deviceName, amountPaid, purchaseDate, notes, createdBy]);

    final customerId = db.select('SELECT last_insert_rowid() as id').first['id'];

    return Response.ok(
      json.encode({
        'success': true,
        'message': 'تم إضافة الزبون بنجاح',
        'customer_id': customerId,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في إضافة الزبون: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم: $e'}),
    );
  }
}

/// PUT /api/shared-game-customers/:id - تحديث بيانات عميل
Future<Response> updateGameCustomer(Request request, Database db, String customerId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final body = await request.readAsString();
  final data = json.decode(body);

  final customerName = data['customer_name'];
  final deviceName = data['device_name'];
  final amountPaid = data['amount_paid'];
  final purchaseDate = data['purchase_date'];
  final notes = data['notes'];

  if (customerName == null || customerName.toString().trim().isEmpty) {
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'اسم الزبون مطلوب'}),
    );
  }

  try {
    db.execute('''
      UPDATE shared_game_customers
      SET customer_name = ?, device_name = ?, amount_paid = ?, purchase_date = ?, notes = ?
      WHERE id = ?
    ''', [customerName, deviceName, amountPaid, purchaseDate, notes, int.parse(customerId)]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم تحديث البيانات بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تحديث البيانات: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// DELETE /api/shared-game-customers/:id - حذف عميل
Future<Response> deleteGameCustomer(Request request, Database db, String customerId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  try {
    db.execute('DELETE FROM shared_game_customers WHERE id = ?', [int.parse(customerId)]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم حذف الزبون بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في حذف الزبون: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// DELETE /api/shared-games/:id - حذف لعبة (مع جميع العملاء)
Future<Response> deleteSharedGame(Request request, Database db, String gameId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final userRole = payload['role'];
  
  // فقط المدراء يمكنهم حذف الألعاب
  if (userRole != 'admin') {
    return Response.forbidden(
      json.encode({'success': false, 'message': 'غير مصرح لك بحذف الألعاب'}),
    );
  }

  try {
    // CASCADE سيحذف جميع العملاء تلقائياً
    db.execute('DELETE FROM shared_games WHERE id = ?', [int.parse(gameId)]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم حذف اللعبة بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في حذف اللعبة: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}

/// PUT /api/shared-games/:id - تحديث بيانات لعبة
Future<Response> updateSharedGame(Request request, Database db, String gameId) async {
  final payload = _verifyToken(request);
  if (payload == null) {
    return Response.forbidden(json.encode({'message': 'غير مصرح'}));
  }

  final body = await request.readAsString();
  final data = json.decode(body);

  final gameName = data['game_name'];
  final email = data['email'];
  final password = data['password'];
  final maxUsers = data['max_users'];
  final notes = data['notes'];

  if (gameName == null || gameName.toString().trim().isEmpty) {
    return Response.badRequest(
      body: json.encode({'success': false, 'message': 'اسم اللعبة مطلوب'}),
    );
  }

  try {
    db.execute('''
      UPDATE shared_games
      SET game_name = ?, email = ?, password = ?, max_users = ?, notes = ?
      WHERE id = ?
    ''', [gameName, email, password, maxUsers, notes, int.parse(gameId)]);

    return Response.ok(
      json.encode({'success': true, 'message': 'تم تحديث اللعبة بنجاح'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    print('❌ خطأ في تحديث اللعبة: $e');
    return Response.internalServerError(
      body: json.encode({'success': false, 'message': 'خطأ في الخادم'}),
    );
  }
}
