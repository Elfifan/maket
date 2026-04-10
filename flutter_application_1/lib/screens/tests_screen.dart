import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'submodule_content_screen.dart';

class TestsScreen extends StatefulWidget {
  final List<TestModel> tests;
  final String submoduleName;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<TestModel>>? submoduleTests;

  const TestsScreen({
    super.key,
    required this.tests,
    required this.submoduleName,
    this.allSubmodules,
    this.currentIndex = 0,
    this.submoduleTests,
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

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    final rightAnswer = widget.tests[_currentTestIndex].rightAnswer;
    setState(() {
      _isAnswered = true;
      _isCorrect = rightAnswer != null && _selectedAnswer == rightAnswer;
      if (_isCorrect) _correctAnswers++;
    });
  }

  void _nextTest() {
    if (_currentTestIndex < widget.tests.length - 1) {
      setState(() {
        _currentTestIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
        _isCorrect = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() async {
    // Сохраняем результат теста
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        // Определяем submoduleId - берем из первого теста или из параметров
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
            _correctAnswers >= (widget.tests.length / 2).ceil(), // isCorrect - 50% и более правильных ответов
          );
        }
      } catch (e) {
        print('Error saving test result: $e');
        // Продолжаем показывать результаты, даже если сохранение не удалось
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Результаты тестирования'),
        content: Text(
          'Вы ответили правильно на $_correctAnswers из ${widget.tests.length} вопросов.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрыть диалог
              _goToNextItem();
            },
            child: const Text('Следующий урок'),
          ),
        ],
      ),
    );
  }

  void _goToNextItem() {
    // Проверяем, есть ли следующий подмодуль
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
              allSubmodules: widget.allSubmodules,
              currentIndex: widget.currentIndex + 1,
              submoduleTests: widget.submoduleTests,
            ),
          ),
        );
        return;
      }
    }

    // Если следующего подмодуля нет, возвращаемся назад
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tests.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тесты'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Тесты не найдены'),
        ),
      );
    }

    final currentTest = widget.tests[_currentTestIndex];
    final options = currentTest.answerOptions;

    if (options.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тесты'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E1E2E),
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Вопрос не имеет вариантов ответа'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.submoduleName} - Тест ${_currentTestIndex + 1}/${widget.tests.length}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTest.question ?? 'Вопрос отсутствует',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2E)),
            ),
            const SizedBox(height: 24),
            ...options.map((option) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: _selectedAnswer,
                  title: Text(option, style: const TextStyle(fontSize: 16)),
                  onChanged: _isAnswered
                      ? null
                      : (value) {
                          setState(() {
                            _selectedAnswer = value;
                          });
                        },
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA58EFF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isAnswered ? _nextTest : (_selectedAnswer == null ? null : _submitAnswer),
                child: Text(
                  _isAnswered
                      ? (_currentTestIndex < widget.tests.length - 1 ? 'Следующий вопрос' : 'Завершить тест')
                      : 'Проверить ответ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: _isAnswered ? const EdgeInsets.all(16) : EdgeInsets.zero,
              decoration: _isAnswered ? BoxDecoration(
                color: _isCorrect ? const Color(0xFFDFF5E7) : const Color(0xFFFDE9E9),
                borderRadius: BorderRadius.circular(12),
              ) : null,
              child: _isAnswered ? Text(
                _isCorrect ? 'Правильно!' : 'Неправильно. Правильный ответ: ${currentTest.rightAnswer ?? 'Не указан'}',
                style: TextStyle(
                  color: _isCorrect ? const Color(0xFF1C6B34) : const Color(0xFF8A1F1F),
                  fontSize: 16,
                ),
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}