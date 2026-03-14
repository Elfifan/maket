import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 4; 

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: 
        break;
      case 1: 
        Navigator.pushNamed(context, '/courses');
        break;
      case 2: 
        break;
      case 3:
        break;
      case 4: 
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            tooltip: 'Курсы',
            onPressed: () {
              Navigator.pushNamed(context, '/courses');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Text(
                        '😊', 
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      user.email ?? 'Пользователь',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge,
                        label: 'ID пользователя',
                        value: '${user.id ?? "N/A"}',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email ?? 'Не указан',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Дата регистрации',
                        value: user.dateRegistration != null
                            ? DateFormat('dd.MM.yyyy').format(user.dateRegistration!)
                            : 'Не указана',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.login,
                        label: 'Последний вход',
                        value: user.lastEntry != null
                            ? DateFormat('dd.MM.yyyy HH:mm').format(user.lastEntry!)
                            : 'Только что',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.verified_user,
                        label: 'Статус',
                        value: user.status == true ? 'Активен' : 'Неактивен',
                        valueColor: user.status == true ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFFF6B6B),
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 18,
                        color: Color(0xFFFF6B6B),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Выйти из аккаунта',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: const Color(0xFF9094A6),
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Дом'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Курсы'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Сообщения'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Аккаунт'),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF666666),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}