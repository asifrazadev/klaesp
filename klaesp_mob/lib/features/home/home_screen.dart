import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';
import '../onboarding/sign_in_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.onThemeChanged,
  });

  final AuthRepository repository;
  final ValueChanged<ThemeMode> onThemeChanged;

  Future<void> _signOut(BuildContext context) async {
    await repository.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SignInScreen(
          repository: repository,
          onThemeChanged: onThemeChanged,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KLAESP'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => onThemeChanged(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Your deadlines will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Replaces the navigation stack with the home screen after a successful sign-in.
void openHome(
  BuildContext context,
  AuthRepository repository,
  ValueChanged<ThemeMode> onThemeChanged,
) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => HomeScreen(
        repository: repository,
        onThemeChanged: onThemeChanged,
      ),
    ),
    (_) => false,
  );
}
