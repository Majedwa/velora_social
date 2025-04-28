// lib/main.dart - Modificaciones para solucionar pantalla en blanco

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'providers/story_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme.dart';
import 'utils/error_handler.dart'; // Nuevo archivo que crearemos
 // Nuevo archivo que crearemos

void main() async {
  // Asegurarse de que las vinculaciones de Flutter estén inicializadas
  WidgetsFlutterBinding.ensureInitialized();
    // إنشاء مثيل ApiService
  final apiService = ApiService();
  
  // تهيئة NetworkHelper
  // Captura errores no manejados
  setupErrorHandling();
  
  // Opcional: Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Iniciar la aplicación dentro de una zona de error controlada
  runZonedGuarded(
    () => runApp(const MyApp(
      
    )),
    
    (error, stackTrace) {
      debugPrint('Error no manejado: $error');
      debugPrint('Stack trace: $stackTrace');
    }
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicios API básicos
        Provider<ApiService>(create: (_) => ApiService()),
        
        // Proveedor de autenticación
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Proveedor de publicaciones
        ChangeNotifierProvider(create: (_) => PostProvider()),
        
        // Proveedor de temas
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Proveedor de favoritos
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        
        // Proveedores de notificaciones, mensajes e historias
        ChangeNotifierProxyProvider<ApiService, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<ApiService>(context, listen: false)
          ),
          update: (context, api, previous) => previous ?? NotificationProvider(api),
        ),
        
        // Proveedor de mensajes - dependiente del proveedor de usuario y notificaciones
        ChangeNotifierProxyProvider3<ApiService, AuthProvider, NotificationProvider, MessageProvider>(
          create: (context) => MessageProvider(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<NotificationProvider>(context, listen: false),
          ),
          update: (context, api, auth, notification, previous) => 
            previous ?? MessageProvider(api, auth, notification),
        ),
        
        // Proveedor de historias - dependiente del proveedor de usuario
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, StoryProvider>(
          create: (context) => StoryProvider(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? StoryProvider(api, auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Velora Social',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            // Pantalla de carga antes de verificar el estado de autenticación
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

// Pantalla de carga para evitar la pantalla en blanco
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Dar tiempo a que se inicialicen los providers
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Intento de cargar el usuario (esto verificará el token almacenado)
      await authProvider.loadUser();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al verificar autenticación: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al iniciar sesión: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si todavía está cargando, mostrar pantalla de carga
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icon de la app
              Icon(
                Icons.group,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                'Velora Social',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    
    // Si hubo un error, mostrar pantalla de error con opción de reintentar
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل التطبيق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _checkAuthStatus();
                },
                child: Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Comprobar el estado de autenticación y redirigir a la pantalla correspondiente
    final authProvider = Provider.of<AuthProvider>(context);
    return authProvider.isAuthenticated ? HomeScreen() : LoginScreen();
  }
}