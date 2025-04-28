import 'dart:io';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  
  User? _user;
  User? _viewedUser;
  bool _isAuthenticated = false;
  bool _loading = false;
  String? _error;
  ApiService _apiService = ApiService();

  User? get user => _user;
  User? get viewedUser => _viewedUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _initAuth();
  }
  

  // Inicializar la autenticación al iniciar la aplicación
  Future<void> _initAuth() async {
    await loadUser();
  }

  // Cargar datos del usuario
  Future<void> loadUser() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('Iniciando carga de datos del usuario');
      final response = await _apiService.getCurrentUser();
      print('Respuesta loadUser: $response');

      if (response['success']) {
        _user = User.fromJson(response['data']);
        _isAuthenticated = true;
        _error = null;
        // Guardar estado de autenticación
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
      } else {
        // En caso de error, no consideramos que sea un problema, solo indicamos que el usuario no está autenticado
        _user = null;
        _isAuthenticated = false;
        _error = null; // No mostramos el error al usuario
        print('No se cargó el usuario: ${response['message']}');
        // Limpiar el estado de autenticación
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', false);
      }
    } catch (e) {
      print('Excepción en loadUser: $e');
      _user = null;
      _isAuthenticated = false;
      _error = null; // No mostramos el error al usuario
      // Limpiar el estado de autenticación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', false);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Obtener todos los usuarios
  Future<Map<String, dynamic>> getUsers() async {
    try {
      print('Obteniendo lista de usuarios');
      final response = await _apiService.getAllUsers();

      if (response['success']) {
        if (response['data'] != null) {
          try {
            final List<User> users =
                (response['data'] as List)
                    .map((json) => User.fromJson(json))
                    .toList();
            return {'success': true, 'data': users};
          } catch (e) {
            print('Error al convertir datos de usuarios: $e');
            return {
              'success': false,
              'message': 'Error al procesar datos de usuarios',
            };
          }
        } else {
          return {'success': true, 'data': []};
        }
      } else {
        return {'success': false, 'message': response['message']};
      }
    } catch (e) {
      print('Excepción en getUsers: $e');
      return {'success': false, 'message': 'Fallo al obtener usuarios'};
    }
  }

  // Registrar un nuevo usuario
  Future<bool> register(String username, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('Iniciando registro de usuario nuevo');
      final response = await _apiService.register(username, email, password);
      print('Respuesta Register: $response');

      _loading = false;

      if (response['success']) {
        await loadUser();
        _isAuthenticated = true;
        // Guardar estado de autenticación
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Excepción en register: $e');
      _loading = false;
      _error = 'Error durante la creación de la cuenta';
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión
  Future<bool> login(String email, String password) async {
    print('Intento de inicio de sesión con: $email');
    print('URL del servidor: ${_apiService.baseUrl}');
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);
      
      print('Respuesta de inicio de sesión: $response');
      
      _loading = false;
      
      if (response['success']) {
        // Cargar datos del usuario por separado en lugar de llamar a loadUser
        try {
          final userResponse = await _apiService.getCurrentUser();
          if (userResponse['success']) {
            _user = User.fromJson(userResponse['data']);
            _isAuthenticated = true;
            // Guardar estado de autenticación
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isAuthenticated', true);
            notifyListeners();
            return true;
          } else {
            print('Fallo al recuperar datos del usuario: ${userResponse['message']}');
            _error = 'Sesión iniciada pero fallo en recuperar datos';
            notifyListeners();
            return false;
          }
        } catch (userError) {
          print('Error al recuperar datos del usuario: $userError');
          // Sin embargo, consideramos que el inicio de sesión fue exitoso
          _isAuthenticated = true;
          // Guardar estado de autenticación
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isAuthenticated', true);
          notifyListeners();
          return true;
        }
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Excepción en login: $e');
      _loading = false;
      _error = 'Error durante el inicio de sesión';
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _apiService.clearToken();
      _user = null;
      _isAuthenticated = false;
      
      // Limpiar estado de autenticación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', false);
      await prefs.remove('token');
    } catch (e) {
      print('Error en el cierre de sesión: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile(String bio, File? profileImage) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        bio,
        profileImage: profileImage,
      );

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Excepción en updateProfile: $e');
      _loading = false;
      _error = 'Error durante la actualización del perfil';
      notifyListeners();
      return false;
    }
  }

  // Obtener perfil de otro usuario
  Future<bool> getUserProfile(String userId) async {
    _loading = true;
    _error = null;
    _viewedUser = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserById(userId);

      if (response['success']) {
        _viewedUser = User.fromJson(response['data']);
        _error = null;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      print('Excepción en getUserProfile: $e');
      _error = 'Fallo al obtener datos del usuario';
    } finally {
      _loading = false;
      notifyListeners();
    }

    return _viewedUser != null;
  }

  // Obtener información de varios usuarios a la vez (para seguidores)
  Future<List<User>> getMultipleUsers(List<String> userIds) async {
    List<User> users = [];

    if (userIds.isEmpty) {
      return users;
    }

    try {
      final response = await _apiService.getMultipleUsers(userIds);

      if (response['success']) {
        users =
            (response['data'] as List)
                .map((userData) => User.fromJson(userData))
                .toList();
      }
    } catch (e) {
      print('Excepción en getMultipleUsers: $e');
    }

    return users;
  }

  // Buscar usuarios
  Future<List<User>> searchUsers(String query) async {
    List<User> users = [];

    if (query.isEmpty) {
      return users;
    }

    try {
      final response = await _apiService.searchUsers(query);

      if (response['success']) {
        users =
            (response['data'] as List)
                .map((userData) => User.fromJson(userData))
                .toList();
      }
    } catch (e) {
      print('Excepción en searchUsers: $e');
    }

    return users;
  }

  // Seguir a un usuario
  Future<bool> followUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.followUser(userId);

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Excepción en followUser: $e');
      _loading = false;
      _error = 'Error al seguir al usuario';
      notifyListeners();
      return false;
    }
  }

  // Dejar de seguir a un usuario
  Future<bool> unfollowUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.unfollowUser(userId);

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Excepción en unfollowUser: $e');
      _loading = false;
      _error = 'Error al dejar de seguir al usuario';
      notifyListeners();
      return false;
    }
  }
}