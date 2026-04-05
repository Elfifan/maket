import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  String? _errorMessage;

  // Цветовая палитра (ИДЕНТИЧНАЯ окну входа)
  static const Color _bgLightGrey = Color(0xFFF8F9FB);
  static const Color _textDark = Color(0xFF1E1E2E);
  static const Color _textGrey = Color(0xFF9094A6);
  static const Color _primaryPurple = Color(0xFFA58EFF); // Основной фиолетовый
  static const Color _accentPink = Color(0xFFF2C9D4);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Пароли не совпадают');
      return;
    }

    setState(() => _errorMessage = null);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/courses');
    } else {
      setState(() => _errorMessage = 'Ошибка при регистрации. Возможно, email занят.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.isLoading) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ТЕПЕРЬ КАК В ОКНЕ ВХОДА
                    _buildHeroBanner(),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Регистрация',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Создайте аккаунт, чтобы начать свое путешествие в IT',
                      style: TextStyle(fontSize: 15, color: _textGrey, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildInputLabel('Электронная почта'),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    
                    _buildInputLabel('Пароль'),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    
                    _buildInputLabel('Подтвердите пароль'),
                    _buildConfirmPasswordField(),
                    
                    if (_errorMessage != null) _buildErrorMessage(),
                    
                    const SizedBox(height: 32),
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- UI Компоненты ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: BoxDecoration(color: _textDark, borderRadius: BorderRadius.circular(8)),
          // Иконка добавлени пользователя
          child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
        ),
      ),
      title: const Text(
        'Кодикс',
        style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  // ПОЛНОСТЬЮ СКОПИРОВАНО ИЗ LOGIN_SCREEN И ОБНОВЛЕН ТЕКСТ
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 220, // Высота как в логине
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFBCAFFF), // Светло-фиолетовый сверху
            _primaryPurple,    // Основной фиолетовый
          ],
        ),
      ),
      child: Stack(
        children: [
          // Белая дуга сверху (декор из логина)
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
          // "Лицо" (глаза и рот - ИДЕНТИЧНО логину)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEye(),
                    const SizedBox(width: 24), // Отступ из логина
                    _buildEye(),
                  ],
                ),
                const SizedBox(height: 24),
                // Рот-линия (НЕ улыбка, как в логине)
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _textDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Обновленный текст для регистрации
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Создай профиль и начни учиться',
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
      width: 14, // Размер из логина
      height: 24, // Размер из логина
      decoration: BoxDecoration(
        color: _textDark,
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }

  // --- Остальные стили (без изменений, совпадают с логином) ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textDark)),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _textGrey, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: _bgLightGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _inputStyle('example@mail.ru', Icons.email_outlined),
      validator: (v) => (v == null || !v.contains('@')) ? 'Введите корректный email' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_passwordVisible,
      decoration: _inputStyle('********', Icons.lock_outline, suffix: IconButton(
        icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: _textGrey),
        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
      )),
      validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: !_confirmVisible,
      decoration: _inputStyle('********', Icons.lock_reset, suffix: IconButton(
        icon: Icon(_confirmVisible ? Icons.visibility : Icons.visibility_off, color: _textGrey),
        onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
      )),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [_primaryPurple, _accentPink]),
        boxShadow: [BoxShadow(color: _primaryPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        onPressed: _register,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Создать аккаунт', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Уже есть аккаунт?', style: TextStyle(color: _textGrey, fontSize: 15)),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Войти', style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
    );
  }
}