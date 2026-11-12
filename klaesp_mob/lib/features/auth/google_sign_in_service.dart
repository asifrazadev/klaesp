import 'package:google_sign_in/google_sign_in.dart';

import '../../config/api_config.dart';

/// Gets a Google ID token on the device. Google tokens never leave the device except as this ID token.
class GoogleSignInService {
  GoogleSignInService() {
    _google = GoogleSignIn(
      scopes: const ['email', 'openid'],
      serverClientId:
          googleServerClientId.isEmpty ? null : googleServerClientId,
    );
  }

  late final GoogleSignIn _google;

  /// Returns the ID token, or null if the user cancelled.
  Future<String?> signInAndGetIdToken() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }
}
