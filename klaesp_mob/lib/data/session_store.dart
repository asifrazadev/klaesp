import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens live only here, in the platform's secure storage (Keychain or Keystore).
class SessionStore {
  SessionStore({FlutterSecureStorage? storage}) {
    _storage = storage ?? const FlutterSecureStorage();
  }

  late final FlutterSecureStorage _storage;

  static const _sessionKey = 'klaesp.session_token';
  static const _moodleKey = 'klaesp.moodle_token';

  Future<String?> sessionToken() => _storage.read(key: _sessionKey);

  Future<void> save({required String sessionToken, String? moodleToken}) async {
    await _storage.write(key: _sessionKey, value: sessionToken);
    if (moodleToken != null) {
      await _storage.write(key: _moodleKey, value: moodleToken);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _moodleKey);
  }
}
