import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post/post_card.dart';
import '../search/search_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  
  @override
  bool get wantKeepAlive => true; // Mantener el estado al cambiar de pestaña
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
    
    // Añadir listener para scrolling para cargar más publicaciones
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Función para detectar cuando se llega al final de la lista y cargar más
  void _scrollListener() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !postProvider.loading &&
        !postProvider.loadingMore &&
        postProvider.hasMorePosts) {
      postProvider.loadMorePosts();
    }
  }
  
  Future<void> _loadPosts() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await Provider.of<PostProvider>(context, listen: false).fetchPosts(refresh: true);
    
    setState(() {
      _isRefreshing = false;
    });
  }

  void _showSortOptions() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'ترتيب المنشورات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text('ترتيب حسب الأحدث'),
                leading: const Icon(Icons.access_time),
                trailing: postProvider.currentSortOption == SortOption.latest
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                selected: postProvider.currentSortOption == SortOption.latest,
                onTap: () {
                  postProvider.setSortOption(SortOption.latest);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('ترتيب حسب الأكثر إعجابًا'),
                leading: const Icon(Icons.favorite),
                trailing: postProvider.currentSortOption == SortOption.mostLiked
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                selected: postProvider.currentSortOption == SortOption.mostLiked,
                onTap: () {
                  postProvider.setSortOption(SortOption.mostLiked);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin
    
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';

    return RefreshIndicator(
      onRefresh: () => _loadPosts(),
      child: _isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : postProvider.loading && postProvider.posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : postProvider.error != null && postProvider.posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ: ${postProvider.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPosts,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    )
                  : postProvider.posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.post_add,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'لا توجد منشورات بعد',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ابدأ بمتابعة أصدقائك أو أنشئ منشورًا جديدًا',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navegar a la pantalla de búsqueda de usuarios
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SearchScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('البحث عن أصدقاء'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: postProvider.posts.length + (postProvider.loadingMore ? 1 : 0) + 1, // +1 para el encabezado
                          itemBuilder: (context, index) {
                            // Encabezado con opciones de filtro
                            if (index == 0) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        postProvider.currentSortOption == SortOption.latest
                                            ? Icons.access_time
                                            : Icons.favorite,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        postProvider.currentSortOption == SortOption.latest
                                            ? 'ترتيب حسب الأحدث'
                                            : 'ترتيب حسب الأكثر إعجابًا',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        icon: const Icon(Icons.sort),
                                        label: const Text('تغيير'),
                                        onPressed: _showSortOptions,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            // Indicador de carga al final
                            if (index == postProvider.posts.length + 1) {
                              return postProvider.loadingMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            
                            // Publicaciones
                            final post = postProvider.posts[index - 1]; // -1 por el encabezado
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: PostCard(
                                post: post,
                                currentUserId: currentUserId,
                                onLike: () => postProvider.likePost(post.id),
                                onUnlike: () => postProvider.unlikePost(post.id),
                                onComment: (text) => postProvider.addComment(post.id, text),
                                onDelete: post.userId == currentUserId
                                    ? () => _showDeleteConfirmation(context, post.id)
                                    : null,
                              ),
                            );
                          },
                        ),
    );
  }
  
  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف المنشور'),
          content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنشور؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('حذف'),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await Provider.of<PostProvider>(context, listen: false)
                    .deletePost(postId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنشور بنجاح')),
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