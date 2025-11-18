/// فئة للتحقق من صحة المدخلات
class Validators {
  // التحقق من اسم المستخدم
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال اسم المستخدم';
    }
    if (value.length < 3) {
      return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 20) {
      return 'اسم المستخدم يجب أن لا يزيد عن 20 حرف';
    }
    return null;
  }

  // التحقق من كلمة المرور
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (value.length > 50) {
      return 'كلمة المرور طويلة جداً';
    }
    return null;
  }

  // التحقق من البريد الإلكتروني
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  // التحقق من رقم الهاتف (سعودي)
  static String? validatePhoneSA(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    // إزالة المسافات والرموز
    final cleanValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // التحقق من التنسيق السعودي
    final phoneRegex = RegExp(r'^(05|5)[0-9]{8}$');

    if (!phoneRegex.hasMatch(cleanValue)) {
      return 'رقم الهاتف غير صحيح (يجب أن يبدأ بـ 05)';
    }
    return null;
  }

  // التحقق من تطابق كلمة المرور
  static String? validatePasswordMatch(String? value, String? otherValue) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value != otherValue) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  // التحقق من حقل نصي عام
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    return null;
  }

  // التحقق من الطول
  static String? validateLength(
    String? value,
    int minLength,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال $fieldName';
    }
    if (value.length < minLength) {
      return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
    }
    if (value.length > maxLength) {
      return '$fieldName يجب أن لا يزيد عن $maxLength حرف';
    }
    return null;
  }
}
