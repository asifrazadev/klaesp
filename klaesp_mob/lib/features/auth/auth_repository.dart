import '../../data/api_client.dart';
import '../../data/profile_cache.dart';
import '../../data/session_store.dart';

enum SignInOutcome {
  /// Session saved. The app can go to the home screen.
  signedIn,

  /// No account exists for this identity. Collect the profile, then retry with it.
  needsProfile,
}

/// Coordinates the server API, secure token storage and the local profile cache.
class AuthRepository {
  AuthRepository({
    ApiClient? api,
    SessionStore? sessions,
    ProfileCache? profiles,
  }) {
    _api = api ?? ApiClient();
    _sessions = sessions ?? SessionStore();
    _profiles = profiles ?? ProfileCache();
  }

  late final ApiClient _api;
  late final SessionStore _sessions;
  late final ProfileCache _profiles;

  Future<bool> hasSession() async => (await _sessions.sessionToken()) != null;

  Future<OnboardingProfile?> cachedProfile() => _profiles.load();

  Future<void> saveProfile(OnboardingProfile profile) => _profiles.save(profile);

  /// Moodle credentials are used for this one request and never stored.
  Future<SignInOutcome> signInWithMoodle({
    required String siteUrl,
    required String username,
    required String password,
    OnboardingProfile? profile,
  }) async {
    try {
      final json = await _api.post('/api/auth/moodle', {
        'site_url': siteUrl,
        'username': username,
        'password': password,
        if (profile != null) 'profile': profile.toApiJson(),
      });
      await _saveSession(json);
      return SignInOutcome.signedIn;
    } on ApiException catch (e) {
      if (e.code == 'no_account') return SignInOutcome.needsProfile;
      rethrow;
    }
  }

  Future<SignInOutcome> signInWithGoogle({
    required String idToken,
    OnboardingProfile? profile,
  }) async {
    try {
      final json = await _api.post('/api/auth/google', {
        'id_token': idToken,
        if (profile != null) 'profile': profile.toApiJson(),
      });
      await _saveSession(json);
      return SignInOutcome.signedIn;
    } on ApiException catch (e) {
      if (e.code == 'no_account') return SignInOutcome.needsProfile;
      rethrow;
    }
  }

  /// Revokes the session on the server when possible, then always clears local tokens.
  Future<void> signOut() async {
    try {
      await _api.post(
        '/api/auth/logout',
        {},
        sessionToken: await _sessions.sessionToken(),
      );
    } catch (_) {
      // Logging out must work offline too. The server session expires on its own.
    } finally {
      await _sessions.clear();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> json) async {
    await _sessions.save(
      sessionToken: json['session_token'] as String,
      moodleToken: json['moodle_token'] as String?,
    );
    // The profile now lives on the server, so the local copy is removed.
    await _profiles.clear();
  }
}
