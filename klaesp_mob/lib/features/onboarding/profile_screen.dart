import 'package:flutter/material.dart';

import '../../data/profile_cache.dart';
import '../auth/auth_repository.dart';

/// Stage 1: basic details. Saved on the device, then returned to the caller.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.repository.cachedProfile().then((cached) {
      if (cached == null || !mounted) return;
      _name.text = cached.fullName;
      _email.text = cached.email;
      _studentId.text = cached.studentId ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final studentId = _studentId.text.trim();
    final profile = OnboardingProfile(
      fullName: _name.text.trim(),
      email: _email.text.trim().toLowerCase(),
      studentId: studentId.isEmpty ? null : studentId,
    );
    try {
      await widget.repository.saveProfile(profile);
      if (mounted) Navigator.of(context).pop(profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your details')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return (value.contains('@') && value.contains('.'))
                      ? null
                      : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Student ID (optional)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _continue,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
