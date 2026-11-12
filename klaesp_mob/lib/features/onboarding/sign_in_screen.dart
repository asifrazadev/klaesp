import 'package:flutter/material.dart';

import '../../data/profile_cache.dart';
import '../auth/auth_repository.dart';
import '../auth/error_messages.dart';
import '../auth/google_sign_in_service.dart';
import '../home/home_screen.dart';
import 'moodle_sign_in_screen.dart';
import 'profile_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.repository,
    required this.onThemeChanged,
  });

  final AuthRepository repository;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _google = GoogleSignInService();
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final idToken = await _google.signInAndGetIdToken();
      if (idToken == null) return; // cancelled

      var outcome = await widget.repository.signInWithGoogle(idToken: idToken);

      if (outcome == SignInOutcome.needsProfile) {
        if (!mounted) return;
        final profile = await Navigator.of(context).push<OnboardingProfile>(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(repository: widget.repository),
          ),
        );
        if (profile == null) return;
        outcome = await widget.repository.signInWithGoogle(
          idToken: idToken,
          profile: profile,
        );
      }

      if (mounted && outcome == SignInOutcome.signedIn) {
        openHome(context, widget.repository, widget.onThemeChanged);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messageFor(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openMoodle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MoodleSignInScreen(
          repository: widget.repository,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'KLAESP',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Courses, deadlines and notices in one place.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: _busy ? null : _openMoodle,
                child: const Text('Continue with Moodle'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _signInWithGoogle,
                child: const Text('Continue with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
