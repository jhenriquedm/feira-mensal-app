import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feira_mensal_app/app.dart';

void main() {
  testWidgets('Deve iniciar o aplicativo e exibir a tela inicial', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FeiraMensalApp()));

    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Controle sua feira com inteligência'), findsOneWidget);
  });
}
