import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'submodule_content_screen.dart';

class CourseProfileScreen extends StatefulWidget {
  final CourseModel course;

  const CourseProfileScreen({super.key, required this.course});

  @override
  State<CourseProfileScreen> createState() => _CourseProfileScreenState();
}

class _CourseProfileScreenState extends State<CourseProfileScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _courseStructure = [];
  bool _loading = false;
  bool _isPurchasing = false;
  bool _isEnrolled = false;

  // Константы дизайна
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _bgLightGrey = Color(0xFFF8F9FB);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

Future<void> _loadModules() async {
  setState(() => _loading = true);
  try {
    final data = await SupabaseService().getModulesWithSubmodules(widget.course.id);
    setState(() {
      _courseStructure = data;
      _loading = false;
    });
  } catch (e) {
    setState(() => _loading = false);
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
                
                // 2. Табы (О курсе / Плейлист)
                _buildTabBar(),
                
                const SizedBox(height: 32),
                
                // 3. Контент в зависимости от выбранного таба
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
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

  Widget _buildTabBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _bgLightGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        labelColor: _textDark,
        unselectedLabelColor: _textGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [Tab(text: 'О курсе'), Tab(text: 'Плейлист')],
      ),
    );
  }

Widget _buildModulesList() {
  if (_loading) return const Center(child: CircularProgressIndicator());
  if (_courseStructure.isEmpty) return const Text("Материалы курса скоро появятся");

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _courseStructure.length,
    itemBuilder: (context, index) {
      final module = _courseStructure[index];
      final List submodules = module['submodule'] ?? [];

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
              backgroundColor: const Color(0xFFA58EFF).withOpacity(0.1),
              child: Text("${module['order_module'] ?? index + 1}", 
                style: const TextStyle(color: Color(0xFFA58EFF), fontWeight: FontWeight.bold)),
            ),
            title: Text(
              module['name'] ?? 'Без названия',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text("${submodules.length} уроков", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            children: submodules.map((sub) {
              // Находим внутри ListView.builder -> itemBuilder -> submodules.map((sub) { ... })

return ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),

  leading: Icon(
    Icons.play_circle_outline, 
    color: _isEnrolled ? const Color(0xFFA58EFF) : Colors.grey, 
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
      
      if (contentUrl != null && contentUrl.isNotEmpty) {
        final allSubmodules = _flattenSubmodules();
        final currentIndex = allSubmodules.indexWhere((item) => item['id'] == sub['id']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubmoduleContentScreen(
              title: sub['name'] ?? 'Урок',
              contentUrl: contentUrl,
              allSubmodules: allSubmodules,
              currentIndex: currentIndex,
            ),
          ),
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
);
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
            result.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }
    return result;
  }

  Widget _buildModuleTile(ModuleModel module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgLightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            height: 40, width: 40,
            decoration: const BoxDecoration(color: Color(0xFFF0EBFF), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: _primaryPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Модуль ${module.orderModule ?? ""}',
                  style: const TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  module.name,
                  style: const TextStyle(color: _textDark, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildActionButton() {
  // 1. Если пользователь уже записан (есть запись в БД)
  if (_isEnrolled) {
    return _buttonTemplate(
      text: 'Продолжить обучение',
      onPressed: () {
        // Здесь логика перехода к первому уроку или последнему открытому
        // Например, переключение таба на "Плейлист"
        _tabController.animateTo(1); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Переходим к материалам...')),
        );
      },
      isAccent: false, // Можно добавить параметр для смены цвета
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
            : [_primaryPurple, _primaryPurple.withOpacity(0.8)],
      ),
      boxShadow: [
        BoxShadow(
          color: _primaryPurple.withOpacity(0.3), 
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
}