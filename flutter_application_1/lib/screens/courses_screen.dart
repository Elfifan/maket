import 'dart:async';
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
  List<CourseModel> _favouriteCourses = [];
  List<CourseModel> _completedCourses = [];
  bool _loading = false;
  String? _errorMessage;
  String _activeFilter = 'Все';

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  int? _selectedYear;
  int? _selectedComplexity;
  bool _isFree = false;

  static const Color _primaryPurple = Color(0xFFA58EFF);

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Все', 'icon': Icons.grid_view_rounded},
    {'label': 'Мои курсы', 'icon': Icons.book_rounded},
    {'label': 'Избранное', 'icon': Icons.favorite_rounded},
    {'label': 'Пройденные', 'icon': Icons.assignment_turned_in_rounded},
  ];

  StreamSubscription? _coursesSub;
  StreamSubscription? _myCoursesSub;
  StreamSubscription? _favouriteCoursesSub;
  StreamSubscription? _completedCoursesSub;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _reconnectStreams() {
    if (_isReconnecting || !mounted) return;
    _isReconnecting = true;
    debugPrint('[CoursesScreen] Начинаем переподключение Realtime-стримов через 5 секунд...');
    
    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      _isReconnecting = false;
      
      // Отменяем старые подписки
      await _cancelStreams();
      
      // Заново запускаем стримы (тихо, без лоадера)
      _setupStreams(silent: true);
    });
  }

  Future<void> _cancelStreams() async {
    await _coursesSub?.cancel();
    await _myCoursesSub?.cancel();
    await _favouriteCoursesSub?.cancel();
    await _completedCoursesSub?.cancel();
    _coursesSub = null;
    _myCoursesSub = null;
    _favouriteCoursesSub = null;
    _completedCoursesSub = null;
  }

  Future<void> _setupStreams({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      await SupabaseService().initialize();
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      _coursesSub ??= SupabaseService().streamCourses().listen((courses) {
        if (mounted) {
          setState(() {
            _allCourses.clear();
            _allCourses.addAll(courses);
            _applyFilter();
            _loading = false;
          });
        }
      }, onError: (e) {
        debugPrint('Error streaming courses: $e');
        if (mounted && _allCourses.isEmpty) {
          setState(() {
            _errorMessage = 'Не удалось загрузить данные. Проверьте интернет.';
            _loading = false;
          });
        }
        _reconnectStreams();
      });

      final user = authProvider.currentUser;
      if (user != null && user.id != null) {
        final userId = user.id!;
        
        _myCoursesSub ??= SupabaseService()
            .streamUserCourses(userId: userId)
            .listen((myCourses) {
          if (mounted) {
            setState(() {
              _myCourses = myCourses;
              _applyFilter();
            });
          }
        }, onError: (e) {
          debugPrint('Error streaming user courses: $e');
          _reconnectStreams();
        });

        _favouriteCoursesSub ??= SupabaseService()
            .streamUserFavouriteCourses(userId: userId)
            .listen((favCourses) {
          if (mounted) {
            setState(() {
              _favouriteCourses = favCourses;
              _applyFilter();
            });
          }
        }, onError: (e) {
          debugPrint('Error streaming favourite courses: $e');
          _reconnectStreams();
        });

        _completedCoursesSub ??= SupabaseService()
            .streamUserCompletedCourses(userId: userId)
            .listen((completedCourses) {
          if (mounted) {
            setState(() {
              _completedCourses = completedCourses;
              _applyFilter();
            });
          }
        }, onError: (e) {
          debugPrint('Error streaming completed courses: $e');
          _reconnectStreams();
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = 'Ошибка инициализации. Проверьте интернет.';
          _loading = false;
        });
      }
      _reconnectStreams();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cancelStreams();
    super.dispose();
  }

  void _applyFilter([String? categoryLabel]) {
    setState(() {
      if (categoryLabel != null) {
        _activeFilter = categoryLabel;
      }
      
      List<CourseModel> baseList;
      if (_activeFilter == 'Мои курсы') {
        baseList = _myCourses;
      } else if (_activeFilter == 'Избранное') {
        baseList = _favouriteCourses;
      } else if (_activeFilter == 'Пройденные') {
        baseList = _completedCourses;
      } else {
        baseList = _allCourses;
      }
      
      _displayCourses = baseList.where((course) {
        if (_searchController.text.isNotEmpty) {
          if (!course.name.toLowerCase().contains(_searchController.text.toLowerCase())) {
            return false;
          }
        }
        if (_selectedCategory != null && course.category != _selectedCategory) {
          return false;
        }
        if (_selectedYear != null) {
          final year = _activeFilter == 'Пройденные' 
              ? course.completedDate?.year 
              : course.dateCreate?.year;
          if (year != _selectedYear) {
            return false;
          }
        }
        if (_selectedComplexity != null && course.complexity != _selectedComplexity) {
          return false;
        }
        if (_isFree && (course.price != null && course.price! > 0)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName =
        authProvider.currentUser?.name ??
        authProvider.currentUser?.email?.split('@')[0] ??
        'Пользователь';

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryPurple),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: context.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _setupStreams,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Попробовать снова',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Если стримы работают, pull-to-refresh может просто делать небольшую задержку
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: _primaryPurple,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _applyFilter(),
                              style: TextStyle(color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Поиск курсов...',
                                hintStyle: TextStyle(color: context.textSecondary),
                                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                                filled: true,
                                fillColor: context.surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showFilterBottomSheet,
                            child: Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                color: _primaryPurple,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.tune, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                            _activeFilter == 'Мои курсы'
                                ? 'Мои курсы'
                                : _activeFilter == 'Избранное'
                                    ? 'Избранное'
                                    : 'Новые курсы',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
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
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: _activeFilter == 'Пройденные' ? 0.70 : 0.75,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildCourseCard(_displayCourses[index]),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фильтры',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: context.textPrimary),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Направление', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    dropdownColor: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryPurple),
                    style: TextStyle(color: context.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все направления', style: TextStyle(color: context.textPrimary)),
                      ),
                      ...['Веб-разработка', 'База данных', 'Программирование']
                          .map((e) => DropdownMenuItem<String?>(
                                value: e,
                                child: Text(e, style: TextStyle(color: context.textPrimary)),
                              )),
                    ],
                    onChanged: (val) => setModalState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 16),
                  Text('Год', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    dropdownColor: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryPurple),
                    style: TextStyle(color: context.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все года', style: TextStyle(color: context.textPrimary)),
                      ),
                      ...[2023, 2024, 2025, 2026]
                          .map((e) => DropdownMenuItem<int?>(
                                value: e,
                                child: Text(e.toString(), style: TextStyle(color: context.textPrimary)),
                              )),
                    ],
                    onChanged: (val) => setModalState(() => _selectedYear = val),
                  ),
                  const SizedBox(height: 16),
                  Text('Сложность', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedComplexity,
                    dropdownColor: context.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryPurple),
                    style: TextStyle(color: context.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.borderColor, width: 1),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Любая сложность', style: TextStyle(color: context.textPrimary)),
                      ),
                      ...[1, 2, 3, 4, 5]
                          .map((e) => DropdownMenuItem<int?>(
                                value: e,
                                child: Text(e.toString(), style: TextStyle(color: context.textPrimary)),
                              )),
                    ],
                    onChanged: (val) => setModalState(() => _selectedComplexity = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Только бесплатные',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: _isFree,
                        onChanged: (val) => setModalState(() => _isFree = val),
                        activeTrackColor: _primaryPurple.withValues(alpha: 0.5),
                        activeThumbColor: _primaryPurple,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: context.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedYear = null;
                                _selectedComplexity = null;
                                _isFree = false;
                              });
                              _applyFilter();
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text('Сбросить', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 50,
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
                            onPressed: () {
                              _applyFilter();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'Применить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
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
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : ThemeProvider.lightTextPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bolt,
              color: context.isDark ? _primaryPurple : Colors.white,
              size: 20,
            ),
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
                border: Border.all(
                  color: _primaryPurple.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child:
                    authProvider.currentUser?.avatarUrl != null &&
                        authProvider.currentUser!.avatarUrl!.isNotEmpty
                    ? Image.network(
                        authProvider.currentUser!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.person,
                          size: 20,
                          color: context.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: context.textSecondary,
                      ),
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
                        builder: (_) =>
                            CourseProfileScreen(course: _myCourses.first),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
              ? (context.isDark
                    ? _primaryPurple.withValues(alpha: 0.25)
                    : _primaryPurple)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? (context.isDark
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null)
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
        errorBuilder: (context, error, stackTrace) =>
            Text('📚', style: TextStyle(fontSize: 48)),
      );
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: _primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 36))),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(child: _buildCourseIcon(course.icon)),
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
                  if (_activeFilter == 'Пройденные' && course.startDate != null && course.completedDate != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Начат: ${_formatDate(course.startDate)}',
                      style: TextStyle(fontSize: 10, color: context.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Пройден: ${_formatDate(course.completedDate)}',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ] else ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
