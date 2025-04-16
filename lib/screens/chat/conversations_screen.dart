import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/chat/conversation_tile.dart';
import '../search/search_screen.dart';
import 'conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar conversaciones al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(context, listen: false).refreshConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.loadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messageProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حدث خطأ: ${messageProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => messageProvider.refreshConversations(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ليس لديك محادثات حاليًا',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ابدأ محادثة جديدة مع أصدقائك',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToSearch,
                    icon: const Icon(Icons.person_add),
                    label: const Text('بدء محادثة جديدة'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => messageProvider.refreshConversations(),
            child: ListView.separated(
              itemCount: messageProvider.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = messageProvider.conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(
                          conversationId: conversation.id,
                          otherUserId: conversation.otherUserId ?? '',
                          otherUserName: conversation.otherUserName ?? 'مستخدم',
                          otherUserAvatar: conversation.otherUserAvatar ?? '',
                        ),
                      ),
                    ).then((_) {
                      // Actualizar conversaciones al volver
                      messageProvider.refreshConversations();
                    });
                  },
                  onDismiss: () => _showDeleteConfirmation(conversation.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSearch,
        child: const Icon(Icons.chat_bubble_outline),
        tooltip: 'محادثة جديدة',
        elevation: 6,
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(isForChat: true),
      ),
    );
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف المحادثة'),
          content: const Text('هل أنت متأكد من رغبتك في حذف هذه المحادثة؟'),
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
              onPressed: () {
                Provider.of<MessageProvider>(context, listen: false)
                    .deleteConversation(conversationId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}