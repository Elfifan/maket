import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/practical_task_model.dart';
import '../models/test_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/certificate_service.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'course_reviews_section.dart';
import 'submodule_content_screen.dart';
import 'tests_screen.dart';
import 'user_chat_screen.dart';
import 'practical_task_screen.dart';
import '../widgets/payment_dialog.dart';

class CourseProfileScreen extends StatefulWidget {
  final CourseModel course;
  static final ValueNotifier<bool> progressNotifier = ValueNotifier<bool>(false);

  const CourseProfileScreen({super.key, required this.course});

  @override
  State<CourseProfileScreen> createState() => _CourseProfileScreenState();
}

class _CourseProfileScreenState extends State<CourseProfileScreen> with RouteAware {
  List<Map<String, dynamic>> _courseStructure = [];
  Map<int, List<TestModel>> _submoduleTests = {};
  Map<int, List<PracticalTaskModel>> _practicalTasks = {};     
  Set<int> _completedPracticalTasks = {};                         
  Set<int> _completedSubmodules = {};
  Set<int> _completedTestSubmodules = {};
  bool _loading = false;
  bool _isPurchasing = false;
  bool _isEnrolled = false;
  bool _hasCertificate = false;
  bool _isGeneratingCertificate = false;
  int _selectedTabIndex = 0;
  bool _isFavourite = false;

  // Константы дизайна
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);

  @override
  void initState() {
    super.initState();
    _loadModules();
    _checkEnrollment();
    CourseProfileScreen.progressNotifier.addListener(_onProgressChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    CourseProfileScreen.progressNotifier.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) {
      _loadModules();
    }
  }

  @override
  void didPopNext() {
    // Вызывается когда верхний экран (урок/тест) закрывается и мы возвращаемся на этот экран
    if (mounted) {
      _loadModules();
    }
  }

  Future<void> _checkEnrollment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || user.id == null) return;

    final userId = user.id!;
    final enrolled = await SupabaseService().isUserEnrolled(
      userId,
      widget.course.id,
    );
    final fav = await SupabaseService().isCourseFavourite(
      userId,
      widget.course.id,
    );
    if (mounted) {
      setState(() {
        _isEnrolled = enrolled;
        _isFavourite = fav;
      });
    }
  }

  Future<void> _toggleFavourite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в аккаунт')),
      );
      return;
    }
    
    final userId = user.id!;
    final newFav = !_isFavourite;
    setState(() => _isFavourite = newFav);
    
    final success = await SupabaseService().toggleFavourite(
      userId,
      widget.course.id,
      newFav,
      purchasePrice: widget.course.price ?? 0.0,
    );
    
    if (!success && mounted) {
      setState(() => _isFavourite = !newFav);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось изменить статус избранного')),
      );
    }
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
      if (mounted) setState(() => _isGeneratingCertificate = true);
      // Генерируем сертификат
      final certificate = await CertificateService().generateAndUploadCertificate(
        user: user,
        course: widget.course,
      );

      if (mounted) setState(() => _isGeneratingCertificate = false);

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
      debugPrint('Loading modules for course ${widget.course.id}');
      final data = await SupabaseService().getModulesWithSubmodules(widget.course.id);
      debugPrint('Loaded ${data.length} modules');
      if (mounted) {
        setState(() {
          _courseStructure = data;
        });
      }

      // Загружаем тесты для каждого подмодуля
      final Map<int, List<TestModel>> testsMap = {};
      for (final module in _courseStructure) {
        final submodules = module['submodule'] as List<dynamic>? ?? [];
        debugPrint('Module ${module['name']} has ${submodules.length} submodules');
        for (final sub in submodules) {
          if (sub is Map<String, dynamic>) {
            final submoduleId = sub['id'] as int?;
            if (submoduleId != null) {
              try {
                final tests = await SupabaseService().getTestsBySubmodule(submoduleId);
                if (tests.isNotEmpty) {
                  testsMap[submoduleId] = tests;
                  debugPrint('Loaded ${tests.length} tests for submodule $submoduleId');
                }
              } catch (e) {
                debugPrint('Error loading tests for submodule $submoduleId: $e');
                // Игнорируем ошибки загрузки тестов для отдельных подмодулей
              }
            }
          }
        }
      }

// Загружаем практические задания для каждого подмодуля
final Map<int, List<PracticalTaskModel>> practicalTasksMap = {};
for (final module in _courseStructure) {
  final submodules = module['submodule'] as List<dynamic>? ?? [];
  for (final sub in submodules) {
    if (sub is Map<String, dynamic>) {
      final submoduleId = sub['id'] as int?;
      if (submoduleId != null) {
        try {
          final tasks = await SupabaseService().getPracticalTasks(submoduleId);
          if (tasks.isNotEmpty) {
            practicalTasksMap[submoduleId] = tasks;
          }
        } catch (e) {
          debugPrint('Error loading practical tasks for submodule $submoduleId: $e');
        }
      }
    }
  }
}

      // Загружаем прогресс пользователя
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null && user.id != null) {
        final userId = user.id!;
        final completedSubmodules = await SupabaseService().getCompletedSubmodules(userId);
        final completedTestSubmodules = await SupabaseService().getCompletedTestSubmodules(userId);
        final completedPracticalTasks = await SupabaseService().getCompletedPracticalTasks(userId);

        if (mounted) {
          setState(() {
            _completedSubmodules = completedSubmodules;
            _completedTestSubmodules = completedTestSubmodules;
            _completedPracticalTasks = completedPracticalTasks;  
            _practicalTasks = practicalTasksMap; 
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
      if (!mounted) return;
      final authProvider2 = Provider.of<AuthProvider>(context, listen: false);
      final user2 = authProvider2.currentUser;
      if (user2 != null && user2.id != null) {
        final hasCertificate = await CertificateService().hasCertificate(user2.id!, widget.course.id);
        if (mounted) setState(() => _hasCertificate = hasCertificate);

        // Проверяем и генерируем сертификат после загрузки всего
        await _checkAndGenerateCertificate(user2);
      }

      debugPrint('Modules loading completed');
    } catch (e) {
      debugPrint('Error in _loadModules: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Большой баннер курса
                _buildCourseBanner(),
                
                const SizedBox(height: 20),
                _buildContactAuthorButton(),
                const SizedBox(height: 24),
                
                // 2. Описание курса
                if (widget.course.description != null && widget.course.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.course.description!,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                _buildTabSelector(),
                const SizedBox(height: 24),
                if (_selectedTabIndex == 0)
                  (_loading
                      ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
                      : _buildModulesList())
                else
                  CourseReviewsSection(
                    courseId: widget.course.id,
                    isEnrolled: _isEnrolled,
                  ),
              ],
            ),
          ),
          // 5. Кнопка действия снизу
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Детали курса',
        style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavourite ? Icons.favorite : Icons.favorite_border,
            color: _isFavourite ? Colors.red : context.textPrimary,
          ),
          onPressed: _toggleFavourite,
        ),
      ],
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
                if (_isGeneratingCertificate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Генерация сертификата...',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else if (_hasCertificate)
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

  Widget _buildTabSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedTabIndex == 0 
                    ? (context.isDark ? _primaryPurple.withValues(alpha: 0.25) : _primaryPurple)
                    : context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedTabIndex == 0 
                      ? (context.isDark ? Colors.white.withValues(alpha: 0.1) : _primaryPurple)
                      : context.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  'Модули',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedTabIndex == 0 ? Colors.white : context.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _selectedTabIndex == 1 
                    ? (context.isDark ? _primaryPurple.withValues(alpha: 0.25) : _primaryPurple)
                    : context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedTabIndex == 1 
                      ? (context.isDark ? Colors.white.withValues(alpha: 0.1) : _primaryPurple)
                      : context.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  'Отзывы',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedTabIndex == 1 ? Colors.white : context.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModulesList() {
  debugPrint('_buildModulesList called, loading: $_loading, courseStructure length: ${_courseStructure.length}');
  if (_loading) return const Center(child: CircularProgressIndicator());
  if (_courseStructure.isEmpty) return const Text("Материалы курса скоро появятся");

  final allSubmodules = _flattenSubmodules();
  debugPrint('All submodules count: ${allSubmodules.length}');

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _courseStructure.length,
    itemBuilder: (context, index) {
      final module = _courseStructure[index];
      final List submodules = module['submodule'] ?? [];
      debugPrint('Building module ${module['name']} with ${submodules.length} submodules');

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFA58EFF).withValues(alpha: 0.1),
              child: Text("${module['order_module'] ?? index + 1}", 
                style: const TextStyle(color: Color(0xFFA58EFF), fontWeight: FontWeight.bold)),
            ),
            title: Text(
              module['name'] ?? 'Без названия',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: submodules.expand((sub) {
              final List<Widget> items = [];

              final int? submoduleId = sub['id'] is int ? sub['id'] as int : int.tryParse(sub['id'].toString());
              if (submoduleId == null) return items;

              final allSubmodules = _flattenSubmodules();
              final currentIndexInAll = allSubmodules.indexWhere((item) => item['id'] == submoduleId);
              
              // Проверка на последовательность: предыдущий подмодуль должен быть полностью завершен
              bool isSubmoduleLocked = false;
              if (currentIndexInAll > 0) {
                final prevSubmoduleId = allSubmodules[currentIndexInAll - 1]['id'] as int?;
                if (prevSubmoduleId != null && !_isSubmoduleFullyCompleted(prevSubmoduleId)) {
                  isSubmoduleLocked = true;
                }
              }

              // Контент
              final bool isContentCompleted = _completedSubmodules.contains(submoduleId);
              final String? contentUrl = sub['content'];

              items.add(ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                leading: Icon(
                  isContentCompleted ? Icons.check_circle : (isSubmoduleLocked ? Icons.lock_outline : Icons.play_circle_outline), 
                  color: isContentCompleted ? Colors.green : (isSubmoduleLocked ? Colors.grey : (_isEnrolled ? const Color(0xFFA58EFF) : Colors.grey)), 
                  size: 20
                ),
                title: Text(
                  sub['name'] ?? 'Без названия',
                  style: TextStyle(
                    color: isSubmoduleLocked ? Colors.grey : (_isEnrolled ? context.textPrimary : _textGrey), 
                  ),
                ),
                trailing: Icon(
                  isSubmoduleLocked ? Icons.lock_outline : (_isEnrolled ? Icons.arrow_forward_ios_rounded : Icons.lock_outline), 
                  size: 16, 
                  color: Colors.grey
                ), 
                onTap: () {
                  if (!_isEnrolled) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала купите курс'), backgroundColor: Colors.orange));
                    return;
                  }
                  if (isSubmoduleLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала пройдите предыдущие уроки'), backgroundColor: Colors.red));
                    return;
                  }
                  if (contentUrl != null && contentUrl.isNotEmpty) {
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
                          currentIndex: currentIndexInAll,
                          submoduleTests: _submoduleTests,
                          practicalTasks: _practicalTasks,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadModules();
                    });
                  }
                },
              ));

              // Тесты
              final tests = _submoduleTests[submoduleId];
              if (tests != null && tests.isNotEmpty) {
                final bool isTestCompleted = _completedTestSubmodules.contains(submoduleId);
                final bool isTestLocked = isSubmoduleLocked || !isContentCompleted;

                items.add(ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  leading: Icon(
                    isTestCompleted ? Icons.check_circle : (isTestLocked ? Icons.lock_outline : Icons.quiz), 
                    color: isTestCompleted ? Colors.green : (isTestLocked ? Colors.grey : const Color(0xFFA58EFF)), 
                    size: 20
                  ),
                  title: Text(
                    'Тесты (${tests.length})',
                    style: TextStyle(
                      color: isTestLocked ? Colors.grey : context.textPrimary, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    isTestLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded, 
                    size: 16, 
                    color: Colors.grey
                  ), 
                  onTap: () {
                    if (isTestLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Сначала изучите материал урока')));
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TestsScreen(
                          tests: tests,
                          submoduleName: sub['name'] ?? 'Подмодуль',
                          courseId: widget.course.id,
                          courseName: widget.course.name,
                          allSubmodules: allSubmodules,
                          currentIndex: currentIndexInAll,
                          submoduleTests: _submoduleTests,
                          practicalTasks: _practicalTasks,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadModules();
                    });
                  },
                ));
              }

              // Практика
              final practicalTasks = _practicalTasks[submoduleId];
              if (practicalTasks != null && practicalTasks.isNotEmpty) {
                final bool isTaskCompleted = _completedPracticalTasks.contains(submoduleId);
                final bool hasTests = tests != null && tests.isNotEmpty;
                final bool isPracticeLocked = isSubmoduleLocked || !isContentCompleted || (hasTests && !_completedTestSubmodules.contains(submoduleId));

                items.add(ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                  leading: Icon(
                    isTaskCompleted ? Icons.check_circle : (isPracticeLocked ? Icons.lock_outline : Icons.code),
                    color: isTaskCompleted ? Colors.green : (isPracticeLocked ? Colors.grey : const Color(0xFFA58EFF)),
                    size: 20,
                  ),
                  title: Text(
                    'Практика (${practicalTasks.length})',
                    style: TextStyle(
                      color: isPracticeLocked ? Colors.grey : context.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    isPracticeLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    if (isPracticeLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Завершите изучение теории и тесты')));
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PracticalTaskScreen(
                          task: practicalTasks[0],
                          courseId: widget.course.id,
                          courseName: widget.course.name,
                          allSubmodules: allSubmodules,
                          currentIndex: currentIndexInAll,
                          practicalTasks: _practicalTasks,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadModules();
                    });
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

bool _isSubmoduleFullyCompleted(int submoduleId) {
  // 1. Проверяем просмотр контента
  bool contentCompleted = _completedSubmodules.contains(submoduleId);
  if (!contentCompleted) return false;
  
  // 2. Проверяем тесты (если они есть)
  final tests = _submoduleTests[submoduleId];
  if (tests != null && tests.isNotEmpty) {
    if (!_completedTestSubmodules.contains(submoduleId)) return false;
  }
  
  // 3. Проверяем практические задания (если они есть)
  final tasks = _practicalTasks[submoduleId];
  if (tasks != null && tasks.isNotEmpty) {
    if (!_completedPracticalTasks.contains(submoduleId)) return false;
  }
  
  return true;
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
      isAccent: true,
    );
  }

  // 2. Если пользователь еще не купил курс
  return _buttonTemplate(
    text: _isPurchasing ? 'Оформление...' : 'Записаться за ${widget.course.price?.toInt() ?? 0} ₽',
    onPressed: _isPurchasing ? null : _handlePurchase,
    isAccent: true,
  );
}

Widget _buildContactAuthorButton() {
  return SizedBox(
    width: double.infinity,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFA58EFF),
        ),
        color: context.isDark
            ? _primaryPurple.withValues(alpha: 0.12)
            : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _contactAuthor,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search_rounded, color: context.isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFA58EFF)),
                const SizedBox(width: 8),
                Text(
                  'Связаться с автором',
                  style: TextStyle(
                    color: context.isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFFA58EFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _contactAuthor() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.currentUser;
  if (user == null || user.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пожалуйста, войдите в аккаунт, чтобы начать чат с автором')),
    );
    return;
  }

  final userId = user.id!;
  final roomId = await ChatService().getOrCreateChatRoom(
    userId,
    widget.course.id,
  );

  if (roomId == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть чат, попробуйте позже')), 
      );
    }
    return;
  }

  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatScreen(
          roomId: roomId,
          userId: userId,
          courseName: widget.course.name,
        ),
      ),
    );
  }
}

// Вспомогательный метод для стилизации кнопок
Widget _buttonTemplate({
  required String text, 
  required VoidCallback? onPressed, 
  bool isAccent = true
}) {
  if (!isAccent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple.withValues(alpha: 0.18),
                  const Color(0xFFF2C9D4).withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x80000000),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: context.isDark
            ? [_primaryPurple.withValues(alpha: 0.25), const Color(0xFFF2C9D4).withValues(alpha: 0.15)]
            : [_primaryPurple, const Color(0xFFF2C9D4)],
      ),
      border: context.isDark
          ? Border.all(color: Colors.white.withValues(alpha: 0.1))
          : null,
      boxShadow: context.isDark ? null : [
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
    final user = authProvider.currentUser;
    if (user == null || user.id == null || user.email == null) return;

    final userId = user.id!;
    final userEmail = user.email!;
    final price = widget.course.price ?? 0;
    
    // Если курс платный, показываем окно оплаты
    if (price > 0) {
      final bool? paymentSuccess = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentDialog(amount: price.toDouble()),
      );
      
      if (paymentSuccess != true) {
        return; // Пользователь отменил оплату или произошла ошибка
      }
    }

    setState(() => _isPurchasing = true);
    
    final success = await SupabaseService().purchaseCourse(
      userId,
      widget.course,
      userEmail,
    );

    if (mounted) {
      setState(() {
        _isPurchasing = false;
        if (success) _isEnrolled = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? 'Вы успешно записаны! Чек отправлен на почту.' 
              : 'Ошибка при покупке'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
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
                practicalTasks: _practicalTasks,
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

    
    // Проверяем, есть ли практические задания для этого подмодуля
final practicalTasks = _practicalTasks[submoduleId];
if (practicalTasks != null && practicalTasks.isNotEmpty && !_completedPracticalTasks.contains(submoduleId)) {
  // Практические задания не выполнены - открываем их
  final currentIndex = allSubmodules.indexOf(submodule);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PracticalTaskScreen(
        task: practicalTasks[0],
        courseId: widget.course.id,
        courseName: widget.course.name,
        allSubmodules: allSubmodules,
        currentIndex: currentIndex,
        practicalTasks: _practicalTasks,
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
