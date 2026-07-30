/// Supabase project configuration.
///
/// Fill these in once the Supabase project is created:
/// - [supabaseUrl]: Project Settings -> API -> Project URL
/// - [supabaseAnonKey]: Project Settings -> API -> Project API keys -> anon/public
///
/// The anon key is safe to ship in a client app — it is designed to be
/// public and is enforced by Row Level Security policies on each table.
/// Never put the service_role key in client code.
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT-REF.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY',
  );

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-REF') && !supabaseAnonKey.contains('YOUR-ANON-KEY');

  /// Deep-link scheme used to return to the app after OAuth (Google) sign-in
  /// and after tapping the "reset password" link in an email.
  ///
  /// Must be added:
  /// - As a redirect URL in Supabase: Authentication -> URL Configuration
  ///   -> Redirect URLs, add both:
  ///     io.escape.app://login-callback/
  ///     io.escape.app://reset-callback/
  /// - As an intent-filter in android/app/src/main/AndroidManifest.xml
  ///   (already configured for this scheme).
  static const String oauthRedirect = 'io.escape.app://login-callback/';
  static const String passwordResetRedirect = 'io.escape.app://reset-callback/';
}
