/// Stage 1 details, held in memory until the first sign-in succeeds.
class OnboardingProfile {
  const OnboardingProfile({
    required this.fullName,
    required this.email,
    this.studentId,
  });

  final String fullName;
  final String email;
  final String? studentId;

  Map<String, dynamic> toApiJson() {
    final id = studentId;
    return {
      'full_name': fullName,
      'email': email,
      if (id != null && id.isNotEmpty) 'student_id': id,
    };
  }
}

/// Keeps the profile in memory. It is cleared once sign-in succeeds, and never holds passwords or tokens.
class ProfileCache {
  OnboardingProfile? _profile;

  Future<OnboardingProfile?> load() async => _profile;

  Future<void> save(OnboardingProfile profile) async => _profile = profile;

  Future<void> clear() async => _profile = null;
}
