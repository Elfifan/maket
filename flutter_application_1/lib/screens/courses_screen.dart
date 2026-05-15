import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_container.dart';
import 'course_profile_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<CourseModel> _allCourses = [];
  List<CourseModel> _displayCourses = [];
  List<CourseModel> _myCourses = [];
  bool _loading = false;
  String? _errorMessage;
  String _activeFilter = 'Все';

  static const Color _primaryPurple = Color(0xFFA58EFF);

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Все', 'icon': Icons.grid_view_rounded},
    {'label': 'Мои курсы', 'icon': Icons.book_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    int attempts = 0;
    const int maxAttempts = 3;
    const Duration timeoutDuration = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      try {
        attempts++;
        debugPrint('Загрузка курсов, попытка $attempts из $maxAttempts...');
        
        await SupabaseService().initialize();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Параллельный запуск запросов с таймаутом
        final results = await Future.wait([
          SupabaseService().getCourses().timeout(timeoutDuration),
          if (authProvider.currentUser != null)
            SupabaseService().getUserCourses(userId: authProvider.currentUser!.id!).timeout(timeoutDuration)
          else
            Future.value(<CourseModel>[]),
        ]);

        final allCourses = results[0] as List<CourseModel>;
        final myCourses = results[1] as List<CourseModel>;

        if (mounted) {
          setState(() {
            _allCourses.clear();
            _allCourses.addAll(allCourses);
            _myCourses = myCourses;
            _applyFilter(_activeFilter);
            _loading = false;
          });
        }
        return; // Успешно загружено, выходим из метода
      } catch (e) {
        debugPrint('Попытка $attempts не удалась: $e');
        if (attempts >= maxAttempts) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Не удалось загрузить данные после $maxAttempts попыток. Проверьте интернет.';
              _loading = false;
            });
          }
        } else {
          // Небольшая пауза перед следующей попыткой
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }

  void _applyFilter(String categoryLabel) {
    setState(() {
      _activeFilter = categoryLabel;
      if (categoryLabel == 'Все') {
        _displayCourses = List.from(_allCourses);
      } else if (categoryLabel == 'Мои курсы') {
        _displayCourses = List.from(_myCourses);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 
                     authProvider.currentUser?.email?.split('@')[0] ?? 
                     'Пользователь';

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: context.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textPrimary, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCourses,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Попробовать снова', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
            onRefresh: _loadCourses,
            color: _primaryPurple,
            child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Доброе утро,\n$userName',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('👏', style: TextStyle(fontSize: 26)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildPathBanner(),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Направления',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) => _buildCategoryChip(
                          _categories[index]['label'],
                          _categories[index]['icon'],
                        ),
                      ),
                    ),
                  ),
    
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            _activeFilter == 'Мои курсы' ? 'Мои курсы' : 'Новые курсы',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_displayCourses.length}',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
    
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: _displayCourses.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  'Курсы не найдены',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildCourseCard(_displayCourses[index]),
                              childCount: _displayCourses.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withValues(alpha: 0.1) : ThemeProvider.lightTextPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bolt, color: context.isDark ? _primaryPurple : Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Кодикс',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: _primaryPurple.withValues(alpha: 0.3), width: 1),
              ),
              child: ClipOval(
                child: authProvider.currentUser?.avatarUrl != null && authProvider.currentUser!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        authProvider.currentUser!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(Icons.person, size: 20, color: context.textSecondary),
                      )
                    : Icon(Icons.person, size: 20, color: context.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBanner() {
    String courseName = 'Начни уже изучать';
    
    if (_myCourses.isNotEmpty) {
      courseName = _myCourses.first.name;
    }

    return GlassContainer(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(20),
      color: _primaryPurple,
      opacity: context.isDark ? 0.2 : 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ТЕКУЩИЙ ПУТЬ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                courseName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (_myCourses.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: 'course_profile'),
                        builder: (_) => CourseProfileScreen(course: _myCourses.first),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _myCourses.isNotEmpty ? 'Продолжить' : 'Выбрать курс',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        margin: const EdgeInsets.only(left: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDark ? _primaryPurple.withValues(alpha: 0.25) : _primaryPurple)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? (context.isDark ? Border.all(color: Colors.white.withValues(alpha: 0.1)) : null)
              : Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : context.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : context.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCourseIcon(String? icon) {
  if (icon == null || icon.isEmpty) {
    return Icon(
      Icons.school,
      color: _primaryPurple.withValues(alpha: 0.3),
      size: 48,
    );
  }

  if (icon.startsWith('http')) {
    return Image.network(
      icon,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Text(
        '📚',
        style: TextStyle(fontSize: 48),
      ),
    );
  }

  return Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
      color: _primaryPurple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Text(
        icon,
        style: const TextStyle(fontSize: 36),
      ),
    ),
  );
}

  Widget _buildCourseCard(CourseModel course) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: 'course_profile'),
            builder: (_) => CourseProfileScreen(course: course),
          ),
        );
      },
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.isDark
                      ? _primaryPurple.withValues(alpha: 0.08)
                      : context.surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: _buildCourseIcon(course.icon),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${course.complexity ?? 1} уровень',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                      Text(
                        '${course.price?.toInt() ?? 0} ₽',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
