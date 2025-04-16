import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/message.dart';
import '../../widgets/common/network_image.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showUserInfo;
  final String userAvatar;
  final String userName;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showUserInfo = false,
    this.userAvatar = '',
    this.userName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del otro usuario (solo para mensajes recibidos)
          if (!isMe && showUserInfo)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: userAvatar.isNotEmpty
                    ? ClipOval(
                        child: NetworkImageWithPlaceholder(
                          imageUrl: userAvatar,
                          width: 32,
                          height: 32,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
              ),
            ),
          
          // Contenido del mensaje
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: _getBubblePadding(),
              decoration: BoxDecoration(
                color: _getBubbleColor(context),
                borderRadius: _getBubbleRadius(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Nombre del remitente (solo para mensajes recibidos)
                  if (!isMe && showUserInfo && userName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        userName,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // Contenido del mensaje según tipo
                  _buildMessageContent(context),
                  
                  // Hora del mensaje y estado de lectura
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                        if (isMe)
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: message.isRead
                                  ? Colors.blue
                                  : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
        );
      
      case MessageType.image:
        return InkWell(
          onTap: () {
            _showFullScreenImage(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageContent(context),
          ),
        );
      
      case MessageType.file:
        return _buildFileContent(context);
      
      case MessageType.voice:
        return _buildVoiceContent(context);
      
      case MessageType.location:
        return _buildLocationContent(context);
      
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        );
      
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        );
    }
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'الصورة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: message.content.startsWith('/')
                  ? Image.file(
                      File(message.content),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'خطأ في تحميل الصورة: $error',
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : NetworkImageWithPlaceholder(
                      imageUrl: message.content,
                      fit: BoxFit.contain,
                      height: double.infinity,
                      width: double.infinity,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    // Verificar si la imagen es local o del servidor
    if (message.content.startsWith('/')) {
      // Imagen local
      return Image.file(
        File(message.content),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red),
            ),
          );
        },
      );
    } else {
      // Imagen del servidor
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkImageWithPlaceholder(
              imageUrl: message.content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              borderRadius: 8,
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFileContent(BuildContext context) {
    final fileName = message.metadata?['name'] ?? 'ملف';
    final fileSize = message.metadata?['size'] ?? 0;
    
    String formattedSize = '';
    if (fileSize is int) {
      if (fileSize < 1024) {
        formattedSize = '$fileSize B';
      } else if (fileSize < 1024 * 1024) {
        formattedSize = '${(fileSize / 1024).toStringAsFixed(1)} KB';
      } else {
        formattedSize = '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe
              ? Colors.blue.withOpacity(0.2)
              : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (formattedSize.isNotEmpty)
                  Text(
                    formattedSize,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.download,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    // En el futuro se puede añadir un reproductor de audio aquí
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMe
              ? Colors.blue.withOpacity(0.2)
              : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          const Text(
            'رسالة صوتية',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.play_arrow_rounded,
            color: Theme.of(context).primaryColor,
          ),
          // Aquí se podría añadir una barra de progreso
        ],
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context) {
    // En el futuro se puede añadir un mapa en miniatura aquí
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: NetworkImage('https://via.placeholder.com/200x120?text=Map'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.location_on,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: const Text(
                'الموقع المشارك',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsetsGeometry _getBubblePadding() {
    switch (message.type) {
      case MessageType.image:
        return const EdgeInsets.all(4);
      case MessageType.file:
      case MessageType.voice:
      case MessageType.location:
        return const EdgeInsets.all(0); // El padding se maneja dentro del contenido
      case MessageType.text:
      default:
        return const EdgeInsets.all(12);
    }
  }

  Color _getBubbleColor(BuildContext context) {
    if (isMe) {
      return Theme.of(context).primaryColor;
    } else {
      switch (message.type) {
        case MessageType.system:
          return Colors.transparent;
        default:
          return Theme.of(context).cardColor;
      }
    }
  }

  BorderRadius _getBubbleRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}