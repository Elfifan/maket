import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/practical_task_model.dart';
import '../providers/auth_provider.dart';
import '../services/judge0_service.dart';
import '../services/supabase_service.dart';
import 'submodule_content_screen.dart';

class PracticalTaskScreen extends StatefulWidget {
  final PracticalTaskModel task;
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>>? allSubmodules;
  final int currentIndex;
  final Map<int, List<PracticalTaskModel>>? practicalTasks;

  const PracticalTaskScreen({
    super.key,
    required this.task,
    required this.courseId,
    required this.courseName,
    this.allSubmodules,
    this.currentIndex = 0,
    this.practicalTasks,
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
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _bgLight = Color(0xFFF8F9FB);

  List<TestResultItem> _testResults = [];
  bool _isRunning = false;
  bool _isTesting = false;
  bool _isCompleted = false;

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

  /// Запустить код без тестов (для отладки)
  Future<void> _runCode() async {
    setState(() => _isRunning = true);

    final result = await _judge0Service.executeCode(
      sourceCode: _codeController.text,
      language: widget.task.language ?? 'dart',
    );

    if (mounted) {
      setState(() => _isRunning = false);
      _showRunResult(result);
    }
  }

//
Future<void> _runTests() async {
  if (widget.task.testCases == null || widget.task.testCases!.isEmpty) return;

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

    // Очищаем строки от лишних пробелов и \n для точного сравнения[cite: 12]
    final actualOutput = result.stdout.trim();
    final expectedOutput = testCase.expectedOutput.trim();
    
    // Проверяем успешность: код 0 и совпадение вывода
    final bool passed = result.success && actualOutput == expectedOutput;

    if (passed) passedCount++;

    results.add(TestResultItem(
      testCase: testCase,
      passed: passed,
      actualOutput: actualOutput,
      error: result.error, 
    ));

    if (mounted) {
      setState(() => _testResults = List.from(results));
    }
  }

  final allPassed = passedCount == widget.task.testCases!.length;
  if (allPassed) {
    await _saveTaskResult();
  }

  if (mounted) {
    setState(() {
      _isTesting = false;
      _isCompleted = allPassed;
    });
  }
}

  /// Сохранить результат выполнения задания
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
      if (e.toString().contains('401')) {
      print('Ошибка: Пользователь не авторизован или ключ API неверен');
        }
      print('Error saving practical task result: $e');
    }
  }

  void _showRunResult(Judge0Result result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  result.success ? 'Выполнено успешно' : 'Ошибка',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (result.stdout != null && result.stdout!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Вывод:', style: TextStyle(color: _textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  result.stdout!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ],
            if (result.error != null) ...[
              const SizedBox(height: 16),
              Text('Ошибка:', style: TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.error!,
                  style: TextStyle(color: Colors.red.shade700, fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Закрыть', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNext() {
    if (widget.allSubmodules != null && 
        widget.currentIndex >= 0 && 
        widget.currentIndex + 1 < widget.allSubmodules!.length) {
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
              submoduleTests: null,
              practicalTasks: widget.practicalTasks,
            ),
          ),
        );
        return;
      }
    }
    Navigator.pop(context, true);
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
        title: Text(
          widget.task.name,
          style: GoogleFonts.roboto(color: _textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.task.language != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildLanguageChip(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Условие задачи
                  if (widget.task.content != null && widget.task.content!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Markdown(
                        data: widget.task.content!,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        styleSheet: MarkdownStyleSheet(
                          h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
                          h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                          p: TextStyle(fontSize: 15, height: 1.6, color: _textDark),
                          code: TextStyle(
                            backgroundColor: _bgLight,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Редактор кода
                  _buildCodeEditor(),
                  const SizedBox(height: 20),

                  // Результаты тестов
                  if (_testResults.isNotEmpty) _buildTestResults(),
                ],
              ),
            ),
          ),

          // Кнопки действий
          _buildActionButtons(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.task.language?.toUpperCase() ?? '',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок редактора
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27C93F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.code, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  'main.${widget.task.language ?? 'dart'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const Spacer(),
                if (_isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Выполнено', style: TextStyle(color: Colors.green, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Поле ввода кода
          SizedBox(
            height: 300,
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFD4D4D4),
                fontSize: 14,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    final passedCount = _testResults.where((t) => t.passed).length;
    final totalCount = _testResults.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passedCount == totalCount ? Icons.check_circle : Icons.warning_amber,
                color: passedCount == totalCount ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Тесты: $passedCount/$totalCount пройдено',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._testResults.asMap().entries.map((entry) {
            final index = entry.key;
            final testResult = entry.value;
            return _buildTestResultItem(index + 1, testResult);
          }),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(int number, TestResultItem result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.passed ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: result.passed ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.passed ? Icons.check_circle : Icons.cancel,
                color: result.passed ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Тест $number: ${result.testCase.description}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: result.passed ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              if (result.executionTime != null) ...[
                const Spacer(),
                Text(
                  '${result.executionTime}s',
                  style: TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ],
          ),
          if (!result.passed) ...[
            const SizedBox(height: 8),
            if (result.testCase.input.isNotEmpty)
              Text('Ввод: ${result.testCase.input}', 
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: _textGrey)),
            Text('Ожидалось: ${result.testCase.expectedOutput}', 
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.red.shade700)),
            Text('Получено: ${result.actualOutput}', 
              style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.red.shade700)),
            if (result.error != null)
              Text('Ошибка: ${result.error}', 
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isRunning ? null : _runCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPurple,
                  side: const BorderSide(color: _primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryPurple),
                      )
                    else
                      const Icon(Icons.play_arrow_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(_isRunning ? 'Выполнение...' : 'Запустить'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _runTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTesting)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else if (_isCompleted)
                      const Icon(Icons.check, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isTesting ? 'Тестирование...' : 
                      _isCompleted ? 'Тесты пройдены' : 'Отправить на проверку',
                    ),
                  ],
                ),
              ),
            ),
          ],
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
