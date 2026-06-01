import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
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
    final isDark = context.isDark;

    final List<Widget> screens = [
      const CoursesScreen(),
      UserChatsListScreen(userId: userId),
      const AiChatScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ThemeProvider.primaryPurple.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ThemeProvider.accentPink.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: MediaQuery.of(context).size.width * 0.3,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C63FF).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          IndexedStack(index: _selectedIndex, children: screens),
        ],
      ),
      extendBody: true,
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
