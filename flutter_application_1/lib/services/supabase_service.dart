
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';

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

  Future<UserModel?> register({
    required String email,
    required String password,
  }) async {
    try {
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


  Future<List<CourseModel>> getCourses({
    String? search,
    String? filterCategory,
  }) async {
    try {

      var query = _client
          .from('courses')
          .select(
            'id,id_employee,name,description,date_create,price,complexity,status',
          );

      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      if (filterCategory != null &&
          filterCategory.isNotEmpty &&
          filterCategory != 'Все' &&
          filterCategory != 'Мои курсы') {
        query = query.ilike('name', '%$filterCategory%');
      }

      final response = await query.order('date_create', ascending: false);
      print('[SupabaseService] raw response type: ${response.runtimeType}');
      print('[SupabaseService] raw response content: $response');

      final list = List<Map<String, dynamic>>.from(response as List);
      print(
        'Loaded ${list.length} courses (search=$search, filter=$filterCategory)',
      );
      return list.map((j) => CourseModel.fromJson(j)).toList();
    } catch (e, st) {
      print('Error getting courses: $e');
      print(st);
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

  Future<List<ModuleModel>> getModules(int courseId) async {
    try {
      final response = await _client
          .from('module')
          .select('id,id_courses,name,order_module,status')
          .eq('id_courses', courseId)
          .order('order_module', ascending: true);

      final list = List<Map<String, dynamic>>.from(response);
      print('Loaded ${list.length} modules for course $courseId');
      return list.map((j) => ModuleModel.fromJson(j)).toList();
    } catch (e, st) {
      print('Error getting modules for course $courseId: $e');
      print(st);
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

  Future<bool> purchaseCourse({
    required int userId,
    required int courseId,
    required double amount,
    required String userEmail,
    required String courseName,
  }) async {
    try {
      await _client.from('transactions').insert({
        'id_user': userId,
        'id_courses': courseId,
        'amount': amount,
        'payment_status': 'completed',
      });

      final existing = await _client
          .from('user_courses')
          .select('id')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();

      if (existing == null) {
        await _client.from('user_courses').insert({
          'id_user': userId,
          'id_courses': courseId,
          'purchase_price': amount,
        });
      } else {
        print('[purchaseCourse] Пользователь $userId уже приобрёл курс $courseId, повторная запись пропущена');
      }


      try {
        await _client.rpc(
          'send_receipt',
          params: {'user_id': userId, 'course_id': courseId, 'amount': amount},
        );
      } catch (_) {
      }


      if (userEmail.trim().isEmpty || !userEmail.contains('@')) {
        print('[purchaseCourse] Адрес "$userEmail" некорректен, письмо не отправляется');
      } else {
        try {
          final sent = await _sendEmailReceipt(
            toEmail: userEmail,
            courseName: courseName,
            amount: amount,
          );
          if (!sent) {
            print('[purchaseCourse] _sendEmailReceipt сигнализировал об ошибке');
          }
        } catch (e) {
          print('[purchaseCourse] ошибка при отправке письма: $e');
        }
      }

      return true;
    } catch (e, st) {
      print('Error during purchase operation: $e');
      print(st);
      return false;
    }
  }

  Future<bool> _sendEmailReceipt({
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

      final date = DateTime.now();
      final dateString = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final orderId = 'TXN-${date.millisecondsSinceEpoch.toString().substring(5)}';

      final htmlContent = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #FFF0F5; padding: 20px; margin: 0;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
          
          <div style="background-color: #4561FF; padding: 40px 20px; text-align: center;">
            <h1 style="margin: 0; color: #ffffff; font-size: 28px;">Успешная покупка!</h1>
            <p style="margin: 10px 0 0 0; color: #D3DCFF; font-size: 16px;">Спасибо, что выбираете нас</p>
          </div>

          <div style="padding: 30px 40px;">
            <p style="font-size: 16px; color: #1E1E2E; margin-bottom: 24px;">
              Здравствуйте, <strong>$toEmail</strong>!<br><br>
              Ваша оплата успешно обработана. Доступ к курсу открыт в вашем личном кабинете. Ниже приведены детали транзакции.
            </p>

            <table style="width: 100%; border-collapse: collapse; margin-bottom: 30px;">
              <tr>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; color: #9094A6; font-size: 14px;">Номер заказа:</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; text-align: right; color: #1E1E2E; font-weight: 600; font-size: 14px;">$orderId</td>
              </tr>
              <tr>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; color: #9094A6; font-size: 14px;">Дата и время:</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; text-align: right; color: #1E1E2E; font-weight: 600; font-size: 14px;">$dateString</td>
              </tr>
              <tr>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; color: #9094A6; font-size: 14px;">Наименование:</td>
                <td style="padding: 12px 0; border-bottom: 1px solid #EEEEEE; text-align: right; color: #1E1E2E; font-weight: 600; font-size: 14px;">$courseName</td>
              </tr>
              <tr>
                <td style="padding: 24px 0 8px 0; color: #1E1E2E; font-size: 18px; font-weight: bold;">Итого:</td>
                <td style="padding: 24px 0 8px 0; text-align: right; color: #4561FF; font-size: 24px; font-weight: bold;">₽${amount.toStringAsFixed(2)}</td>
              </tr>
            </table>

            <div style="text-align: center;">
              <a href="#" style="display: inline-block; padding: 14px 32px; background-color: #4561FF; color: #ffffff; text-decoration: none; border-radius: 8px; font-weight: 600; font-size: 16px;">
                Перейти к обучению
              </a>
            </div>
          </div>

          <div style="background-color: #F8F9FA; padding: 20px; text-align: center; border-top: 1px solid #EEEEEE;">
            <p style="margin: 0; color: #9094A6; font-size: 12px;">
              Если у вас возникли вопросы, напишите нам на <a href="mailto:support@yourservice.com" style="color: #4561FF; text-decoration: none;">support@yourservice.com</a>
            </p>
            <p style="margin: 8px 0 0 0; color: #9094A6; font-size: 12px;">
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
        ..subject = '🧾 Ваш чек: покупка курса «$courseName»'
        ..html = htmlContent;

      print('[Email] Готовится отправка письма на: $toEmail');
      print('[Email] Попытка подключения к SMTP и отправки...');
      final sendReport = await send(message, smtpServer).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[Email] ❌ Timeout при отправке письма');
          throw Exception('Timeout при отправке письма');
        },
      );
      print('[Email] ✅ Письмо отправлено: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('[Email] ❌ ОШИБКА MailerException: $e');
      for (var p in e.problems) {
        print('[Email] Проблема: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e, st) {
      print('[Email] ❌ ОШИБКА при отправке письма: $e');
      print('[Email] Stacktrace: $st');
      return false;
    }
  }
}