import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 اختبار API الأقسام المخصصة\n');
  
  // استبدل هذا بالتوكن الفعلي من تسجيل الدخول
  const token = 'YOUR_JWT_TOKEN_HERE';
  const baseUrl = 'http://localhost:53365/api';
  
  print('1️⃣ اختبار: جلب الأقسام المخصصة');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/custom-categories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('   الحالة: ${response.statusCode}');
    print('   الاستجابة: ${response.body}\n');
  } catch (e) {
    print('   ❌ خطأ: $e\n');
  }
  
  print('2️⃣ اختبار: جلب إعدادات المشاركة');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/custom-categories/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('   الحالة: ${response.statusCode}');
    print('   الاستجابة: ${response.body}\n');
  } catch (e) {
    print('   ❌ خطأ: $e\n');
  }
  
  print('3️⃣ اختبار: إنشاء قسم جديد');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/custom-categories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': 'قسم تجريبي'}),
    );
    print('   الحالة: ${response.statusCode}');
    print('   الاستجابة: ${response.body}\n');
  } catch (e) {
    print('   ❌ خطأ: $e\n');
  }
  
  print('4️⃣ اختبار: تحديث إعدادات المشاركة');
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/custom-categories/settings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'share_with_employees': true}),
    );
    print('   الحالة: ${response.statusCode}');
    print('   الاستجابة: ${response.body}\n');
  } catch (e) {
    print('   ❌ خطأ: $e\n');
  }
  
  print('✅ انتهى الاختبار');
}
