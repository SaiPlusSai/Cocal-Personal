import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocal_personal/main.dart';

void main() {
  testWidgets('Carga inicial de CoCal', (WidgetTester tester) async {
    // Construir la aplicación y renderizar el primer frame.
    await tester.pumpWidget(const AplicacionCoCal());

    // Verificar que aparezca el texto de bienvenida.
    expect(find.text('Bienvenido a CoCal 🎉'), findsOneWidget);
  });
}
