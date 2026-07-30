import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:escape/main.dart';

void main() {
  testWidgets('App boots to sign-in screen when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

    await tester.pumpWidget(const EscapeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ESCAPE'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
