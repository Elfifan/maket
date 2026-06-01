
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/certificate_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/glass_container.dart';
import 'certificate_pdf_viewer_screen.dart';
import 'pdf_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSavingName = false;

  bool? _authorStatus;
  bool _checkingAuthor = true;

  static const Color _primaryPurple = Color(0xFFA58EFF);

  List<AchievementModel>? _cachedAchievements;
  List<CertificateModel>? _cachedCertificates;
  Stream<List<AchievementModel>>? _achievementsStream;
  Stream<List<CertificateModel>>? _certificatesStream;

  @override
  void initState() {
    super.initState();
    _checkAuthorStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    if (user != null && user.id != null) {
      _achievementsStream ??= SupabaseService().streamUserAchievements(user.id!);
      _certificatesStream ??= SupabaseService().streamUserCertificates(user.id!);
    } else {
      _achievementsStream = null;
      _certificatesStream = null;
      _cachedAchievements = null;
      _cachedCertificates = null;
    }
  }

  Future<void> _checkAuthorStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null || user.id == null) return;
    
    final status = await SupabaseService().checkAuthorStatus(user.id!);
    if (mounted) {
      setState(() {
        _authorStatus = status;
        _checkingAuthor = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Ошибка данных пользователя')));
    }

    final userName = user.name ?? user.email?.split('@')[0] ?? 'Пользователь';
    final avatarUrl = user.avatarUrl;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Text('Профиль', style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(userName, avatarUrl),
              const SizedBox(height: 24),
              _buildNameTile(userName),
              const SizedBox(height: 32),
              _buildAchievements(user.id!),
              const SizedBox(height: 32),
              _buildCertificates(user.id!),
              const SizedBox(height: 32),
              _buildSettingsMenu(),
              const SizedBox(height: 32),
              _buildLogoutButton(context, authProvider),
              const SizedBox(height: 24),
              Center(
                child: Text('ВЕРСИЯ ПРИЛОЖЕНИЯ 2.4.0',
                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== АВАТАР И ИМЯ ====================

  Widget _buildHeaderCard(String name, String? avatarUrl) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: _primaryPurple,
      opacity: context.isDark ? 0.1 : 0.08,
      child: Column(
        children: [
          GestureDetector(
            onTap: _changeAvatar,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: context.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPurple.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: _primaryPurple,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person, size: 50, color: context.textSecondary),
                          )
                        : Icon(Icons.person, size: 50, color: context.textSecondary),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _primaryPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.bgColor, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildNameTile(String currentName) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: context.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _saveName(),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingName = true;
                        _nameController.text = currentName;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ИМЯ', style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(currentName, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ),
          IconButton(
            icon: _isSavingName
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryPurple))
                : Icon(_isEditingName ? Icons.check_rounded : Icons.edit_rounded, color: _primaryPurple, size: 20),
            onPressed: _isSavingName ? null : () {
              if (_isEditingName) {
                _saveName();
              } else {
                setState(() {
                  _isEditingName = true;
                  _nameController.text = currentName;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == user.name) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isSavingName = true);

    final success = await SupabaseService().updateUserName(user.id!, newName);
    if (success) {
      await authProvider.refreshCurrentUser();
      if (mounted) {
        setState(() {
          _isEditingName = false;
          _isSavingName = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isSavingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка сохранения'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeAvatar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    // Показываем индикатор загрузки
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: _primaryPurple)),
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final ext = image.path.split('.').last;

      final url = await SupabaseService().uploadAvatar(user.id!, bytes, ext);
      if (url != null) {
        final success = await SupabaseService().updateUserAvatar(user.id!, url);
        if (success) {
          await authProvider.refreshCurrentUser();
          if (mounted) {
            Navigator.pop(context); // Закрываем индикатор
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Аватар обновлен'), backgroundColor: Colors.green),
            );
          }
        } else {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка сохранения ссылки в БД'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка загрузки файла в Storage'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // ==================== ДОСТИЖЕНИЯ ====================

  Widget _buildAchievements(int userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Мои достижения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
        const SizedBox(height: 16),
        StreamBuilder<List<AchievementModel>>(
          stream: _achievementsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _cachedAchievements = snapshot.data;
            }
            final achievements = _cachedAchievements ?? [];
            if (snapshot.connectionState == ConnectionState.waiting && achievements.isEmpty) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: _primaryPurple)));
            }
            if (achievements.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('У вас пока нет достижений', style: TextStyle(color: context.textSecondary))),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildAchievementCard(
                      title: ach.name ?? 'Награда',
                      description: ach.description ?? '',
                      imageUrl: ach.image,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard({required String title, required String description, String? imageUrl}) {
    return GlassContainer(
      width: 180,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: context.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.emoji_events_outlined, color: _primaryPurple, size: 36),
                    )
                  : const Icon(Icons.emoji_events_outlined, color: _primaryPurple, size: 36),
            ),
          ),
          const Spacer(),
          Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 4),
          Text(description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.textSecondary)),
        ],
      ),
    );
  }

  // ==================== СЕРТИФИКАТЫ ====================

  Widget _buildCertificates(int userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Мои сертификаты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
        const SizedBox(height: 16),
        StreamBuilder<List<CertificateModel>>(
          stream: _certificatesStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _cachedCertificates = snapshot.data;
            }
            final certificates = _cachedCertificates ?? [];
            if (snapshot.connectionState == ConnectionState.waiting && certificates.isEmpty) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: _primaryPurple)));
            }
            if (certificates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('У вас пока нет сертификатов', style: TextStyle(color: context.textSecondary))),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: certificates.length,
                itemBuilder: (context, index) {
                  final cert = certificates[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildCertificatePdfCard(context, cert),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCertificatePdfCard(BuildContext context, CertificateModel certificate) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CertificatePdfViewerScreen(
            certificateUrl: certificate.certificateUrl,
            title: certificate.courseName ?? 'Сертификат',
          ),
        ),
      ),
      child: GlassContainer(
        width: 180,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 70, width: 70,
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: context.isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined, color: _primaryPurple, size: 36),
            ),
            const Spacer(),
            Text(
              certificate.courseName ?? 'Сертификат',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    return Column(
      children: [
        // Переключатель темы
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: _primaryPurple,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text('Тёмная тема', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: context.textPrimary)),
              const Spacer(),
              Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: _primaryPurple.withValues(alpha: 0.5),
                activeThumbColor: _primaryPurple,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: context.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.1),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (!_checkingAuthor) ...[
          if (_authorStatus == null)
            _buildMenuItem(
              icon: Icons.assignment_ind_outlined,
              title: 'Стать автором курсов',
              onTap: () => _showBecomeAuthorDialog(user!),
            )
          else if (_authorStatus == false)
            _buildMenuItem(
              icon: Icons.hourglass_empty_rounded,
              title: 'Ждите одобрения',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ждите одобрения')),
                );
              },
            )
          else if (_authorStatus == true)
            _buildMenuItem(
              icon: Icons.school_outlined,
              title: 'Вы — автор курсов',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Работать с курсами можно в настольном приложении.')),
                );
              },
            ),
        ],
        _buildMenuItem(icon: Icons.security_outlined, title: 'Безопасность', onTap: () => _openPdf('assets/pdf/security.pdf', 'Безопасность')),
        _buildMenuItem(icon: Icons.help_outline_rounded, title: 'Помощь', onTap: () => _openPdf('assets/pdf/help.pdf', 'Помощь')),
        _buildMenuItem(icon: Icons.info_outline_rounded, title: 'О приложении', onTap: () => _openPdf('assets/pdf/about.pdf', 'О приложении')),
      ],
    );
  }

  void _openPdf(String assetPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(assetPath: assetPath, title: title),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: _primaryPurple, size: 24),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: context.textPrimary)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: context.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return InkWell(
      onTap: () {
        authProvider.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: Colors.red,
        opacity: context.isDark ? 0.08 : 0.04,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
            SizedBox(width: 10),
            Text('Выйти из аккаунта', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
          ],
        ),
      ),
    );
  }

  void _showBecomeAuthorDialog(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final surnameController = TextEditingController();
    final nameController = TextEditingController();
    final patronymicController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Заявка на автора',
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
                      Text(
                        'Заполните анкету сотрудника-автора для получения доступа к созданию и публикации курсов на платформе.',
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: surnameController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: _buildInputDecoration('Фамилия'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Введите фамилию' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: _buildInputDecoration('Имя'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Введите имя' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: patronymicController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: _buildInputDecoration('Отчество (необязательно)'),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Container(
                        width: double.infinity,
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
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator(color: _primaryPurple)),
                              );
                              
                              final success = await SupabaseService().becomeAuthor(
                                userId: user.id!,
                                name: nameController.text.trim(),
                                surname: surnameController.text.trim(),
                                patronymic: patronymicController.text.trim(),
                                email: user.email!,
                                password: user.password ?? '',
                              );
                              
                              if (mounted) {
                                Navigator.pop(context); // закрыть лоадер
                                Navigator.pop(context); // закрыть bottomsheet
                                
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Вы успешно подали заявку, ждите одобрения'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _checkAuthorStatus(); // Обновить статус на экране
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Произошла ошибка при отправке заявки'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Отправить заявку',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.textSecondary),
      filled: true,
      fillColor: context.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}