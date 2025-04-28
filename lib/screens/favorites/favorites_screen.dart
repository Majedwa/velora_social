// Nueva pantalla: lib/screens/favorites/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post/post_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';
    
    final favoritePosts = favoriteProvider.favoritePosts;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bookmark),
            const SizedBox(width: 8),
            const Text('المنشورات المحفوظة'),
          ],
        ),
        actions: [
          if (favoritePosts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearConfirmation,
              tooltip: 'مسح كل المحفوظات',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoritePosts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: favoritePosts.length,
                  itemBuilder: (context, index) {
                    final post = favoritePosts[index];
                    return PostCard(
                      post: post,
                      currentUserId: currentUserId,
                      onLike: () async {
                        // Intentar dar "me gusta" al post
                        // Observación: esto podría no funcionar si el post no está ya en el feed
                        // En ese caso, necesitaríamos actualizar la lista de favoritos
                        return true;
                      },
                      onUnlike: () async {
                        // Intentar quitar "me gusta" al post
                        return true;
                      },
                      onComment: (text) async {
                        // Intentar comentar el post
                        return true;
                      },
                      onDelete: null, // No permitir eliminar desde esta pantalla
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد منشورات محفوظة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'المنشورات التي تحفظها ستظهر هنا',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Volver al feed
            },
            icon: const Icon(Icons.home),
            label: const Text('استعرض المنشورات'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مسح كل المنشورات المحفوظة'),
          content: const Text('هل أنت متأكد من رغبتك في مسح جميع المنشورات المحفوظة؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('مسح الكل'),
              onPressed: () {
                Provider.of<FavoriteProvider>(context, listen: false)
                    .clearAllFavorites();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}