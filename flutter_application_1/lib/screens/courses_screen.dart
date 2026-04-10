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
  bool _loading = false;
  String _activeFilter = 'Все';

  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _bgLightGrey = Color(0xFFF8F9FB);

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Все', 'icon': Icons.grid_view_rounded},
    {'label': 'Python', 'icon': Icons.code_rounded},
    {'label': 'Frontend', 'icon': Icons.laptop_chromebook_rounded},
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
      final list = await SupabaseService().getCourses();
      setState(() {
        _allCourses.clear();
        _allCourses.addAll(list);
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
      } else {
        _displayCourses = _allCourses
            .where((c) => c.name.toLowerCase().contains(categoryLabel.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.email?.split('@')[0] ?? 'Кирилл';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
        : CustomScrollView( // Используем CustomScrollView для общей прокрутки
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
                          Text('Доброе утро,\n$userName',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark, height: 1.2)),
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
                          const Text('Направления', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                          TextButton(onPressed: () {}, child: const Text('См. все', style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              
              // Горизонтальные категории
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) => _buildCategoryChip(_categories[index]['label'], _categories[index]['icon']),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      const Text('Новые курсы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _bgLightGrey, borderRadius: BorderRadius.circular(8)),
                        child: const Text('ТОП-10', style: TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),

              // Сетка курсов, которая является частью общего списка прокрутки
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
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
              const SliverToBoxAdapter(child: SizedBox(height: 30)), // Отступ снизу
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
            decoration: BoxDecoration(color: _textDark, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('Кодикс', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  Widget _buildPathBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFBCAFFF), _primaryPurple]),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ТЕКУЩИЙ ПУТЬ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                SizedBox(height: 6),
                Text('Путь Fullstack\nразработчика', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Продолжить', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const Text('64%', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        decoration: BoxDecoration(color: isSelected ? _primaryPurple : _bgLightGrey, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : _textDark),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : _textDark, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseProfileScreen(course: course))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Container(decoration: const BoxDecoration(color: _bgLightGrey, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: const Center(child: Icon(Icons.laptop, color: _textGrey)))),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('12 уроков', style: TextStyle(fontSize: 11, color: _textGrey)),
                      Text('${course.price?.toInt() ?? 0} ₽', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryPurple)),
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