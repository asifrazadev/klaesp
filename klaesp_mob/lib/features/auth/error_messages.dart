import '../../data/api_client.dart';

/// Turns an error into text for the student. Codes come from the server's error table.
String messageFor(Object error) {
  if (error is NetworkException) {
    return 'No connection. Check your internet and try again.';
  }
  if (error is ApiException) {
    switch (error.code) {
      case 'invalid_site_url':
        return 'That school address is not valid. Use the full https:// address.';
      case 'site_unreachable':
        return "Your school's system cannot be reached right now. Try again later.";
      case 'moodle_invalid_credentials':
        return 'Username or password is incorrect.';
      case 'moodle_webservice_disabled':
        return 'Your school has not enabled mobile access. Contact your administrator.';
      case 'moodle_sso_required':
        return 'Your school uses single sign-on, which is not supported yet.';
      case 'moodle_token_invalid':
        return 'Your school session has expired. Sign in with Moodle again.';
      case 'email_in_use':
        return 'This email already belongs to another account. Sign in to that account and connect this one from settings.';
      case 'google_token_invalid':
        return 'Google sign-in could not be verified. Try again.';
      case 'session_invalid':
        return 'Your session has ended. Please sign in again.';
      case 'already_connected':
        return 'This account is already connected.';
      case 'moodle_account_linked_elsewhere':
      case 'google_account_linked_elsewhere':
        return 'This account is linked to a different KLAESP user. Accounts are not merged.';
      default:
        return 'Something went wrong. Try again.';
    }
  }
  return 'Something went wrong. Try again.';
}
