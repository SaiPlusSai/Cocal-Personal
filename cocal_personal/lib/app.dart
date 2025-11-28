import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rutas/rutas_app.dart';
import 'utils/navigation.dart';
import 'proveedores/proveedor_autenticacion.dart';

class AplicacionCoCal extends StatelessWidget {
  const AplicacionCoCal({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProveedorAutenticacion()),
      ],
      child: MaterialApp(
        title: 'CoCal',
        debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/inicio',
        routes: obtenerRutas(),
      ),
    );
  }
}
