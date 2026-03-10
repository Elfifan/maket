import 'dart:math';

import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../services/supabase_service.dart';

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

  static const List<IconData> _iconPool = [
    Icons.book,
    Icons.code,
    Icons.school,
    Icons.computer,
    Icons.lock,
    Icons.brush,
    Icons.camera_alt,
    Icons.language,
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
    });

    // Убедимся, что клиент инициализирован (на случай, если экран
    // открылся до полного завершения инициализации в AuthProvider).
    await SupabaseService().initialize();

    try {
      final list = await SupabaseService().getCourses(
        search: _search,
        filterCategory: _filter,
      );
      debugPrint('[_loadCourses] received ${list.length} items');
      setState(() {
        _courses
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[CoursesScreen] error fetching courses: $e');
      debugPrint('$st');
      setState(() {
        _courses.clear();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _search = value;
    _loadCourses();
  }

  void _onFilterSelected(String category) {
    _filter = category;
    _loadCourses();
  }

  IconData _randomIcon(int seed) {
    return _iconPool[seed % _iconPool.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
        backgroundColor: const Color(0xFF2196F3),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Поисковая строка (обёрнута в карточку с тенью)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Введите название курса',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Фильтры (чипсы)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Все'),
                const SizedBox(width: 8),
                _buildFilterChip('Flutter'),
                const SizedBox(width: 8),
                _buildFilterChip('Dart'),
                const SizedBox(width: 8),
                _buildFilterChip('Тестирование'),
                const SizedBox(width: 8),
                _buildFilterChip('UI/UX'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Список курсов
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _courses.isEmpty
                    ? const Center(
                        child: Text(
                          'Курсы не найдены или недоступны.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          final icon = _randomIcon(course.id);
                          // генерация рандомных значений на основе id
                          final rand = Random(course.id);
                          final durationH = 1 + rand.nextInt(10);
                          final priceValue = course.price ?? (rand.nextInt(100) + 1).toDouble();
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.grey, width: 1),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              title: Text(
                                course.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (course.description != null && course.description!.isNotEmpty)
                                    Text(
                                      course.description!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue, width: 1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Цена: ${priceValue.toStringAsFixed(2)} ₽',
                                          style: const TextStyle(fontSize: 13, color: Colors.blue),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.orange, width: 1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Время: $durationH ч',
                                          style: const TextStyle(fontSize: 13, color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF2196F3), width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 32, color: const Color(0xFF2196F3)),
                              ),
                              onTap: () {
                                // TODO: перейти на детальную страницу
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _filter == label;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _onFilterSelected(label),
    );
  }
}
