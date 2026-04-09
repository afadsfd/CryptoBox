// Basic smoke test for CryptoFolio app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CryptoFolioApp(),
      ),
    );

    // App should render without crashing
    await tester.pump();
  });
}
