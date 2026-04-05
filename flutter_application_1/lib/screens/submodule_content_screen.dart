import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; // Нужно добавить
import 'package:chewie/chewie.dart';           // Нужно добавить

class SubmoduleContentScreen extends StatefulWidget {
  final String title;
  final String contentUrl;

  const SubmoduleContentScreen({
    super.key,
    required this.title,
    required this.contentUrl,
  });

  @override
  State<SubmoduleContentScreen> createState() => _SubmoduleContentScreenState();
}

class _SubmoduleContentScreenState extends State<SubmoduleContentScreen> {
  String _markdownContent = "";
  bool _isLoading = true;
  String? _error;

  // Контроллеры для видео
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideo = false;

@override
void initState() {
  super.initState();
  
  // Более надежная проверка: приводим к нижнему регистру и проверяем наличие расширения до знаков вопроса
  final String url = widget.contentUrl.toLowerCase();
  _isVideo = url.contains('.mp4') || url.contains('.mov') || url.contains('.avi');
  
  if (_isVideo) {
    _initializeVideo();
  } else {
    _fetchMarkdown();
  }
}

  // Инициализация видеоплеера
  Future<void> _initializeVideo() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.contentUrl));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        // Стилизация под цвета вашего приложения
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFA58EFF),
          handleColor: const Color(0xFFA58EFF),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Ошибка инициализации видео: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMarkdown() async {
    try {
      final response = await http.get(Uri.parse(widget.contentUrl));
      if (response.headers['content-type']?.contains('video') ?? false) {
       setState(() {
         _isVideo = true;
         _initializeVideo();
       });
       return;
    }
      if (response.statusCode == 200) {
        setState(() {
          _markdownContent = utf8.decode(response.bodyBytes);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Ошибка загрузки: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Ошибка сети: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA58EFF)))
          : _error != null
              ? Center(child: Text(_error!))
              : _isVideo 
                  ? _buildVideoUI() 
                  : _buildMarkdownUI(),
    );
  }

  // Виджет для отображения видео
  Widget _buildVideoUI() {
    return Column(
      children: [
        if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          )
        else
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          ),
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Просмотр видеоурока",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Виджет для отображения текста (ваш текущий Markdown)
  Widget _buildMarkdownUI() {
    return Markdown(
      data: _markdownContent,
      selectable: true,
      onTapLink: (text, href, title) async {
        if (href != null) {
          final url = Uri.parse(href);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      imageBuilder: (uri, title, alt) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              uri.toString(),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2E)),
        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2E)),
        p: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF2E2E3E)),
        listBullet: const TextStyle(fontSize: 16, color: Color(0xFFA58EFF)),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
      ),
    );
  }
}