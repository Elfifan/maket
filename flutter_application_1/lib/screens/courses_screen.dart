import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
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
  String _activeFilter = 'Все';

  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _bgLightGrey = Color(0xFFF8F9FB);

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
    setState(() => _loading = true);
    await SupabaseService().initialize();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Загружаем все активные курсы
      final allCourses = await SupabaseService().getCourses();
      
      // Загружаем курсы пользователя
      List<CourseModel> myCourses = [];
      if (authProvider.currentUser != null) {
        myCourses = await SupabaseService().getUserCourses(
          userId: authProvider.currentUser!.id!,
        );
      }

      setState(() {
        _allCourses.clear();
        _allCourses.addAll(allCourses);
        _myCourses = myCourses;
        _applyFilter('Все');
      });
    } catch (e) {
      debugPrint('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
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
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
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
                          const Text(
                            'Направления',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bgLightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_displayCourses.length}',
                          style: const TextStyle(
                            color: _textGrey,
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
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'Курсы не найдены',
                              style: TextStyle(
                                color: _textGrey,
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
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _textDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Кодикс',
            style: TextStyle(
              color: _textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  Widget _buildPathBanner() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Находим первый курс пользователя для отображения в "текущем пути"
    String courseName = 'Начни уже изучать';
    String progressText = '0%';
    
    if (_myCourses.isNotEmpty) {
      courseName = _myCourses.first.name;
      // Можно добавить реальный прогресс
      progressText = 'Продолжить';
    }

    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFBCAFFF), _primaryPurple],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
          color: isSelected ? _primaryPurple : _bgLightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : _textDark,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _textDark,
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
      color: _primaryPurple.withOpacity(0.3),
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
      color: _primaryPurple.withOpacity(0.1),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CourseProfileScreen(course: course)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _bgLightGrey,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${course.complexity ?? 1} уровень',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textGrey,
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