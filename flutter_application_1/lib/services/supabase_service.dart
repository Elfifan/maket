
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
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
    print('Supabase initialized');
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
      print('Error checking enrollment: $e');
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
        print('Email already registered: $email');
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

      print('Registration successful for: $email');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Registration error for $email: $e');
      return null;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      print('Attempting login for: $email');

      final response = await _client
          .from('users')
          .select()
          .eq('email', email)
          .eq('status', true)
          .maybeSingle();

      if (response == null) {
        print('User not found: $email');
        return null;
      }

      if (response['password'] != password) {
        print('Incorrect password for: $email');
        return null;
      }

      await _client
          .from('users')
          .update({
            'last_entry': DateTime.now().toIso8601String().split('T')[0],
          })
          .eq('id', response['id']);

      print('Login successful for: $email');
      return UserModel.fromJson(response);
    } catch (e) {
      print('Login error for $email: $e');
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
        print('User not found by id: $userId');
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error fetching user by id $userId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select()
          .order('date_registration', ascending: false);

      print('Total users in database: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }


Future<List<CourseModel>> getCourses({String? search, String? category}) async {
  try {

    var query = _client.from('courses').select();

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
    print('Error fetching courses: $e');
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
            'id,id_employee,name,description,date_create,price,complexity,status',
          )
          .filter('id', 'in', '(${ids.join(',')})');
      final list = List<Map<String, dynamic>>.from(coursesResp as List);
      return list.map((j) => CourseModel.fromJson(j)).toList();
    } catch (e, st) {
      print('[SupabaseService] error getting user courses: $e');
      print(st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getModulesWithSubmodules(int courseId) async {
    try {
      print('Querying modules for course $courseId');
      // Запрашиваем модули и сразу все связанные подмодули
      final response = await _client
          .from('module')
          .select('''
            *,
            submodule (*)
          ''')
          .eq('id_courses', courseId)
          .order('order_module', ascending: true);

      print('Modules query result: ${response.length} items');
      for (var module in response) {
        print('Module: ${module['name']}, submodules: ${(module['submodule'] as List?)?.length ?? 0}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching modules and submodules: $e');
      return [];
    }
  }

  Future<List<TestModel>> getTestsBySubmodule(int submoduleId) async {
    try {
      final response = await _client
          .from('test')
          .select()
          .eq('id_submodule', submoduleId)
          .order('id', ascending: true);

      final tests = List<Map<String, dynamic>>.from(response)
          .map((json) => TestModel.fromJson(json))
          .toList();

      if (tests.isNotEmpty) {
        return tests;
      } 
    } catch (e) {
      print('Direct test query failed: $e');
    }

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
      print('Join test query failed: $e');
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
      print('[SupabaseService] error checking purchase: $e');
      return false;
    }
  }

Future<bool> purchaseCourse(int userId, CourseModel course, String userEmail) async {
  try {
    await _client.from('user_courses').insert({
      'id_user': userId,
      'id_courses': course.id,
      'purchase_price': course.price ?? 0.0, 
      'purchase_date': DateTime.now().toIso8601String(),
    });
    
    await sendEmailReceipt(
      toEmail: userEmail,
      courseName: course.name,
      amount: course.price ?? 0.0,
    );
    return true;
  } catch (e) {
    print('Ошибка при записи в БД: $e');
    return false;
  }
}


Future<List<AchievementModel>> getUserAchievements(int userId) async {
  try {

    final response = await _client
        .from('achievements_user')
        .select('achievement (*)')
        .eq('id_user', userId);

    final List<dynamic> data = response as List<dynamic>;
    
    return data
        .where((item) => item['achievement'] != null)
        .map((item) => AchievementModel.fromJson(item['achievement']))
        .toList();
  } catch (e) {
    print('Error fetching user achievements: $e');
    return [];
  }
}

Future<List<CertificateModel>> getUserCertificates(int userId) async {
  try {
    final response = await _client
        .from('certificates')
        .select('*, courses(name)')
        .eq('id_user', userId);

    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) => CertificateModel.fromJson(item)).toList();
  } catch (e) {
    print('Error fetching user certificates: $e');
    return [];
  }
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

      print('[Email] Отправка стилизованного письма на: $toEmail');
      
      // Используем await для реальной отправки
      await send(message, smtpServer).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout при отправке почты'),
      );
      
      print('[Email] ✅ Письмо успешно доставлено');
      return true;
    } catch (e) {
      print('[Email] ❌ Ошибка: $e');
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
        print('Submodule progress saved: user $userId, submodule $submoduleId');
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
        print('Submodule progress updated: user $userId, submodule $submoduleId');
      }
    } catch (e) {
      print('Error saving submodule progress: $e');
      throw e;
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
      print('Test result saved: user $userId, submodule $submoduleId, correct $numberCorrectAnswers/$numberTests');
    } catch (e) {
      print('Error saving test result: $e');
      throw e;
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

      print('Completed submodules for user $userId: $completedIds');
      return completedIds;
    } catch (e) {
      print('Error fetching completed submodules: $e');
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

      print('Completed test submodules for user $userId: $completedIds');
      return completedIds;
    } catch (e) {
      print('Error fetching completed test submodules: $e');
      return {};
    }
  }
}