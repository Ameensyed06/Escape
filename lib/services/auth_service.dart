import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin wrapper around Supabase Auth used by the sign-in / sign-up flows.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  bool get hasVerifiedEmail => currentUser?.emailConfirmedAt != null;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Creates an account with email + password. Supabase sends a
  /// confirmation email automatically (if enabled on the project).
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
      emailRedirectTo: SupabaseConfig.oauthRedirect,
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Opens a browser tab for Google OAuth; the app resumes via deep link
  /// once the user completes sign-in (handled by [onAuthStateChange]).
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.oauthRedirect,
    );
  }

  Future<void> resendConfirmationEmail(String email) {
    return _auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.passwordResetRedirect,
    );
  }

  Future<UserResponse> updatePassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _auth.signOut();
}
