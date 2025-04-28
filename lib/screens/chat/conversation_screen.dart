import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/common/network_image.dart';
import '../../services/image_service.dart';
import '../profile/profile_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ConversationScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showAttachmentOptions = false;
  bool _isSendingMessage = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<MessageProvider>(
        context,
        listen: false,
      ).loadMessages(widget.conversationId);

      // Desplazar a último mensaje después de cargar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error al cargar mensajes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    _messageController.clear();

    setState(() {
      _isSendingMessage = true;
    });

    final messageProvider = Provider.of<MessageProvider>(
      context,
      listen: false,
    );

    try {
      final success = await messageProvider.sendMessage(
        recipientId: widget.otherUserId,
        content: text,
      );

      if (success) {
        // Desplazar a último mensaje
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error al enviar mensaje: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fallo al enviar mensaje: $e')));
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final File? selectedImage = await ImageService.showImageSourceActionSheet(
        context,
      );

      if (selectedImage != null) {
        setState(() {
          _showAttachmentOptions = false;
        });

        final messageProvider = Provider.of<MessageProvider>(
          context,
          listen: false,
        );

        setState(() {
          _isSendingMessage = true;
        });

        // Enviar la imagen como mensaje
        final success = await messageProvider.sendMessage(
          recipientId: widget.otherUserId,
          content: selectedImage.path, // Usar ruta de imagen como contenido
          type: MessageType.image,
          file: selectedImage,
          metadata: {
            'size': await selectedImage.length(),
            'name': selectedImage.path.split('/').last,
          },
        );

        setState(() {
          _isSendingMessage = false;
        });

        if (success) {
          // Desplazar a último mensaje
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error al elegir imagen: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fallo al cargar imagen: $e')));
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.otherUserId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: ClipOval(
                  child: NetworkImageWithPlaceholder(
                    imageUrl: widget.otherUserAvatar,
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'انقر لعرض الملف الشخصي',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'تحديث المحادثة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar mensajes
          Expanded(child: _buildMessagesList()),

          // Opciones de adjuntos
          if (_showAttachmentOptions)
            Container(
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showAttachmentOptions = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.photo,
                        label: 'صورة',
                        onTap: _pickImage,
                      ),
                      _buildAttachmentOption(
                        icon: Icons.file_present,
                        label: 'ملف',
                        onTap: () {
                          // Enviar archivo
                          // Esta funcionalidad puede añadirse después
                          setState(() {
                            _showAttachmentOptions = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('سيتم إضافة هذه الميزة قريبًا'),
                            ),
                          );
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.location_on,
                        label: 'موقع',
                        onTap: () {
                          // Enviar ubicación
                          // Esta funcionalidad puede añadirse después
                          setState(() {
                            _showAttachmentOptions = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('سيتم إضافة هذه الميزة قريبًا'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Campo de entrada de mensaje
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachmentOptions ? Icons.close : Icons.attachment,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachmentOptions = !_showAttachmentOptions;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        _isSendingMessage
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSendingMessage ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = Provider.of<MessageProvider>(context).messages;
    final conversationMessages = messages[widget.conversationId] ?? [];
    final currentUserId = Provider.of<AuthProvider>(context).user?.id ?? '';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ابدأ المحادثة مع ${widget.otherUserName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أرسل رسالة للبدء',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: conversationMessages.length,
      itemBuilder: (context, index) {
        final message = conversationMessages[index];
        final isMe = message.senderId == currentUserId;

        // Agrupar mensajes por fecha
        final bool showDate =
            index == 0 ||
            _shouldShowDate(
              conversationMessages[index].createdAt,
              index > 0 ? conversationMessages[index - 1].createdAt : null,
            );

        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            MessageBubble(
              message: message,
              isMe: isMe,
              showUserInfo: !isMe,
              userAvatar: isMe ? '' : widget.otherUserAvatar,
              userName: isMe ? '' : widget.otherUserName,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  bool _shouldShowDate(DateTime current, DateTime? previous) {
    if (previous == null) return true;

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'اليوم';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'الأمس';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
