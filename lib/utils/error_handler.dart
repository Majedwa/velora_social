// lib/utils/error_handler.dart
// مكتبة للتعامل مع الأخطاء العامة في التطبيق

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

// إعداد التعامل مع الأخطاء الغير معالجة
void setupErrorHandling() {
  // التقاط أخطاء Flutter غير المعالجة
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // التقاط أخطاء Dart غير المعالجة
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Dart Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
}

// فئة للتعامل مع مختلف أنواع الأخطاء في التطبيق
class ErrorHandler {
  // معالجة أخطاء الشبكة والاتصال
  static String handleNetworkError(dynamic error) {
    // DioError
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'انتهت مهلة الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت الخاص بك';
        case DioExceptionType.sendTimeout:
          return 'انتهت مهلة إرسال البيانات، يرجى التحقق من اتصال الإنترنت الخاص بك';
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة استقبال البيانات، يرجى التحقق من اتصال الإنترنت الخاص بك';
        case DioExceptionType.badResponse:
          return _handleResponseError(error);
        case DioExceptionType.cancel:
          return 'تم إلغاء الطلب';
        case DioExceptionType.connectionError:
          return 'فشل الاتصال بالخادم، يرجى التحقق من عنوان الخادم والإنترنت';
        default:
          return 'حدث خطأ غير متوقع أثناء الاتصال بالخادم: ${error.message}';
      }
    }
    
    // أخطاء SocketException (مشاكل الشبكة)
    else if (error is SocketException) {
      return 'لا يمكن الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت الخاص بك';
    }
    
    // أخطاء HttpException (مشاكل في طلبات HTTP)
    else if (error is HttpException) {
      return 'فشل طلب HTTP: ${error.message}';
    }
    
    // أخطاء FormatException (مشاكل في تنسيق البيانات)
    else if (error is FormatException) {
      return 'خطأ في تنسيق البيانات المستلمة من الخادم';
    }
    
    // أخطاء TimeoutException (انتهاء مهلة الاتصال)
    else if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
    }
    
    // الأخطاء الأخرى
    else {
      return 'حدث خطأ: ${error.toString()}';
    }
  }

  // معالجة أخطاء الاستجابة (وفقاً لرمز الحالة)
  static String _handleResponseError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return 'طلب غير صالح: ${_getErrorMessage(error)}';
      case 401:
        return 'غير مصرح لك: يرجى تسجيل الدخول مرة أخرى';
      case 403:
        return 'ممنوع: ليس لديك صلاحية للوصول إلى هذا المورد';
      case 404:
        return 'لم يتم العثور على المورد المطلوب';
      case 409:
        return 'تعارض: ${_getErrorMessage(error)}';
      case 422:
        return 'بيانات غير صالحة: ${_getErrorMessage(error)}';
      case 500:
        return 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً';
      case 502:
        return 'بوابة غير صالحة، قد يكون الخادم غير متاح حالياً';
      case 503:
        return 'الخدمة غير متوفرة، قد يكون الخادم تحت الصيانة';
      case 504:
        return 'انتهت مهلة البوابة، يرجى التحقق من اتصالك والمحاولة مرة أخرى';
      default:
        return 'حدث خطأ: ${error.response?.statusCode ?? 'غير معروف'} - ${_getErrorMessage(error)}';
    }
  }

  // استخراج رسالة الخطأ من كائن DioError
  static String _getErrorMessage(DioException error) {
    // محاولة استخراج رسالة الخطأ من استجابة JSON
    if (error.response?.data != null && error.response!.data is Map) {
      final data = error.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'].toString();
      } else if (data.containsKey('msg')) {
        return data['msg'].toString();
      } else if (data.containsKey('error')) {
        return data['error'].toString();
      }
    } 
    
    // إذا كانت البيانات نصية مباشرة
    else if (error.response?.data != null && error.response!.data is String) {
      return error.response!.data.toString();
    }
    
    // استخدام الرسالة العامة للخطأ
    return error.message ?? 'حدث خطأ غير معروف';
  }

  // عرض رسالة خطأ للمستخدم
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // عرض حوار خطأ للأخطاء الهامة
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('حسناً'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}