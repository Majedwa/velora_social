import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/user.dart';
import '../profile/profile_screen.dart';
import '../chat/conversation_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isForChat;
  
  const SearchScreen({
    Key? key, 
    this.isForChat = false,
  }) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final results = await Provider.of<AuthProvider>(context, listen: false).searchUsers(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في البحث: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToChat(User user) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    // Crear o obtener conversación
    messageProvider.getOrCreateConversation(
      user.id, 
      user.username, 
      user.profilePicture,
    ).then((conversationId) {
      // Navegar a la pantalla de conversación
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: conversationId,
            otherUserId: user.id,
            otherUserName: user.username,
            otherUserAvatar: user.profilePicture,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).user?.id ?? '';
    final isInChatMode = widget.isForChat;

    return Scaffold(
      appBar: AppBar(
        title: Text(isInChatMode ? 'بحث عن محادثة' : 'بحث'),
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isInChatMode 
                    ? 'ابحث عن مستخدم للدردشة'
                    : 'البحث عن مستخدمين',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _searchUsers(value);
                } else if (value.isEmpty) {
                  _searchUsers('');
                }
              },
            ),
          ),
          
          // Resultados de búsqueda
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInChatMode ? Icons.chat : Icons.search, 
                              size: 80, 
                              color: Colors.grey
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isInChatMode 
                                  ? 'ابحث عن شخص للدردشة معه'
                                  : 'ابحث عن أصدقائك',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isInChatMode
                                  ? 'اكتب اسم المستخدم للبحث وبدء محادثة'
                                  : 'اكتب اسم المستخدم للبحث'
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(child: Text('لا توجد نتائج لهذا البحث'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              
                              // No mostrar el usuario actual en los resultados
                              if (user.id == currentUserId) {
                                return const SizedBox.shrink();
                              }
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(user.profilePicture),
                                  ),
                                  title: Text(user.username),
                                  subtitle: Text(
                                    user.bio.isEmpty ? 'لا توجد نبذة' : user.bio,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isInChatMode
                                      ? IconButton(
                                          icon: const Icon(Icons.chat_bubble_outline),
                                          onPressed: () => _navigateToChat(user),
                                        )
                                      : null,
                                  onTap: isInChatMode
                                      ? () => _navigateToChat(user)
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfileScreen(userId: user.id),
                                            ),
                                          );
                                        },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}