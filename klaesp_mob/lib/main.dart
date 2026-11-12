import 'package:flutter/material.dart';

import 'features/auth/auth_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/sign_in_screen.dart';
import 'theme/klaesp_theme.dart';

void main() {
  runApp(const KlaespApp());
}

class KlaespApp extends StatefulWidget {
  const KlaespApp({super.key});

  @override
  State<KlaespApp> createState() => _KlaespAppState();
}

class _KlaespAppState extends State<KlaespApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final _repository = AuthRepository();

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KLAESP',
      theme: KlaespTheme.light(),
      darkTheme: KlaespTheme.dark(),
      themeMode: _themeMode,
      home: _StartScreen(
        repository: _repository,
        onThemeChanged: _setThemeMode,
      ),
    );
  }
}

/// Opens the home screen when a session exists, otherwise the sign-in screen.
class _StartScreen extends StatefulWidget {
  const _StartScreen({required this.repository, required this.onThemeChanged});

  final AuthRepository repository;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  late final Future<bool> _hasSession = widget.repository.hasSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!) {
          return HomeScreen(
            repository: widget.repository,
            onThemeChanged: widget.onThemeChanged,
          );
        }
        return SignInScreen(
          repository: widget.repository,
          onThemeChanged: widget.onThemeChanged,
        );
      },
    );
  }
}
