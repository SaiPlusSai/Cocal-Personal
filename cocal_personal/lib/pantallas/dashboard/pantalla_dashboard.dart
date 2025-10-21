import 'package:flutter/material.dart';
import '../../proveedores/proveedor_autenticacion.dart';
import 'pestañas/calendario_pestana.dart';
import 'pestañas/grupos_pestana.dart';
import 'pestañas/foro_pestana.dart';
import 'pestañas/perfil_pestana.dart';
import '../../widgets/barra_navegacion.dart';
import 'package:provider/provider.dart';

class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key});

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  int _indiceActual = 0;

  final List<Widget> _pestanas = const [
    CalendarioPestana(),
    GruposPestana(),
    ForoPestana(),
    PerfilPestana(),
  ];

  @override
  Widget build(BuildContext context) {
    final proveedor = Provider.of<ProveedorAutenticacion>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${proveedor.correoUsuario ?? 'Usuario'}'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _indiceActual,
        children: _pestanas,
      ),
      bottomNavigationBar: BarraNavegacion(
        indice: _indiceActual,
        onTap: (i) => setState(() => _indiceActual = i),
      ),
    );
  }
}
