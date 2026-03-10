import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ЗАМЕНИТЕ ЭТИ КОНСТАНТЫ НА ВАШИ РЕАЛЬНЫЕ КЛЮЧИ!
  static const String supabaseUrl = 'https://xrpuolgthmgonondczfy.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_IhbTmOl7pBstD0BKxGWjxw_hA2YaqgO';

  late final SupabaseClient _client;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      // уже инициализирован
      return;
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    _initialized = true;
    print('Supabase initialized');
  }

  // Упрощенная регистрация без имени и аватара
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

  // Авторизация
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

      // Обновляем дату последнего входа
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

  // Получение всех пользователей (для тестирования)
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

  // Получение списка курсов из таблицы "courses".
  // Можно указать необязательные параметры для поиска по имени и фильтра.
  Future<List<CourseModel>> getCourses({
    String? search,
    String? filterCategory,
  }) async {
    try {
      // Построим запрос: сначала фильтры (ilike), затем сортировку (order).
      // explicitly list columns (exclude icon) to avoid transporting it
      var query = _client.from('courses').select('id,id_employee,name,description,date_create,price,complexity,status');

      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      if (filterCategory != null &&
          filterCategory.isNotEmpty &&
          filterCategory != 'Все') {
        // Используем перечисленные нами категории как подстроку
        query = query.ilike('name', '%$filterCategory%');
      }

      // Применяем сортировку последней (order возвращает PostgrestTransformBuilder)
      final response = await query.order('date_create', ascending: false);
      // debug info
      print('[SupabaseService] raw response type: ${response.runtimeType}');
      print('[SupabaseService] raw response content: $response');

      if (response == null) {
        print('[SupabaseService] warning: response is null');
        return [];
      }

      if (response is List) {
        final list = List<Map<String, dynamic>>.from(response);
        print('Loaded ${list.length} courses (search=$search, filter=$filterCategory)');
        return list.map((j) => CourseModel.fromJson(j)).toList();
      } else {
        // Если сервер вернул ошибку или не список
        print('[SupabaseService] unexpected response shape: ${response.runtimeType}');
        return [];
      }
    } catch (e, st) {
      print('Error getting courses: $e');
      print(st);
      return [];
    }
  }

  // Получение списка модулей для курса по id_courses
  Future<List<ModuleModel>> getModules(int courseId) async {
    try {
      final response = await _client
          .from('module')
          .select('id,id_courses,name,order_module,status')
          .eq('id_courses', courseId)
          .order('order_module', ascending: true);

      if (response == null) {
        print('[SupabaseService] warning: response is null for modules');
        return [];
      }

      if (response is List) {
        final list = List<Map<String, dynamic>>.from(response);
        print('Loaded ${list.length} modules for course $courseId');
        return list.map((j) => ModuleModel.fromJson(j)).toList();
      } else {
        print('[SupabaseService] unexpected response shape for modules: ${response.runtimeType}');
        return [];
      }
    } catch (e, st) {
      print('Error getting modules for course $courseId: $e');
      print(st);
      return [];
    }
  }
}