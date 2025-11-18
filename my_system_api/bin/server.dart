import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'subscription_handlers.dart' as sub;
import 'product_handlers.dart' as prod;
import 'order_handlers.dart' as ord;
import 'settlement_handlers.dart' as settle;

const String secretKey = 'your-super-secret-key-change-this-2024';
const int port = 53365;
const String dbPath = 'database.db';

Database? db;

void main() async {
  db = sqlite3.open('database.db');
  
  db!.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT DEFAULT 'employee',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // إضافة عمود name للجدول الموجود (إذا لم يكن موجوداً)
  try {
    db!.execute('ALTER TABLE users ADD COLUMN name TEXT DEFAULT ""');
    print('✅ تم إضافة حقل الاسم لقاعدة البيانات');
  } catch (e) {
    // العمود موجود مسبقاً
  }

  // جدول الاشتراكات
  db!.execute('''
    CREATE TABLE IF NOT EXISTS subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      service_name TEXT NOT NULL,
      account_number TEXT,
      cost REAL NOT NULL,
      max_users INTEGER NOT NULL,
      current_users INTEGER DEFAULT 0,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      email TEXT,
      password TEXT,
      created_by INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (created_by) REFERENCES users(id)
    )
  ''');

  // جدول مستخدمي الاشتراكات
  db!.execute('''
    CREATE TABLE IF NOT EXISTS subscription_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subscription_id INTEGER NOT NULL,
      customer_name TEXT NOT NULL,
      profile_name TEXT NOT NULL,
      amount REAL NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      added_by TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
    )
  ''');

  // جدول المنتجات
  db!.execute('''
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

  // جدول الطلبات
  db!.execute('''
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      customer_name TEXT NOT NULL,
      customer_phone TEXT,
      cost REAL NOT NULL,
      price REAL NOT NULL,
      profit REAL NOT NULL,
      payment_method TEXT NOT NULL,
      status TEXT DEFAULT 'مكتمل',
      category TEXT NOT NULL,
      employee_username TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      archived INTEGER DEFAULT 0
    )
  ''');

  // جدول رأس المال والعمليات المالية
  db!.execute('''
    CREATE TABLE IF NOT EXISTS capital_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      amount REAL NOT NULL,
      description TEXT,
      created_by TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // جدول التحاسبات
  db!.execute('''
    CREATE TABLE IF NOT EXISTS settlements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      total_orders INTEGER NOT NULL,
      total_sales REAL NOT NULL,
      commission_rate REAL NOT NULL,
      commission_amount REAL NOT NULL,
      status TEXT DEFAULT 'pending',
      rejection_reason TEXT,
      created_at TEXT NOT NULL,
      processed_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''');

  // جدول الطلبات المرتبطة بالتحاسبات
  db!.execute('''
    CREATE TABLE IF NOT EXISTS settlement_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      settlement_id INTEGER NOT NULL,
      order_id INTEGER NOT NULL,
      FOREIGN KEY (settlement_id) REFERENCES settlements(id) ON DELETE CASCADE,
      FOREIGN KEY (order_id) REFERENCES orders(id)
    )
  ''');

  // جدول نسب العمولات لكل موظف
  db!.execute('''
    CREATE TABLE IF NOT EXISTS employee_commissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      commission_rate REAL DEFAULT 5.0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''');

  final adminPassword = hashPassword('admin123');
  try {
    db!.execute('''
      INSERT INTO users (username, password, name, role) 
      VALUES ('admin', '$adminPassword', 'المدير العام', 'admin')
    ''');
    print('✅ تم إنشاء حساب المدير');
  } catch (e) {
    print('Admin user already exists');
    // تحديث اسم المدير إذا كان فارغاً
    db!.execute('''
      UPDATE users SET name = 'المدير العام' WHERE username = 'admin' AND (name IS NULL OR name = '')
    ''');
  }
  
  // إضافة بيانات تجريبية للاشتراكات (إذا كانت قاعدة البيانات فارغة)
  final subsCount = db!.select('SELECT COUNT(*) as count FROM subscriptions').first['count'];
  if (subsCount == 0) {
    print('📝 إضافة بيانات تجريبية للاشتراكات...');
    
    // إضافة اشتراك Netflix
    db!.execute('''
      INSERT INTO subscriptions (service_name, account_number, cost, max_users, start_date, end_date, email, password, created_by)
      VALUES ('Netflix', 'NF-12345', 15000, 5, '2025-01-01', '2025-12-31', 'netflix@example.com', 'pass123', 1)
    ''');
    
    final netflixId = db!.select('SELECT last_insert_rowid() as id').first['id'];
    
    // إضافة مستخدمين لـ Netflix
    db!.execute('''
      INSERT INTO subscription_users (subscription_id, customer_name, profile_name, amount, start_date, end_date, added_by)
      VALUES (?, 'أحمد محمد', 'Profile 1', 3000, '2025-01-01', '2025-02-01', 'المدير العام')
    ''', [netflixId]);
    
    db!.execute('''
      INSERT INTO subscription_users (subscription_id, customer_name, profile_name, amount, start_date, end_date, added_by)
      VALUES (?, 'فاطمة علي', 'Profile 2', 3000, '2025-01-05', '2025-02-05', 'المدير العام')
    ''', [netflixId]);
    
    // إضافة اشتراك Shahid
    db!.execute('''
      INSERT INTO subscriptions (service_name, account_number, cost, max_users, start_date, end_date, email, password, created_by)
      VALUES ('Shahid VIP', 'SH-98765', 12000, 4, '2025-01-15', '2025-12-15', 'shahid@example.com', 'shahid456', 1)
    ''');
    
    final shahidId = db!.select('SELECT last_insert_rowid() as id').first['id'];
    
    // إضافة مستخدم لـ Shahid
    db!.execute('''
      INSERT INTO subscription_users (subscription_id, customer_name, profile_name, amount, start_date, end_date, added_by)
      VALUES (?, 'محمد حسن', 'VIP Profile', 3000, '2025-01-15', '2025-02-15', 'المدير العام')
    ''', [shahidId]);
    
    print('✅ تم إضافة بيانات تجريبية بنجاح');
  }

  // إضافة عمود archived إذا لم يكن موجوداً في جدول orders الموجود
  try {
    db!.execute('ALTER TABLE orders ADD COLUMN archived INTEGER DEFAULT 0');
    print('✅ تم إضافة عمود archived إلى جدول الطلبات');
  } catch (e) {
    // العمود موجود بالفعل، لا مشكلة
    print('📝 عمود archived موجود بالفعل');
  }

  final router = Router()
    ..post('/api/login', _loginHandler)
    ..post('/api/users/create', _createUserHandler)
    ..delete('/api/users/<id>', _deleteUserHandler)
    ..put('/api/users/<id>/password', _changePasswordHandler)
    ..get('/api/users/list', _getUsersListHandler)
    ..get('/api/health', _healthHandler)
    ..get('/api/protected', _protectedHandler)
    // Subscriptions routes
    ..get('/api/subscriptions', (request) => sub.getSubscriptionsHandler(request, db!))
    ..post('/api/subscriptions', (request) => sub.createSubscriptionHandler(request, db!))
    ..put('/api/subscriptions/<id>', (request, id) => sub.updateSubscriptionHandler(request, id, db!))
    ..delete('/api/subscriptions/<id>', (request, id) => sub.deleteSubscriptionHandler(request, id, db!))
    ..get('/api/subscriptions/<id>/users', (request, id) => sub.getSubscriptionUsersHandler(request, id, db!))
    ..post('/api/subscriptions/<id>/users', (request, id) => sub.addSubscriptionUserHandler(request, id, db!))
    ..put('/api/subscription-users/<id>', (request, id) => sub.updateSubscriptionUserHandler(request, id, db!))
    ..put('/api/subscription-users/<id>/extend', (request, id) => sub.extendSubscriptionUserHandler(request, id, db!))
    ..delete('/api/subscription-users/<id>', (request, id) => sub.deleteSubscriptionUserHandler(request, id, db!))
    // Products routes
    ..get('/api/products', (request) => prod.getProducts(request, db!))
    ..get('/api/products/category/<category>', (request, category) => prod.getProductsByCategory(request, db!, category))
    ..post('/api/products', (request) => prod.createProduct(request, db!))
    ..put('/api/products/<id>', (request, id) => prod.updateProduct(request, db!, id))
    ..delete('/api/products/<id>', (request, id) => prod.deleteProduct(request, db!, id))
    // Orders routes
    ..get('/api/orders', (request) => ord.getOrders(request, db!))
    ..get('/api/orders/archived', (request) => ord.getArchivedOrders(request, db!))
    ..post('/api/orders', (request) => ord.createOrder(request, db!))
    ..put('/api/orders/<id>', (request, id) => ord.updateOrder(request, db!, id))
    ..put('/api/orders/<id>/status', (request, id) => ord.updateOrderStatus(request, db!, id))
    ..delete('/api/orders/<id>', (request, id) => ord.deleteOrder(request, db!, id))
    ..get('/api/orders/statistics', (request) => ord.getOrdersStatistics(request, db!))
    ..post('/api/orders/<id>/archive', (request, id) => ord.archiveOrder(request, db!, id))
    ..post('/api/orders/<id>/unarchive', (request, id) => ord.unarchiveOrder(request, db!, id))
    // Capital routes
    ..get('/api/capital', _getCapitalInfo)
    ..post('/api/capital/add', _addCapital)
    ..post('/api/capital/withdraw', _withdrawCapital)
    ..delete('/api/capital/transactions/<date>', _deleteTransactionsByDate)
    // Settlement routes - للموظفين
    ..get('/api/settlements/employee-stats', (request) => settle.getEmployeeSettlementStats(request, db!))
    ..post('/api/settlements/request', (request) => settle.createSettlementRequest(request, db!))
    ..get('/api/settlements/my-history', (request) => settle.getEmployeeSettlementHistory(request, db!))
    // Settlement routes - للمدير
    ..get('/api/settlements/manager/pending', (request) => settle.getPendingSettlements(request, db!))
    ..get('/api/settlements/manager/all', (request) => settle.getAllSettlements(request, db!))
    ..post('/api/settlements/manager/approve/<id>', (request, id) => settle.approveSettlement(request, db!, id))
    ..post('/api/settlements/manager/reject/<id>', (request, id) => settle.rejectSettlement(request, db!, id))
    ..delete('/api/settlements/manager/<id>', (request, id) => settle.deleteSettlement(request, db!, id))
    ..put('/api/settlements/manager/commission/<userId>', (request, userId) => settle.updateEmployeeCommission(request, db!, userId))
    ..get('/api/settlements/manager/commission/<userId>', (request, userId) => settle.getEmployeeCommission(request, db!, userId));

  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    '127.0.0.1',
    port,
  );

  print('🚀 API يعمل على المنفذ $port');
  print('✅ جاهز للاتصال عبر: admin.taif.digital');
  print('📊 قاعدة البيانات: database.db');
  print('👤 حساب تجريبي: admin / admin123');
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders());
      }

      final response = await handler(request);
      return response.change(headers: _corsHeaders());
    };
  };
}

Map<String, String> _corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };
}

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<Response> _loginHandler(Request request) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final username = data['username'];
    final password = data['password'];

    if (username == null || password == null) {
      return Response(400,
          body: jsonEncode({
            'success': false,
            'message': 'الرجاء إدخال اسم المستخدم وكلمة المرور'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    final hashedPassword = hashPassword(password);
    final result = db!.select(
        'SELECT * FROM users WHERE username = ? AND password = ?',
        [username, hashedPassword]);

    if (result.isEmpty) {
      return Response(401,
          body: jsonEncode({
            'success': false,
            'message': 'اسم المستخدم أو كلمة المرور غير صحيحة'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    final user = result.first;
    final jwt = JWT({
      'id': user['id'],
      'username': user['username'],
      'name': user['name'] ?? user['username'],
      'role': user['role'],
      'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
    });

    final token = jwt.sign(SecretKey(secretKey));

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم تسجيل الدخول بنجاح',
          'token': token,
          'user': {
            'id': user['id'],
            'username': user['username'],
            'name': user['name'] ?? user['username'],
            'role': user['role'],
          }
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> _healthHandler(Request request) async {
  return Response.ok(
      jsonEncode({'status': 'ok', 'message': 'API يعمل بنجاح'}),
      headers: {'Content-Type': 'application/json'});
}

Future<Response> _protectedHandler(Request request) async {
  final authHeader = request.headers['authorization'];
  
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response(401,
        body: jsonEncode({'success': false, 'message': 'غير مصرح'}),
        headers: {'Content-Type': 'application/json'});
  }

  final token = authHeader.substring(7);

  try {
    final jwt = JWT.verify(token, SecretKey(secretKey));
    
    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'مرحباً بك!',
          'user': jwt.payload
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response(403,
        body: jsonEncode({'success': false, 'message': 'الجلسة منتهية'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> _createUserHandler(Request request) async {
  try {
    // التحقق من صلاحيات المدير
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

    // التحقق من أن المستخدم مدير
    if (jwt.payload['role'] != 'admin') {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'ليس لديك صلاحية'}),
          headers: {'Content-Type': 'application/json'});
    }

    // قراءة البيانات
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final username = data['username'];
    final password = data['password'];
    final name = data['name'];
    final role = data['role'] ?? 'employee';

    if (username == null || password == null || name == null) {
      return Response(400,
          body: jsonEncode({
            'success': false,
            'message': 'الرجاء إدخال جميع البيانات المطلوبة'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    final db = sqlite3.open(dbPath);

    // التحقق من وجود المستخدم
    final existing = db.select(
        'SELECT id FROM users WHERE username = ?', [username]);

    if (existing.isNotEmpty) {
      db.dispose();
      return Response(400,
          body: jsonEncode({
            'success': false,
            'message': 'اسم المستخدم موجود مسبقاً'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // إضافة المستخدم
    final hashedPassword = hashPassword(password);
    db.execute('''
      INSERT INTO users (username, password, name, role)
      VALUES (?, ?, ?, ?)
    ''', [username, hashedPassword, name, role]);

    db.dispose();

    print('✅ تم إضافة مستخدم جديد: $name ($username - $role)');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم إضافة الموظف بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> _getUsersListHandler(Request request) async {
  try {
    // التحقق من صلاحيات المدير
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

    // التحقق من أن المستخدم مدير
    if (jwt.payload['role'] != 'admin') {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'ليس لديك صلاحية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final db = sqlite3.open(dbPath);

    final result = db.select('SELECT id, username, name, role FROM users');

    final users = result.map((row) {
      return {
        'id': row['id'],
        'username': row['username'],
        'name': row['name'] ?? row['username'],
        'role': row['role'],
      };
    }).toList();

    db.dispose();

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

Future<Response> _deleteUserHandler(Request request, String id) async {
  try {
    // التحقق من التوكن
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'يجب تسجيل الدخول أولاً'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(secretKey));
    final payload = jwt.payload;
    final currentUserId = payload['id'];
    final currentUserRole = payload['role'];

    // التحقق من صلاحية المدير
    if (currentUserRole != 'admin') {
      return Response.forbidden(
          jsonEncode({'success': false, 'message': 'ليس لديك صلاحية لحذف المستخدمين'}),
          headers: {'Content-Type': 'application/json'});
    }

    final userId = int.tryParse(id);
    if (userId == null) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'معرف المستخدم غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    // منع حذف الحساب الشخصي
    if (userId == currentUserId) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'لا يمكنك حذف حسابك الخاص'}),
          headers: {'Content-Type': 'application/json'});
    }

    final db = sqlite3.open(dbPath);

    // التحقق من وجود المستخدم
    final checkResult = db.select('SELECT id FROM users WHERE id = ?', [userId]);
    if (checkResult.isEmpty) {
      db.dispose();
      return Response.notFound(
          jsonEncode({'success': false, 'message': 'المستخدم غير موجود'}),
          headers: {'Content-Type': 'application/json'});
    }

    // حذف المستخدم
    db.execute('DELETE FROM users WHERE id = ?', [userId]);
    db.dispose();

    print('✅ تم حذف المستخدم: ID $userId بواسطة المدير ID $currentUserId');

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

Future<Response> _changePasswordHandler(Request request, String id) async {
  try {
    // التحقق من التوكن
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(
          jsonEncode({'success': false, 'message': 'يجب تسجيل الدخول أولاً'}),
          headers: {'Content-Type': 'application/json'});
    }

    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(secretKey));
    final payload = jwt.payload;
    final currentUserId = payload['id'];
    final currentUserRole = payload['role'];

    final userId = int.tryParse(id);
    if (userId == null) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'معرف المستخدم غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    // التحقق من الصلاحية (مدير أو نفس المستخدم)
    if (currentUserRole != 'admin' && currentUserId != userId) {
      return Response.forbidden(
          jsonEncode({'success': false, 'message': 'ليس لديك صلاحية لتغيير كلمة المرور'}),
          headers: {'Content-Type': 'application/json'});
    }

    final requestBody = await request.readAsString();
    final data = jsonDecode(requestBody);
    final newPassword = data['newPassword'];

    if (newPassword == null || newPassword.isEmpty) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'يجب إدخال كلمة المرور الجديدة'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (newPassword.length < 6) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'}),
          headers: {'Content-Type': 'application/json'});
    }

    final db = sqlite3.open(dbPath);

    // التحقق من وجود المستخدم
    final checkResult = db.select('SELECT id FROM users WHERE id = ?', [userId]);
    if (checkResult.isEmpty) {
      db.dispose();
      return Response.notFound(
          jsonEncode({'success': false, 'message': 'المستخدم غير موجود'}),
          headers: {'Content-Type': 'application/json'});
    }

    // تشفير كلمة المرور الجديدة
    final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();

    // تحديث كلمة المرور
    db.execute('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, userId]);
    db.dispose();

    print('✅ تم تغيير كلمة المرور للمستخدم: ID $userId');

    return Response.ok(
        jsonEncode({
          'success': true,
          'message': 'تم تغيير كلمة المرور بنجاح'
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

// ============= Capital Management Handlers =============

// جلب معلومات رأس المال
Future<Response> _getCapitalInfo(Request request) async {
  try {
    // التحقق من صلاحيات المدير
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

    // التحقق من أن المستخدم مدير
    if (jwt.payload['role'] != 'admin') {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'ليس لديك صلاحية'}),
          headers: {'Content-Type': 'application/json'});
    }

    // حساب رأس المال الحالي
    final deposits = db!.select(
      'SELECT COALESCE(SUM(amount), 0) as total FROM capital_transactions WHERE type = ?',
      ['deposit']
    ).first['total'] as num;

    final withdrawals = db!.select(
      'SELECT COALESCE(SUM(amount), 0) as total FROM capital_transactions WHERE type = ?',
      ['withdraw']
    ).first['total'] as num;

    final currentCapital = deposits - withdrawals;

    // جلب آخر 50 عملية
    final transactions = db!.select('''
      SELECT type, amount, description, created_by, created_at
      FROM capital_transactions
      ORDER BY created_at DESC
      LIMIT 50
    ''');

    return Response.ok(
        jsonEncode({
          'success': true,
          'capital': {
            'currentCapital': currentCapital,
            'totalDeposits': deposits,
            'totalWithdrawals': withdrawals,
            'transactions': transactions.map((row) => {
              'type': row['type'],
              'amount': row['amount'],
              'description': row['description'],
              'created_by': row['created_by'],
              'created_at': row['created_at'],
            }).toList(),
          }
        }),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

// إضافة رأس مال
Future<Response> _addCapital(Request request) async {
  try {
    // التحقق من صلاحيات المدير
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

    // التحقق من أن المستخدم مدير
    if (jwt.payload['role'] != 'admin') {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'ليس لديك صلاحية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final requestBody = await request.readAsString();
    final data = jsonDecode(requestBody);
    final amount = data['amount'];

    if (amount == null || amount <= 0) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'المبلغ غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    final now = DateTime.now().toIso8601String();
    
    final username = jwt.payload['username'] ?? 'admin';
    
    db!.execute('''
      INSERT INTO capital_transactions (type, amount, description, created_by, created_at)
      VALUES (?, ?, ?, ?, ?)
    ''', ['deposit', amount, 'إيداع رأس مال', username, now]);

    print('✅ تم إضافة رأس مال: $amount دينار بواسطة $username');

    return Response.ok(
        jsonEncode({'success': true, 'message': 'تم إضافة المبلغ بنجاح'}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

// سحب رأس مال
Future<Response> _withdrawCapital(Request request) async {
  try {
    // التحقق من صلاحيات المدير
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

    // التحقق من أن المستخدم مدير
    if (jwt.payload['role'] != 'admin') {
      return Response(403,
          body: jsonEncode({'success': false, 'message': 'ليس لديك صلاحية'}),
          headers: {'Content-Type': 'application/json'});
    }

    final requestBody = await request.readAsString();
    final data = jsonDecode(requestBody);
    final amount = data['amount'];

    if (amount == null || amount <= 0) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'المبلغ غير صالح'}),
          headers: {'Content-Type': 'application/json'});
    }

    // التحقق من توفر رأس المال
    final deposits = db!.select(
      'SELECT COALESCE(SUM(amount), 0) as total FROM capital_transactions WHERE type = ?',
      ['deposit']
    ).first['total'] as num;

    final withdrawals = db!.select(
      'SELECT COALESCE(SUM(amount), 0) as total FROM capital_transactions WHERE type = ?',
      ['withdraw']
    ).first['total'] as num;

    final currentCapital = deposits - withdrawals;

    if (amount > currentCapital) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'رأس المال غير كافٍ للسحب'}),
          headers: {'Content-Type': 'application/json'});
    }

    final now = DateTime.now().toIso8601String();
    
    final username = jwt.payload['username'] ?? 'admin';
    final description = data['description'] ?? 'سحب رأس مال';
    
    db!.execute('''
      INSERT INTO capital_transactions (type, amount, description, created_by, created_at)
      VALUES (?, ?, ?, ?, ?)
    ''', ['withdraw', amount, description, username, now]);

    print('✅ تم سحب رأس مال: $amount دينار بواسطة $username');

    return Response.ok(
        jsonEncode({'success': true, 'message': 'تم سحب المبلغ بنجاح'}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}

Future<Response> _deleteTransactionsByDate(Request request, String date) async {
  try {
    // التحقق من صحة التوكن
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.forbidden(
          jsonEncode({'success': false, 'message': 'غير مصرح'}));
    }

    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey(secretKey));

    // التحقق من صلاحية المستخدم
    final role = jwt.payload['role'];
    if (role != 'admin' && role != 'manager') {
      return Response.forbidden(
          jsonEncode({'success': false, 'message': 'لا تملك صلاحية لحذف العمليات'}));
    }

    // التحقق من صحة صيغة التاريخ
    if (date.isEmpty || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return Response.badRequest(
          body: jsonEncode({'success': false, 'message': 'صيغة التاريخ غير صحيحة'}),
          headers: {'Content-Type': 'application/json'});
    }

    final username = jwt.payload['username'] ?? 'admin';

    // عدّ العمليات المراد حذفها
    final countResult = db!.select('''
      SELECT COUNT(*) as count FROM capital_transactions 
      WHERE DATE(created_at) = ?
    ''', [date]);

    final count = countResult.first['count'] as int;

    if (count == 0) {
      return Response.ok(
          jsonEncode({'success': true, 'message': 'لا توجد عمليات في هذا التاريخ', 'deletedCount': 0}),
          headers: {'Content-Type': 'application/json'});
    }

    // حذف العمليات
    db!.execute('''
      DELETE FROM capital_transactions 
      WHERE DATE(created_at) = ?
    ''', [date]);

    print('🗑️ تم حذف $count عملية في التاريخ $date بواسطة $username');

    return Response.ok(
        jsonEncode({'success': true, 'message': 'تم حذف العمليات بنجاح', 'deletedCount': count}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    print('❌ خطأ في حذف العمليات: $e');
    return Response.internalServerError(
        body: jsonEncode({'success': false, 'message': 'خطأ في الخادم: $e'}),
        headers: {'Content-Type': 'application/json'});
  }
}
