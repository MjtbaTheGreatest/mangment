import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/animated_notification.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// الصفحة الرئيسية - تسجيل الطلبات
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'الكل';
  String? _username;
  String? _name;
  String? _role;
  bool _isLoading = true;
  String _sortBy = 'الأحدث'; // خيار الفرز الافتراضي
  String _cardSize = 'صغير جداً'; // الافتراضي: صغير جداً
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadCardSize();
    _checkAuthAndLoadUserInfo();
    _loadProducts();
  }

  Future<void> _loadCardSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cardSize = prefs.getString('card_size') ?? 'صغير جداً';
    });
  }

  Future<void> _saveCardSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_size', size);
  }

  Future<void> _checkAuthAndLoadUserInfo() async {
    // فحص حالة تسجيل الدخول
    final isLoggedIn = await ApiService.isLoggedIn();
    
    if (!isLoggedIn) {
      // إذا مو مسجل دخول، ارجع لصفحة تسجيل الدخول
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // تحميل معلومات المستخدم
    final username = await ApiService.getUsername();
    final name = await ApiService.getName();
    final role = await ApiService.getRole();
    
    setState(() {
      _username = username;
      _name = name;
      _role = role;
      _isLoading = false;
    });
  }

  Future<void> _loadProducts() async {
    try {
      final result = await ApiService.getProducts();
      print('📦 API Response: $result');
      print('📦 Products count: ${result['products']?.length ?? 0}');
      
      if (result['success'] == true && mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result['products']);
          print('📦 _products updated: ${_products.length} items');
        });
      } else {
        print('⚠️ Success is false or not mounted');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGold,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false, // منع الرجوع للخلف
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  // Category Tabs
                  _buildCategoryTabs(),

                  // Products Grid
                  Expanded(
                    child: _buildProductsGrid(),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddProductDialog,
            backgroundColor: AppColors.primaryGold,
            child: Icon(Icons.add, color: AppColors.pureBlack, size: 32),
          ),
          drawer: _buildDrawer(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.primaryGold, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'مرحباً، ${_name ?? _username ?? 'مستخدم'}',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                  ),
                ),
                Text(
                  _role == 'admin' ? 'مدير النظام' : 'موظف',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['الكل', 'ألعاب', 'اشتراكات'];
    
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Sort Button
            GestureDetector(
              onTap: _showSortOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.glassBlack,
                  border: Border.all(
                    color: AppColors.primaryGold,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort, color: AppColors.primaryGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _sortBy,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Card Size Button
            GestureDetector(
              onTap: _showCardSizeOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.glassBlack,
                  border: Border.all(
                    color: AppColors.primaryGold,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.view_compact, color: AppColors.primaryGold, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _cardSize,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Categories
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
            
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? AppColors.goldGradient
                            : null,
                        color: isSelected ? null : AppColors.glassBlack,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGold
                              : AppColors.glassWhite,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.pureBlack
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'ترتيب حسب',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textGold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSortOption('الأحدث', Icons.new_releases),
                  _buildSortOption('الأقدم', Icons.history),
                  _buildSortOption('الأعلى سعراً', Icons.arrow_upward),
                  _buildSortOption('الأقل سعراً', Icons.arrow_downward),
                  _buildSortOption('الاسم (أ-ي)', Icons.sort_by_alpha),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardSizeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'حجم البطاقات',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textGold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCardSizeOption('صغير جداً', Icons.view_agenda),
                  _buildCardSizeOption('صغير', Icons.view_module),
                  _buildCardSizeOption('متوسط', Icons.view_comfy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSizeOption(String title, IconData icon) {
    final isSelected = _cardSize == title;
    return GestureDetector(
      onTap: () {
        setState(() => _cardSize = title);
        _saveCardSize(title);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? AppColors.goldGradient
              : LinearGradient(
                  colors: [AppColors.glassWhite, AppColors.glassBlack],
                ),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.glassWhite,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pureBlack : AppColors.primaryGold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.pureBlack : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.pureBlack,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    final isSelected = _sortBy == title;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = title);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? AppColors.goldGradient
              : LinearGradient(
                  colors: [AppColors.glassWhite, AppColors.glassBlack],
                ),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.glassWhite,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pureBlack : AppColors.primaryGold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.pureBlack : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.pureBlack,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    // تصفية المنتجات حسب القسم المحدد
    final filteredProducts = _selectedCategory == 'الكل'
        ? _products
        : _products.where((p) => p['category'] == _selectedCategory).toList();

    // تحديد عدد الأعمدة حسب حجم البطاقة
    int crossAxisCount;
    double childAspectRatio;
    
    switch (_cardSize) {
      case 'صغير جداً':
        crossAxisCount = 5; // 5 بطاقات في الصف - أصغر
        childAspectRatio = 1.0; // مربع
        break;
      case 'صغير':
        crossAxisCount = 3; // 3 بطاقات في الصف
        childAspectRatio = 0.95;
        break;
      case 'متوسط':
      default:
        crossAxisCount = 2; // 2 بطاقات في الصف
        childAspectRatio = 0.95;
        break;
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isExtraSmall = _cardSize == 'صغير جداً';
    final isSmall = _cardSize == 'صغير';
    
    // استخدام سعر البيع إذا كان موجوداً، وإلا التكلفة، وإلا 0
    final displayPrice = product['sell_price'] ?? product['cost_price'] ?? 0;
    
    return GestureDetector(
      onTap: () => _showOrderDialog(product),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.charcoal,
              AppColors.darkGray,
            ],
          ),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // المحتوى الرئيسي
            Center(
              child: Padding(
                padding: EdgeInsets.all(isExtraSmall ? 10 : (isSmall ? 16 : 20)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // أيقونة المنتج
                    Container(
                      width: isExtraSmall ? 45 : (isSmall ? 60 : 70),
                      height: isExtraSmall ? 45 : (isSmall ? 60 : 70),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        product['category'] == 'ألعاب'
                            ? Icons.sports_esports
                            : Icons.subscriptions,
                        color: AppColors.pureBlack,
                        size: isExtraSmall ? 22 : (isSmall ? 28 : 32),
                      ),
                    ),
                    
                    SizedBox(height: isExtraSmall ? 8 : (isSmall ? 12 : 14)),
                    
                    // اسم المنتج
                    Text(
                      product['name']!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: isExtraSmall ? 13 : (isSmall ? 16 : 18),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: isExtraSmall ? 6 : (isSmall ? 10 : 12)),
                    
                    // السعر
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExtraSmall ? 10 : (isSmall ? 16 : 20),
                        vertical: isExtraSmall ? 5 : (isSmall ? 8 : 10),
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        displayPrice > 0 ? '${displayPrice.toStringAsFixed(0)} د.ع' : 'غير محدد',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.pureBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: isExtraSmall ? 12 : (isSmall ? 15 : 17),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // زر الحذف للمدراء فقط
            if (_role == 'admin')
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  onTap: () => _showDeleteProductDialog(product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: isExtraSmall ? 16 : (isSmall ? 18 : 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellPriceController = TextEditingController();
    String selectedCategory = 'ألعاب';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.charcoal,
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
                ),
                child: Icon(
                  Icons.add_shopping_cart,
                  color: AppColors.pureBlack,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إضافة منتج جديد',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اسم المنتج
                _buildDialogTextField(
                  controller: nameController,
                  label: 'اسم المنتج *',
                  icon: Icons.label,
                ),
                const SizedBox(height: 16),

                // القسم
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassWhite),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppColors.charcoal,
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      items: ['ألعاب', 'اشتراكات'].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                category == 'ألعاب' ? Icons.games : Icons.subscriptions,
                                color: AppColors.primaryGold,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(category),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // سعر التكلفة
                _buildDialogTextField(
                  controller: costPriceController,
                  label: 'سعر التكلفة *',
                  icon: Icons.price_change,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 16),

                // سعر البيع
                _buildDialogTextField(
                  controller: sellPriceController,
                  label: 'سعر البيع (اختياري)',
                  icon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  '* الحقول المطلوبة',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  AnimatedNotification.show(
                    context,
                    message: ' يرجى إدخال اسم المنتج',
                    type: NotificationType.warning,
                    duration: const Duration(seconds: 3),
                  );
                  return;
                }

                if (costPriceController.text.trim().isEmpty) {
                  AnimatedNotification.show(
                    context,
                    message: ' يرجى إدخال سعر التكلفة',
                    type: NotificationType.warning,
                    duration: const Duration(seconds: 3),
                  );
                  return;
                }

                final costPrice = double.tryParse(costPriceController.text);
                if (costPrice == null || costPrice <= 0) {
                  AnimatedNotification.show(
                    context,
                    message: ' يرجى إدخال سعر تكلفة صحيح',
                    type: NotificationType.warning,
                    duration: const Duration(seconds: 3),
                  );
                  return;
                }

                // إظهار مؤشر التحميل
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: const Color.fromARGB(123, 255, 217, 0),
                    ),
                  ),
                );

                final result = await ApiService.createProduct(
                  name: nameController.text.trim(),
                  category: selectedCategory,
                  costPrice: costPrice,
                  sellPrice: sellPriceController.text.isNotEmpty
                      ? double.tryParse(sellPriceController.text)
                      : null,
                );

                if (mounted) {
                  Navigator.pop(context); // إغلاق مؤشر التحميل
                  
                  print('📦 Create Product Result: $result');
                  print('📦 Success: ${result['success']}');
                  print('📦 Product: ${result['product']}');

                  if (result['success'] && result['product'] != null) {
                    // إضافة المنتج الجديد مباشرة للقائمة
                    setState(() {
                      _products.insert(0, Map<String, dynamic>.from(result['product']));
                      print('📦 Product added to list. Total products: ${_products.length}');
                    });
                    
                    // إغلاق الحوار
                    Navigator.pop(context);
                    
                    AnimatedNotification.show(
                      context,
                      message: '🎉 تمت إضافة "${result['product']['name']}" بنجاح',
                      type: NotificationType.success,
                    );
                  } else {
                    AnimatedNotification.show(
                      context,
                      message: result['message'] ?? 'خطأ في إضافة المنتج',
                      type: NotificationType.error,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(131, 255, 217, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'إضافة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.pureBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDialog(Map<String, dynamic> product) {
    final isSubscription = product['category'] == 'اشتراكات';
    
    final productNameController = TextEditingController(text: product['name']);
    final customerNameController = TextEditingController();
    final profileNameController = TextEditingController(); // للاشتراكات
    
    final costPrice = (product['cost_price'] ?? 0).toDouble();
    final sellPrice = (product['sell_price'] ?? costPrice).toDouble();
    
    final costController = TextEditingController(
      text: costPrice > 0 ? costPrice.toStringAsFixed(0) : '',
    );
    final priceController = TextEditingController(
      text: sellPrice > 0 ? sellPrice.toStringAsFixed(0) : '',
    );
    
    double calculatedProfit = sellPrice - costPrice;
    String paymentMethod = 'زين كاش';
    String subscriptionDuration = 'شهر واحد'; // المدة الافتراضية
    final notesController = TextEditingController();
    
    // للاشتراكات: تحميل قائمة الخدمات المتاحة
    List<Map<String, dynamic>> availableServices = [];
    int? selectedServiceId;
    bool loadingServices = isSubscription;

    // تحميل الخدمات إذا كان اشتراك
    if (isSubscription) {
      ApiService.getSubscriptions().then((response) {
        if (response['success'] == true) {
          final subscriptions = response['subscriptions'] as List;
          availableServices = subscriptions.map((s) => {
            'id': s['id'],
            'serviceName': s['serviceName'] ?? 'غير محدد',
            'accountNumber': s['accountNumber'] ?? '',
            'maxUsers': s['maxUsers'] ?? 0,
            'currentUsers': 0, // سيتم تحديثه
          }).toList();
          
          if (availableServices.isNotEmpty) {
            selectedServiceId = availableServices.first['id'] as int;
          }
        }
        loadingServices = false;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateProfit() {
            final cost = double.tryParse(costController.text) ?? 0;
            final price = double.tryParse(priceController.text) ?? 0;
            setDialogState(() {
              calculatedProfit = price - cost;
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGold, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.charcoal, AppColors.pureBlack],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_cart_checkout,
                            color: AppColors.pureBlack,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'تسجيل طلب',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // العمود الأيمن
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // اسم المنتج
                                _buildDialogTextField(
                                  controller: productNameController,
                                  label: 'اسم المنتج',
                                  icon: Icons.inventory_2,
                                ),
                                const SizedBox(height: 16),

                                // اسم الزبون
                                _buildDialogTextField(
                                  controller: customerNameController,
                                  label: 'اسم الزبون *',
                                  icon: Icons.person,
                                ),
                                const SizedBox(height: 16),

                                // اختيار الخدمة (للاشتراكات فقط)
                                if (isSubscription) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassBlack,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.glassWhite),
                                    ),
                                    child: loadingServices
                                        ? Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primaryGold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: selectedServiceId,
                                              isExpanded: true,
                                              dropdownColor: AppColors.charcoal,
                                              icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                              hint: Text(
                                                'اختر الخدمة *',
                                                style: AppTextStyles.bodyMedium.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              items: availableServices.map((service) {
                                                return DropdownMenuItem<int>(
                                                  value: service['id'] as int,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.subscriptions,
                                                        color: AppColors.primaryGold,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              '${service['serviceName']}',
                                                              style: AppTextStyles.bodyMedium.copyWith(
                                                                color: AppColors.textPrimary,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            if (service['accountNumber'] != null && service['accountNumber'].toString().isNotEmpty)
                                                              Text(
                                                                'حساب: ${service['accountNumber']}',
                                                                style: AppTextStyles.bodySmall.copyWith(
                                                                  color: AppColors.textSecondary,
                                                                  fontSize: 11,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setDialogState(() => selectedServiceId = value);
                                              },
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  _buildDialogTextField(
                                    controller: profileNameController,
                                    label: 'اسم البروفايل *',
                                    icon: Icons.account_circle,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // سعر التكلفة
                                _buildDialogTextField(
                                  controller: costController,
                                  label: 'سعر التكلفة',
                                  icon: Icons.price_change,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  onChanged: (value) => updateProfit(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // العمود الأيسر
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // سعر البيع
                                _buildDialogTextField(
                                  controller: priceController,
                                  label: 'سعر البيع *',
                                  icon: Icons.sell,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  onChanged: (value) => updateProfit(),
                                ),
                                const SizedBox(height: 16),

                                // الربح المتوقع
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: calculatedProfit >= 0 
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: calculatedProfit >= 0 
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.trending_up,
                                            color: calculatedProfit >= 0 
                                                ? AppColors.success
                                                : AppColors.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'الربح المتوقع:',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${calculatedProfit.toStringAsFixed(0)} د.ع',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: calculatedProfit >= 0 
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // مدة الاشتراك (للاشتراكات فقط)
                                if (isSubscription) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassBlack,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.glassWhite),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: subscriptionDuration,
                                        isExpanded: true,
                                        dropdownColor: AppColors.charcoal,
                                        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        items: [
                                          {'value': 'شهر واحد', 'emoji': '📅'},
                                          {'value': 'شهرين', 'emoji': '📅'},
                                          {'value': 'ثلاثة أشهر', 'emoji': '📅'},
                                          {'value': 'أربعة أشهر', 'emoji': '📅'},
                                          {'value': 'خمسة أشهر', 'emoji': '📅'},
                                          {'value': 'ستة أشهر', 'emoji': '📅'},
                                          {'value': 'سنة', 'emoji': '📆'},
                                        ].map((duration) {
                                          return DropdownMenuItem(
                                            value: duration['value'] as String,
                                            child: Row(
                                              children: [
                                                Text(
                                                  duration['emoji'] as String,
                                                  style: const TextStyle(fontSize: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(duration['value'] as String),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setDialogState(() => subscriptionDuration = value!);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // طريقة الدفع
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassBlack,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.glassWhite),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: paymentMethod,
                                      isExpanded: true,
                                      dropdownColor: AppColors.charcoal,
                                      icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGold),
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      items: [
                                        {'value': 'زين كاش', 'emoji': '📱'},
                                        {'value': 'آفدين', 'emoji': '💳'},
                                        {'value': 'آسياسيل', 'emoji': '📞'},
                                        {'value': 'نقدي', 'emoji': '💵'},
                                      ].map((method) {
                                        return DropdownMenuItem(
                                          value: method['value'] as String,
                                          child: Row(
                                            children: [
                                              Text(
                                                method['emoji'] as String,
                                                style: const TextStyle(fontSize: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(method['value'] as String),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setDialogState(() => paymentMethod = value!);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // ملاحظات
                                _buildDialogTextField(
                                  controller: notesController,
                                  label: 'ملاحظات (اختياري)',
                                  icon: Icons.note,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.glassBlack,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '* الحقول المطلوبة',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'إلغاء',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                  // التحقق من المدخلات
                  if (customerNameController.text.trim().isEmpty) {
                    AnimatedNotification.show(
                      context,
                      message: '⚠️ يرجى إدخال اسم الزبون',
                      type: NotificationType.warning,
                    );
                    return;
                  }

                  // التحقق من اختيار الخدمة للاشتراكات
                  if (isSubscription && selectedServiceId == null) {
                    AnimatedNotification.show(
                      context,
                      message: '⚠️ يرجى اختيار الخدمة',
                      type: NotificationType.warning,
                    );
                    return;
                  }

                  // التحقق من اسم البروفايل للاشتراكات
                  if (isSubscription && profileNameController.text.trim().isEmpty) {
                    AnimatedNotification.show(
                      context,
                      message: '⚠️ يرجى إدخال اسم البروفايل',
                      type: NotificationType.warning,
                    );
                    return;
                  }

                  final price = double.tryParse(priceController.text);
                  if (price == null || price <= 0) {
                    AnimatedNotification.show(
                      context,
                      message: '⚠️ يرجى إدخال سعر بيع صحيح',
                      type: NotificationType.warning,
                    );
                    return;
                  }

                  // حفظ الـ context قبل العمليات غير المتزامنة
                  final dialogContext = context;

                  // إظهار مؤشر التحميل
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (loadingContext) => Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGold,
                      ),
                    ),
                  );

                  Map<String, dynamic> result;
                  
                  // إذا كان اشتراك، نضيف المشترك للخدمة المختارة
                  if (isSubscription && selectedServiceId != null) {
                    // حساب عدد الأشهر من المدة المختارة
                    int months = 1;
                    if (subscriptionDuration == 'شهرين') {
                      months = 2;
                    } else if (subscriptionDuration == 'ثلاثة أشهر') months = 3;
                    else if (subscriptionDuration == 'أربعة أشهر') months = 4;
                    else if (subscriptionDuration == 'خمسة أشهر') months = 5;
                    else if (subscriptionDuration == 'ستة أشهر') months = 6;
                    else if (subscriptionDuration == 'سنة') months = 12;
                    
                    final startDate = DateTime.now();
                    final endDate = DateTime.now().add(Duration(days: months * 30));
                    
                    // إضافة المشترك للخدمة المختارة (وليس المنتج)
                    result = await ApiService.addSubscriptionUser(
                      subscriptionId: selectedServiceId!, // استخدام الخدمة المختارة
                      customerName: customerNameController.text.trim(),
                      profileName: profileNameController.text.trim(),
                      amount: price,
                      startDate: startDate.toIso8601String(),
                      endDate: endDate.toIso8601String(),
                    );
                    
                    // الحصول على اسم الخدمة المختارة
                    final selectedService = availableServices.firstWhere(
                      (s) => s['id'] == selectedServiceId,
                      orElse: () => {'serviceName': 'غير محدد'},
                    );
                    
                    // أيضاً نسجل الطلب للتقارير
                    await ApiService.createOrder(
                      productId: product['id'] ?? 0,
                      productName: '${product['name']} - ${selectedService['serviceName']}',
                      customerName: customerNameController.text.trim(),
                      customerPhone: null,
                      cost: double.tryParse(costController.text) ?? 0,
                      price: price,
                      profit: calculatedProfit,
                      paymentMethod: paymentMethod,
                      category: product['category'] ?? 'غير محدد',
                      notes: 'خدمة: ${selectedService['serviceName']} | بروفايل: ${profileNameController.text.trim()} | مدة: $subscriptionDuration${notesController.text.trim().isNotEmpty ? ' | ${notesController.text.trim()}' : ''}',
                    );
                  } else {
                    // إرسال الطلب العادي للسيرفر
                    result = await ApiService.createOrder(
                      productId: product['id'] ?? 0,
                      productName: productNameController.text.trim(),
                      customerName: customerNameController.text.trim(),
                      customerPhone: null,
                      cost: double.tryParse(costController.text) ?? 0,
                      price: price,
                      profit: calculatedProfit,
                      paymentMethod: paymentMethod,
                      category: product['category'] ?? 'غير محدد',
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    );
                  }

                  // خصم التكلفة من رأس المال تلقائياً
                  if (result['success']) {
                    final cost = double.tryParse(costController.text) ?? 0;
                    if (cost > 0) {
                      final productName = product['name'] ?? 'غير معروف';
                      final customerName = customerNameController.text.trim();
                      final orderDetails = '$productName - $customerName';
                      await ApiService.withdrawForOrder(cost, orderDetails);
                    }
                  }

                  if (mounted) {
                    Navigator.of(dialogContext).pop(); // إغلاق مؤشر التحميل
                    Navigator.of(dialogContext).pop(); // إغلاق حوار تسجيل الطلب

                    AnimatedNotification.show(
                      dialogContext,
                      message: result['success'] 
                          ? '✅ ${result['message'] ?? (isSubscription ? 'تم إضافة المشترك بنجاح' : 'تم تسجيل الطلب بنجاح')}' 
                          : '❌ ${result['message'] ?? 'خطأ في العملية'}',
                      type: result['success'] ? NotificationType.success : NotificationType.error,
                    );
                    
                    // إعادة تحميل المنتجات
                    if (result['success']) {
                      _loadProducts();
                    }
                  }
                },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تسجيل الطلب',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.pureBlack,
                                      fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    int? maxLines,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      maxLines: maxLines ?? 1,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        filled: true,
        fillColor: AppColors.glassBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.charcoal,
              AppColors.pureBlack,
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradient,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.pureBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _name ?? _username ?? 'مستخدم',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textGold,
                          ),
                        ),
                        Text(
                          _role == 'admin' ? 'مدير النظام' : 'موظف',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.glassWhite, thickness: 1),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildDrawerItem(
                          icon: Icons.home,
                          title: 'الصفحة الرئيسية',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildDrawerItem(
                          icon: Icons.person,
                          title: 'الملف الشخصي',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        
                        Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                        
                        // Shared screens for Admin and Employee
                        _buildDrawerItem(
                          icon: Icons.subscriptions,
                          title: 'إدارة الاشتراكات',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/subscriptions');
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_bag,
                          title: 'إدارة الطلبات',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/orders');
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.archive,
                          title: 'الأرشيف',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/archive');
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.monetization_on_rounded,
                          title: 'التحاسب',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/settlement');
                          },
                        ),
                        
                        // Admin only screens
                        if (_role == 'admin') ...[
                          Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'إدارة المدير',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildDrawerItem(
                            icon: Icons.bar_chart,
                            title: 'الإحصائيات',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/statistics');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.account_balance_wallet,
                            title: 'رأس المال',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/capital');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.people,
                            title: 'إدارة الموظفين',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/employees');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.receipt_long_rounded,
                            title: 'إدارة التحاسبات',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/settlements-management');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.settings,
                            title: 'الإعدادات',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Divider(color: AppColors.glassWhite, thickness: 1),
                        
                        _buildDrawerItem(
                          icon: Icons.logout,
                          title: 'تسجيل الخروج',
                          onTap: () async {
                            await ApiService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGold),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      hoverColor: AppColors.glassWhite,
    );
  }

  void _showDeleteProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.charcoal,
                  AppColors.charcoal.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'تأكيد الحذف',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'هل أنت متأكد من حذف المنتج "${product['name']}"؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا يمكن التراجع عن هذا الإجراء',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mediumGray,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Delete Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext loadingContext) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGold,
                                ),
                              );
                            },
                          );
                          
                          try {
                            final result = await ApiService.deleteProduct(product['id']);
                            
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              
                              if (result['success'] == true) {
                                AnimatedNotification.show(
                                  context,
                                  message: '✨ تم حذف المنتج "${product['name']}" بنجاح',
                                  type: NotificationType.delete,
                                );
                                
                                // Reload products
                                _loadProducts();
                              } else {
                                AnimatedNotification.show(
                                  context,
                                  message: result['message'] ?? 'فشل حذف المنتج',
                                  type: NotificationType.error,
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              AnimatedNotification.show(
                                context,
                                message: 'حدث خطأ: $e',
                                type: NotificationType.error,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'حذف',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
