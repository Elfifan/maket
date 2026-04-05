import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav.dart'; // Убедитесь, что импорт верный

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Цвета из дизайна
  static const Color _bgLightPurple = Color(0xFFFBF4FF); // Светлый фон верхней карточки
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _iconPurpleBackground = Color(0xFFF5F0FF);

  @override
  Widget build(BuildContext context) {
    // Получаем данные пользователя из провайдера
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Если пользователь не найден (хотя это маловероятно после входа)
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Ошибка данных пользователя')));
    }

    // Извлекаем имя из email (как на макете "Алексей"), если нет поля name в модели
    final userName = user.email?.split('@')[0] ?? 'Пользователь';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Верхний фиолетовый блок с аватаром и именем
              _buildHeaderCard(userName),
              
              const SizedBox(height: 24),
              
              // 2. Поля данных (Имя и Почта)
              _buildInfoTile(
                icon: Icons.person_outline_rounded,
                label: 'ИМЯ',
                value: userName,
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.email_outlined,
                label: 'ЭЛЕКТРОННАЯ ПОЧТА',
                value: user.email ?? 'alex.felix@codix.ru', // Реальный email или заглушка
              ),
              
              const SizedBox(height: 32),
              
              // 3. Блок "Прогресс обучения"
              _buildProgressCard(),
              
              const SizedBox(height: 32),
              
              // 4. Заголовок "Мои курсы" и "Смотреть все"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Мои курсы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Смотреть все',
                      style: TextStyle(color: _primaryPurple, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 5. Горизонтальный список моих курсов (заглушки)
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildMyCourseCard(
                      title: 'Основы дизайна в Figma',
                      progress: 0.75,
                      imagePath: 'lib/assets/images/course_figma.png', // Добавьте картинку в ассеты
                      color: const Color(0xFFB4C8D7), // Фон картинки как на макете
                    ),
                    const SizedBox(width: 16),
                    _buildMyCourseCard(
                      title: 'React: с нуля до профи',
                      progress: 0.32,
                      imagePath: 'lib/assets/images/course_react.png', // Добавьте картинку в ассеты
                      color: const Color(0xFFA79683), // Фон картинки как на макете
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 6. Меню настроек (Уведомления, Конфиденциальность, Помощь)
              _buildSettingsMenu(),
              
              const SizedBox(height: 32),
              
              // 7. Кнопка "Выйти из аккаунта"
              _buildLogoutButton(context, authProvider),
              
              const SizedBox(height: 24),
              
              // 8. Версия приложения
              const Center(
                child: Text(
                  'ВЕРСИЯ ПРИЛОЖЕНИЯ 2.4.0',
                  style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 24), // Отступ снизу для скролла
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Компоненты ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Убираем кнопку назад
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
          // Аватар с иконкой редактирования
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: const AssetImage('lib/assets/images/avatar_felix.png'), // Добавьте в ассеты
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: _primaryPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Имя пользователя (Алексей Феликс на макете, берем из БД)
          Text(
            '$name', // Добавил фамилию как на макете
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textGrey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, color: Color(0xFFE0CFFF), size: 20),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: _primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Прогресс обучения',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '64%',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  '3 из 5 курсов в процессе',
                  style: TextStyle(fontSize: 13, color: _textGrey),
                ),
              ],
            ),
          ),
          // Прогресс бар (круговой)
          SizedBox(
            height: 70,
            width: 70,
            child: Stack(
              children: [
                const Center(
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: 0.64,
                      strokeWidth: 8,
                      backgroundColor: Color(0xFFEAE0FF),
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: const BoxDecoration(color: _primaryPurple, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCourseCard({required String title, required double progress, required String imagePath, required Color color}) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Картинка курса с прогрессом
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                    child: Text(
                      '${(progress * 100).toInt()}% пройдено',
                      style: const TextStyle(color: _textDark, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Название
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark, height: 1.2),
            ),
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
          const Divider(height: 1, indent: 60),
          _buildSettingsTile(Icons.verified_user_outlined, 'Конфиденциальность'),
          const Divider(height: 1, indent: 60),
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
          // Выход из аккаунта
          authProvider.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5F6F8), // Серый фон как на макете
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