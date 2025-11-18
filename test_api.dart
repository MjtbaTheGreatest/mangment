import 'dart:convert';
import 'dart:io';

void main() async {
  // اختبار endpoint الإحصائيات
  final token = 'YOUR_TOKEN_HERE'; // ضع token الموظف هنا
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:53365/api/settlements/employee-stats'));
    request.headers.add('Authorization', 'Bearer $token');
    request.headers.add('Content-Type', 'application/json');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status Code: ${response.statusCode}');
    print('Response: $responseBody');
    
    final data = jsonDecode(responseBody);
    print('\n📊 Parsed Data:');
    print('Success: ${data['success']}');
    print('Stats: ${data['stats']}');
    
    client.close();
  } catch (e) {
    print('❌ Error: $e');
  }
}
