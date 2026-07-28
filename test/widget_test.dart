import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestion_locative/main.dart';

void main() {
  // flutter_secure_storage talks to the platform over a MethodChannel that
  // has no handler in widget tests; mock it so reads resolve to "no token
  // stored" instead of the call hanging forever.
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (call) async => null);

  testWidgets('App boots, restores session (none stored) and lands on Login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GestionLocativeApp()));

    // Splash screen first, with its indeterminate spinner (pumpAndSettle
    // never resolves while it's on screen, so we pump bounded frames
    // instead of settling).
    await tester.pump();
    expect(find.text('Gestion Locative'), findsOneWidget);

    // No token stored (no platform channel in tests) -> bootstrap()
    // resolves to unauthenticated -> router redirects to /login. The
    // splash's indeterminate spinner keeps animating, so we pump a
    // bounded number of frames instead of pumpAndSettle().
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Connexion'), findsOneWidget);
  });
}
