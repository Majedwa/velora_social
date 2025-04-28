// lib/utils/app_config.dart - Actualizado con colores Velora
import 'package:flutter/material.dart';

/// فئة لإدارة إعدادات التطبيق وإمكانية الوصول إليها من جميع أنحاء التطبيق
class AppConfig {
  // إعدادات عامة للتطبيق
  static const String appName = 'Velora Social';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'منصة اجتماعية لمشاركة تجارب وآراء المستخدمين حول تطبيق Velora السياحي والرحلات المختلفة';
  
  // النصوص المستخدمة في التطبيق
  static const Map<String, String> appTexts = {
    // عام
    'app_welcome': 'مرحباً بك في Velora Social',
    'app_slogan': 'شارك تجاربك السياحية وآرائك مع العالم',
    
    // تسجيل الدخول والتسجيل
    'login_title': 'تسجيل الدخول إلى Velora Social',
    'login_subtitle': 'سجل دخولك لمشاركة رحلاتك وتجاربك السياحية',
    'register_title': 'إنشاء حساب جديد',
    'register_subtitle': 'انضم إلى مجتمع Velora وشارك تجاربك السياحية',
    
    // الصفحة الرئيسية
    'home_feed_title': 'آخر المشاركات السياحية',
    'create_post_hint': 'شارك رأيك حول تجربتك السياحية مع Velora...',
    'post_placeholder': 'ما هي أفضل وجهة سياحية زرتها مع Velora؟',
    
    // أقسام التطبيق
    'tab_home': 'الرئيسية',
    'tab_explore': 'استكشاف',
    'tab_create': 'مشاركة',
    'tab_chat': 'محادثات',
    'tab_profile': 'حسابي',
    
    // كتابة منشور
    'post_title': 'مشاركة تجربة سياحية',
    'post_hint': 'شارك رأيك عن تجربتك مع تطبيق Velora السياحي',
    'add_photo': 'إضافة صورة من رحلتك',
    'post_button': 'نشر المشاركة',
    
    // الصفحة الشخصية
    'profile_posts': 'تجاربي السياحية',
    'profile_edit': 'تعديل الملف الشخصي',
    'profile_bio_hint': 'أضف نبذة عن اهتماماتك السياحية المفضلة',
    
    // التعليقات والتفاعلات
    'comments_title': 'التعليقات',
    'add_comment': 'أضف تعليقًا على هذه التجربة',
    'likes_count': 'إعجابات',
    'comments_count': 'تعليقات',
    
    // البحث
    'search_title': 'استكشف الوجهات والتجارب',
    'search_hint': 'ابحث عن وجهات، أماكن، أو مستخدمين...',
    
    // صفحة الإعدادات
    'settings_title': 'الإعدادات',
    'theme_settings': 'إعدادات المظهر',
    'notification_settings': 'إعدادات الإشعارات',
    'language_settings': 'إعدادات اللغة',
    
    // رسائل الخطأ
    'error_loading': 'حدث خطأ أثناء تحميل البيانات',
    'error_connection': 'تعذر الاتصال بالخادم، تحقق من اتصالك بالإنترنت',
    'error_login': 'تعذر تسجيل الدخول، تحقق من بيانات الدخول',
    
    // أنواع المنشورات
    'post_type_review': 'تقييم تجربة',
    'post_type_trip': 'مشاركة رحلة',
    'post_type_tip': 'نصيحة سياحية',
    'post_type_question': 'سؤال عن وجهة',
  };
  
  // ألوان التطبيق الرئيسية - تم تحديثها لتتناسب مع ألوان شعار Velora
  static const Color primaryColor = Color(0xFF00A851); // لون أخضر من شعار Velora
  static const Color secondaryColor = Color(0xFF232323); // لون أسود/رمادي داكن
  static const Color accentColor = Color(0xFFF23D3D); // لون أحمر من علامة الموقع في الشعار
  
  // الحصول على نص بناءً على المفتاح
  static String getText(String key) {
    return appTexts[key] ?? key;
  }
  
  // الحصول على سمة التطبيق (يمكن توسيعها لاحقًا)
  static ThemeData getTheme(bool isDark) {
    // يمكنك تخصيص سمة التطبيق بشكل أكبر هنا
    return isDark ? _darkTheme : _lightTheme;
  }
  
  // سمة الوضع الفاتح
  static final ThemeData _lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
    ),
  );
  
  // سمة الوضع الداكن
  static final ThemeData _darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
  );
}