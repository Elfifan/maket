import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/practical_task_model.dart';
import '../models/test_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_container.dart';
import 'submodule_content_screen.dart';

class TestsScreen extends StatefulWidget {
  final List<TestModel> tests;
  final String submoduleName;
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<TestModel>>? submoduleTests;
  final Map<int, List<PracticalTaskModel>>? practicalTasks;

  const TestsScreen({
    super.key,
    required this.tests,
    required this.submoduleName,
    required this.courseId,
    required this.courseName,
    this.allSubmodules,
    this.currentIndex = 0,
    this.submoduleTests,
    this.practicalTasks
  });

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  int _currentTestIndex = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int _correctAnswers = 0;
  bool _showResults = false;

  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _accentPink = Color(0xFFF2C9D4);

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    HapticFeedback.mediumImpact();
    final rightAnswer = widget.tests[_currentTestIndex].rightAnswer;
    setState(() {
      _isAnswered = true;
      _isCorrect = rightAnswer != null && _selectedAnswer == rightAnswer;
      if (_isCorrect) _correctAnswers++;
    });
  }

  void _nextTest() {
    HapticFeedback.lightImpact();
    if (_currentTestIndex < widget.tests.length - 1) {
      setState(() {
        _currentTestIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _isCorrect = false;
      });
    } else {
      _finishTest();
    }
  }

  void _finishTest() async {
    setState(() => _showResults = true);
    HapticFeedback.heavyImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        int submoduleId = widget.tests.isNotEmpty ? (widget.tests[0].submoduleId ?? 0) : 0;
        if (submoduleId == 0 && widget.allSubmodules != null && widget.currentIndex >= 0 && widget.currentIndex < widget.allSubmodules!.length) {
          submoduleId = widget.allSubmodules![widget.currentIndex]['id'] as int;
        }

        if (submoduleId > 0) {
          await SupabaseService().saveTestResult(
            authProvider.currentUser!.id!,
            submoduleId,
            widget.tests.length,
            _correctAnswers,
            _correctAnswers >= (widget.tests.length / 2).ceil(),
          );
        }
      } catch (e) {
        debugPrint('Error saving test result: $e');
      }
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

    if (widget.tests.isEmpty) {
      return _buildEmptyState('Тесты не найдены');
    }

    if (_showResults) {
      return _buildResultsScreen();
    }

    final currentTest = widget.tests[_currentTestIndex];
    final options = currentTest.answerOptions;
    final progress = (_currentTestIndex + 1) / widget.tests.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.submoduleName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Декоративные сферы
          if (isDark) ...[
            Positioned(
              top: 100,
              right: -50,
              child: _buildDecorativeSphere(_primaryPurple.withValues(alpha: 0.1), 200),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: _buildDecorativeSphere(_accentPink.withValues(alpha: 0.1), 250),
            ),
          ],

          SafeArea(
            child: Column(
              children: [
                // Прогресс бар
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Вопрос ${_currentTestIndex + 1} из ${widget.tests.length}',
                            style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              color: isDark ? _primaryPurple.withValues(alpha: 0.8) : _primaryPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? _primaryPurple.withValues(alpha: 0.4) : _primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey<int>(_currentTestIndex),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Карточка вопроса
                          GlassContainer(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            borderRadius: 24,
                            child: Text(
                              currentTest.question ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Варианты ответа
                          ...options.map((option) => _buildOption(option)),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                // Панель действий
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAnswered) _buildFeedbackArea(currentTest),
                      const SizedBox(height: 16),
                      _buildMainButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String option) {
    final isSelected = _selectedAnswer == option;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: _isAnswered ? null : () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAnswer = option);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? _primaryPurple.withValues(alpha: isDark ? 0.2 : 0.1) 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? _primaryPurple 
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: _primaryPurple.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryPurple : (isDark ? Colors.white24 : Colors.black26),
                  width: 2,
                ),
                color: isSelected ? _primaryPurple : Colors.transparent,
              ),
              child: isSelected 
                  ? const Icon(Icons.check, color: Colors.white, size: 16) 
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _primaryPurple : context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackArea(TestModel currentTest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.error_rounded,
            color: _isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect 
                  ? 'Отлично! Вы ответили правильно.' 
                  : 'Не совсем... Правильно: ${currentTest.rightAnswer}',
              style: TextStyle(
                color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    final isDark = context.isDark;
    final isEnabled = _isAnswered || _selectedAnswer != null;

    return GestureDetector(
      onTap: isEnabled ? (_isAnswered ? _nextTest : _submitAnswer) : null,
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
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            _isAnswered
                ? (_currentTestIndex < widget.tests.length - 1 ? 'Дальше' : 'Результаты')
                : 'Проверить ответ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEnabled 
                  ? Colors.white 
                  : (isDark ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final percent = (_correctAnswers / widget.tests.length * 100).toInt();
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(top: -50, left: -50, child: _buildDecorativeSphere(_primaryPurple.withValues(alpha: 0.15), 300)),
            Positioned(bottom: -50, right: -50, child: _buildDecorativeSphere(_accentPink.withValues(alpha: 0.15), 300)),
          ],
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      percent >= 50 ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                      size: 64,
                      color: _primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    percent >= 50 ? 'Поздравляем!' : 'Нужно потренироваться',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Вы успешно ответили на $_correctAnswers из ${widget.tests.length} вопросов',
                    style: TextStyle(fontSize: 16, color: context.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Кольцо прогресса
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: _correctAnswers / widget.tests.length,
                          strokeWidth: 12,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(_primaryPurple),
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 64),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _goToNextItem,
                      child: const Text('Продолжить обучение', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDecorativeSphere(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      backgroundColor: context.bgColor,
      body: Center(
        child: Text(message, style: TextStyle(color: context.textSecondary)),
      ),
    );
  }
}

