import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../services/supabase_service.dart';

class CourseProfileScreen extends StatefulWidget {
  final CourseModel course;

  const CourseProfileScreen({super.key, required this.course});

  @override
  State<CourseProfileScreen> createState() => _CourseProfileScreenState();
}

class _CourseProfileScreenState extends State<CourseProfileScreen> {
  final List<ModuleModel> _modules = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _loading = true;
    });

    await SupabaseService().initialize();

    try {
      final list = await SupabaseService().getModules(widget.course.id);
      setState(() {
        _modules
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[CourseProfileScreen] error fetching modules: $e');
      debugPrint('$st');
      setState(() {
        _modules.clear();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Основные цвета из макета
    const Color primaryBlue = Color(0xFF4561FF);
    const Color bgPink = Color(0xFFFFF0F5);
    const Color textDark = Color(0xFF1E1E2E);
    const Color textGrey = Color(0xFF9094A6);

    return Scaffold(
      backgroundColor: bgPink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.visibility_off_outlined, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // --- ВЕРХНЯЯ ЧАСТЬ (Шапка) ---
// --- ВЕРХНЯЯ ЧАСТЬ (Шапка) ---
Container(
  height: 260,
  width: double.infinity,
  padding: const EdgeInsets.only(left: 24, top: 100, right: 24),
  child: Stack(
    clipBehavior: Clip.none, // Позволяет картинке слегка выходить за границы Stack, как в макете
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Бейдж Bestseller
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'BESTSELLER',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Заголовок в шапке (ограничиваем ширину, чтобы текст не залезал на картинку)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.55, 
            child: Text(
              widget.course.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textDark, // Использует переменную textDark из предыдущего кода
              ),
            ),
          ),
        ],
      ),
      // Иллюстрация персонажа
      Positioned(
        right: -10, // Прижимаем к правому краю
        bottom: -32, // Слегка опускаем вниз к белой карточке
        child: Image.asset(
          'lib/assets/images/course.png',
          height: 260, // Высоту можно немного подогнать по месту
          fit: BoxFit.contain,
        ),
      ),
    ],
  ),
),      
          // --- ОСНОВНОЙ КОНТЕНТ (Белая карточка) ---
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название и Цена
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.course.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                        Text(
                          widget.course.price != null 
                              ? 'P${widget.course.price!.toStringAsFixed(2)}' 
                              : 'P0.00',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Заглушка: время и количество уроков
                    Text(
                      '6ч 14мин · ${_modules.length} урока', 
                      style: const TextStyle(fontSize: 14, color: textGrey),
                    ),
                    const SizedBox(height: 24),
                    
                    // Об этом курсе
                    const Text(
                      'Об этом курсе',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.course.description ?? 'Описание отсутствует...',
                      style: const TextStyle(
                        fontSize: 14, 
                        color: textGrey, 
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Center(
                      child: Icon(Icons.visibility_off_outlined, color: textGrey, size: 20),
                    ),
                    const SizedBox(height: 20),

                    // Список модулей
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_modules.isEmpty)
                      const Text(
                        'Модули не найдены.',
                        style: TextStyle(color: textGrey),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _modules.length,
                        itemBuilder: (context, index) {
                          final module = _modules[index];
                          // Логика блокировки для демо (например, статус false означает, что модуль закрыт)
                          final isLocked = module.status == false || index > 1; 

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              children: [
                                // Порядковый номер (01, 02...)
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    (index + 1).toString().padLeft(2, '0'),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC8CCDB),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Инфо модуля
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '6:10 мин', // Заглушка времени модуля
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isLocked ? textGrey : primaryBlue,
                                            ),
                                          ),
                                          if (!isLocked) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check_circle, size: 14, color: primaryBlue),
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Кнопка действия (Play / Lock)
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isLocked ? const Color(0xFFD3DCFF) : primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isLocked ? Icons.lock : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      // --- НИЖНЯЯ ПАНЕЛЬ (Кнопки) ---
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
        child: Row(
          children: [
            // Кнопка избранного (звездочка)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.star_border, color: Color(0xFFFF6B00), size: 28),
                onPressed: () {
                  // Логика добавления в избранное
                },
              ),
            ),
            const SizedBox(width: 16),
            // Кнопка "Купить"
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // Логика покупки
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Купить',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}