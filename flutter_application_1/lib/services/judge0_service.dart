import 'dart:convert';
import 'package:http/http.dart' as http;

class Judge0Service {
  // Базовый URL для Glot.io
  static const String _baseUrl = 'https://glot.io/api/run';
  // Вставьте сюда ваш токен
  static const String _apiToken = 'be9c4765-ba3f-4765-8ee7-39324fff9da1';

  /// Выполнить код через Glot.io
  Future<Judge0Result> executeCode({
    required String sourceCode,
    required String language,
    String? stdin,
  }) async {
    try {
      // Glot.io использует свои названия для языков
      final String lang = _mapLanguage(language);
      
      final url = Uri.parse('$_baseUrl/$lang/latest');

      final body = {
        "files": [
          {
            "name": _getFileName(lang),
            "content": sourceCode
          }
        ],
        "stdin": stdin ?? ""
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Glot.io возвращает stdout, stderr и error отдельно
        return Judge0Result(
          success: data['error'] == "" && data['stderr'] == "",
          stdout: data['stdout']?.toString() ?? '',
          stderr: data['stderr']?.toString() ?? '',
          error: data['error']?.toString().isNotEmpty == true ? data['error'] : null,
        );
      }

      return Judge0Result(
        success: false,
        error: 'Ошибка сервера Glot: ${response.statusCode}',
      );
    } catch (e) {
      return Judge0Result(
        success: false,
        error: 'Ошибка сети: $e',
      );
    }
  }

  String _mapLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'python': return 'python';
      case 'dart': return 'dart';
      case 'javascript': return 'javascript';
      case 'cpp': case 'c++': return 'cpp';
      case 'csharp': case 'c#': return 'csharp';
      default: return 'python';
    }
  }

  String _getFileName(String lang) {
    switch (lang) {
      case 'python': return 'main.py';
      case 'dart': return 'main.dart';
      case 'javascript': return 'main.js';
      case 'csharp': return 'main.cs';
      default: return 'main';
    }
  }
}

class Judge0Result {
  final bool success;
  final String stdout;
  final String stderr;
  final String? error;

  Judge0Result({
    required this.success,
    this.stdout = '',
    this.stderr = '',
    this.error,
  });
}