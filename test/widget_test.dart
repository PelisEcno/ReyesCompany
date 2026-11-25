import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('La app muestra la pantalla de carga y luego el login', (WidgetTester tester) async {
    await tester.pumpWidget(const ReyesCompanyApp());

    expect(find.text('ReyesCompany'), findsOneWidget);
    expect(find.text('Sistema de Inventario y Ventas'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
