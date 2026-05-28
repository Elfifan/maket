
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/practical_task_model.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/test_model.dart';
import '../models/certificate_model.dart';


class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://xrpuolgthmgonondczfy.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_IhbTmOl7pBstD0BKxGWjxw_hA2YaqgO';

  late final SupabaseClient _client;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _client = Supabase.instance.client;
    _initialized = true;
    debugPrint('Supabase initialized');
  }

Future<bool> isUserEnrolled(int userId, int courseId) async {
    try {
      final response = await _client
          .from('user_courses')
          .select()
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking enrollment: $e');
      return false;
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
  }) async {
    try {
      // Check if email is already registered
      final existingUser = await _client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        debugPrint('Email already registered: $email');
        throw Exception('Email уже зарегистрирован');
      }

      final now = DateTime.now();

      final response = await _client
          .from('users')
          .insert({
            'email': email,
            'password': password,
            'date_registration': now.toIso8601String().split('T')[0],
            'status': true,
            'last_entry': now.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      debugPrint('Registration successful for: $email');
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Registration error for $email: $e');
      return null;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      debugPrint('Attempting login for: $email');

      final response = await _client
          .from('users')
          .select()
          .eq('email', email)
          .eq('status', true)
          .maybeSingle();

      if (response == null) {
        debugPrint('User not found: $email');
        return null;
      }

      if (response['password'] != password) {
        debugPrint('Incorrect password for: $email');
        return null;
      }

      await _client
          .from('users')
          .update({
            'last_entry': DateTime.now().toIso8601String().split('T')[0],
          })
          .eq('id', response['id']);

      debugPrint('Login successful for: $email');
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Login error for $email: $e');
      return null;
    }
  }

  Future<UserModel?> getUserById(int userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('User not found by id: $userId');
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user by id $userId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('date_registration', ascending: false);

      debugPrint('Total users in database: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  Future<List<CourseModel>> getCourses({String? search, String? category}) async {
  try {
    var query = _client
        .from('courses')
        .select()
        .eq('status', 'Активный'); 

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query;

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CourseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      return [];
    }
  }

  /// Список курсов, приобретённых пользователем.
  Future<List<CourseModel>> getUserCourses({
    required int userId,
  }) async {
    try {
      final resp = await _client
          .from('user_courses')
          .select('id_courses')
          .eq('id_user', userId);
      final ids = List<Map<String, dynamic>>.from(resp)
          .map((e) => e['id_courses'])
          .toList();
      if (ids.isEmpty) return [];
      final coursesResp = await _client
          .from('courses')
          .select(
            'id,id_employee,name,description,icon,date_create,price,complexity,status,category',
          )
          .inFilter('id', ids.toSet().toList())
          .eq('status', 'Активный');
      final list = List<Map<String, dynamic>>.from(coursesResp as List);
      return list.map((j) => CourseModel.fromJson(j)).toList();
    } catch (e, st) {
      debugPrint('[SupabaseService] error getting user courses: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getModulesWithSubmodules(int courseId) async {
    try {
      debugPrint('Querying modules for course $courseId');
      // Запрашиваем модули и сразу все связанные подмодули
      final response = await _client
          .from('module')
          .select('''
            *,
            submodule (*)
          ''''')
          .eq('id_courses', courseId)
          .order('order_module', ascending: true);

      debugPrint('Modules query result: ${response.length} items');
      for (var module in response) {
        debugPrint('Module: ${module['name']}, submodules: ${(module['submodule'] as List?)?.length ?? 0}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching modules and submodules: $e');
      return [];
    }
  }

  Future<List<TestModel>> getTestsBySubmodule(int submoduleId) async {
    try {
      final joinResponse = await _client
          .from('submodule_test')
          .select('test(*)')
          .eq('id_submodule', submoduleId)
          .order('order_test', ascending: true);

      final rows = List<Map<String, dynamic>>.from(joinResponse);
      final tests = <TestModel>[];
      for (final row in rows) {
        final testData = row['test'];
        if (testData is Map<String, dynamic>) {
          tests.add(TestModel.fromJson(testData));
        }
      }
      return tests;
    } catch (e) {
      debugPrint('Join test query failed: $e');
      return [];
    }
  }


  Future<bool> hasPurchasedCourse({
    required int userId,
    required int courseId,
  }) async {
    try {
      final existing = await _client
          .from('user_courses')
          .select('id')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      debugPrint('[SupabaseService] error checking purchase: $e');
      return false;
    }
  }

  /// Выдать достижение пользователю
  Future<void> awardAchievement(int userId, int achievementId) async {
    await initialize();
    try {
      // Проверяем, есть ли уже такое достижение у пользователя
      final existing = await _client
          .from('achievements_user')
          .select('id')
          .eq('id_user', userId)
          .eq('id_achievements', achievementId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('achievements_user').insert({
          'id_user': userId,
          'id_achievements': achievementId,
        });
        debugPrint('Achievement $achievementId awarded to user $userId');
      }
    } catch (e) {
      debugPrint('Error awarding achievement: $e');
    }
  }

  Future<bool> purchaseCourse(int userId, CourseModel course, String userEmail) async {
    try {
      // Проверяем, первая ли это покупка
      final existingPurchases = await _client
          .from('user_courses')
          .select('id')
          .eq('id_user', userId)
          .limit(1);
      
      final isFirstPurchase = (existingPurchases as List).isEmpty;

      await _client.from('user_courses').insert({
        'id_user': userId,
        'id_courses': course.id,
        'purchase_price': course.price ?? 0.0, 
        'purchase_date': DateTime.now().toIso8601String(),
      });
      
      // Если покупка первая и платная, выдаем достижение ID 8
      if (isFirstPurchase && (course.price ?? 0) > 0) {
        await awardAchievement(userId, 8);
      }

      await sendEmailReceipt(
        toEmail: userEmail,
        courseName: course.name,
        amount: course.price ?? 0.0,
      );
      return true;
    } catch (e) {
      debugPrint('Ошибка при записи в БД: $e');
      return false;
    }
  }

  Future<T?> _withRetry<T>(Future<T?> Function() action, String label) async {
    int attempts = 0;
    const int maxAttempts = 3;
    const Duration timeout = Duration(seconds: 1);

    while (attempts < maxAttempts) {
      try {
        attempts++;
        return await action().timeout(timeout);
      } catch (e) {
        debugPrint('[$label] Попытка $attempts не удалась: $e');
        if (attempts >= maxAttempts) return null;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    return null;
  }

  Future<List<AchievementModel>> getUserAchievements(int userId) async {
    final data = await _withRetry(() async {
      return await _client
          .from('achievements_user')
          .select('achievement (*)')
          .eq('id_user', userId);
    }, 'Fetch Achievements');

    if (data == null) return [];

    final List<dynamic> listData = data as List<dynamic>;
    return listData
        .where((item) => item['achievement'] != null)
        .map((item) => AchievementModel.fromJson(item['achievement']))
        .toList();
  }

  /// Обновить имя пользователя
  Future<bool> updateUserName(int userId, String newName) async {
    try {
      await _client
          .from('users')
          .update({'name': newName})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating user name: $e');
      return false;
    }
  }

  /// Загрузить аватар в Storage
  Future<String?> uploadAvatar(int userId, Uint8List imageBytes, String extension) async {
    try {
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // Определяем корректный Content-Type
      final String contentType = (extension.toLowerCase() == 'png') ? 'image/png' : 'image/jpeg';
      
      await _client.storage
          .from('avatars')
          .uploadBinary(fileName, imageBytes,
              fileOptions: FileOptions(contentType: contentType, upsert: true));

      final url = _client.storage.from('avatars').getPublicUrl(fileName);
      debugPrint('File uploaded to storage: $url');
      return url;
    } catch (e) {
      debugPrint('Error uploading avatar to storage: $e');
      rethrow;
    }
  }

  /// Сохранить URL аватара в профиле
  Future<bool> updateUserAvatar(int userId, String avatarUrl) async {
    try {
      final response = await _client
          .from('users')
          .update({'avatar': avatarUrl})
          .eq('id', userId)
          .select();
          
      if (response.isNotEmpty) {
        debugPrint('Avatar URL saved to DB successfully');
        return true;
      }
      debugPrint('Update failed: No data returned from DB');
      return false;
    } catch (e) {
      debugPrint('Error updating avatar in DB: $e');
      return false;
    }
  }

  Future<List<CertificateModel>> getUserCertificates(int userId) async {
    final data = await _withRetry(() async {
      return await _client
          .from('certificates')
          .select('*, courses(name)')
          .eq('id_user', userId);
    }, 'Fetch Certificates');

    if (data == null) return [];

    final List<dynamic> listData = data as List<dynamic>;
    return listData.map((item) => CertificateModel.fromJson(item)).toList();
  }

  Future<bool> sendEmailReceipt({
    required String toEmail,
    required String courseName,
    required double amount,
  }) async {
    try {

      const username = 'vergunovcyril@yandex.ru';
      const password = 'yatdkhfbiiodwnfj'; 

      final smtpServer = SmtpServer(
        'smtp.yandex.ru',
        port: 465,
        username: username,
        password: password,
        ssl: true,
      );

      // Формирование данных чека
      final date = DateTime.now();
      final dateString = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final orderId = 'TXN-${date.millisecondsSinceEpoch.toString().substring(5)}';

      // Стилистика приложения
      const primaryPurple = '#A58EFF';
      const accentPink = '#F2C9D4';
      const textDark = '#1E1E2E';
      const textGrey = '#9094A6';
      const bgGrey = '#F8F9FB';

      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: $bgGrey; padding: 20px; margin: 0; -webkit-font-smoothing: antialiased;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 32px; overflow: hidden; box-shadow: 0 10px 25px rgba(165,142,255,0.1);">
          
          <div style="background: linear-gradient(135deg, $primaryPurple 0%, $accentPink 100%); padding: 50px 20px; text-align: center;">
            <div style="background-color: rgba(255,255,255,0.2); width: 60px; height: 60px; border-radius: 20px; margin: 0 auto 20px auto; line-height: 60px; display: inline-block;">
               <span style="font-size: 30px;">🎓</span>
            </div>
            <h1 style="margin: 20px 0 0 0; color: #ffffff; font-size: 26px; font-weight: bold;">Покупка успешна!</h1>
            <p style="margin: 10px 0 0 0; color: #ffffff; font-size: 16px; opacity: 0.9;">Ваш путь в обучении начинается здесь</p>
          </div>

          <div style="padding: 40px;">
            <p style="font-size: 16px; color: $textDark; line-height: 1.6; margin-bottom: 30px;">
              Здравствуйте! Ваша оплата курса <strong>«$courseName»</strong> прошла успешно. Мы уже подготовили все материалы в вашем личном кабинете.
            </p>

            <div style="background-color: $bgGrey; border-radius: 24px; padding: 25px; margin-bottom: 30px;">
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="padding: 8px 0; color: $textGrey; font-size: 13px; text-transform: uppercase; letter-spacing: 1px;">Заказ</td>
                  <td style="padding: 8px 0; text-align: right; color: $textDark; font-weight: bold; font-size: 14px;">$orderId</td>
                </tr>
                <tr>
                  <td style="padding: 8px 0; color: $textGrey; font-size: 13px; text-transform: uppercase; letter-spacing: 1px;">Дата</td>
                  <td style="padding: 8px 0; text-align: right; color: $textDark; font-weight: bold; font-size: 14px;">$dateString</td>
                </tr>
                <tr>
                  <td colspan="2" style="padding: 15px 0 10px 0; border-top: 1px solid #E0E0E0; margin-top: 10px;">
                    <span style="color: $textGrey; font-size: 13px; text-transform: uppercase; letter-spacing: 1px;">К оплате</span>
                  </td>
                </tr>
                <tr>
                  <td colspan="2" style="color: $primaryPurple; font-size: 32px; font-weight: 800;">
                    ${amount.toStringAsFixed(0)} <span style="font-size: 20px;">₽</span>
                  </td>
                </tr>
              </table>
            </div>

            <div style="text-align: center;">
              <a href="https://your-app-link.com" style="display: inline-block; padding: 18px 40px; background: linear-gradient(135deg, $primaryPurple 0%, $accentPink 100%); color: #ffffff; text-decoration: none; border-radius: 16px; font-weight: bold; font-size: 16px;">
                Начать обучение
              </a>
            </div>
          </div>

          <div style="background-color: #ffffff; padding: 30px; text-align: center; border-top: 1px solid $bgGrey;">
            <p style="margin: 0; color: $textGrey; font-size: 13px;">
              Есть вопросы? Пишите на <a href="mailto:support@yourservice.com" style="color: $primaryPurple; text-decoration: none; font-weight: bold;">support@yourservice.com</a>
            </p>
            <p style="margin: 12px 0 0 0; color: $textGrey; font-size: 11px; text-transform: uppercase; letter-spacing: 1px;">
              © ${date.year} Учебный сервис. Все права защищены.
            </p>
          </div>
        </div>
      </body>
      </html>
      ''';

      final message = Message()
        ..from = Address(username, 'Учебный сервис')
        ..recipients.add(toEmail)
        ..subject = '🧾 Чек по заказу: $courseName'
        ..html = htmlContent;

      debugPrint('[Email] Отправка стилизованного письма на: $toEmail');
      
      // Используем await для реальной отправки
      await send(message, smtpServer).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout при отправке почты'),
      );
      
      debugPrint('[Email] ✅ Письмо успешно доставлено');
      return true;
    } catch (e) {
      debugPrint('[Email] ❌ Ошибка: $e');
      return false;
    }
  }

  // Сохранение прогресса подмодуля
  Future<void> saveSubmoduleProgress(int userId, int submoduleId) async {
    try {
      // Проверяем, существует ли уже запись
      final existing = await _client
          .from('user_submodule_progress')
          .select('id')
          .eq('id_user', userId)
          .eq('id_submodule', submoduleId)
          .maybeSingle();

      if (existing == null) {
        // Создаем новую запись
        await _client.from('user_submodule_progress').insert({
          'id_user': userId,
          'id_submodule': submoduleId,
          'is_completed': true,
          'completed_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Submodule progress saved: user $userId, submodule $submoduleId');
      } else {
        // Обновляем существующую
        await _client
            .from('user_submodule_progress')
            .update({
              'is_completed': true,
              'completed_at': DateTime.now().toIso8601String(),
            })
            .eq('id_user', userId)
            .eq('id_submodule', submoduleId);
        debugPrint('Submodule progress updated: user $userId, submodule $submoduleId');
      }
    } catch (e) {
      debugPrint('Error saving submodule progress: $e');
    }
  }

  // Сохранение результатов теста
  Future<void> saveTestResult(int userId, int submoduleId, int numberTests, int numberCorrectAnswers, bool isCorrect) async {
    try {
      await _client.from('student_test_result').insert({
        'id_user': userId,
        'id_submodule': submoduleId,
        'number_tests': numberTests,
        'number_correct_answers': numberCorrectAnswers,
        'is_correct': isCorrect,
        'date_completed': DateTime.now().toIso8601String(),
      });
      debugPrint('Test result saved: user $userId, submodule $submoduleId, correct $numberCorrectAnswers/$numberTests');
    } catch (e) {
      debugPrint('Error saving test result: $e');
    }
  }

  // Получение прогресса подмодулей для пользователя
  Future<Set<int>> getCompletedSubmodules(int userId) async {
    try {
      final response = await _client
          .from('user_submodule_progress')
          .select('id_submodule')
          .eq('id_user', userId)
          .eq('is_completed', true);

      final completedIds = List<Map<String, dynamic>>.from(response)
          .map((row) => row['id_submodule'] as int)
          .toSet();

      debugPrint('Completed submodules for user $userId: $completedIds');
      return completedIds;
    } catch (e) {
      debugPrint('Error fetching completed submodules: $e');
      return {};
    }
  }

  // Получение пройденных тестов для подмодулей
  Future<Set<int>> getCompletedTestSubmodules(int userId) async {
    try {
      final response = await _client
          .from('student_test_result')
          .select('id_submodule')
          .eq('id_user', userId);

      final completedIds = List<Map<String, dynamic>>.from(response)
          .map((row) => row['id_submodule'] as int)
          .toSet();

      debugPrint('Completed test submodules for user $userId: $completedIds');
      return completedIds;
    } catch (e) {
      debugPrint('Error fetching completed test submodules: $e');
      return {};
    }
  }

  // Добавьте в класс SupabaseService:

/// Получить практические задания для подмодуля
Future<List<PracticalTaskModel>> getPracticalTasks(int submoduleId) async {
  try {
    final response = await _client
        .from('practical_task')
        .select('*')
        .eq('id_submodule', submoduleId)
        .eq('status', true)
        .order('order_task', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => PracticalTaskModel.fromJson(json))
        .toList();
  } catch (e) {
    debugPrint('Error getting practical tasks: $e');
    return [];
    }
  }

/// Сохранить результат практического задания
Future<void> savePracticalTaskResult(
  int userId,
  int taskId,
  int submoduleId,
  String submission,
) async {
  try {
    // Проверяем, существует ли уже запись
    final existing = await _client
        .from('student_practical_result')
        .select('id')
        .eq('id_user', userId)
        .eq('id_task', taskId)
        .maybeSingle();

    if (existing != null) {
      // Обновляем
      await _client
          .from('student_practical_result')
          .update({
            'submission': submission,
            'status': 'completed',
            'score': 100,
            'date_submitted': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
    } else {
      // Создаем новую
      await _client
          .from('student_practical_result')
          .insert({
            'id_user': userId,
            'id_task': taskId,
            'id_submodule': submoduleId,
            'submission': submission,
            'status': 'completed',
            'score': 100,
            'date_submitted': DateTime.now().toIso8601String(),
          });
    }
    } catch (e) {
      debugPrint('Error saving practical task result: $e');
    }
  }

/// Получить завершенные практические задания (возвращает набор id_submodule)
Future<Set<int>> getCompletedPracticalTasks(int userId) async {
  try {
    final response = await _client
        .from('student_practical_result')
        .select('id_submodule')
        .eq('id_user', userId)
        .eq('status', 'completed');

    return List<Map<String, dynamic>>.from(response)
        .map((row) => row['id_submodule'] as int)
        .toSet();
    } catch (e) {
      debugPrint('Error getting completed practical tasks: $e');
      return {};
    }
  }

  // ================= STREAMS (Real-time) =================

  Stream<List<CourseModel>> streamCourses({String? search, String? category}) {
    // В Supabase Streams фильтрация `ilike` и т.д. не работает напрямую в .stream(),
    // поэтому мы слушаем всю таблицу, а потом вызываем обычный getCourses.
    return _client
        .from('courses')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getCourses(search: search, category: category));
  }

  Stream<List<CourseModel>> streamUserCourses({required int userId}) {
    return _client
        .from('user_courses')
        .stream(primaryKey: ['id'])
        .eq('id_user', userId)
        .asyncMap((_) => getUserCourses(userId: userId));
  }

  Future<bool> isCourseFavourite(int userId, int courseId) async {
    try {
      final response = await _client
          .from('user_courses')
          .select('favourites')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();
      if (response == null) return false;
      return response['favourites'] == true;
    } catch (e) {
      debugPrint('Error checking favourite status: $e');
      return false;
    }
  }

  Future<bool> toggleFavourite(int userId, int courseId, bool makeFavourite, {double purchasePrice = 0.0}) async {
    try {
      final existing = await _client
          .from('user_courses')
          .select('id')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('user_courses')
            .update({'favourites': makeFavourite})
            .eq('id_user', userId)
            .eq('id_courses', courseId);
      } else {
        await _client.from('user_courses').insert({
          'id_user': userId,
          'id_courses': courseId,
          'purchase_price': purchasePrice,
          'favourites': makeFavourite,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling favourite: $e');
      return false;
    }
  }

  Future<List<CourseModel>> getUserFavouriteCourses({
    required int userId,
  }) async {
    try {
      final resp = await _client
          .from('user_courses')
          .select('id_courses')
          .eq('id_user', userId)
          .eq('favourites', true);
      final ids = List<Map<String, dynamic>>.from(resp)
          .map((e) => e['id_courses'])
          .toList();
      if (ids.isEmpty) return [];
      final coursesResp = await _client
          .from('courses')
          .select(
            'id,id_employee,name,description,icon,date_create,price,complexity,status,category',
          )
          .inFilter('id', ids.toSet().toList())
          .eq('status', 'Активный');
      final list = List<Map<String, dynamic>>.from(coursesResp as List);
      return list.map((j) => CourseModel.fromJson(j)).toList();
    } catch (e, st) {
      debugPrint('[SupabaseService] error getting user favourite courses: $e');
      return [];
    }
  }

  Stream<List<CourseModel>> streamUserFavouriteCourses({required int userId}) {
    return _client
        .from('user_courses')
        .stream(primaryKey: ['id'])
        .eq('id_user', userId)
        .asyncMap((_) => getUserFavouriteCourses(userId: userId));
  }

  Stream<List<AchievementModel>> streamUserAchievements(int userId) {
    return _client
        .from('achievements_user')
        .stream(primaryKey: ['id'])
        .eq('id_user', userId)
        .asyncMap((_) => getUserAchievements(userId));
  }

  Stream<List<CertificateModel>> streamUserCertificates(int userId) {
    return _client
        .from('certificates')
        .stream(primaryKey: ['id'])
        .eq('id_user', userId)
        .asyncMap((_) => getUserCertificates(userId));
  }

  Future<List<CourseModel>> getUserCompletedCourses({required int userId}) async {
    try {
      final certificatesResp = await _client
          .from('certificates')
          .select('id_courses, issue_date')
          .eq('id_user', userId);
      
      final certsList = List<Map<String, dynamic>>.from(certificatesResp);
      if (certsList.isEmpty) return [];
      
      final courseIds = certsList.map((c) => c['id_courses'] as int).toList();
      
      final enrollResp = await _client
          .from('user_courses')
          .select('id_courses, purchase_date')
          .eq('id_user', userId)
          .inFilter('id_courses', courseIds);
          
      final enrollList = List<Map<String, dynamic>>.from(enrollResp);
      
      final coursesResp = await _client
          .from('courses')
          .select('id,id_employee,name,description,icon,date_create,price,complexity,status,category')
          .inFilter('id', courseIds)
          .eq('status', 'Активный');
          
      final list = List<Map<String, dynamic>>.from(coursesResp as List);
      
      return list.map((json) {
        final courseId = json['id'] as int;
        
        final cert = certsList.firstWhere((c) => c['id_courses'] == courseId, orElse: () => {});
        final issueDateStr = cert['issue_date'];
        final DateTime? completedDate = issueDateStr != null ? DateTime.tryParse(issueDateStr.toString()) : null;
        
        final enroll = enrollList.firstWhere((e) => e['id_courses'] == courseId, orElse: () => {});
        final purchaseDateStr = enroll['purchase_date'];
        final DateTime? startDate = purchaseDateStr != null ? DateTime.tryParse(purchaseDateStr.toString()) : null;
        
        final course = CourseModel.fromJson(json);
        course.startDate = startDate;
        course.completedDate = completedDate;
        return course;
      }).toList();
    } catch (e) {
      debugPrint('Error getting completed courses: $e');
      return [];
    }
  }

  Stream<List<CourseModel>> streamUserCompletedCourses({required int userId}) {
    return _client
        .from('certificates')
        .stream(primaryKey: ['id'])
        .eq('id_user', userId)
        .asyncMap((_) => getUserCompletedCourses(userId: userId));
  }

  SupabaseClient get client {
    return _client;
  }
}

