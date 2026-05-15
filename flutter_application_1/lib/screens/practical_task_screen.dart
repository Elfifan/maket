import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/practical_task_model.dart';
import '../models/test_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/judge0_service.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_container.dart';
import 'dart:ui' as ui;
import 'submodule_content_screen.dart';

class PracticalTaskScreen extends StatefulWidget {
  final PracticalTaskModel task;
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<PracticalTaskModel>>? practicalTasks;
  final Map<int, List<TestModel>>? submoduleTests;

  const PracticalTaskScreen({
    super.key,
    required this.task,
    required this.courseId,
    required this.courseName,
    this.allSubmodules,
    this.currentIndex = 0,
    this.practicalTasks,
    this.submoduleTests,
  });

  @override
  State<PracticalTaskScreen> createState() => _PracticalTaskScreenState();
}

class _PracticalTaskScreenState extends State<PracticalTaskScreen> {
  final TextEditingController _codeController = TextEditingController();
  final Judge0Service _judge0Service = Judge0Service();
  final ScrollController _scrollController = ScrollController();

  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _accentPink = Color(0xFFF2C9D4);
  static const Color _textGrey = Color(0xFF9094A6);

  List<TestResultItem> _testResults = [];
  bool _isTesting = false;
  bool _isCompleted = false;
  bool _isDescriptionExpanded = true;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.task.starterCode ?? '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runTests() async {
    if (widget.task.testCases == null || widget.task.testCases!.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isTesting = true;
      _testResults = [];
    });

    final results = <TestResultItem>[];
    int passedCount = 0;

    for (final testCase in widget.task.testCases!) {
      final result = await _judge0Service.executeCode(
        sourceCode: _codeController.text,
        language: widget.task.language ?? 'dart',
        stdin: testCase.input,
      );

      final actualOutput = result.stdout.trim();
      final expectedOutput = testCase.expectedOutput.trim();
      final bool passed = result.success && actualOutput == expectedOutput;

      if (passed) passedCount++;

      results.add(
        TestResultItem(
          testCase: testCase,
          passed: passed,
          actualOutput: actualOutput,
          error: result.error,
        ),
      );

      if (mounted) {
        setState(() => _testResults = List.from(results));
      }
    }

    final allPassed = passedCount == widget.task.testCases!.length;
    if (allPassed) {
      HapticFeedback.heavyImpact();
      await _saveTaskResult();
    }

    if (mounted) {
      setState(() {
        _isTesting = false;
        _isCompleted = allPassed;
      });
    }
  }

  Future<void> _saveTaskResult() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      await SupabaseService().savePracticalTaskResult(
        authProvider.currentUser!.id!,
        widget.task.id,
        widget.task.submoduleId ?? 0,
        _codeController.text,
      );
    } catch (e) {
      debugPrint('Error saving practical task result: $e');
    }
  }

  void _goToNextItem() {
    if (widget.allSubmodules != null && widget.currentIndex >= 0 && widget.currentIndex + 1 < widget.allSubmodules!.length) {
      final next = widget.allSubmodules![widget.currentIndex + 1];
      final nextContentUrl = next['content'] as String?;
      if (nextContentUrl != null && nextContentUrl.isNotEmpty) {
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
              practicalTasks: widget.practicalTasks,
            ),
          ),
        );
        return;
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.settings.name == 'course_profile');
          },
        ),
        title: Text(
          widget.task.name,
          style: GoogleFonts.roboto(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.task.language != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _buildLanguageChip()),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Декоративные сферы
          if (isDark) ...[
            Positioned(
              top: 100,
              right: -50,
              child: _buildDecorativeSphere(
                _primaryPurple.withValues(alpha: 0.1),
                200,
              ),
            ),
            Positioned(
              bottom: 150,
              left: -50,
              child: _buildDecorativeSphere(
                _accentPink.withValues(alpha: 0.08),
                250,
              ),
            ),
          ],

          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 100, // Extra padding so content can scroll above the floating button
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Условие задачи (Сворачиваемое)
                  _buildTaskDescription(isDark),
                  const SizedBox(height: 24),

                  // Редактор кода
                  _buildCodeEditor(isDark),
                  const SizedBox(height: 24),

                  // Результаты тестов
                  if (_testResults.isNotEmpty) _buildTestResults(isDark),
                ],
              ),
            ),
          ),

          // Плавающая кнопка
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: _buildActionButtons(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeSphere(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _buildTaskDescription(bool isDark) {
    if (widget.task.content == null || widget.task.content!.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      width: double.infinity,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(
              () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: _primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Условие задачи',
                    style: GoogleFonts.roboto(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isDescriptionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: _textGrey,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: MarkdownBody(
                data: widget.task.content!,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: context.textPrimary,
                  ),
                  code: TextStyle(
                    backgroundColor: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip() {
    final colors = {
      'python': const Color(0xFF3776AB),
      'javascript': const Color(0xFFF7DF1E),
      'dart': const Color(0xFF0175C2),
      'cpp': const Color(0xFF00599C),
      'java': const Color(0xFFED8B00),
    };
    final color = colors[widget.task.language?.toLowerCase()] ?? _primaryPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        widget.task.language?.toUpperCase() ?? '',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCodeEditor(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Компактный хедер редактора
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: _primaryPurple, size: 18),
                const SizedBox(width: 8),
                Text(
                  'main.${widget.task.language ?? 'dart'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isCompleted)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Поле ввода
          SizedBox(
            height: 350,
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.firaCode(
                color: const Color(0xFFE0E0E0),
                fontSize: 14,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
                hintText: '// Пишите ваш код здесь...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults(bool isDark) {
    final passedCount = _testResults.where((t) => t.passed).length;
    final totalCount = widget.task.testCases?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Text(
                'Результаты тестов',
                style: GoogleFonts.roboto(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '$passedCount / $totalCount',
                style: TextStyle(
                  color: passedCount == totalCount
                      ? Colors.green
                      : _primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ..._testResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return _buildTestResultItem(index + 1, result, isDark);
        }),
      ],
    );
  }

  Widget _buildTestResultItem(int number, TestResultItem result, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.passed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: result.passed ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Тест $number: ${result.testCase.description}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (!result.passed) ...[
            const SizedBox(height: 12),
            _buildResultDetail(
              'Ожидалось:',
              result.testCase.expectedOutput,
              Colors.green,
            ),
            const SizedBox(height: 4),
            _buildResultDetail('Получено:', result.actualOutput, Colors.red),
            if (result.error != null) ...[
              const SizedBox(height: 8),
              Text(
                result.error!,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResultDetail(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '(пусто)' : value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final isEnabled = !_isTesting;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: GestureDetector(
          onTap: isEnabled ? (_isCompleted ? _goToNextItem : _runTests) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: isDark 
              ? ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10) 
              : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: isDark
                          ? [_primaryPurple.withValues(alpha: 0.25), _accentPink.withValues(alpha: 0.15)]
                          : [_primaryPurple, _accentPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(16),
              border: isEnabled && isDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                  : null,
              boxShadow: isEnabled && !isDark
                  ? [
                      BoxShadow(
                        color: _primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: _isTesting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isCompleted
                              ? 'Дальше'
                              : 'Отправить на проверку',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TestResultItem {
  final TestCase testCase;
  final bool passed;
  final String actualOutput;
  final String? error;
  final String? executionTime;

  TestResultItem({
    required this.testCase,
    required this.passed,
    required this.actualOutput,
    this.error,
    this.executionTime,
  });
}
