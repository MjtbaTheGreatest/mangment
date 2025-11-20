import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة إدارة الموظفين المتكاملة
class EmployeesManagementScreen extends StatefulWidget {
  const EmployeesManagementScreen({super.key});

  @override
  State<EmployeesManagementScreen> createState() => _EmployeesManagementScreenState();
}

class _EmployeesManagementScreenState extends State<EmployeesManagementScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _viewMode = 'grid'; // grid or list

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading employees from API...');
      
      final token = await ApiService.getToken();
      if (token == null) {
        _showError('يجب تسجيل الدخول أولاً');
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:53365/api/users/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['users'] ?? [];
        print('👥 Found ${users.length} employees');
        
        setState(() {
          _employees = List<Map<String, dynamic>>.from(users);
          _isLoading = false;
        });
        
        // تحميل إحصائيات كل موظف
        for (var employee in _employees) {
          _loadEmployeeStats(employee['username']);
        }
      } else {
        print('❌ Failed with status: ${response.statusCode}');
        setState(() => _isLoading = false);
        _showError('فشل تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error loading employees: $e');
      setState(() => _isLoading = false);
      _showError('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _loadEmployeeStats(String username) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:53365/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allOrders = List<Map<String, dynamic>>.from(data['orders'] ?? []);
        
        // فلترة طلبات الموظف
        final employeeOrders = allOrders.where((order) => 
          order['employee_username'] == username
        ).toList();
        
        // حساب الإحصائيات
        final stats = {
          'totalOrders': employeeOrders.length,
          'completedOrders': employeeOrders.where((o) => o['status'] == 'مكتمل').length,
          'pendingOrders': employeeOrders.where((o) => o['status'] == 'pending').length,
          'totalRevenue': employeeOrders.fold<double>(0, (sum, o) => sum + (o['price'] ?? 0)),
          'totalProfit': employeeOrders.fold<double>(0, (sum, o) => sum + (o['profit'] ?? 0)),
        };
        
        if (mounted) {
          setState(() {
            final index = _employees.indexWhere((e) => e['username'] == username);
            if (index != -1) {
              _employees[index]['stats'] = stats;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading stats for $username: $e');
    }
  }

  void _showAddEmployeeDialog() {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'employee';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add, color: AppColors.primaryGold, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  'إضافة موظف جديد',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'الاسم الكامل',
                    icon: Icons.badge,
                    hint: 'مثال: أحمد محمد',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: usernameController,
                    label: 'اسم المستخدم',
                    icon: Icons.account_circle,
                    hint: 'مثال: ahmed_m',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock,
                    hint: 'أدخل كلمة مرور قوية',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلاحية',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: 'موظف',
                                icon: Icons.person,
                                color: AppColors.info,
                                isSelected: role == 'employee',
                                onTap: () => setDialogState(() => role = 'employee'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'مدير',
                                icon: Icons.admin_panel_settings,
                                color: AppColors.warning,
                                isSelected: role == 'admin',
                                onTap: () => setDialogState(() => role = 'admin'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty ||
                      usernameController.text.trim().isEmpty ||
                      passwordController.text.trim().isEmpty) {
                    _showError('يرجى ملء جميع الحقول');
                    return;
                  }
                  Navigator.pop(context);
                  await _addEmployee(
                    nameController.text.trim(),
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                    role,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.check, color: AppColors.charcoal),
                label: Text(
                  'إضافة',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.charcoal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withOpacity(0.5)),
        filled: true,
        fillColor: AppColors.darkGray.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.textSecondary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEmployee(String name, String username, String password, String role) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _showError('يجب تسجيل الدخول أولاً');
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:53365/api/users/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccess('تمت إضافة الموظف بنجاح');
        await _loadEmployees();
      } else {
        final data = json.decode(response.body);
        _showError(data['error'] ?? 'فشل في إضافة الموظف');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.charcoal, AppColors.darkGray],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGold.withOpacity(0.3),
                        AppColors.mediumGold.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          employee['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                          color: AppColors.primaryGold,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee['name'] ?? 'غير محدد',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.account_circle, color: AppColors.textSecondary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '@${employee['username']}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: employee['role'] == 'admin' 
                            ? AppColors.warning.withOpacity(0.2)
                            : AppColors.info.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: employee['role'] == 'admin' ? AppColors.warning : AppColors.info,
                          ),
                        ),
                        child: Text(
                          employee['role'] == 'admin' ? 'مدير' : 'موظف',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: employee['role'] == 'admin' ? AppColors.warning : AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildEmployeeStats(employee),
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkGray.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditEmployeeDialog(employee);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: Text(
                            'تعديل',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(employee);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: Text(
                            'حذف',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeStats(Map<String, dynamic> employee) {
    final stats = employee['stats'] as Map<String, dynamic>?;
    
    if (stats == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    final totalOrders = stats['totalOrders'] ?? 0;
    final completedOrders = stats['completedOrders'] ?? 0;
    final pendingOrders = stats['pendingOrders'] ?? 0;
    final totalRevenue = stats['totalRevenue'] ?? 0.0;
    final totalProfit = stats['totalProfit'] ?? 0.0;
    final completionRate = totalOrders > 0 
      ? ((completedOrders / totalOrders) * 100).toStringAsFixed(1)
      : '0.0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'إجمالي الطلبات',
                value: totalOrders.toString(),
                icon: Icons.shopping_bag,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'نسبة الإنجاز',
                value: '$completionRate%',
                icon: Icons.check_circle,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'مكتمل',
                value: completedOrders.toString(),
                icon: Icons.done_all,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'قيد الانتظار',
                value: pendingOrders.toString(),
                icon: Icons.pending,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'إجمالي المبيعات',
          value: '${totalRevenue.toStringAsFixed(0)} د.ع',
          icon: Icons.attach_money,
          color: AppColors.primaryGold,
          isWide: true,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          title: 'إجمالي الأرباح',
          value: '${totalProfit.toStringAsFixed(0)} د.ع',
          icon: Icons.trending_up,
          color: Colors.green,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isWide = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employee) {
    final nameController = TextEditingController(text: employee['name']);
    final usernameController = TextEditingController(text: employee['username']);
    final passwordController = TextEditingController();
    String role = employee['role'] ?? 'employee';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.edit, color: AppColors.info, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  'تعديل بيانات الموظف',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: nameController,
                    label: 'الاسم الكامل',
                    icon: Icons.badge,
                    hint: 'الاسم الكامل',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: usernameController,
                    label: 'اسم المستخدم',
                    icon: Icons.account_circle,
                    hint: 'اسم المستخدم',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    label: 'كلمة المرور الجديدة (اختياري)',
                    icon: Icons.lock,
                    hint: 'اتركه فارغاً للاحتفاظ بالقديمة',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الصلاحية',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleCard(
                                title: 'موظف',
                                icon: Icons.person,
                                color: AppColors.info,
                                isSelected: role == 'employee',
                                onTap: () => setDialogState(() => role = 'employee'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleCard(
                                title: 'مدير',
                                icon: Icons.admin_panel_settings,
                                color: AppColors.warning,
                                isSelected: role == 'admin',
                                onTap: () => setDialogState(() => role = 'admin'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateEmployee(
                    employee['id'],
                    nameController.text.trim(),
                    usernameController.text.trim(),
                    passwordController.text.trim(),
                    role,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'حفظ التعديلات',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateEmployee(int id, String name, String username, String password, String role) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _showError('يجب تسجيل الدخول أولاً');
        return;
      }

      if (password.isNotEmpty) {
        final response = await http.put(
          Uri.parse('http://localhost:53365/api/users/$id/password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'password': password}),
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to update password');
        }
      }

      _showSuccess('تم تحديث بيانات الموظف بنجاح');
      await _loadEmployees();
    } catch (e) {
      _showError('خطأ في التحديث: $e');
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 2),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف الموظف "${employee['name']}"؟\n\nسيتم حذف جميع بياناته من النظام.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteEmployee(employee['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: Text(
                'حذف نهائياً',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _showError('يجب تسجيل الدخول أولاً');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://localhost:53365/api/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _showSuccess('تم حذف الموظف بنجاح');
        await _loadEmployees();
      } else {
        _showError('فشل في حذف الموظف');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إدارة الموظفين',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
                color: AppColors.primaryGold,
              ),
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                });
              },
              tooltip: 'تغيير العرض',
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadEmployees,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : Column(
                    children: [
                      // Header Stats
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade700.withOpacity(0.3),
                                Colors.blue.shade700.withOpacity(0.3),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('👥', style: TextStyle(fontSize: 32)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'إجمالي الموظفين',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_employees.length}',
                                      style: AppTextStyles.displayMedium.copyWith(
                                        color: AppColors.textGold,
                                        fontSize: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  _buildMiniStat(
                                    'مدراء',
                                    _employees.where((e) => e['role'] == 'admin').length.toString(),
                                    AppColors.warning,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMiniStat(
                                    'موظفين',
                                    _employees.where((e) => e['role'] == 'employee').length.toString(),
                                    AppColors.info,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Employees List/Grid
                      Expanded(
                        child: _employees.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 80,
                                      color: AppColors.textSecondary.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا يوجد موظفين',
                                      style: AppTextStyles.headlineSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _viewMode == 'grid'
                                ? _buildGridView()
                                : _buildListView(),
                      ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: FloatingActionButton.extended(
            onPressed: _showAddEmployeeDialog,
            backgroundColor: AppColors.primaryGold,
            icon: Icon(Icons.person_add, color: AppColors.charcoal),
            label: Text(
              'إضافة موظف',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.charcoal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(_employees[index], index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeListTile(_employees[index], index);
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, int index) {
    final stats = employee['stats'] as Map<String, dynamic>?;
    final isAdmin = employee['role'] == 'admin';

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 100),
      child: InkWell(
        onTap: () => _showEmployeeDetails(employee),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isAdmin
                    ? AppColors.warning.withOpacity(0.15)
                    : AppColors.info.withOpacity(0.15),
                isAdmin
                    ? AppColors.warning.withOpacity(0.05)
                    : AppColors.info.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAdmin
                  ? AppColors.warning.withOpacity(0.3)
                  : AppColors.info.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? AppColors.warning : AppColors.info,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  employee['name'] ?? 'غير محدد',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${employee['username']}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (stats != null) ...[
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                        stats['totalOrders']?.toString() ?? '0',
                        'طلب',
                        Icons.shopping_bag,
                      ),
                      _buildQuickStat(
                        '${((stats['completedOrders'] ?? 0) / (stats['totalOrders'] ?? 1) * 100).toStringAsFixed(0)}%',
                        'إنجاز',
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeListTile(Map<String, dynamic> employee, int index) {
    final stats = employee['stats'] as Map<String, dynamic>?;
    final isAdmin = employee['role'] == 'admin';

    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isAdmin
                  ? AppColors.warning.withOpacity(0.15)
                  : AppColors.info.withOpacity(0.15),
              isAdmin
                  ? AppColors.warning.withOpacity(0.05)
                  : AppColors.info.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdmin
                ? AppColors.warning.withOpacity(0.3)
                : AppColors.info.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.warning.withOpacity(0.2)
                  : AppColors.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: isAdmin ? AppColors.warning : AppColors.info,
              size: 28,
            ),
          ),
          title: Text(
            employee['name'] ?? 'غير محدد',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '@${employee['username']}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (stats != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInlineStat(
                      '${stats['totalOrders']} طلب',
                      Icons.shopping_bag,
                    ),
                    const SizedBox(width: 16),
                    _buildInlineStat(
                      '${((stats['completedOrders'] ?? 0) / (stats['totalOrders'] ?? 1) * 100).toStringAsFixed(0)}% إنجاز',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: AppColors.primaryGold),
            onPressed: () => _showEmployeeDetails(employee),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
