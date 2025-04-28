// lib/api/api_config.dart
// وحدة لإدارة وتخزين إعدادات API

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // مفاتيح التخزين
  static const String _keyHost = 'api_host';
  static const String _keyPort = 'api_port';
  static const String _keyPath = 'api_path';
  
  // القيم الافتراضية
  static const String _defaultHost = 'localhost';
  static const String _defaultPort = '5000';
  static const String _defaultPath = '/api';

  // الحصول على عنوان API الكامل
  static Future<String> getApiBaseUrl() async {
    final host = await getApiHost();
    final port = await getApiPort();
    final path = await getApiPath();
    
    return 'http://$host:$port$path';
  }

  // الحصول على المضيف
  static Future<String> getApiHost() async {
    try {
      final host = await _storage.read(key: _keyHost);
      return host ?? _defaultHost;
    } catch (e) {
      print('خطأ في قراءة المضيف: $e');
      return _defaultHost;
    }
  }

  // الحصول على المنفذ
  static Future<String> getApiPort() async {
    try {
      final port = await _storage.read(key: _keyPort);
      return port ?? _defaultPort;
    } catch (e) {
      print('خطأ في قراءة المنفذ: $e');
      return _defaultPort;
    }
  }

  // الحصول على المسار
  static Future<String> getApiPath() async {
    try {
      final path = await _storage.read(key: _keyPath);
      return path ?? _defaultPath;
    } catch (e) {
      print('خطأ في قراءة المسار: $e');
      return _defaultPath;
    }
  }

  // حفظ إعدادات API
  static Future<void> saveApiSettings({
    required String host,
    required int port,
    required String path,
  }) async {
    try {
      await _storage.write(key: _keyHost, value: host);
      await _storage.write(key: _keyPort, value: port.toString());
      
      // التأكد من أن المسار يبدأ بـ '/'
      String formattedPath = path.startsWith('/') ? path : '/$path';
      await _storage.write(key: _keyPath, value: formattedPath);
      
      print('تم حفظ إعدادات API: $host:$port$formattedPath');
    } catch (e) {
      print('خطأ في حفظ إعدادات API: $e');
    }
  }

  // حذف جميع الإعدادات المخزنة
  static Future<void> clearSettings() async {
    try {
      await _storage.delete(key: _keyHost);
      await _storage.delete(key: _keyPort);
      await _storage.delete(key: _keyPath);
      print('تم حذف إعدادات API');
    } catch (e) {
      print('خطأ في حذف إعدادات API: $e');
    }
  }
}