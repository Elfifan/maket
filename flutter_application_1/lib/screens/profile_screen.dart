import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Константы стилей
  static const Color _bgLightPurple = Color(0xFFFBF4FF);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _iconPurpleBackground = Color(0xFFF5F0FF);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Ошибка данных пользователя')),
      );
    }

    final userName = user.name ?? user.email?.split('@')[0] ?? 'Пользователь';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(userName),
              const SizedBox(height: 24),
              _buildInfoTile(
                icon: Icons.person_outline_rounded,
                label: 'ИМЯ',
                value: userName,
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.email_outlined,
                label: 'ЭЛЕКТРОННАЯ ПОЧТА',
                value: user.email ?? 'example@codix.ru',
              ),
              const SizedBox(height: 24),
              _buildProgressCard(),
              const SizedBox(height: 32),
              
              // Заголовок блока достижений
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Мои достижения',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: _textDark
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Смотреть все',
                      style: TextStyle(
                        color: _primaryPurple, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Динамический список достижений
              FutureBuilder<List<AchievementModel>>(
                future: SupabaseService().getUserAchievements(user.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator(color: _primaryPurple)),
                    );
                  }

                  final achievements = snapshot.data ?? [];

                  if (achievements.isEmpty) {
                    return const Text(
                      'У вас пока нет достижений',
                      style: TextStyle(color: _textGrey),
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
                            bytes: ach.imageBytes,
                            color: _iconPurpleBackground,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              _buildSettingsMenu(),
              const SizedBox(height: 32),
              _buildLogoutButton(context, authProvider),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'ВЕРСИЯ ПРИЛОЖЕНИЯ 2.4.0',
                  style: TextStyle(
                    color: _textGrey, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 24,
      title: const Text(
        'Профиль',
        style: TextStyle(color: _textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  Widget _buildHeaderCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
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
          Icon(icon, color: _textGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, color: Color(0xFFE0CFFF), size: 18),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgLightPurple,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Прогресс обучения',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                ),
                SizedBox(height: 12),
                Text(
                  '64%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
              value: 0.64,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFEAE0FF),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildAchievementCard({
    required String title,
    required String description,
    Uint8List? bytes, 
    required Color color,
  }) {
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
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),

              child: bytes != null 
                  ? Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.emoji_events_outlined, color: _primaryPurple),
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _textGrey, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.notifications_none_rounded, 'Уведомления'),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          _buildSettingsTile(Icons.verified_user_outlined, 'Конфиденциальность'),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          _buildSettingsTile(Icons.help_outline_rounded, 'Помощь'),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: _iconPurpleBackground, shape: BoxShape.circle),
        child: Icon(icon, color: _primaryPurple, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: _textGrey, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          authProvider.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F6F8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
            SizedBox(width: 10),
            Text(
              'Выйти из аккаунта',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)),
            ),
          ],
        ),
      ),
    );
  }
}