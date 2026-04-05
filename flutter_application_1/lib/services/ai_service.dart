import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:uuid/uuid.dart';

class AiService {
  // Вставь сюда свой "Ключ авторизации" (Base64) из кабинета GigaChat
  final String authKey = 'MDE5ZDVlOGEtNTZlZS03OTBjLTk0OTQtOThlMTA1MzE4YWVkOjg5NmZjZDlhLTFjNjgtNDBhNi1hZTBhLTM1NTUxNzE5YWJmNg=='; 
  final String scope = 'GIGACHAT_API_PERS';
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  // 1. Получение или обновление токена
  Future<String?> _getToken() async {
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken;
    }

    try {
      final response = await http.post(
        Uri.parse('https://ngw.devices.sberbank.ru:9443/api/v2/oauth'),
        headers: {
          'Authorization': 'Basic ${authKey.trim()}',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'RqUID': Uuid().v4(), 
        },
        body: {'scope': scope},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
print('СТАТУС: ${response.statusCode}');
  print('ОТВЕТ: ${response.body}');
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 25)); 
        return _accessToken;
      } else {
        print('Ошибка GigaAuth: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Исключение при получении токена: $e');
    }
    return null;
  }

  // 2. Главный метод для получения ответа от ИИ
  Future<String> getAiResponse(String message, List<Map<String, dynamic>> history) async {
    final token = await _getToken();
    if (token == null) return "Ошибка авторизации. Проверьте ключи в AiService.";

    try {
      final response = await http.post(
        Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "model": "GigaChat",
          "messages": [
            {"role": "system", "content": "Ты — Кодикс, помощник программиста. Отвечай на русском. Код выделяй ```."},
            ...history, // Передаем историю для контекста
            {"role": "user", "content": message}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded['choices'][0]['message']['content'];
      } else {
        return "Ошибка GigaChat: ${response.statusCode}";
      }
    } catch (e) {
      return "Ошибка сети: $e";
    }
  }
}