import 'package:flutter/material.dart';

import '../../data/profile_cache.dart';
import '../auth/auth_repository.dart';
import '../auth/error_messages.dart';
import '../home/home_screen.dart';
import 'profile_screen.dart';

/// Moodle sign-in. Credentials are sent once and held only in these controllers.
class MoodleSignInScreen extends StatefulWidget {
  const MoodleSignInScreen({
    super.key,
    required this.repository,
    required this.onThemeChanged,
  });

  final AuthRepository repository;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<MoodleSignInScreen> createState() => _MoodleSignInScreenState();
}

class _MoodleSignInScreenState extends State<MoodleSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrl = TextEditingController(text: 'https://');
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _siteUrl.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final siteUrl = _siteUrl.text.trim();
    final username = _username.text.trim();
    final password = _password.text;

    try {
      var outcome = await widget.repository.signInWithMoodle(
        siteUrl: siteUrl,
        username: username,
        password: password,
      );

      if (outcome == SignInOutcome.needsProfile) {
        if (!mounted) return;
        final profile = await Navigator.of(context).push<OnboardingProfile>(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(repository: widget.repository),
          ),
        );
        if (profile == null) return;
        outcome = await widget.repository.signInWithMoodle(
          siteUrl: siteUrl,
          username: username,
          password: password,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect Moodle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _siteUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'School Moodle address',
                  hintText: 'https://moodle.example.edu',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.startsWith('https://')
                      ? null
                      : 'Use the full https:// address';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Your password is used once to connect. KLAESP does not store it.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
