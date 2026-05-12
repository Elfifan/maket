import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; 
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../models/course_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../services/certificate_service.dart';
import 'tests_screen.dart';
import '../models/practical_task_model.dart';
import '../widgets/glass_container.dart';

class SubmoduleContentScreen extends StatefulWidget {
  final String title;
  final String contentUrl;
  final int submoduleId;
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<TestModel>>? submoduleTests;
  final Map<int, List<PracticalTaskModel>>? practicalTasks;

  const SubmoduleContentScreen({
    super.key,
    required this.title,
    required this.contentUrl,
    required this.submoduleId,
    required this.courseId,
    required this.courseName,
    required this.allSubmodules,
    required this.currentIndex,
    this.submoduleTests,
    this.practicalTasks,
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

  bool get _isLastSubmodule {
    return widget.allSubmodules != null && widget.currentIndex >= 0 && widget.currentIndex == widget.allSubmodules!.length - 1;
  }

  Map<String, dynamic>? get _nextSubmodule {
    if (!_hasNextSubmodule) return null;
    return widget.allSubmodules![widget.currentIndex + 1];
  }

  void _completeCourse() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Проверяем, есть ли уже сертификат для этого курса
    final hasCertificate = await CertificateService().hasCertificate(
      authProvider.currentUser!.id!,
      widget.courseId,
    );

    if (hasCertificate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сертификат за этот курс уже был выдан ранее'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Сохраняем прогресс текущего подмодуля
    try {
      await SupabaseService().saveSubmoduleProgress(authProvider.currentUser!.id!, widget.submoduleId);
    } catch (e) {
      debugPrint('Error saving submodule progress: $e');
    }

    // Проверяем, есть ли тесты для текущего подмодуля и проходим их
    final tests = widget.submoduleTests?[widget.submoduleId];
    if (!mounted) return;
    if (tests != null && tests.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestsScreen(
            tests: tests,
            submoduleName: widget.title,
            courseId: widget.courseId,
            courseName: widget.courseName,
            allSubmodules: widget.allSubmodules,
            currentIndex: widget.currentIndex,
            submoduleTests: widget.submoduleTests,
          ),
        ),
      );

      if (result != true) {
        // Тесты не пройдены
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пройдите тесты, чтобы завершить курс')),
          );
        }
        return;
      }
    }

    // Генерируем сертификат
    final course = CourseModel(
      id: widget.courseId,
      name: widget.courseName,
      description: null,
      price: null,
      complexity: null,
      status: null,
      icon: null,
      dateCreate: null,
      idEmployee: null,
    );

    final certificate = await CertificateService().generateAndUploadCertificate(
      user: authProvider.currentUser!,
      course: course,
    );

    if (certificate != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поздравляем! Курс завершен. Сертификат выдан.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при генерации сертификата'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _goToNextSubmodule() async {
    // Сохраняем прогресс текущего подмодуля
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        await SupabaseService().saveSubmoduleProgress(authProvider.currentUser!.id!, widget.submoduleId);
      } catch (e) {
        debugPrint('Error saving submodule progress: $e');
        // Продолжаем, даже если сохранение не удалось
      }
    }

    // Сначала проверяем, есть ли тесты для текущего подмодуля
    final tests = widget.submoduleTests?[widget.submoduleId];
    if (tests != null && tests.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestsScreen(
            tests: tests,
            submoduleName: widget.title,
            courseId: widget.courseId,
            courseName: widget.courseName,
            allSubmodules: widget.allSubmodules,
            currentIndex: widget.currentIndex,
            submoduleTests: widget.submoduleTests,
            practicalTasks: widget.practicalTasks,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Содержимое следующего урока недоступно')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubmoduleContentScreen(
          title: next['name'] ?? 'Следующий урок',
          contentUrl: nextContentUrl,
          submoduleId: next['id'] as int,
          courseId: widget.courseId,
          courseName: widget.courseName,
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: context.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Фоновые декорации для темной темы
          if (context.isDark) ...[
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA58EFF).withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF2C9D4).withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
          
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFA58EFF)))
              : _error != null
                  ? Center(child: Text(_error!))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _isVideo ? _buildVideoUI() : _buildMarkdownUI(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildVideoUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Стилизованный плеер
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA58EFF).withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: _videoPlayerController?.value.isInitialized == true
                  ? _videoPlayerController!.value.aspectRatio
                  : 16 / 9,
              child: _chewieController != null && _videoPlayerController?.value.isInitialized == true
                  ? Chewie(controller: _chewieController!)
                  : Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFA58EFF))),
                    ),
            ),
          ),
        ),

        // Информационная карточка урока
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA58EFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFA58EFF), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Видеоурок • ${widget.courseName}",
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: context.borderColor, height: 1),
                const SizedBox(height: 20),
                Text(
                  "В этом уроке мы разберем ключевые концепции темы и закрепим их на практических примерах. Обязательно досмотрите до конца, чтобы успешно пройти итоговый тест.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: context.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Блок ключевых моментов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  "Ключевые тезисы",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              _buildTopicItem(Icons.check_circle_outline_rounded, "Теоретические основы и определения"),
              _buildTopicItem(Icons.check_circle_outline_rounded, "Практическое применение инструментов"),
              _buildTopicItem(Icons.check_circle_outline_rounded, "Разбор типичных ошибок"),
              _buildTopicItem(Icons.check_circle_outline_rounded, "Советы по оптимизации рабочего процесса"),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Превью следующего урока
        if (_hasNextSubmodule) _buildNextLessonPreview(),
      ],
    );
  }

  Widget _buildTopicItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA58EFF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: context.textPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextLessonPreview() {
    final next = _nextSubmodule;
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              "Следующий урок",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: _goToNextSubmodule,
            borderRadius: BorderRadius.circular(20),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA58EFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFA58EFF)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next['name'] ?? 'Урок',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Перейти к следующему этапу обучения",
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
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

  Widget _buildBottomNavigation() {
    if (_hasNextSubmodule) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA58EFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _goToNextSubmodule,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Перейти к следующему уроку',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLastSubmodule) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _completeCourse,
            child: const Text(
              'Завершить курс и получить сертификат',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
      // ignore: deprecated_member_use
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
        h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary),
        h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
        p: TextStyle(fontSize: 16, height: 1.5, color: context.textPrimary),
        listBullet: const TextStyle(fontSize: 16, color: Color(0xFFA58EFF)),
        codeblockDecoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.borderColor),
        ),
      ),
    );
  }
}
