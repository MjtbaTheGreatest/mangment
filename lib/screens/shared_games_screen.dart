import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة إدارة الألعاب المشتركة
class SharedGamesScreen extends StatefulWidget {
  const SharedGamesScreen({super.key});

  @override
  State<SharedGamesScreen> createState() => _SharedGamesScreenState();
}

class _SharedGamesScreenState extends State<SharedGamesScreen> {
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadGames();
  }

  Future<void> _loadUserRole() async {
    final role = await ApiService.getRole();
    setState(() => _role = role);
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSharedGames();
      if (response['success'] == true && mounted) {
        setState(() {
          _games = List<Map<String, dynamic>>.from(response['games'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل الألعاب: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingIndicator()
                      : _games.isEmpty
                          ? _buildEmptyState()
                          : _buildGamesList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildAddButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, AppColors.pureBlack],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.primaryGold),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              color: AppColors.pureBlack,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الألعاب المشتركة',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                  ),
                ),
                Text(
                  'إدارة الحسابات المشتركة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // زر التحديث
          IconButton(
            onPressed: _loadGames,
            icon: Icon(Icons.refresh, color: AppColors.primaryGold),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 80,
              color: AppColors.primaryGold.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد ألعاب مشتركة',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة لعبة جديدة',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 80),
          duration: const Duration(milliseconds: 500),
          child: _buildGameCard(_games[index]),
        );
      },
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final customersCount = game['customers_count'] ?? 0;
    final maxUsers = game['max_users'] ?? 1;
    final isFull = customersCount >= maxUsers;
    final percentage = maxUsers > 0 ? (customersCount / maxUsers) : 0.0;

    return GestureDetector(
      onTap: () => _openGameDetails(game),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.charcoal.withOpacity(0.95),
                AppColors.pureBlack,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFull 
                  ? Colors.red.withOpacity(0.6)
                  : AppColors.primaryGold.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isFull 
                    ? Colors.red.withOpacity(0.25)
                    : AppColors.primaryGold.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Background gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGold.withOpacity(0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                
                // محتوى البطاقة
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header مع أيقونة
                      Row(
                        children: [
                          // أيقونة اللعبة مع تأثير
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isFull
                                  ? LinearGradient(
                                      colors: [Colors.red, Colors.red.shade700],
                                    )
                                  : AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isFull ? Colors.red : AppColors.primaryGold).withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_esports_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                          // زر تعديل
                          if (_role == 'admin')
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () => _showEditGameDialog(game),
                                icon: Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primaryGold,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // اسم اللعبة
                      Text(
                        game['game_name'] ?? '',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Progress bar مع أنيميشن
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_rounded,
                                    color: isFull ? Colors.red : AppColors.primaryGold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الزبائن',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$customersCount / $maxUsers',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isFull ? Colors.red : AppColors.primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.charcoal,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isFull
                                            ? [Colors.red, Colors.red.shade700]
                                            : [AppColors.primaryGold, AppColors.mediumGold],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isFull ? Colors.red : AppColors.primaryGold).withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // مؤشر امتلاء مع أنيميشن
                if (isFull)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: FadeIn(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.shade700],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ممتلئ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // زر حذف (للمدراء فقط)
                if (_role == 'admin')
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteGame(game['id']),
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        tooltip: 'حذف اللعبة',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddGameDialog,
      backgroundColor: AppColors.primaryGold,
      icon: Icon(Icons.add, color: AppColors.pureBlack),
      label: Text(
        'إضافة لعبة',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.pureBlack,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEditGameDialog(Map<String, dynamic> game) {
    final gameNameController = TextEditingController(text: game['game_name']);
    final emailController = TextEditingController(text: game['email'] ?? '');
    final passwordController = TextEditingController(text: game['password'] ?? '');
    final maxUsersController = TextEditingController(text: '${game['max_users'] ?? 1}');
    final notesController = TextEditingController(text: game['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.pureBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.primaryGold, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.edit_rounded, color: AppColors.pureBlack, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تعديل اللعبة',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textGold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: gameNameController,
                  label: 'اسم اللعبة *',
                  icon: Icons.sports_esports,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: maxUsersController,
                  label: 'الحد الأقصى للمستخدمين',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: notesController,
                  label: 'ملاحظات',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (gameNameController.text.trim().isEmpty) {
                  _showError('اسم اللعبة مطلوب');
                  return;
                }

                Navigator.pop(context);

                final result = await ApiService.updateSharedGame(
                  gameId: game['id'],
                  gameName: gameNameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  maxUsers: int.tryParse(maxUsersController.text) ?? 1,
                  notes: notesController.text.trim(),
                );

                if (result['success'] == true) {
                  _showSuccess('تم تحديث اللعبة بنجاح');
                  _loadGames();
                } else {
                  _showError(result['message'] ?? 'فشل التحديث');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'حفظ',
                style: TextStyle(color: AppColors.pureBlack, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGameDialog() {
    final gameNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final maxUsersController = TextEditingController(text: '1');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: FadeIn(
          duration: const Duration(milliseconds: 300),
          child: AlertDialog(
            backgroundColor: AppColors.pureBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.primaryGold, width: 2),
            ),
            title: FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.sports_esports, color: AppColors.pureBlack, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'إضافة لعبة مشتركة',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.pureBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          content: SingleChildScrollView(
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: gameNameController,
                    label: 'اسم اللعبة *',
                    icon: Icons.sports_esports,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: maxUsersController,
                    label: 'الحد الأقصى للمستخدمين',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: notesController,
                    label: 'ملاحظات',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FadeInLeft(
              delay: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ),
            ),
            FadeInRight(
              delay: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: () async {
                  if (gameNameController.text.trim().isEmpty) {
                    _showError('اسم اللعبة مطلوب');
                    return;
                  }

                  Navigator.pop(context);

                  final result = await ApiService.createSharedGame(
                    gameName: gameNameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    maxUsers: int.tryParse(maxUsersController.text) ?? 1,
                    notes: notesController.text.trim(),
                  );

                  if (result['success'] == true) {
                    _showSuccess('تم إضافة اللعبة بنجاح');
                    _loadGames();
                  } else {
                    _showError(result['message'] ?? 'فشل إضافة اللعبة');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 5,
                  shadowColor: AppColors.primaryGold.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.pureBlack),
                    const SizedBox(width: 8),
                    Text(
                      'إضافة',
                      style: TextStyle(
                        color: AppColors.pureBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withOpacity(0.1),
            AppColors.primaryGold.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        maxLines: maxLines,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.pureBlack, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  void _openGameDetails(Map<String, dynamic> game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailsScreen(game: game),
      ),
    ).then((_) => _loadGames()); // تحديث القائمة عند الرجوع
  }

  Future<void> _deleteGame(int gameId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.pureBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: AppTextStyles.headlineSmall.copyWith(color: Colors.red),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف هذه اللعبة؟\nسيتم حذف جميع العملاء المرتبطين بها.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteSharedGame(gameId);
      if (result['success'] == true) {
        _showSuccess('تم حذف اللعبة بنجاح');
        _loadGames();
      } else {
        _showError(result['message'] ?? 'فشل الحذف');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// صفحة تفاصيل اللعبة + العملاء
class GameDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getGameCustomers(widget.game['id']);
      if (response['success'] == true && mounted) {
        setState(() {
          _customers = List<Map<String, dynamic>>.from(response['customers'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل العملاء: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersCount = _customers.length;
    final maxUsers = widget.game['max_users'] ?? 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(customersCount, maxUsers),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                          ),
                        )
                      : _customers.isEmpty
                          ? _buildEmptyState()
                          : _buildCustomersList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: customersCount < maxUsers
            ? FloatingActionButton.extended(
                onPressed: _showAddCustomerDialog,
                backgroundColor: AppColors.primaryGold,
                icon: Icon(Icons.person_add, color: AppColors.pureBlack),
                label: Text(
                  'إضافة زبون',
                  style: TextStyle(
                    color: AppColors.pureBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader(int customersCount, int maxUsers) {
    final percentage = maxUsers > 0 ? (customersCount / maxUsers) : 0.0;
    final isFull = customersCount >= maxUsers;
    final totalRevenue = _customers.fold<double>(0, (sum, customer) => sum + (customer['amount_paid'] ?? 0));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal,
            AppColors.pureBlack,
            AppColors.primaryGold.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top row with back button and refresh
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: AppColors.pureBlack),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game['game_name'] ?? '',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textGold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Full badge
                    if (isFull)
                      FadeIn(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block, color: Colors.red, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'اللعبة ممتلئة',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: _loadCustomers,
                  icon: Icon(Icons.refresh, color: AppColors.primaryGold),
                  tooltip: 'تحديث',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Statistics cards
          Row(
            children: [
              // Customers count card
              Expanded(
                child: FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: _buildStatCard(
                    Icons.people,
                    'عدد الزبائن',
                    '$customersCount / $maxUsers',
                    percentage,
                    isFull,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Revenue card
              Expanded(
                child: FadeInRight(
                  delay: const Duration(milliseconds: 200),
                  child: _buildStatCard(
                    Icons.attach_money,
                    'إجمالي الإيرادات',
                    '${totalRevenue.toStringAsFixed(0)} د.ع',
                    1.0,
                    false,
                  ),
                ),
              ),
            ],
          ),
          
          // Account info
          if (widget.game['email'] != null && widget.game['email'].toString().isNotEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGold.withOpacity(0.1),
                      AppColors.primaryGold.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.email, 'البريد', widget.game['email']),
                    if (widget.game['password'] != null && widget.game['password'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.lock, 'كلمة المرور', widget.game['password']),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(IconData icon, String label, String value, double percentage, bool isFull) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.charcoal.withOpacity(0.8),
            AppColors.pureBlack.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFull ? Colors.red.withOpacity(0.5) : AppColors.primaryGold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isFull ? Colors.red : AppColors.primaryGold).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isFull 
                    ? LinearGradient(colors: [Colors.red, Colors.redAccent])
                    : AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: (isFull ? Colors.red : AppColors.primaryGold).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.pureBlack, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isFull ? Colors.red : AppColors.textGold,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (label.contains('الزبائن')) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? Colors.red : AppColors.primaryGold,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.bodySmall.copyWith(
                color: isFull ? Colors.red : AppColors.primaryGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.primaryGold.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد زبائن بعد',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر + لإضافة زبون',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: _buildCustomerCard(_customers[index]),
        );
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final amountPaid = customer['amount_paid'] ?? 0;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.charcoal.withOpacity(0.9),
              AppColors.pureBlack.withOpacity(0.95),
              AppColors.primaryGold.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.person,
                  size: 100,
                  color: AppColors.primaryGold.withOpacity(0.05),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and actions
                    Row(
                      children: [
                        // Avatar with gradient
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.pureBlack,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer['customer_name'] ?? '',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Badge showing purchase date
                              if (customer['purchase_date'] != null && customer['purchase_date'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: AppColors.primaryGold,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer['purchase_date'],
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textGold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _deleteCustomer(customer['id']),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: 20,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                            tooltip: 'حذف الزبون',
                          ),
                        ),
                      ],
                    ),
                    
                    // Divider with gradient
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primaryGold.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    
                    // Details grid
                    Row(
                      children: [
                        // Device info
                        if (customer['device_name'] != null && customer['device_name'].toString().isNotEmpty)
                          Expanded(
                            child: _buildDetailBox(
                              Icons.devices,
                              'الجهاز',
                              customer['device_name'],
                              AppColors.primaryGold.withOpacity(0.15),
                            ),
                          ),
                        
                        if (customer['device_name'] != null && customer['device_name'].toString().isNotEmpty && amountPaid > 0)
                          const SizedBox(width: 12),
                        
                        // Amount info
                        if (amountPaid > 0)
                          Expanded(
                            child: _buildDetailBox(
                              Icons.payments,
                              'المبلغ',
                              '$amountPaid د.ع',
                              Colors.green.withOpacity(0.15),
                            ),
                          ),
                      ],
                    ),
                    
                    // Notes section
                    if (customer['notes'] != null && customer['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGold.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.notes,
                              color: AppColors.primaryGold,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer['notes'],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailBox(IconData icon, String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGold,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddCustomerDialog() {
    final customerNameController = TextEditingController();
    final deviceNameController = TextEditingController();
    final amountController = TextEditingController();
    final purchaseDateController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: FadeIn(
          duration: const Duration(milliseconds: 300),
          child: AlertDialog(
            backgroundColor: AppColors.pureBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppColors.primaryGold, width: 2),
            ),
            title: FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppColors.pureBlack, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'إضافة زبون',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.pureBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          content: SingleChildScrollView(
            child: FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: customerNameController,
                    label: 'اسم الزبون *',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: deviceNameController,
                    label: 'اسم الجهاز (اختياري)',
                    icon: Icons.devices,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: amountController,
                    label: 'المبلغ المدفوع (اختياري)',
                    icon: Icons.payments,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: purchaseDateController,
                    label: 'تاريخ الشراء (اختياري)',
                    icon: Icons.date_range,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: notesController,
                    label: 'ملاحظات (اختياري)',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FadeInLeft(
              delay: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ),
            ),
            FadeInRight(
              delay: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: () async {
                  if (customerNameController.text.trim().isEmpty) {
                    _showError('اسم الزبون مطلوب');
                    return;
                  }

                  Navigator.pop(context);

                  final result = await ApiService.addGameCustomer(
                    gameId: widget.game['id'],
                    customerName: customerNameController.text.trim(),
                    deviceName: deviceNameController.text.trim(),
                    amountPaid: double.tryParse(amountController.text),
                    purchaseDate: purchaseDateController.text.trim(),
                    notes: notesController.text.trim(),
                  );

                  if (result['success'] == true) {
                    _showSuccess('تم إضافة الزبون بنجاح');
                    _loadCustomers();
                  } else {
                    _showError(result['message'] ?? 'فشل إضافة الزبون');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 5,
                  shadowColor: AppColors.primaryGold.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.pureBlack),
                    const SizedBox(width: 8),
                    Text(
                      'إضافة',
                      style: TextStyle(
                        color: AppColors.pureBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        filled: true,
        fillColor: AppColors.charcoal.withOpacity(0.5),
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

  Future<void> _deleteCustomer(int customerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.pureBlack,
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الزبون؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteGameCustomer(customerId);
      if (result['success'] == true) {
        _showSuccess('تم حذف الزبون بنجاح');
        _loadCustomers();
      } else {
        _showError(result['message'] ?? 'فشل الحذف');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
