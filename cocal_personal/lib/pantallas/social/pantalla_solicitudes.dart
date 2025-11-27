// lib/pantallas/social/pantalla_solicitudes.dart
import 'package:flutter/material.dart';
import '../../servicios/social/amigos_service.dart';
import '../../servicios/social/modelos_amigos.dart';

class PantallaSolicitudes extends StatefulWidget {
  const PantallaSolicitudes({super.key});

  @override
  State<PantallaSolicitudes> createState() => _PantallaSolicitudesState();
}

class _PantallaSolicitudesState extends State<PantallaSolicitudes> {
  bool _cargando = true;
  List<SolicitudAmistad> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await AmigosService.obtenerSolicitudesRecibidas();
    if (!mounted) return;
    setState(() {
      _solicitudes = res;
      _cargando = false;
    });
  }

  Future<void> _responder(SolicitudAmistad s, bool aceptar) async {
    final err = await AmigosService.responderSolicitud(
      idSolicitud: s.id,
      aceptar: aceptar,
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceptar
                ? 'Ahora eres amigo de ${s.nombreRemitente}'
                : 'Solicitud rechazada',
          ),
        ),
      );
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de amistad'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _solicitudes.isEmpty
          ? const Center(child: Text('No tienes solicitudes pendientes'))
          : RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          itemCount: _solicitudes.length,
          itemBuilder: (_, i) {
            final s = _solicitudes[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(s.nombreRemitente),
                subtitle: Text(
                  'Te envió una solicitud el ${s.creadaEn.toLocal()}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: scheme.error),
                      onPressed: () => _responder(s, false),
                    ),
                    IconButton(
                      icon: Icon(Icons.check_circle,
                          color: scheme.primary),
                      onPressed: () => _responder(s, true),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
