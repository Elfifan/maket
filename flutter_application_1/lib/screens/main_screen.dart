import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'ai_chat_screen.dart';
import 'courses_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;


  final List<Widget> _screens = [
    const CoursesScreen(), 
    const Center(child: Text('Экран Обучения')), 
    const AiChatScreen(),
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack позволяет сохранять состояние экранов при переключении
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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