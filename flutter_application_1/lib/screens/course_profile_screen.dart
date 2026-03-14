import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/module_model.dart';
import '../providers/auth_provider.dart';
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
  bool _isPurchasing = false; 
  bool _isEnrolled = false; 

  @override
  void initState() {
    super.initState();
    _loadModules();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnrollment());
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

  Future<void> _checkEnrollment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      return;
    }
    await SupabaseService().initialize();
    final enrolled = await SupabaseService().hasPurchasedCourse(
      userId: currentUser.id!,
      courseId: widget.course.id,
    );
    setState(() {
      _isEnrolled = enrolled;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [

          Container(
            height: 260,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, top: 100, right: 24),
            child: Stack(
              clipBehavior: Clip
                  .none, 
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.55,
                      child: Text(
                        widget.course.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color:
                              textDark, 
                        ),
                      ),
                    ),
                  ],
                ),

                Positioned(
                  right: -10, 
                  bottom: -32, 
                  child: Image.asset(
                    'lib/assets/images/course.png',
                    height: 260, 
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
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
                    Text(
                      '6ч 14мин · ${_modules.length} урока',
                      style: const TextStyle(fontSize: 14, color: textGrey),
                    ),
                    const SizedBox(height: 24),

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
                      child: Icon(
                        Icons.visibility_off_outlined,
                        color: textGrey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),

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
                          final isLocked = module.status == false || index > 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              children: [
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            '6:10 мин',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isLocked
                                                  ? textGrey
                                                  : primaryBlue,
                                            ),
                                          ),
                                          if (!isLocked) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: primaryBlue,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isLocked
                                        ? const Color(0xFFD3DCFF)
                                        : primaryBlue,
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

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 32,
          top: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.star_border,
                  color: Color(0xFFFF6B00),
                  size: 28,
                ),
                onPressed: () {
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 60,
                child: _isEnrolled
                    ? Container(
                        alignment: Alignment.center,
                        child: const Text(
                          'Вы уже записаны на курс',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: (_loading || _isPurchasing) ? null : () async {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final currentUser = authProvider.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сначала войдите в систему'),
                        ),
                      );
                      return;
                    }

                    setState(() => _isPurchasing = true);
                    final success = await SupabaseService().purchaseCourse(
                      userId: currentUser.id!,
                      courseId: widget.course.id,
                      amount: widget.course.price ?? 0,
                      userEmail: currentUser.email ?? '',
                      courseName: widget.course.name,
                    );
                    setState(() => _isPurchasing = false);

                    if (success) {
                      setState(() {
                        _isEnrolled = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Курс успешно куплен, чек отправлен на почту',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Не удалось оформить покупку'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
