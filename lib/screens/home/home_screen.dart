// lib/screens/home/home_screen.dart - Modificado para mostrar stories solo en la pantalla Home

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/story_provider.dart';
import 'feed_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../chat/conversations_screen.dart';
import '../notification/notification_screen.dart';
import '../story/story_view_screen.dart';
import '../story/create_story_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/story/story_circle.dart';
import '../../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar datos al cargar la pantalla
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Cargar notificaciones
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).refreshNotifications();

    // Cargar historias
    await Provider.of<StoryProvider>(context, listen: false).refreshStories();
  }

  void _navigateToStoryView(
    String userId,
    String username,
    String profilePicture,
  ) {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final story = storyProvider.getStoryByUserId(userId);

    if (story != null && story.validItems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => StoryViewScreen(
                story: story,
                userName: username,
                userProfilePicture: profilePicture,
              ),
        ),
      );
    }
  }

  // Construir sección de historias
  Widget _buildStoriesSection() {
    final storyProvider = Provider.of<StoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const SizedBox(height: 0);
    }

    // Historia del usuario actual
    final myStory = storyProvider.myStory;
    final hasMyStory = myStory != null && myStory.validItems.isNotEmpty;

    // Historias disponibles (excluyendo las vacías)
    final availableStories =
        storyProvider.stories
            .where((story) => story.validItems.isNotEmpty)
            .toList();

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              'القصص',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount:
                  1 + availableStories.length, // Mi historia + otras historias
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Mi historia
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        StoryCircle(
                          imageUrl: currentUser.profilePicture,
                          radius: 32,
                          hasStory: hasMyStory,
                          isViewed:
                              true, // La propia historia siempre se considera vista
                          onTap:
                              hasMyStory
                                  ? () => _navigateToStoryView(
                                    currentUser.id,
                                    currentUser.username,
                                    currentUser.profilePicture,
                                  )
                                  : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const CreateStoryScreen(),
                                    ),
                                  ),
                          addIcon:
                              !hasMyStory
                                  ? const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'قصتي',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Historias de otros
                  final story = availableStories[index - 1];
                  final isViewed = story.allViewedBy(currentUser.id);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        StoryCircle(
                          imageUrl: story.userProfilePicture,
                          radius: 32,
                          hasStory: true,
                          isViewed: isViewed,
                          onTap:
                              () => _navigateToStoryView(
                                story.userId,
                                story.username,
                                story.userProfilePicture,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.username.length > 10
                              ? '${story.username.substring(0, 8)}...'
                              : story.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);

    // Lista de pantallas disponibles en la navegación principal
    final List<Widget> screens = [
      const FeedScreen(),
      const SearchScreen(),
      const SizedBox.shrink(), // Será reemplazado por la ventana de crear post
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: _currentIndex == 2
          ? const SizedBox.shrink()
          : CustomScrollView(
              slivers: [
                // AppBar con diseño moderno
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  title: Text(
                    'Velora Social',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  actions: [
                    // Botón de notificaciones con indicador
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (notificationProvider.unreadCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationProvider.unreadCount > 9
                                    ? '9+'
                                    : notificationProvider.unreadCount
                                        .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Botón de cambio de tema
                    IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                    ),

                    // Botón de salir
                    IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        _showLogoutDialog();
                      },
                    ),
                  ],
                ),

                // MODIFICACIÓN: Sección de historias solo cuando estamos en la página principal (index 0)
                if (_currentIndex == 0)
                  SliverToBoxAdapter(child: _buildStoriesSection()),

                // Contenido principal
                SliverFillRemaining(child: screens[_currentIndex]),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        onTap: (index) {
          if (index == 2) {
            _showCreatePostModal();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'إضافة'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'المحادثات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateStoryScreen(),
                      ),
                    ),
                child: const Icon(Icons.add_photo_alternate),
                tooltip: 'إضافة قصة',
              )
              : null,
    );
  }

  void _showCreatePostModal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('تسجيل الخروج'),
              onPressed: () async {
                Navigator.of(context).pop(); // إغلاق الحوار

                // تسجيل الخروج
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();

                // إعادة التوجيه إلى شاشة تسجيل الدخول
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}