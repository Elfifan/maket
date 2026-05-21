import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_container.dart';
import 'pdf_viewer_screen.dart';

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
  bool _acceptedTerms = false;
  String? _errorMessage;

  static const Color _primaryPurple = Color(0xFFA58EFF);
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

    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Необходимо принять пользовательское соглашение');
      return;
    }

    setState(() => _errorMessage = null);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final errorMessage = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (errorMessage == null) {
      Navigator.pushReplacementNamed(context, '/courses');
    } else {
      setState(() => _errorMessage = errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            if (auth.isLoading) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 8),
                    Text(
                      'Регистрация',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Создайте аккаунт, чтобы начать свое путешествие в IT',
                      style: TextStyle(fontSize: 15, color: context.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _buildInputLabel('Электронная почта'),
                    _buildEmailField(),
                    const SizedBox(height: 10),
                    _buildInputLabel('Пароль'),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildInputLabel('Подтвердите пароль'),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 12),
                    _buildAgreementCheckbox(),
                    if (_errorMessage != null) _buildErrorMessage(),
                    const SizedBox(height: 16),
                    _buildRegisterButton(),
                    const SizedBox(height: 12),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDark ? Colors.white.withValues(alpha: 0.1) : ThemeProvider.lightTextPrimary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.person_add_alt_1, color: context.isDark ? _primaryPurple : Colors.white, size: 18),
        ),
      ),
      title: Text(
        'Кодикс',
        style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return GlassContainer(
      width: double.infinity,
      height: 220,
      color: _primaryPurple,
      opacity: context.isDark ? 0.2 : 0.75,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: context.isDark ? 0.1 : 0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
                ),
              ),
            ),
          ),
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
                    color: context.isDark ? Colors.white : ThemeProvider.lightTextPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Создай профиль и начни учиться',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildEye() => Container(
    width: 14,
    height: 24,
    decoration: BoxDecoration(
      color: context.isDark ? Colors.white : ThemeProvider.lightTextPrimary,
      borderRadius: BorderRadius.circular(7),
    ),
  );

  Widget _buildInputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4.0, left: 4),
    child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary)),
  );

  InputDecoration _inputStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textSecondary, fontSize: 15),
      prefixIcon: Icon(icon, color: context.textSecondary, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.isDark ? Colors.white.withValues(alpha: 0.05) : context.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: context.isDark ? BorderSide(color: context.borderColor) : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: context.isDark ? BorderSide(color: context.borderColor) : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
      ),
    );
  }

  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    style: TextStyle(color: context.textPrimary, fontSize: 15),
    decoration: _inputStyle('example@mail.ru', Icons.email_outlined),
    keyboardType: TextInputType.emailAddress,
    validator: (v) => (v == null || !v.contains('@')) ? 'Введите корректный email' : null,
  );

  Widget _buildPasswordField() => TextFormField(
    controller: _passwordController,
    obscureText: !_passwordVisible,
    style: TextStyle(color: context.textPrimary, fontSize: 15),
    decoration: _inputStyle('********', Icons.lock_outline, suffix: IconButton(
      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: context.textSecondary, size: 22),
      onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
    )),
    validator: (v) => (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
  );

  Widget _buildConfirmPasswordField() => TextFormField(
    controller: _confirmPasswordController,
    obscureText: !_confirmVisible,
    style: TextStyle(color: context.textPrimary, fontSize: 15),
    decoration: _inputStyle('********', Icons.lock_reset, suffix: IconButton(
      icon: Icon(_confirmVisible ? Icons.visibility : Icons.visibility_off, color: context.textSecondary, size: 22),
      onPressed: () => setState(() => _confirmVisible = !_confirmVisible),
    )),
    validator: (v) => (v == null || v.isEmpty) ? 'Подтвердите пароль' : null,
  );

  Widget _buildRegisterButton() => Container(
    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: context.isDark
            ? [_primaryPurple.withValues(alpha: 0.25), _accentPink.withValues(alpha: 0.15)]
            : [_primaryPurple, _accentPink],
      ),
      border: context.isDark
          ? Border.all(color: Colors.white.withValues(alpha: 0.1))
          : null,
      boxShadow: context.isDark ? null : [BoxShadow(color: _primaryPurple.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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

  Widget _buildLoginLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Уже есть аккаунт?', style: TextStyle(color: context.textSecondary, fontSize: 15)),
      TextButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: const Text('Войти', style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    ],
  );

  Widget _buildAgreementCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() {
              _acceptedTerms = value ?? false;
              if (_acceptedTerms) {
                _errorMessage = null;
              }
            });
          },
          activeColor: _primaryPurple,
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Я принимаю ', style: TextStyle(fontSize: 13, color: context.textPrimary)),
              GestureDetector(
                onTap: _openTermsPdf,
                child: const Text(
                  'пользовательское соглашение',
                  style: TextStyle(
                    fontSize: 13,
                    color: _primaryPurple,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text('.', style: TextStyle(fontSize: 13, color: context.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  void _openTermsPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PdfViewerScreen(
          title: 'Пользовательское соглашение',
          assetPath: 'assets/pdf/sog.pdf',
        ),
      ),
    );
  }

  Widget _buildErrorMessage() => Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
  );
}