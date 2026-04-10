import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/test_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/certificate_service.dart';
import '../services/supabase_service.dart';
import 'submodule_content_screen.dart';
import 'tests_screen.dart';

class CourseProfileScreen extends StatefulWidget {
  final CourseModel course;

  const CourseProfileScreen({super.key, required this.course});

  @override
  State<CourseProfileScreen> createState() => _CourseProfileScreenState();
}

class _CourseProfileScreenState extends State<CourseProfileScreen> {
  List<Map<String, dynamic>> _courseStructure = [];
  Map<int, List<TestModel>> _submoduleTests = {};
  Set<int> _completedSubmodules = {};
  Set<int> _completedTestSubmodules = {};
  bool _loading = false;
  bool _isPurchasing = false;
  bool _isEnrolled = false;
  bool _hasCertificate = false;

  // Константы дизайна
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);

  @override
  void initState() {
    super.initState();
    _loadModules();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    final enrolled = await SupabaseService().isUserEnrolled(
      authProvider.currentUser!.id!,
      widget.course.id,
    );
    if (mounted) setState(() => _isEnrolled = enrolled);
  }

  Future<void> _checkAndGenerateCertificate(UserModel user) async {
    // Проверяем, есть ли уже сертификат и сразу возвращаем существующий
    final existingCertificate = await CertificateService().getCertificate(user.id!, widget.course.id);
    if (existingCertificate != null) {
      if (mounted) setState(() => _hasCertificate = true);
      return;
    }

    // Получаем все подмодули курса
    final allSubmodules = <int>{};
    final submodulesWithTests = <int>{};

    for (final module in _courseStructure) {
      final submodules = module['submodule'] as List<dynamic>? ?? [];
      for (final sub in submodules) {
        if (sub is Map<String, dynamic>) {
          final submoduleId = sub['id'] as int?;
          if (submoduleId != null) {
            allSubmodules.add(submoduleId);
            // Проверяем, есть ли тесты для этого подмодуля
            if (_submoduleTests.containsKey(submoduleId) && _submoduleTests[submoduleId]!.isNotEmpty) {
              submodulesWithTests.add(submoduleId);
            }
          }
        }
      }
    }

    // Проверяем, что все подмодули завершены
    final allSubmodulesCompleted = allSubmodules.every((id) => _completedSubmodules.contains(id));

    // Проверяем, что все тесты пройдены
    final allTestsCompleted = submodulesWithTests.every((id) => _completedTestSubmodules.contains(id));

    if (allSubmodulesCompleted && allTestsCompleted) {
      // Генерируем сертификат
      final certificate = await CertificateService().generateAndUploadCertificate(
        user: user,
        course: widget.course,
      );

      if (certificate != null && mounted) {
        setState(() => _hasCertificate = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поздравляем! Сертификат о завершении курса выдан.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _loadModules() async {
    if (mounted) setState(() => _loading = true);
    try {
      print('Loading modules for course ${widget.course.id}');
      final data = await SupabaseService().getModulesWithSubmodules(widget.course.id);
      print('Loaded ${data.length} modules');
      if (mounted) {
        setState(() {
          _courseStructure = data;
        });
      }

      // Загружаем тесты для каждого подмодуля
      final Map<int, List<TestModel>> testsMap = {};
      for (final module in _courseStructure) {
        final submodules = module['submodule'] as List<dynamic>? ?? [];
        print('Module ${module['name']} has ${submodules.length} submodules');
        for (final sub in submodules) {
          if (sub is Map<String, dynamic>) {
            final submoduleId = sub['id'] as int?;
            if (submoduleId != null) {
              try {
                final tests = await SupabaseService().getTestsBySubmodule(submoduleId);
                if (tests.isNotEmpty) {
                  testsMap[submoduleId] = tests;
                  print('Loaded ${tests.length} tests for submodule $submoduleId');
                }
              } catch (e) {
                print('Error loading tests for submodule $submoduleId: $e');
                // Игнорируем ошибки загрузки тестов для отдельных подмодулей
              }
            }
          }
        }
      }

      // Загружаем прогресс пользователя
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final completedSubmodules = await SupabaseService().getCompletedSubmodules(authProvider.currentUser!.id!);
        final completedTestSubmodules = await SupabaseService().getCompletedTestSubmodules(authProvider.currentUser!.id!);
        
        if (mounted) {
          setState(() {
            _completedSubmodules = completedSubmodules;
            _completedTestSubmodules = completedTestSubmodules;
          });
        }
      }

      if (mounted) {
        setState(() {
          _submoduleTests = testsMap;
          _loading = false;
        });
      }

      // Проверяем наличие сертификата и генерируем если нужно
      final authProvider2 = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider2.currentUser != null) {
        final hasCertificate = await CertificateService().hasCertificate(authProvider2.currentUser!.id!, widget.course.id);
        if (mounted) setState(() => _hasCertificate = hasCertificate);

        // Проверяем и генерируем сертификат после загрузки всего
        await _checkAndGenerateCertificate(authProvider2.currentUser!);
      }

      print('Modules loading completed');
    } catch (e) {
      print('Error in _loadModules: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Большой баннер курса
                _buildCourseBanner(),
                
                const SizedBox(height: 24),
                
                // 2. Описание курса
                if (widget.course.description != null && widget.course.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.course.description!,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // 3. Список модулей
                _loading 
                  ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
                  : _buildModulesList(),
              ],
            ),
          ),
          
          // 4. Кнопка действия снизу
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Детали курса',
        style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCourseBanner() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4DAFF), Color(0xFFF2C9D4)],
        ),
      ),
      child: Stack(
        children: [
          // Заглушка под картинку или реальное изображение
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Opacity(
                opacity: 0.8,
                child: Image.network(
                  'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500', 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_hasCertificate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Сертификат получен',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Сложность: ${widget.course.complexity ?? 1}',
                    style: const TextStyle(color: _primaryPurple, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.course.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesList() {
  print('_buildModulesList called, loading: $_loading, courseStructure length: ${_courseStructure.length}');
  if (_loading) return const Center(child: CircularProgressIndicator());
  if (_courseStructure.isEmpty) return const Text("Материалы курса скоро появятся");

  final allSubmodules = _flattenSubmodules();
  print('All submodules count: ${allSubmodules.length}');

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _courseStructure.length,
    itemBuilder: (context, index) {
      final module = _courseStructure[index];
      final List submodules = module['submodule'] ?? [];
      print('Building module ${module['name']} with ${submodules.length} submodules');

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFA58EFF).withValues(alpha: 0.1),
              child: Text("${module['order_module'] ?? index + 1}", 
                style: const TextStyle(color: Color(0xFFA58EFF), fontWeight: FontWeight.bold)),
            ),
            title: Text(
              module['name'] ?? 'Без названия',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text("${submodules.length} уроков", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            children: submodules.expand((sub) {
              final List<Widget> items = [];

              // Добавляем подмодуль
              final int? submoduleId = sub['id'] is int ? sub['id'] as int : int.tryParse(sub['id'].toString());
              final bool isSubmoduleCompleted = submoduleId != null && _completedSubmodules.contains(submoduleId);
              
              items.add(ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                leading: Icon(
                  isSubmoduleCompleted ? Icons.check_circle : Icons.play_circle_outline, 
                  color: isSubmoduleCompleted ? Colors.green : (_isEnrolled ? const Color(0xFFA58EFF) : Colors.grey), 
                  size: 20
                ),
                title: Text(
                  sub['name'] ?? 'Без названия',
                  style: TextStyle(
                    color: _isEnrolled ? _textDark : _textGrey, 
                  ),
                ),
                trailing: Icon(
                  _isEnrolled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline, 
                  size: 16, 
                  color: Colors.grey
                ), 
                onTap: () {
                  if (_isEnrolled) {
                    final String? contentUrl = sub['content'];
                    final int? submoduleId = sub['id'] is int ? sub['id'] as int : int.tryParse(sub['id'].toString());
                    
                    if (contentUrl != null && contentUrl.isNotEmpty && submoduleId != null) {
                      final allSubmodules = _flattenSubmodules();
                      final currentIndex = allSubmodules.indexWhere((item) => item['id'] == submoduleId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubmoduleContentScreen(
                            title: sub['name'] ?? 'Урок',
                            contentUrl: contentUrl,
                            submoduleId: submoduleId,
                            courseId: widget.course.id,
                            courseName: widget.course.name,
                            allSubmodules: allSubmodules,
                            currentIndex: currentIndex,
                            submoduleTests: _submoduleTests,
                          ),
                        ),
                      );
                    } else if (contentUrl != null && contentUrl.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не удалось определить ID подмодуля для тестов')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Контент для этого урока еще не загружен')),
                      );
                    }
                  } else {
                    // Сообщение, если пользователь пытается открыть закрытый курс
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сначала необходимо купить курс'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ));

              // Добавляем тесты для этого подмодуля, если они есть
              final tests = submoduleId != null ? _submoduleTests[submoduleId] : null;
              if (tests != null && tests.isNotEmpty) {
                final bool isTestCompleted = submoduleId != null && _completedTestSubmodules.contains(submoduleId);
                
                items.add(ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  leading: Icon(
                    isTestCompleted ? Icons.check_circle : Icons.quiz, 
                    color: isTestCompleted ? Colors.green : (_isEnrolled ? const Color(0xFFA58EFF) : Colors.grey), 
                    size: 20
                  ),
                  title: Text(
                    'Тесты (${tests.length})',
                    style: TextStyle(
                      color: _isEnrolled ? _textDark : _textGrey, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    _isEnrolled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline, 
                    size: 16, 
                    color: Colors.grey
                  ), 
                  onTap: () {
                    if (_isEnrolled) {
                      final currentIndex = allSubmodules.indexWhere((item) => item['id'] == submoduleId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestsScreen(
                            tests: tests,
                            submoduleName: sub['name'] ?? 'Подмодуль',
                            courseId: widget.course.id,
                            courseName: widget.course.name,
                            allSubmodules: allSubmodules,
                            currentIndex: currentIndex,
                            submoduleTests: _submoduleTests,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сначала необходимо купить курс'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ));
              }

              return items;
            }).toList(),
          ),
        ),
      );
    },
  );
}

  List<Map<String, dynamic>> _flattenSubmodules() {
    final List<Map<String, dynamic>> result = [];
    for (final module in _courseStructure) {
      final subs = module['submodule'] as List<dynamic>?;
      if (subs != null) {
        for (final item in subs) {
          if (item is Map) {
            final normalized = Map<String, dynamic>.from(item);
            // Нормализуем id к int
            if (normalized['id'] != null) {
              normalized['id'] = normalized['id'] is int ? normalized['id'] : int.tryParse(normalized['id'].toString());
            }
            result.add(normalized);
          }
        }
      }
    }
    return result;
  }

Widget _buildActionButton() {
  // 1. Если пользователь уже записан (есть запись в БД)
  if (_isEnrolled) {
    return _buttonTemplate(
      text: 'Продолжить обучение',
      onPressed: _continueLearning,
      isAccent: false,
    );
  }

  // 2. Если пользователь еще не купил курс
  return _buttonTemplate(
    text: _isPurchasing ? 'Оформление...' : 'Записаться за ${widget.course.price?.toInt() ?? 0} ₽',
    onPressed: _isPurchasing ? null : _handlePurchase,
    isAccent: true,
  );
}

// Вспомогательный метод для стилизации кнопок
Widget _buttonTemplate({
  required String text, 
  required VoidCallback? onPressed, 
  bool isAccent = true
}) {
  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      // Если курс куплен, можно сделать градиент чуть спокойнее (например, только фиолетовый)
      gradient: LinearGradient(
        colors: isAccent 
            ? [_primaryPurple, const Color(0xFFF2C9D4)] 
            : [_primaryPurple, _primaryPurple.withValues(alpha: 0.8)],
      ),
      boxShadow: [
        BoxShadow(
          color: _primaryPurple.withValues(alpha: 0.3), 
          blurRadius: 12, 
          offset: const Offset(0, 4)
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Colors.white 
        ),
      ),
    ),
  );
}

  Future<void> _handlePurchase() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isPurchasing = true);
    
    final success = await SupabaseService().purchaseCourse(
      authProvider.currentUser!.id!,
      widget.course,
      authProvider.currentUser!.email!,
    );

    if (mounted) {
      setState(() {
        _isPurchasing = false;
        if (success) _isEnrolled = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Вы успешно записаны!' : 'Ошибка при покупке')),
      );
    }
  }

  void _continueLearning() {
    final allSubmodules = _flattenSubmodules();
    
    for (final submodule in allSubmodules) {
      final submoduleId = submodule['id'] as int?;
      if (submoduleId == null) continue;
      
      // Проверяем, пройден ли подмодуль
      if (!_completedSubmodules.contains(submoduleId)) {
        // Подмодуль не пройден - открываем его
        final contentUrl = submodule['content'] as String?;
        if (contentUrl != null && contentUrl.isNotEmpty) {
          final currentIndex = allSubmodules.indexOf(submodule);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmoduleContentScreen(
                title: submodule['name'] ?? 'Урок',
                contentUrl: contentUrl,
                submoduleId: submoduleId,
                courseId: widget.course.id,
                courseName: widget.course.name,
                allSubmodules: allSubmodules,
                currentIndex: currentIndex,
                submoduleTests: _submoduleTests,
              ),
            ),
          );
          return;
        }
      }
      
      // Проверяем, пройдены ли тесты для этого подмодуля
      final tests = _submoduleTests[submoduleId];
      if (tests != null && tests.isNotEmpty && !_completedTestSubmodules.contains(submoduleId)) {
        // Тесты не пройдены - открываем их
        final currentIndex = allSubmodules.indexOf(submodule);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestsScreen(
              tests: tests,
              submoduleName: submodule['name'] ?? 'Подмодуль',
              courseId: widget.course.id,
              courseName: widget.course.name,
              allSubmodules: allSubmodules,
              currentIndex: currentIndex,
              submoduleTests: _submoduleTests,
            ),
          ),
        );
        return;
      }
    }
    
    // Все подмодули и тесты пройдены
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Поздравляем! Вы завершили курс!')),
    );
  }
}