import 'package:feira_mensal_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: FeiraMensalApp()));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('Deve iniciar o aplicativo e exibir a tela de login', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Feira Mensal'), findsOneWidget);
    expect(find.text('Entrar na conta'), findsOneWidget);
    expect(find.text('Dados de acesso'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Ainda não possui uma conta?'), findsOneWidget);
    expect(find.text('Criar cadastro'), findsOneWidget);
  });

  testWidgets('Deve alternar da tela de login para cadastro', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    final createAccountButton = find.text('Criar cadastro');

    await tester.ensureVisible(createAccountButton);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(createAccountButton);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Dados do cadastro'), findsOneWidget);
    expect(find.text('Cadastrar'), findsOneWidget);
    expect(find.text('Já possui uma conta cadastrada?'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });
}
