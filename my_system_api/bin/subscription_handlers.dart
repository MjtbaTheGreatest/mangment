import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:sqlite3/sqlite3.dart';

const String secretKey = 'your-super-secret-key-change-this-2024';

// ==================== Subscriptions Handlers ====================

Future<Response> getSubscriptionsHandler(Request request, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final result = db.select('''
      SELECT s.*, 
             (SELECT COUNT(*) FROM subscription_users WHERE subscription_id = s.id) as current_users
      FROM subscriptions s
      ORDER BY s.created_at DESC
    ''');

    final subscriptions = result.map((row) {
      return {
        'id': row['id'],
        'serviceName': row['service_name'],
        'accountNumber': row['account_number'],
        'cost': row['cost'],
        'maxUsers': row['max_users'],
        'currentUsers': row['current_users'] ?? 0,
        'startDate': row['start_date'],
        'endDate': row['end_date'],
        'email': row['email'],
        'password': row['password'],
        'createdBy': row['created_by'],
      };
    }).toList();

    return Response.ok(
        jsonEncode({
          'success': true,
          'subscriptions': subscriptions
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> createSubscriptionHandler(Request request, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    late JWT jwt;
    try {
      jwt = JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    final serviceName = data['serviceName'];
    final accountNumber = data['accountNumber'];
    final cost = data['cost'];
    final maxUsers = data['maxUsers'];
    final startDate = data['startDate'];
    final endDate = data['endDate'];
    final email = data['email'];
    final password = data['password'];
    final createdBy = jwt.payload['id'];

    if (serviceName == null || cost == null || maxUsers == null || 
        startDate == null || endDate == null) {
      return Response(400,
          body: jsonEncode({
            'success': false,
            'message': 'الرجاء إدخال جميع البيانات المطلوبة'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    db.execute('''
      INSERT INTO subscriptions (service_name, account_number, cost, max_users, 
                                start_date, end_date, email, password, created_by)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [serviceName, accountNumber, cost, maxUsers, startDate, endDate, 
          email, password, createdBy]);

    final insertedId = db.select('SELECT last_insert_rowid() as id').first['id'];

    print('✅ تم إضافة اشتراك جديد: $serviceName');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم إضافة الاشتراك بنجاح',
          'subscription': {
            'id': insertedId,
            'serviceName': serviceName,
            'accountNumber': accountNumber,
            'cost': cost,
            'maxUsers': maxUsers,
            'currentUsers': 0,
            'startDate': startDate,
            'endDate': endDate,
            'email': email,
            'password': password,
          }
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> updateSubscriptionHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final subscriptionId = int.tryParse(id);
    if (subscriptionId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف الاشتراك غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    db.execute('''
      UPDATE subscriptions 
      SET service_name = ?, account_number = ?, cost = ?, max_users = ?,
          start_date = ?, end_date = ?, email = ?, password = ?
      WHERE id = ?
    ''', [
      data['serviceName'],
      data['accountNumber'],
      data['cost'],
      data['maxUsers'],
      data['startDate'],
      data['endDate'],
      data['email'],
      data['password'],
      subscriptionId
    ]);

    print('✅ تم تحديث اشتراك: ${data['serviceName']}');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم تحديث الاشتراك بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> deleteSubscriptionHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final subscriptionId = int.tryParse(id);
    if (subscriptionId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف الاشتراك غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    db.execute('DELETE FROM subscriptions WHERE id = ?', [subscriptionId]);

    print('✅ تم حذف اشتراك: ID $subscriptionId');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم حذف الاشتراك بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> getSubscriptionUsersHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final subscriptionId = int.tryParse(id);
    if (subscriptionId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف الاشتراك غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final result = db.select('''
      SELECT * FROM subscription_users 
      WHERE subscription_id = ?
      ORDER BY created_at DESC
    ''', [subscriptionId]);

    final users = result.map((row) {
      return {
        'id': row['id'],
        'subscriptionId': row['subscription_id'],
        'customerName': row['customer_name'],
        'profileName': row['profile_name'],
        'amount': row['amount'],
        'startDate': row['start_date'],
        'endDate': row['end_date'],
        'addedBy': row['added_by'],
      };
    }).toList();

    return Response.ok(
        jsonEncode({
          'success': true,
          'users': users
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> addSubscriptionUserHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final subscriptionId = int.tryParse(id);
    if (subscriptionId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف الاشتراك غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final subscription = db.select(
      'SELECT max_users, (SELECT COUNT(*) FROM subscription_users WHERE subscription_id = ?) as current_users FROM subscriptions WHERE id = ?',
      [subscriptionId, subscriptionId]
    );

    if (subscription.isEmpty) {
      return Response(404,
          body: jsonEncode({'success': false, 'message': 'الاشتراك غير موجود'}),
          headers: {'Content-Type': 'application/json'});
    }

    final maxUsers = subscription.first['max_users'];
    final currentUsers = subscription.first['current_users'];

    if (currentUsers >= maxUsers) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'الاشتراك ممتلئ'}),
          headers: {'Content-Type': 'application/json'});
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    db.execute('''
      INSERT INTO subscription_users (subscription_id, customer_name, profile_name, 
                                     amount, start_date, end_date, added_by)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      subscriptionId,
      data['customerName'],
      data['profileName'],
      data['amount'],
      data['startDate'],
      data['endDate'],
      data['addedBy']
    ]);

    final insertedId = db.select('SELECT last_insert_rowid() as id').first['id'];

    print('✅ تم إضافة مستخدم للاشتراك: ${data['customerName']}');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم إضافة المستخدم بنجاح',
          'user': {
            'id': insertedId,
            'subscriptionId': subscriptionId,
            'customerName': data['customerName'],
            'profileName': data['profileName'],
            'amount': data['amount'],
            'startDate': data['startDate'],
            'endDate': data['endDate'],
            'addedBy': data['addedBy'],
          }
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> updateSubscriptionUserHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final userId = int.tryParse(id);
    if (userId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف المستخدم غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    db.execute('''
      UPDATE subscription_users 
      SET customer_name = ?, profile_name = ?, amount = ?,
          start_date = ?, end_date = ?
      WHERE id = ?
    ''', [
      data['customerName'],
      data['profileName'],
      data['amount'],
      data['startDate'],
      data['endDate'],
      userId
    ]);

    print('✅ تم تحديث مستخدم اشتراك: ${data['customerName']}');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم تحديث المستخدم بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> extendSubscriptionUserHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final userId = int.tryParse(id);
    if (userId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف المستخدم غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);
    final days = data['days'] ?? 30;

    final user = db.select('SELECT end_date FROM subscription_users WHERE id = ?', [userId]);
    if (user.isEmpty) {
      return Response(404,
          body: jsonEncode({'success': false, 'message': 'المستخدم غير موجود'}),
          headers: {'Content-Type': 'application/json'});
    }

    final currentEndDate = DateTime.parse(user.first['end_date']);
    final newEndDate = currentEndDate.add(Duration(days: days));

    db.execute('''
      UPDATE subscription_users 
      SET end_date = ?
      WHERE id = ?
    ''', [newEndDate.toIso8601String().split('T')[0], userId]);

    print('✅ تم تمديد اشتراك مستخدم بـ $days يوم');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم تمديد الاشتراك بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> deleteSubscriptionUserHandler(Request request, String id, Database db) async {
  try {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401,
          body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    try {
      JWT.verify(token, SecretKey(secretKey));
    } catch (e) {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final userId = int.tryParse(id);
    if (userId == null) {
      return Response(400,
          body: jsonEncode({'success': false, 'message': 'معرف المستخدم غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    db.execute('DELETE FROM subscription_users WHERE id = ?', [userId]);

    print('✅ تم حذف مستخدم اشتراك: ID $userId');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم حذف المستخدم بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}
