import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Production API endpoint via Cloudflare Tunnel
  // static const String baseUrl = 'https://admin.taif.digital/api';
  
  // Local development (منفذ مؤقت)
  static const String baseUrl = 'http://localhost:53366/api';

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('username', data['user']['username']);
        await prefs.setString('role', data['user']['role']);
        await prefs.setString('name', data['user']['name'] ?? data['user']['username']);

        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالخادم: ${e.toString()}'
      };
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // حفظ بيانات الدخول (Remember Me)
  static Future<void> saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', username);
    await prefs.setString('saved_password', password);
    await prefs.setBool('remember_me', true);
  }

  // الحصول على بيانات الدخول المحفوظة
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    if (rememberMe) {
      return {
        'username': prefs.getString('saved_username'),
        'password': prefs.getString('saved_password'),
      };
    }
    return {'username': null, 'password': null};
  }

  // مسح بيانات الدخول المحفوظة
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
    await prefs.remove('remember_me');
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': 'فشل الاتصال'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getProtectedData() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/protected'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إضافة موظف جديد (للمدير فقط)
  static Future<Map<String, dynamic>> createUser(
      String username, String password, String name, String role) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'username': username,
          'password': password,
          'name': name,
          'role': role,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // عرض قائمة المستخدمين (للمدير فقط)
  static Future<Map<String, dynamic>> getUsersList() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        return {'success': true, 'users': data['users']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // Alias للتوافق
  static Future<Map<String, dynamic>> getUsers() async {
    return getUsersList();
  }

  // حذف مستخدم (للمدير فقط)
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تغيير كلمة المرور (للمدير أو المستخدم نفسه)
  static Future<Map<String, dynamic>> changePassword(
      int userId, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // ==================== Subscriptions Management ====================
  
  // الحصول على قائمة الاشتراكات
  static Future<Map<String, dynamic>> getSubscriptions() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        return {'success': true, 'subscriptions': data['subscriptions']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إضافة اشتراك جديد
  static Future<Map<String, dynamic>> createSubscription({
    required String serviceName,
    String? accountNumber,
    required double cost,
    required int maxUsers,
    required String startDate,
    required String endDate,
    String? email,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceName': serviceName,
          'accountNumber': accountNumber,
          'cost': cost,
          'maxUsers': maxUsers,
          'startDate': startDate,
          'endDate': endDate,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف',
        'subscription': data['subscription'],
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تحديث اشتراك
  static Future<Map<String, dynamic>> updateSubscription({
    required int subscriptionId,
    required String serviceName,
    String? accountNumber,
    required double cost,
    required int maxUsers,
    required String startDate,
    required String endDate,
    String? email,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceName': serviceName,
          'accountNumber': accountNumber,
          'cost': cost,
          'maxUsers': maxUsers,
          'startDate': startDate,
          'endDate': endDate,
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف اشتراك
  static Future<Map<String, dynamic>> deleteSubscription(int subscriptionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // الحصول على مستخدمي اشتراك معين
  static Future<Map<String, dynamic>> getSubscriptionUsers(int subscriptionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        return {'success': true, 'users': data['users']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إضافة مستخدم لاشتراك
  static Future<Map<String, dynamic>> addSubscriptionUser({
    required int subscriptionId,
    required String customerName,
    required String profileName,
    required double amount,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }
      
      // الحصول على اسم المستخدم الحالي
      String addedBy = await getName() ?? await getUsername() ?? 'مجهول';

      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'customerName': customerName,
          'profileName': profileName,
          'amount': amount,
          'startDate': startDate,
          'endDate': endDate,
          'addedBy': addedBy,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف',
        'user': data['user'],
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تحديث مستخدم اشتراك
  static Future<Map<String, dynamic>> updateSubscriptionUser({
    required int userId,
    required String customerName,
    required String profileName,
    required double amount,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/subscription-users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'customerName': customerName,
          'profileName': profileName,
          'amount': amount,
          'startDate': startDate,
          'endDate': endDate,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تمديد اشتراك مستخدم
  static Future<Map<String, dynamic>> extendSubscriptionUser(int userId, int days) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/subscription-users/$userId/extend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'days': days,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف مستخدم من اشتراك
  static Future<Map<String, dynamic>> deleteSubscriptionUser(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/subscription-users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف'
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // ========== دوال المنتجات ==========

  // إضافة منتج جديد
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String category,
    double? costPrice,
    double? sellPrice,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'category': category,
          'cost_price': costPrice ?? 0,
          'sell_price': sellPrice ?? 0,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['product'] != null) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إضافة المنتج',
          'product': data['product'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'خطأ في إضافة المنتج',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب جميع المنتجات
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'products': data['products'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'خطأ في جلب المنتجات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب منتجات حسب القسم
  static Future<Map<String, dynamic>> getProductsByCategory(String category) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/category/$category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'products': data['products'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تحديث منتج
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? name,
    String? category,
    double? costPrice,
    double? sellPrice,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (category != null) 'category': category,
          if (costPrice != null) 'costPrice': costPrice,
          if (sellPrice != null) 'sellPrice': sellPrice,
        }),
      );

      final data = json.decode(response.body);

      return {
        'success': data['success'] ?? false,
        'message': data['message'] ?? 'خطأ غير معروف',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف منتج
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'تم حذف المنتج بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'فشل حذف المنتج',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // ============== الطلبات ==============
  
  // جلب جميع الطلبات
  static Future<Map<String, dynamic>> getOrders() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? [],
        };
      } else {
        return {'success': false, 'message': 'خطأ في جلب الطلبات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إنشاء طلب جديد
  static Future<Map<String, dynamic>> createOrder({
    required int productId,
    required String productName,
    required String customerName,
    String? customerPhone,
    required double cost,
    required double price,
    required double profit,
    required String paymentMethod,
    required String category,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final username = await getUsername();

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': productId,
          'product_name': productName,
          'customer_name': customerName,
          'customer_phone': customerPhone ?? '',
          'cost': cost,
          'price': price,
          'profit': profit,
          'payment_method': paymentMethod,
          'category': category,
          'employee_username': username ?? 'unknown',
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم تسجيل الطلب بنجاح',
          'order': data['order'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'خطأ في تسجيل الطلب',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تحديث حالة الطلب
  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم تحديث حالة الطلب'};
      } else {
        return {'success': false, 'message': 'خطأ في تحديث الطلب'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تعديل طلب
  static Future<Map<String, dynamic>> updateOrder({
    required int orderId,
    required String productName,
    required String customerName,
    required String customerPhone,
    required double cost,
    required double price,
    required String paymentMethod,
    required String status,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_name': productName,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'cost': cost,
          'price': price,
          'payment_method': paymentMethod,
          'status': status,
          'notes': notes ?? '',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'تم تعديل الطلب بنجاح'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'خطأ في تعديل الطلب'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف طلب
  static Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم حذف الطلب'};
      } else {
        return {'success': false, 'message': 'خطأ في حذف الطلب'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إحصائيات الطلبات
  static Future<Map<String, dynamic>> getOrdersStatistics() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'statistics': data,
        };
      } else {
        return {'success': false, 'message': 'خطأ في جلب الإحصائيات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إحصائيات الشهر الحالي
  static Future<Map<String, dynamic>> getCurrentMonthStatistics() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/statistics/current-month'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'statistics': data,
        };
      } else {
        return {'success': false, 'message': 'خطأ في جلب الإحصائيات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // رأس المال - جلب المعلومات
  static Future<Map<String, dynamic>> getCapitalInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/capital'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Server already returns {success: true, capital: {...}}
        return data;
      } else {
        return {'success': false, 'message': 'خطأ في جلب معلومات رأس المال'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // رأس المال - إضافة مبلغ
  static Future<Map<String, dynamic>> addCapital(double amount) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/capital/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم إضافة المبلغ بنجاح',
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في إضافة المبلغ'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // رأس المال - سحب مبلغ
  static Future<Map<String, dynamic>> withdrawCapital(double amount, {String? description}) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/capital/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          if (description != null) 'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم سحب المبلغ بنجاح',
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في سحب المبلغ'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> withdrawForOrder(
    double amount, 
    String orderDetails, {
    int? orderId,
    String? productName,
    String? customerName,
    String? customerPhone,
    double? sellPrice,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ withdrawForOrder: لا يوجد token');
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      print('🔵 withdrawForOrder: إرسال طلب خصم');
      print('   المبلغ: $amount');
      print('   رقم الطلب: $orderId');
      print('   المنتج: $productName');
      print('   الزبون: $customerName');

      final response = await http.post(
        Uri.parse('$baseUrl/capital/withdraw-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'order_id': orderId,
          'product_name': productName,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'sell_price': sellPrice,
        }),
      );

      print('🔵 withdrawForOrder: Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ withdrawForOrder: نجح الخصم');
        return {
          'success': true,
          'message': data['message'] ?? 'تم خصم التكلفة من رأس المال',
        };
      } else {
        final data = json.decode(response.body);
        print('❌ withdrawForOrder: فشل الخصم - ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'خطأ في خصم التكلفة'};
      }
    } catch (e) {
      print('❌ withdrawForOrder: خطأ في الاتصال - $e');
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // الحصول على تفاصيل معاملة واحدة
  static Future<Map<String, dynamic>> getTransactionDetails(int transactionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/capital/transaction/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في جلب التفاصيل'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف معاملة واحدة
  static Future<Map<String, dynamic>> deleteTransaction(int transactionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/capital/transactions/single/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم حذف المعاملة بنجاح',
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في حذف المعاملة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // رأس المال - حذف العمليات حسب التاريخ
  static Future<Map<String, dynamic>> deleteTransactionsByDate(DateTime date) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      // تنسيق التاريخ بصيغة yyyy-MM-dd
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await http.delete(
        Uri.parse('$baseUrl/capital/transactions/$dateStr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم حذف العمليات بنجاح',
          'deletedCount': data['deletedCount'] ?? 0,
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في حذف العمليات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // أرشفة طلب
  static Future<Map<String, dynamic>> archiveOrder(int orderId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/archive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم أرشفة الطلب بنجاح'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في الأرشفة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // إلغاء أرشفة طلب
  static Future<Map<String, dynamic>> unarchiveOrder(int orderId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/unarchive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم إلغاء الأرشفة بنجاح'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في إلغاء الأرشفة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب جميع الطلبات المؤرشفة
  static Future<Map<String, dynamic>> getArchivedOrders() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/orders/archived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final orders = json.decode(response.body) as List;
        return {'success': true, 'orders': orders};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في جلب الطلبات المؤرشفة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // ==================== Settlement APIs ====================
  
  // جلب إحصائيات التحاسب للموظف
  static Future<Map<String, dynamic>> getEmployeeSettlementStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/settlements/employee-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': data['success'] ?? true, 'stats': data['stats']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في جلب الإحصائيات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // طلب تحاسب جديد
  static Future<Map<String, dynamic>> createSettlementRequest({
    required int totalOrders,
    required double totalSales,
    required double commissionRate,
    required double commissionAmount,
    required List<int> orderIds,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/settlements/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'totalOrders': totalOrders,
          'totalSales': totalSales,
          'commissionRate': commissionRate,
          'commissionAmount': commissionAmount,
          'orderIds': orderIds,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'error': data['error'],
          'message': data['error'] ?? 'خطأ في إرسال الطلب',
          'hasPending': data['hasPending'] ?? false,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب سجل التحاسبات للموظف
  static Future<Map<String, dynamic>> getEmployeeSettlementHistory() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/settlements/my-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final settlements = json.decode(response.body) as List;
        return {'success': true, 'history': settlements};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في جلب السجل'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب طلبات التحاسب المعلقة (للمدير فقط)
  static Future<Map<String, dynamic>> getPendingSettlements() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/settlements/manager/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final settlements = json.decode(response.body) as List;
        return {'success': true, 'settlements': settlements};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في جلب الطلبات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب جميع التحاسبات (للمدير فقط)
  static Future<Map<String, dynamic>> getAllSettlements() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/settlements/manager/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final settlements = json.decode(response.body) as List;
        return {'success': true, 'settlements': settlements};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في جلب التحاسبات'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // الموافقة على التحاسب (للمدير فقط)
  static Future<Map<String, dynamic>> approveSettlement(int settlementId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/settlements/manager/approve/$settlementId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في الموافقة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // رفض التحاسب (للمدير فقط)
  static Future<Map<String, dynamic>> rejectSettlement(int settlementId, String reason) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/settlements/manager/reject/$settlementId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في الرفض'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // تحديث نسبة عمولة الموظف (للمدير فقط)
  static Future<Map<String, dynamic>> updateEmployeeCommission(int userId, double commissionRate) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/settlements/manager/commission/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commissionRate': commissionRate}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في التحديث'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // جلب نسبة عمولة الموظف (للمدير فقط)
  static Future<Map<String, dynamic>> getEmployeeCommission(int userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/settlements/manager/commission/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'commissionRate': data['commissionRate']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في جلب النسبة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف التحاسب (للمدير فقط)
  static Future<Map<String, dynamic>> deleteSettlement(int settlementId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/settlements/manager/$settlementId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['error'] ?? 'خطأ في الحذف'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // ================== وظائف أرشفة السجل المالي ==================

  // أرشفة معاملة واحدة
  static Future<Map<String, dynamic>> archiveCapitalTransaction(int transactionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/capital/archive/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'] ?? 'تم الأرشفة بنجاح'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في الأرشفة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // أرشفة جميع المعاملات
  static Future<Map<String, dynamic>> archiveAllCapitalTransactions() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/capital/archive/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم الأرشفة بنجاح',
          'archivedCount': data['archivedCount'] ?? 0,
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في الأرشفة'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // الحصول على المعاملات المؤرشفة
  static Future<Map<String, dynamic>> getArchivedCapitalTransactions() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/capital/archived'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'transactions': data['transactions'] ?? [],
        };
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في جلب الأرشيف'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // استرجاع معاملة من الأرشيف
  static Future<Map<String, dynamic>> unarchiveCapitalTransaction(int transactionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/capital/unarchive/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'] ?? 'تم الاسترجاع بنجاح'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في الاسترجاع'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // حذف معاملة مؤرشفة نهائياً
  static Future<Map<String, dynamic>> deleteArchivedCapitalTransaction(int transactionId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/capital/archived/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'message': data['message'] ?? 'تم الحذف بنجاح'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'خطأ في الحذف'};
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  // =============== Custom Categories APIs ===============
  
  /// الحصول على الأقسام المخصصة للمستخدم
  static Future<Map<String, dynamic>> getCustomCategories() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'categories': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/custom-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'categories': data['categories'] ?? [],
        };
      } else {
        return {'success': false, 'categories': []};
      }
    } catch (e) {
      print('خطأ في جلب الأقسام المخصصة: $e');
      return {'success': false, 'categories': []};
    }
  }

  /// إنشاء قسم مخصص جديد
  static Future<Map<String, dynamic>> createCustomCategory(String name) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/custom-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'name': name}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'category': data['category'],
          'message': data['message'] ?? 'تم إنشاء القسم بنجاح',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'فشل إنشاء القسم',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// حذف قسم مخصص
  static Future<Map<String, dynamic>> deleteCustomCategory(int categoryId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/custom-categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم حذف القسم',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'فشل حذف القسم',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// الحصول على منتجات قسم معين
  static Future<Map<String, dynamic>> getCategoryProducts(int categoryId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'product_ids': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/custom-categories/$categoryId/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'product_ids': data['product_ids'] ?? [],
        };
      } else {
        return {'success': false, 'product_ids': []};
      }
    } catch (e) {
      return {'success': false, 'product_ids': []};
    }
  }

  /// إضافة منتج إلى قسم
  static Future<Map<String, dynamic>> addProductToCategory(int categoryId, int productId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/custom-categories/$categoryId/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'product_id': productId}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إضافة المنتج',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'فشل إضافة المنتج',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// إزالة منتج من قسم
  static Future<Map<String, dynamic>> removeProductFromCategory(int categoryId, int productId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/custom-categories/$categoryId/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم إزالة المنتج',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'فشل إزالة المنتج',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// الحصول على إعدادات الأقسام المخصصة
  static Future<Map<String, dynamic>> getCustomCategoriesSettings() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'share_with_employees': false};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/custom-categories/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'share_with_employees': data['share_with_employees'] ?? false,
        };
      } else {
        return {'success': false, 'share_with_employees': false};
      }
    } catch (e) {
      return {'success': false, 'share_with_employees': false};
    }
  }

  /// تحديث إعدادات الأقسام المخصصة
  static Future<Map<String, dynamic>> updateCustomCategoriesSettings({
    required bool shareWithEmployees,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/custom-categories/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'share_with_employees': shareWithEmployees}),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'تم تحديث الإعدادات',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'فشل تحديث الإعدادات',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// الحصول على جميع الأقسام المخصصة (للمدير فقط)
  static Future<Map<String, dynamic>> getAllCustomCategories() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'categories': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/custom-categories/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'categories': data['categories'] ?? [],
        };
      } else {
        return {'success': false, 'categories': []};
      }
    } catch (e) {
      return {'success': false, 'categories': []};
    }
  }

  // ==========================================
  // Shared Games API Functions
  // ==========================================

  /// الحصول على جميع الألعاب المشتركة
  static Future<Map<String, dynamic>> getSharedGames() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'games': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/shared-games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'games': data['games'] ?? [],
        };
      } else {
        return {'success': false, 'games': []};
      }
    } catch (e) {
      return {'success': false, 'games': []};
    }
  }

  /// إنشاء لعبة مشتركة جديدة
  static Future<Map<String, dynamic>> createSharedGame({
    required String gameName,
    String? email,
    String? password,
    int? maxUsers,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/shared-games'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'game_name': gameName,
          'email': email,
          'password': password,
          'max_users': maxUsers,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// تحديث بيانات لعبة مشتركة
  static Future<Map<String, dynamic>> updateSharedGame({
    required int gameId,
    required String gameName,
    String? email,
    String? password,
    int? maxUsers,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/shared-games/$gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'game_name': gameName,
          'email': email,
          'password': password,
          'max_users': maxUsers,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// حذف لعبة مشتركة
  static Future<Map<String, dynamic>> deleteSharedGame(int gameId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/shared-games/$gameId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// الحصول على عملاء لعبة معينة
  static Future<Map<String, dynamic>> getGameCustomers(int gameId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'customers': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/shared-games/$gameId/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'customers': data['customers'] ?? [],
        };
      } else {
        return {'success': false, 'customers': []};
      }
    } catch (e) {
      return {'success': false, 'customers': []};
    }
  }

  /// إضافة عميل إلى لعبة
  static Future<Map<String, dynamic>> addGameCustomer({
    required int gameId,
    required String customerName,
    String? deviceName,
    double? amountPaid,
    String? purchaseDate,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/shared-games/$gameId/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'customer_name': customerName,
          'device_name': deviceName,
          'amount_paid': amountPaid,
          'purchase_date': purchaseDate,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// تحديث بيانات عميل
  static Future<Map<String, dynamic>> updateGameCustomer({
    required int customerId,
    required String customerName,
    String? deviceName,
    double? amountPaid,
    String? purchaseDate,
    String? notes,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/shared-game-customers/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'customer_name': customerName,
          'device_name': deviceName,
          'amount_paid': amountPaid,
          'purchase_date': purchaseDate,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }

  /// حذف عميل من لعبة
  static Future<Map<String, dynamic>> deleteGameCustomer(int customerId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'غير مسجل دخول'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/shared-game-customers/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: ${e.toString()}'};
    }
  }
}
