import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _passwordVisible = false;
  String? _errorMessage;

  // Константы цветов из дизайна
  static const Color _bgLightGrey = Color(0xFFF8F9FB);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _accentPink = Color(0xFFF2C9D4);

  @override
  void initState() {
    super.initState();
    // Тестовые данные оставляем для удобства
    _emailController.text = 'vergunov06@bk.ru';
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Неверная электронная почта или пароль';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Кастомный AppBar как на картинке
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: _textDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          'Кодикс',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif', // Похоже на Serif шрифт в лого
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (authProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Фиолетовый баннер с "лицом"
                    _buildHeroBanner(),
                    
                    const SizedBox(height: 32),
                    
                    // 2. Заголовок и подзаголовок
                    const Text(
                      'Вход в аккаунт',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Введите свои данные, чтобы продолжить обучение',
                      style: TextStyle(
                        fontSize: 15,
                        color: _textGrey,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 3. Поля ввода (стилизованные)
                    _buildInputLabel('Электронная почта'),
                    _buildEmailField(),
                    
                    const SizedBox(height: 20),
                    
                    _buildInputLabel('Пароль'),
                    _buildPasswordField(),
                    
                    // 4. Забыли пароль?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Забыли пароль?',
                          style: TextStyle(
                            color: _primaryPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    if (_errorMessage != null) _buildErrorMessage(),
                    
                    const SizedBox(height: 24),
                    
                    // 5. Кнопка "Войти" с градиентом и стрелкой
                    _buildLoginButton(),
                    
                    const SizedBox(height: 24),
                    
                    // 6. Ссылка на регистрацию
                    _buildRegisterLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Вспомогательные виджеты ---

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFBCAFFF), // Более светлый фиолетовый сверху
            Color(0xFFA58EFF), // Основной фиолетовый
          ],
        ),
      ),
      child: Stack(
        children: [
          // Белая дуга сверху
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
                ),
              ),
            ),
          ),
          // "Лицо" (глаза и рот)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEye(),
                    const SizedBox(width: 24),
                    _buildEye(),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Текст на баннере
                const Text(
                  'С возвращением!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Продолжай учиться и создавай будущее',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 14,
      height: 24,
      decoration: BoxDecoration(
        color: _textDark,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textDark,
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration({required String hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textGrey, fontSize: 15),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: _bgLightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: _getInputDecoration(
        hint: 'example@mail.ru',
        prefix: const Icon(Icons.email_outlined, color: _textGrey, size: 22),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Введите email';
        if (!value.contains('@')) return 'Введите корректный email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      style: const TextStyle(color: _textDark, fontSize: 15),
      decoration: _getInputDecoration(
        hint: '********',
        prefix: const Icon(Icons.lock_outline, color: _textGrey, size: 22),
        suffix: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: _textGrey,
            size: 22,
          ),
          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Введите пароль';
        if (value.length < 6) return 'Минимум 6 символов';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _primaryPurple,
            _accentPink,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Войти',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Нет аккаунта?',
          style: TextStyle(color: _textGrey, fontSize: 15),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            'Зарегистрироваться',
            style: TextStyle(
              color: _primaryPurple,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}