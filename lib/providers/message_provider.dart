import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

class MessageProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;
  final NotificationProvider _notificationProvider;
  
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {};
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  String? _error;
  
  MessageProvider(
    this._apiService, 
    this._authProvider,
    this._notificationProvider,
  ) {
    _initializeMessages();
  }
  
  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  String? get error => _error;
  
  // التهيئة الأولية للمحادثات والرسائل
  Future<void> _initializeMessages() async {
    if (_authProvider.isAuthenticated) {
      await loadConversations();
    }
  }
  
  // تحميل المحادثات
  Future<void> loadConversations() async {
    if (!_authProvider.isAuthenticated) return;
    
    _loadingConversations = true;
    _error = null;
    notifyListeners();
    
    try {
      // في حالة وجود API للمحادثات
      // final response = await _apiService.getConversations();
      
      // للتجربة، سنستخدم بيانات محلية محفوظة
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = prefs.getString('conversations');
      
      if (conversationsJson != null) {
        final List<dynamic> conversationsData = jsonDecode(conversationsJson);
        _conversations = conversationsData
            .map((data) => Conversation.fromJson(
                data, 
                currentUserId: _authProvider.user!.id,
              ))
            .toList();
      }
    } catch (e) {
      print('خطأ في تحميل المحادثات: $e');
      _error = 'فشل في تحميل المحادثات';
    } finally {
      _loadingConversations = false;
      notifyListeners();
    }
  }
  
  // حفظ المحادثات محليًا
  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsJson = jsonEncode(
        _conversations.map((conversation) => conversation.toJson()).toList(),
      );
      await prefs.setString('conversations', conversationsJson);
    } catch (e) {
      print('خطأ في حفظ المحادثات: $e');
    }
  }
  
  // تحميل رسائل محادثة معينة
  Future<List<Message>> loadMessages(String conversationId) async {
    if (!_authProvider.isAuthenticated) return [];
    
    _loadingMessages = true;
    _error = null;
    notifyListeners();
    
    try {
      // في حالة وجود API للرسائل
      // final response = await _apiService.getMessages(conversationId);
      
      // للتجربة، سنستخدم بيانات محلية محفوظة
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'messages_$conversationId';
      final messagesJson = prefs.getString(messagesKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesData = jsonDecode(messagesJson);
        final messages = messagesData
            .map((data) => Message.fromJson(data))
            .toList();
        
        _messages[conversationId] = messages;
        
        // تعليم الرسائل المستلمة كمقروءة
        _markConversationAsRead(conversationId);
        
        return messages;
      }
      
      return [];
    } catch (e) {
      print('خطأ في تحميل الرسائل: $e');
      _error = 'فشل في تحميل الرسائل';
      return [];
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }
  
  // حفظ رسائل محادثة معينة محليًا
  Future<void> _saveMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'messages_$conversationId';
      
      if (_messages.containsKey(conversationId)) {
        final messagesJson = jsonEncode(
          _messages[conversationId]!.map((message) => message.toJson()).toList(),
        );
        await prefs.setString(messagesKey, messagesJson);
      }
    } catch (e) {
      print('خطأ في حفظ الرسائل: $e');
    }
  }
  
  // إرسال رسالة جديدة
// Modificación de lib/providers/message_provider.dart

// Modificamos el método sendMessage para arreglar las notificaciones
Future<bool> sendMessage({
  required String recipientId,
  required String content,
  MessageType type = MessageType.text,
  File? file,
  Map<String, dynamic>? metadata,
}) async {
  if (!_authProvider.isAuthenticated) return false;
  
  try {
    final currentUser = _authProvider.user!;
    
    // Verificar si existe una conversación entre los usuarios
    String conversationId = _findExistingConversation(recipientId);
    
    if (conversationId.isEmpty) {
      // Crear nueva conversación
      conversationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Obtener información del destinatario
      User? recipient;
      try {
        final response = await _apiService.getUserById(recipientId);
        if (response['success']) {
          recipient = User.fromJson(response['data']);
        }
      } catch (e) {
        print('Error al obtener datos del destinatario: $e');
      }
      
      final newConversation = Conversation(
        id: conversationId,
        participants: [currentUser.id, recipientId],
        lastMessageContent: content,
        lastMessageTime: DateTime.now(),
        hasUnreadMessages: false,
        unreadCount: 0,
        otherUserId: recipientId,
        otherUserName: recipient?.username ?? 'مستخدم',
        otherUserAvatar: recipient?.profilePicture ?? '',
      );
      
      _conversations.insert(0, newConversation);
      _messages[conversationId] = [];
    }
    
    // Crear nuevo mensaje
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.id,
      recipientId: recipientId,
      conversationId: conversationId,
      type: type,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
      metadata: metadata,
    );
    
    // Actualizar la lista de mensajes
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    
    _messages[conversationId]!.add(newMessage);
    
    // Actualizar el último mensaje en la conversación
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];
      
      // Modificación: Crear una conversación para el usuario actual (sin notificación)
      _conversations[conversationIndex] = Conversation(
        id: conversation.id,
        participants: conversation.participants,
        lastMessageContent: content,
        lastMessageTime: DateTime.now(),
        hasUnreadMessages: false,  // No necesitamos notificación para el remitente
        unreadCount: conversation.unreadCount,
        otherUserId: conversation.otherUserId,
        otherUserName: conversation.otherUserName,
        otherUserAvatar: conversation.otherUserAvatar,
      );
      
      // Reordenar para que la conversación aparezca arriba
      if (conversationIndex > 0) {
        final conv = _conversations.removeAt(conversationIndex);
        _conversations.insert(0, conv);
      }
    }
    
    // Guardar datos localmente
    await _saveConversations();
    await _saveMessages(conversationId);
    
    // MODIFICACIÓN AQUÍ: Enviar notificación SOLO al destinatario (no al remitente)
    // Solo enviar notificación si el destinatario es diferente al remitente
    if (recipientId != currentUser.id) {
      _notificationProvider.addMessageNotification(
        recipientId: recipientId,
        senderId: currentUser.id,
        senderName: currentUser.username,
        senderAvatar: currentUser.profilePicture,
        messageText: content,
        conversationId: conversationId,
      );
    }
    
    notifyListeners();
    return true;
  } catch (e) {
    print('Error al enviar mensaje: $e');
    _error = 'Fallo al enviar mensaje';
    notifyListeners();
    return false;
  }
}
  
  // البحث عن محادثة موجودة بين مستخدمين
  String _findExistingConversation(String otherUserId) {
    if (!_authProvider.isAuthenticated) return '';
    
    final currentUserId = _authProvider.user!.id;
    
    for (final conversation in _conversations) {
      if (conversation.participants.length == 2 &&
          conversation.participants.contains(currentUserId) &&
          conversation.participants.contains(otherUserId)) {
        return conversation.id;
      }
    }
    
    return '';
  }
  
  // تعليم رسائل محادثة كمقروءة
  Future<void> _markConversationAsRead(String conversationId) async {
    if (!_authProvider.isAuthenticated) return;
    
    final currentUserId = _authProvider.user!.id;
    
    try {
      // تعليم الرسائل التي استلمها المستخدم كمقروءة
      if (_messages.containsKey(conversationId)) {
        for (int i = 0; i < _messages[conversationId]!.length; i++) {
          final message = _messages[conversationId]![i];
          if (message.recipientId == currentUserId && !message.isRead) {
            _messages[conversationId]![i] = message.copyWithRead(read: true);
          }
        }
      }
      
      // تحديث عدد الرسائل غير المقروءة في المحادثة
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        final conversation = _conversations[conversationIndex];
        
        _conversations[conversationIndex] = Conversation(
          id: conversation.id,
          participants: conversation.participants,
          lastMessageContent: conversation.lastMessageContent,
          lastMessageTime: conversation.lastMessageTime,
          hasUnreadMessages: false,
          unreadCount: 0,
          otherUserId: conversation.otherUserId,
          otherUserName: conversation.otherUserName,
          otherUserAvatar: conversation.otherUserAvatar,
        );
      }
      
      // حفظ التغييرات
      await _saveConversations();
      await _saveMessages(conversationId);
      
      notifyListeners();
    } catch (e) {
      print('خطأ في تعليم الرسائل كمقروءة: $e');
    }
  }
  
  // تحديث/تحميل المحادثات
  Future<void> refreshConversations() async {
    await loadConversations();
  }
  
  // حذف محادثة
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((conversation) => conversation.id == conversationId);
    _messages.remove(conversationId);
    
    // حذف البيانات المحلية
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'messages_$conversationId';
      await prefs.remove(messagesKey);
      await _saveConversations();
    } catch (e) {
      print('خطأ في حذف بيانات المحادثة: $e');
    }
    
    notifyListeners();
  }
  
  // الحصول على عدد إجمالي الرسائل غير المقروءة
  int getTotalUnreadCount() {
    int total = 0;
    for (final conversation in _conversations) {
      if (conversation.hasUnreadMessages) {
        total += conversation.unreadCount;
      }
    }
    return total;
  }
  
  // إنشاء أو العثور على محادثة بين مستخدمين
  Future<String> getOrCreateConversation(String otherUserId, String otherUserName, String otherUserAvatar) async {
    if (!_authProvider.isAuthenticated) return '';
    
    // البحث عن محادثة موجودة
    final existingConversationId = _findExistingConversation(otherUserId);
    if (existingConversationId.isNotEmpty) {
      return existingConversationId;
    }
    
    // إنشاء محادثة جديدة
    final currentUser = _authProvider.user!;
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final newConversation = Conversation(
      id: conversationId,
      participants: [currentUser.id, otherUserId],
      lastMessageContent: null,
      lastMessageTime: null,
      hasUnreadMessages: false,
      unreadCount: 0,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatar: otherUserAvatar,
    );
    
    _conversations.insert(0, newConversation);
    _messages[conversationId] = [];
    
    await _saveConversations();
    
    notifyListeners();
    return conversationId;
  }
}