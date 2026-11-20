import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('TaskFlow launches on its splash screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Explore Tour'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.theme?.textTheme.bodyMedium?.fontFamily, 'Inter');
  });
}
