/// Server base URL. Override per build with --dart-define=API_BASE_URL=https://...
/// 10.0.2.2 reaches the host machine from the Android emulator.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.109:3000',
);

/// Web OAuth client ID. Google Sign-In on Android needs it to issue an ID token.
const String googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);
