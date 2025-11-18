import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'subscription_handlers.dart' as sub;
import 'product_handlers.dart' as prod;

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
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
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
      created_at TEXT NOT NULL,
      FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE
    )
  ''');

  // جدول المنتجات ⭐ NEW
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

  // إضافة admin افتراضي
  final adminCheck = db!.select('SELECT * FROM users WHERE username = ?', ['admin']);
  if (adminCheck.isEmpty) {
    final hashedPassword = sha256.convert(utf8.encode('admin123')).toString();
    db!.execute(
      'INSERT INTO users (username, password, name, role) VALUES (?, ?, ?, ?)',
      ['admin', hashedPassword, 'المدير العام', 'admin'],
    );
    print('✅ تم إضافة حساب المدير الافتراضي');
  }

  // إضافة منتجات تجريبية إذا كان الجدول فارغاً ⭐ NEW
  final productsCheck = db!.select('SELECT COUNT(*) as count FROM products');
  if (productsCheck.first['count'] == 0) {
    final now = DateTime.now().toIso8601String();
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['PUBG Mobile', 4500, 5000, 'ألعاب', now, now]);
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['Free Fire', 2700, 3000, 'ألعاب', now, now]);
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['Netflix', 13500, 15000, 'اشتراكات', now, now]);
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['Spotify', 7200, 8000, 'اشتراكات', now, now]);
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['PSN Card', 22500, 25000, 'ألعاب', now, now]);
    db!.execute('INSERT INTO products (name, cost_price, sell_price, category, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['iTunes', 9000, 10000, 'اشتراكات', now, now]);
    print('✅ تم إضافة منتجات تجريبية');
  }

  // إضافة اشتراكات تجريبية
  final subscriptionsCheck = db!.select('SELECT COUNT(*) as count FROM subscriptions');
  if (subscriptionsCheck.first['count'] == 0) {
    final now = DateTime.now().toIso8601String();
    final startDate = DateTime.now().toIso8601String().split('T')[0];
    final endDate = DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0];

    final netflixId = db!.select('''
      INSERT INTO subscriptions (service_name, account_number, cost, max_users, current_users, start_date, end_date, email, password, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING id
    ''', ['Netflix', 'NET-2024-001', 15000.0, 4, 0, startDate, endDate, 'netflix@example.com', 'pass123', now, now]);

    final shahidId = db!.select('''
      INSERT INTO subscriptions (service_name, cost, max_users, current_users, start_date, end_date, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING id
    ''', ['Shahid VIP', 12000.0, 3, 0, startDate, endDate, now, now]);

    print('✅ تم إضافة بيانات تجريبية بنجاح');
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
    // Products routes ⭐ NEW
    ..get('/api/products', (request) => prod.getProducts(request, db!))
    ..get('/api/products/category/<category>', (request, category) => prod.getProductsByCategory(request, db!, category))
    ..post('/api/products', (request) => prod.createProduct(request, db!))
    ..put('/api/products/<id>', (request, id) => prod.updateProduct(request, db!, id))
    ..delete('/api/products/<id>', (request, id) => prod.deleteProduct(request, db!, id));

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
  print('📦 Products API: Enabled');
}

// ... بقية الدوال كما هي في الملف الأصلي
