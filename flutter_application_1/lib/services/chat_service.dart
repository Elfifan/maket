import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Создать или получить комнату чата
  Future<int?> getOrCreateChatRoom(int userId, int courseId) async {
    try {
      // Проверяем, существует ли комната
      final existing = await _client
          .from('chat_rooms')
          .select('id')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as int;
      }

      // Создаем новую комнату
      final newRoom = await _client
          .from('chat_rooms')
          .insert({
            'id_user': userId,
            'id_courses': courseId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return newRoom['id'] as int;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      return null;
    }
  }

  /// Получить список чатов пользователя
  Future<List<Map<String, dynamic>>> getUserChatRooms(int userId) async {
    try {
      final response = await _client
          .from('chat_rooms')
          .select('''
            id,
            id_courses,
            created_at,
            courses!inner(id, name, id_employee)
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user chat rooms: $e');
      return [];
    }
  }

  /// Загрузить сообщения чата
  Future<List<ChatMessageModel>> getChatMessages(int roomId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('*')
          .eq('id_room', roomId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  /// Отправить сообщение
  Future<ChatMessageModel?> sendChatMessage({
    required int roomId,
    required String senderType,
    required int senderId,
    required String message,
  }) async {
    try {
      final response = await _client
          .from('chat_messages')
          .insert({
            'id_room': roomId,
            'sender_type': senderType,
            'sender_id': senderId,
            'message': message,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ChatMessageModel.fromJson(response);
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  /// Подписка на новые сообщения в реальном времени
  Stream<ChatMessageModel> subscribeToChatMessages(int roomId) {
    final channel = _client.channel(
      'chat-room-$roomId',
      opts: const RealtimeChannelConfig(),
    );

    final controller = StreamController<ChatMessageModel>.broadcast();

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id_room',
        value: roomId,
      ),
      callback: (payload) {
        try {
          final json = Map<String, dynamic>.from(payload.newRecord);
          final message = ChatMessageModel.fromJson(json);
          controller.add(message);
        } catch (e) {
          debugPrint('Error parsing realtime message: $e');
        }
      },
    );

    channel.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('✅ Subscribed to chat room $roomId');
      } else {
        debugPrint('❌ Subscription error: $status');
      }
    });

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };

    return controller.stream;
  }

  /// Получить последнее сообщение в комнате
  Future<Map<String, dynamic>?> getLastMessage(int roomId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('message, created_at')
          .eq('id_room', roomId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  /// Пометить сообщения как прочитанные
  Future<void> markMessagesAsRead(int roomId, String senderType) async {
    try {
      await _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('id_room', roomId)
          .neq('sender_type', senderType)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Получить количество непрочитанных сообщений
  Future<int> getUnreadCount(int userId) async {
    try {
      // Получаем все комнаты пользователя
      final rooms = await _client
          .from('chat_rooms')
          .select('id')
          .eq('id_user', userId);

      if (rooms.isEmpty) return 0;

      final roomIds = List<Map<String, dynamic>>.from(rooms)
          .map((r) => r['id'] as int)
          .toList();

      // Считаем непрочитанные сообщения
      final response = await _client
          .from('chat_messages')
          .select('id')
          .inFilter('id_room', roomIds)
          .neq('sender_type', 'user')
          .eq('is_read', false);

      return List<Map<String, dynamic>>.from(response).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}
