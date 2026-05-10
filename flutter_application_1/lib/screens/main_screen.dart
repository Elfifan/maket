import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/auth_provider.dart';
import 'ai_chat_screen.dart';
import 'courses_screen.dart';
import 'profile_screen.dart';
import 'user_chats_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? 0;

    // Все экраны (5 вкладок)
    final List<Widget> screens = [
      const CoursesScreen(),                          // 0 - Каталог
      UserChatsListScreen(userId: userId),            // 2 - Чаты
      const AiChatScreen(),                           // 3 - Чат ИИ
      const ProfileScreen(),                          // 4 - Профиль
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}