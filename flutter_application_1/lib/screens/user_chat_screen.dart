import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class UserChatScreen extends StatefulWidget {
  final int roomId;
  final int userId;
  final String courseName;

  const UserChatScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.courseName,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  StreamSubscription<ChatMessageModel>? _realtimeSubscription;

  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _accentPink = Color(0xFFF2C9D4);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _bgLight = Color(0xFFF8F9FB);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToRealtimeMessages(); // ← Включаем realtime
  }

  /// Загружаем старые сообщения
  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getChatMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Подписываемся на новые сообщения в реальном времени
  void _subscribeToRealtimeMessages() {
    _realtimeSubscription = _chatService
        .subscribeToChatMessages(widget.roomId)
        .listen(
          (newMessage) {
            if (mounted) {
              setState(() {
                // Проверяем, нет ли уже такого сообщения (избегаем дубликатов)
                final exists = _messages.any((m) => m.id == newMessage.id);
                if (!exists) {
                  _messages.add(newMessage);
                  _scrollToBottom();
                }
              });
            }
          },
          onError: (error) {
            print('Realtime error: $error');
          },
        );
  }

  /// Отправка сообщения
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Очищаем поле сразу для быстрого UI
    _messageController.clear();

    try {
      final sentMessage = await _chatService.sendChatMessage(
        roomId: widget.roomId,
        senderType: 'user',
        senderId: widget.userId,
        message: text,
      );

      // Добавляем отправленное сообщение в список (если еще не добавлено через realtime)
      if (sentMessage != null && mounted) {
        setState(() {
          final exists = _messages.any((m) => m.id == sentMessage.id);
          if (!exists) {
            _messages.add(sentMessage);
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Возвращаем текст обратно в поле
        _messageController.text = text;
      }
    }
  }

  /// Прокрутка вниз
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel(); // ← Отписываемся при уходе
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textGrey, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseName,
              style: GoogleFonts.roboto(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Автор курса',
              style: GoogleFonts.roboto(
                color: _textGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          // Индикатор онлайн статуса
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Онлайн',
                  style: GoogleFonts.roboto(
                    color: _textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryPurple),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _primaryPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: _primaryPurple.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Начните общение',
                              style: GoogleFonts.roboto(
                                color: _textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Задайте вопрос автору курса',
                              style: GoogleFonts.roboto(
                                color: _textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderType == 'user';
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),
          // Поле ввода
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, bool isMe) {
    final time = msg.createdAt != null
        ? '${msg.createdAt!.hour.toString().padLeft(2, '0')}:${msg.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [_primaryPurple, _accentPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? _primaryPurple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: isMe ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                color: isMe ? Colors.white : _textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white.withOpacity(0.7) : _textGrey,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.roboto(fontSize: 15, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Ваше сообщение...',
                    hintStyle: GoogleFonts.roboto(color: _textGrey),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryPurple, _accentPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPurple.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}