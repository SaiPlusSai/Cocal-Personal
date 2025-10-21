import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocal_personal/app.dart'; // 👈 en vez de main.dart

void main() {
  testWidgets('Carga inicial de CoCal', (WidgetTester tester) async {
    await tester.pumpWidget(const AplicacionCoCal());
    expect(find.text('Bienvenido a CoCal 🎉'), findsOneWidget);
  });
}
