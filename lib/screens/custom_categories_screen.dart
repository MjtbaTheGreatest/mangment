import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// شاشة تخصيص الأقسام
class CustomCategoriesScreen extends StatefulWidget {
  const CustomCategoriesScreen({super.key});

  @override
  State<CustomCategoriesScreen> createState() => _CustomCategoriesScreenState();
}

class _CustomCategoriesScreenState extends State<CustomCategoriesScreen> {
  bool _isLoading = true;
  bool _shareWithEmployees = false;
  List<Map<String, dynamic>> _customCategories = [];
  List<Map<String, dynamic>> _allProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 تحميل البيانات...');
      
      // تحميل الأقسام المخصصة
      final categoriesResponse = await ApiService.getCustomCategories();
      print('📁 الأقسام المحملة: ${categoriesResponse['categories']?.length ?? 0}');
      
      // تحميل جميع المنتجات
      final productsResponse = await ApiService.getProducts();
      print('📦 المنتجات المحملة: ${productsResponse['products']?.length ?? 0}');
      
      // تحميل إعدادات المشاركة
      final settingsResponse = await ApiService.getCustomCategoriesSettings();
      print('⚙️ إعدادات المشاركة: ${settingsResponse['share_with_employees']}');
      
      if (mounted) {
        setState(() {
          _customCategories = List<Map<String, dynamic>>.from(categoriesResponse['categories'] ?? []);
          _allProducts = List<Map<String, dynamic>>.from(productsResponse['products'] ?? []);
          _shareWithEmployees = settingsResponse['share_with_employees'] ?? false;
          _isLoading = false;
        });
        print('✅ تم تحديث الحالة بنجاح');
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('فشل تحميل البيانات', e.toString());
      }
    }
  }

  Future<void> _toggleSharing(bool value) async {
    try {
      print('🔄 تحديث إعدادات المشاركة إلى: $value');
      final response = await ApiService.updateCustomCategoriesSettings(shareWithEmployees: value);
      print('✅ استجابة تحديث الإعدادات: $response');
      
      if (response['success'] == true && mounted) {
        setState(() => _shareWithEmployees = value);
        _showSuccessMessage(value ? 'تم تفعيل المشاركة مع الموظفين' : 'تم إيقاف المشاركة');
      } else if (mounted) {
        _showErrorDialog('خطأ', response['message'] ?? 'فشل تحديث الإعدادات');
      }
    } catch (e) {
      print('❌ خطأ في تحديث الإعدادات: $e');
      if (mounted) {
        _showErrorDialog('خطأ', 'فشل تحديث الإعدادات: ${e.toString()}');
      }
    }
  }

  Future<void> _createCategory() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category, color: AppColors.primaryGold, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'قسم جديد',
              style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
            ),
          ],
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textGold),
          decoration: InputDecoration(
            hintText: 'اسم القسم',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.glassBlack,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'إنشاء',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.pureBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        print('🔄 محاولة إنشاء قسم: ${nameController.text.trim()}');
        final response = await ApiService.createCustomCategory(nameController.text.trim());
        print('✅ استجابة API: $response');
        
        if (response['success'] == true) {
          await _loadData();
          if (mounted) {
            _showSuccessMessage('تم إنشاء القسم بنجاح');
          }
        } else {
          if (mounted) {
            _showErrorDialog('خطأ', response['message'] ?? 'فشل إنشاء القسم');
          }
        }
      } catch (e) {
        print('❌ خطأ في إنشاء القسم: $e');
        if (mounted) {
          _showErrorDialog('خطأ', 'فشل إنشاء القسم: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _showCategoryProducts(Map<String, dynamic> category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsScreen(
          category: category,
          allProducts: _allProducts,
          onUpdate: _loadData,
        ),
      ),
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text('تأكيد الحذف', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا القسم؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('حذف', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteCustomCategory(categoryId);
        await _loadData();
        _showSuccessMessage('تم حذف القسم');
      } catch (e) {
        _showErrorDialog('خطأ', 'فشل حذف القسم');
      }
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
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGold),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSharingToggle(),
                          const SizedBox(height: 24),
                          _buildCategoriesList(),
                          const SizedBox(height: 20),
                          _buildCreateButton(),
                        ],
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

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withOpacity(0.1),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.primaryGold, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category, color: AppColors.pureBlack, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              'تخصيص الأقسام',
              style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textGold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingToggle() {
    return FadeInRight(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.charcoal,
              AppColors.darkGray,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.share, color: AppColors.primaryGold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مشاركة الأقسام',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'السماح للموظفين الآخرين برؤية أقسامك',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: _shareWithEmployees,
              onChanged: _toggleSharing,
              activeThumbColor: AppColors.primaryGold,
              activeTrackColor: AppColors.primaryGold.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_customCategories.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.category_outlined, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'لا توجد أقسام مخصصة',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على "إنشاء قسم جديد" للبدء',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأقسام المخصصة',
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _customCategories.length,
          (index) => FadeInUp(
            duration: Duration(milliseconds: 400 + (index * 100)),
            child: _buildCategoryCard(_customCategories[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final productsCount = category['products_count'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.charcoal, AppColors.darkGray],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCategoryProducts(category),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder, color: AppColors.pureBlack, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'] ?? 'قسم',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$productsCount منتج',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _deleteCategory(category['id']),
                ),
                Icon(Icons.chevron_left, color: AppColors.primaryGold),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _createCategory,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(
            'إنشاء قسم جديد',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGold,
            foregroundColor: AppColors.pureBlack,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(title, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)),
        content: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }
}

/// شاشة منتجات القسم
class CategoryProductsScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  final List<Map<String, dynamic>> allProducts;
  final VoidCallback onUpdate;

  const CategoryProductsScreen({
    super.key,
    required this.category,
    required this.allProducts,
    required this.onUpdate,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<int> _selectedProductIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryProducts() async {
    try {
      final response = await ApiService.getCategoryProducts(widget.category['id']);
      setState(() {
        _selectedProductIds = List<int>.from(response['product_ids'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleProduct(int productId, bool isSelected) async {
    try {
      if (isSelected) {
        await ApiService.addProductToCategory(widget.category['id'], productId);
        setState(() => _selectedProductIds.add(productId));
      } else {
        await ApiService.removeProductFromCategory(widget.category['id'], productId);
        setState(() => _selectedProductIds.remove(productId));
      }
      widget.onUpdate();
    } catch (e) {
      _showErrorDialog('خطأ', 'فشل تحديث المنتج');
    }
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    var products = widget.allProducts;
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      products = products.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGold),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isSelected = _selectedProductIds.contains(product['id']);
                        return _buildProductItem(product, isSelected);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withOpacity(0.1),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.primaryGold, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.category['name'] ?? 'القسم',
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
                  ),
                  Text(
                    'اختر المنتجات',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withOpacity(0.15),
              AppColors.mediumGold.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGold),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppColors.primaryGold),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, bool isSelected) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.charcoal, AppColors.darkGray],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? AppColors.primaryGold 
              : AppColors.primaryGold.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(isSelected ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.games,
                  color: AppColors.primaryGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? 'منتج',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product['sell_price'] ?? 0} د.ع',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSelected,
                onChanged: (value) => _toggleProduct(product['id'], value),
                activeThumbColor: AppColors.primaryGold,
                activeTrackColor: AppColors.primaryGold.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text(title, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)),
        content: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }
}
