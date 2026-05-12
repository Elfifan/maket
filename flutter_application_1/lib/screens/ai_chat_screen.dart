import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/ai_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/theme_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final AiService _aiService = AiService();
  bool _isTyping = false;

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _controller.clear();
      _isTyping = true;
    });

    final response = await _aiService.getAiResponse(
      text, 
      _messages.sublist(0, _messages.length - 1)
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({"role": "assistant", "content": response});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Чат ИИ',
          style: GoogleFonts.manrope(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.isEmpty ? 1 : _messages.length,
              itemBuilder: (context, index) {
                if (_messages.isEmpty) return _buildWelcomeCard();
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Кодикс печатает...",
                style: GoogleFonts.manrope(color: Colors.grey, fontSize: 12),
              ),
            ),
          _buildInputPanel(),
        ],
      ),
    );
  }

Widget _buildMessageBubble(Map<String, dynamic> msg) {
  bool isUser = msg['role'] == 'user';
  String content = msg['content'];


  final parts = content.split(RegExp(r'```'));

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: List.generate(parts.length, (index) {
        final part = parts[index].trim();
        if (part.isEmpty) return const SizedBox.shrink();


        bool isCode = index % 2 != 0;

        if (isCode) {
          return _buildCodeBlock(part);
        } else {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFFA58EFF).withValues(alpha: context.isDark ? 0.3 : 0.2)
                  : context.isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(20),
              border: context.isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
            ),
            child: Text(
              part,
              style: GoogleFonts.manrope(fontSize: 14, color: context.textPrimary),
            ),
          );
        }
      }),
    ),
  );
}

Widget _buildCodeBlock(String code) {
  final lines = code.split('\n');
  String language = 'dart'; 
  if (lines.isNotEmpty && lines[0].trim().length < 10 && !lines[0].contains(' ')) {
    language = lines[0].trim();
    lines.removeAt(0);
  }
  final cleanCode = lines.join('\n').trim();

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    width: MediaQuery.of(context).size.width * 0.85,
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E2E), 
      borderRadius: BorderRadius.circular(15),
    ),
    child: HighlightView(
      cleanCode,
      language: language,
      theme: atomOneDarkTheme,
      textStyle: GoogleFonts.firaCode(fontSize: 12),
      padding: const EdgeInsets.all(8),
    ),
  );
}

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.isDark
            ? const Color(0xFFA58EFF).withValues(alpha: 0.1)
            : const Color(0xFFEBE7FF),
        borderRadius: BorderRadius.circular(32),
        border: context.isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFA58EFF),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Помощник Кодикс',
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Я помогу тебе разобраться в коде или объяснить сложные концепции программирования.',
            style: GoogleFonts.manrope(color: const Color(0xFF5E5E7E), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      decoration: BoxDecoration(
        color: context.isDark ? ThemeProvider.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_none_rounded, color: Color(0xFF5E5E7E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.manrope(fontSize: 13, color: context.textPrimary),
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Спроси о коде...',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFF9094A6), 
                          fontSize: 13
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFA58EFF), Color(0xFFF2C9D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA58EFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}