import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; 
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'tests_screen.dart';

class SubmoduleContentScreen extends StatefulWidget {
  final String title;
  final String contentUrl;
  final int submoduleId;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<TestModel>>? submoduleTests;

  const SubmoduleContentScreen({
    super.key,
    required this.title,
    required this.contentUrl,
    required this.submoduleId,
    required this.allSubmodules,
    required this.currentIndex,
    this.submoduleTests,
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

    final String url = widget.contentUrl.toLowerCase();
    _isVideo = url.contains('.mp4') || url.contains('.mov') || url.contains('.avi');

    if (_isVideo) {
      _initializeVideo();
    } else {
      _fetchMarkdown();
    }
  }
  VideoFormat _detectVideoFormat(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('application/vnd.apple.mpegurl')) {
      return VideoFormat.hls;
    }
    if (lower.contains('.mpd')) {
      return VideoFormat.dash;
    }
    return VideoFormat.other;
  }

  // Инициализация видеоплеера
  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.tryParse(widget.contentUrl.trim());
      if (uri == null || uri.scheme.isEmpty) {
        throw FormatException('Неверный URL видео');
      }

      final formatHint = _detectVideoFormat(widget.contentUrl);
      _videoPlayerController = VideoPlayerController.networkUrl(
        uri,
        formatHint: formatHint,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Mobile Safari/537.36',
          'Accept': 'video/*,*/*;q=0.8',
        },
      );

      await _videoPlayerController!.initialize();
      _videoPlayerController!.setLooping(false);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFA58EFF),
          handleColor: const Color(0xFFA58EFF),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Video init failed: ${widget.contentUrl} / $e');
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

  bool get _hasNextSubmodule {
    return widget.allSubmodules != null && widget.currentIndex >= 0 && widget.currentIndex + 1 < widget.allSubmodules!.length;
  }

  Map<String, dynamic>? get _nextSubmodule {
    if (!_hasNextSubmodule) return null;
    return widget.allSubmodules![widget.currentIndex + 1];
  }

  void _goToNextSubmodule() async {
    // Сохраняем прогресс текущего подмодуля
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        await SupabaseService().saveSubmoduleProgress(authProvider.currentUser!.id!, widget.submoduleId);
      } catch (e) {
        print('Error saving submodule progress: $e');
        // Продолжаем, даже если сохранение не удалось
      }
    }

    // Сначала проверяем, есть ли тесты для текущего подмодуля
    final tests = widget.submoduleTests?[widget.submoduleId];
    if (tests != null && tests.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestsScreen(
            tests: tests,
            submoduleName: widget.title,
            allSubmodules: widget.allSubmodules,
            currentIndex: widget.currentIndex,
            submoduleTests: widget.submoduleTests,
          ),
        ),
      );
      return;
    }

    // Если тестов нет, переходим к следующему подмодулю
    final next = _nextSubmodule;
    if (next == null) return;

    final nextContentUrl = next['content'] as String?;
    if (nextContentUrl == null || nextContentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Содержимое следующего урока недоступно')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubmoduleContentScreen(
          title: next['name'] ?? 'Следующий урок',
          contentUrl: nextContentUrl,
          submoduleId: next['id'] as int,
          allSubmodules: widget.allSubmodules,
          currentIndex: widget.currentIndex + 1,
          submoduleTests: widget.submoduleTests,
        ),
      ),
    );
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
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _isVideo ? _buildVideoUI() : _buildMarkdownUI(),
                          ],
                        ),
                      ),
                    ),
                    if (_hasNextSubmodule)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA58EFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _goToNextSubmodule,
                            child: Text(
                              'Следующий: ${_nextSubmodule?['name'] ?? 'урок'}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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