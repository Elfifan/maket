import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/courses_screen.dart';

import 'dart:ui';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            scrollBehavior: MyCustomScrollBehavior(),
            debugShowCheckedModeBanner: false,
            title: 'Кодикс',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            navigatorObservers: [routeObserver],
            home: const InitialScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const MainScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/courses': (context) => const CoursesScreen(),
            },
          );
        },
      ),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});
  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return authProvider.isLoggedIn
            ? const MainScreen()
            : const OnboardingScreen();
      },
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
