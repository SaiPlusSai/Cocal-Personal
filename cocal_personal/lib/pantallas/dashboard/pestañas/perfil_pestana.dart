import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../proveedores/proveedor_autenticacion.dart';

class PerfilPestana extends StatelessWidget {
  const PerfilPestana({super.key});

  @override
  Widget build(BuildContext context) {
    final proveedor = Provider.of<ProveedorAutenticacion>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 10),
          Text(proveedor.correoUsuario ?? 'Sin sesión'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () => proveedor.cerrarSesion(),
          ),
        ],
      ),
    );
  }
}
