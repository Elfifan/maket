import 'dart:math';
import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/supabase_service.dart';
import 'course_profile_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final List<CourseModel> _courses = [];
  bool _loading = false;
  String _search = '';
  String _filter = 'Все';
  int _selectedIndex = 1; // Курсы активны по умолчанию

  // Цвета из макета
  static const Color primaryBlue = Color(0xFF4561FF);
  static const Color textDark = Color(0xFF1E1E2E);
  static const Color textGrey = Color(0xFF9094A6);

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loading = true);
    await SupabaseService().initialize();
    try {
      final list = await SupabaseService().getCourses(
        search: _search,
        filterCategory: _filter,
      );
      setState(() {
        _courses..clear()..addAll(list);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Дом
        // Пока ничего
        break;
      case 1: // Курсы
        // Уже здесь
        break;
      case 2: // Поиск
        // Пока ничего
        break;
      case 3: // Сообщения
        // Пока ничего
        break;
      case 4: // Аккаунт
        Navigator.pushNamed(context, '/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Курсы',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFE5E5),
                    child: ClipOval(
                      child: Image.network(
                        'https://api.dicebear.com/7.x/avataaars/png?seed=Felix', // Временный аватар
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- ПОИСК ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Найти курс',
                    hintStyle: TextStyle(color: textGrey),
                    prefixIcon: Icon(Icons.search, color: textGrey),
                    suffixIcon: Icon(Icons.tune, color: textGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // --- КАРТОЧКИ КАТЕГОРИЙ ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  _buildCategoryCard('Язык', 'lib/assets/images/Frame2.png', const Color(0xFFD3EFFF)),
                  const SizedBox(width: 16),
                  _buildCategoryCard('Прог', 'lib/assets/images/Frame.png', const Color(0xFFE8DFFF)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- ПОДЗАГОЛОВОК И ТАБЫ ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Курсы',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: [
                  _buildTab('Все'),
                  _buildTab('Популярное'),
                  _buildTab('Новые'),
                ],
              ),
            ),

            // --- СПИСОК КУРСОВ ---
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        final rand = Random(course.id);
                        final durationH = 10 + rand.nextInt(10);
                        
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourseProfileScreen(course: course)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Заглушка изображения курса
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9D9D9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Инфо курса
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 14, color: textGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _filter == 'Все' ? 'Программирование' : _filter,
                                            style: const TextStyle(color: textGrey, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'P${course.price?.toInt() ?? 190}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFE5E5),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$durationH часов',
                                              style: const TextStyle(
                                                color: Color(0xFFFF6B00),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
      // --- НИЖНЯЯ НАВИГАЦИЯ ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textGrey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Дом'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Курсы'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Сообщения'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Аккаунт'),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String label, String imagePath, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0, bottom: 0, top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              left: 16, bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = label;
        _loadCourses();
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryBlue : textGrey,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2, width: 20,
                color: primaryBlue,
              )
          ],
        ),
      ),
    );
  }
}