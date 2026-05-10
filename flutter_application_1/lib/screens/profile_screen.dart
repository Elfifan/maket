
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/certificate_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
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

  static const Color _bgLightPurple = Color(0xFFFBF4FF);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _iconPurpleBackground = Color(0xFFF5F0FF);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: const Text('Профиль', style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
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
              const Center(
                child: Text('ВЕРСИЯ ПРИЛОЖЕНИЯ 2.4.0',
                    style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(32),
      ),
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
                    color: Colors.grey[200],
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
                                const Icon(Icons.person, size: 50, color: _textGrey),
                          )
                        : const Icon(Icons.person, size: 50, color: _textGrey),
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
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
        ],
      ),
    );
  }

  Widget _buildNameTile(String currentName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: _textGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
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
                        const Text('ИМЯ', style: TextStyle(color: _textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(currentName, style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600)),
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
        const Text('Мои достижения', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        FutureBuilder<List<AchievementModel>>(
          future: SupabaseService().getUserAchievements(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: _primaryPurple)));
            }
            final achievements = snapshot.data ?? [];
            if (achievements.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('У вас пока нет достижений', style: TextStyle(color: _textGrey))),
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
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: _iconPurpleBackground,
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
          Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 4),
          Text(description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _textGrey)),
        ],
      ),
    );
  }

  // ==================== СЕРТИФИКАТЫ ====================

  Widget _buildCertificates(int userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Мои сертификаты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
        const SizedBox(height: 16),
        FutureBuilder<List<CertificateModel>>(
          future: SupabaseService().getUserCertificates(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: _primaryPurple)));
            }
            final certificates = snapshot.data ?? [];
            if (certificates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('У вас пока нет сертификатов', style: TextStyle(color: _textGrey))),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CertificatePdfViewerScreen(certificateUrl: certificate.certificateUrl, title: 'Сертификат'))),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Column(
          children: [
            Container(height: 70, width: 70, decoration: BoxDecoration(color: _iconPurpleBackground, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.picture_as_pdf_outlined, color: _primaryPurple, size: 36)),
            const Spacer(),
            const Text('Сертификат', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Column(
      children: [
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Row(
          children: [
            Icon(icon, color: _primaryPurple, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _textDark)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: _textGrey, size: 16),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEEEEEE))),
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
}