import 'package:sqlite3/sqlite3.dart';

/// سكريبت لتحديث طرق الدفع في قاعدة البيانات الموجودة
void main() {
  final db = sqlite3.open('database.db');
  
  print('🔄 جاري تحديث طرق الدفع...');
  
  // حذف الطرق القديمة
  db.execute('DELETE FROM payment_methods');
  print('✅ تم حذف الطرق القديمة');
  
  // إضافة الطرق الجديدة المستخدمة فعلياً في النظام
  final methods = ['زين كاش', 'آفدين', 'آسياسيل', 'نقدي'];
  
  for (var method in methods) {
    db.execute(
      'INSERT INTO payment_methods (name, is_active) VALUES (?, 1)',
      [method],
    );
    print('✅ تمت إضافة: $method');
  }
  
  // عرض النتيجة
  print('\n📋 طرق الدفع الحالية:');
  final results = db.select('SELECT * FROM payment_methods ORDER BY id');
  for (var row in results) {
    print('   - ${row['id']}: ${row['name']}');
  }
  
  db.dispose();
  print('\n✅ تم التحديث بنجاح!');
}
