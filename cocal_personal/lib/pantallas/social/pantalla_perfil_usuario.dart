// lib/pantallas/social/pantalla_perfil_usuario.dart
import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';
import '../../servicios/social/amigos_service.dart';
import '../../servicios/servicio_calendario.dart';

class PantallaPerfilUsuario extends StatefulWidget {
  final int userId;

  const PantallaPerfilUsuario({super.key, required this.userId});

  @override
  State<PantallaPerfilUsuario> createState() => _PantallaPerfilUsuarioState();
}

class _PantallaPerfilUsuarioState extends State<PantallaPerfilUsuario> {
  String nombre = '';
  String apellido = '';
  String correo = '';
  String? fotoUrl;
  int cantidadAmigos = 0;
  List<Map<String, dynamic>> calendarios = [];

  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar perfil del usuario
      final cliente = SupabaseService.cliente;
      final usuarioRes = await cliente
          .from('usuario')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (usuarioRes == null) {
        setState(() {
          error = 'Usuario no encontrado';
          cargando = false;
        });
        return;
      }

      // Cargar calendarios públicos del usuario
      final cals = await ServicioCalendario.listarCalendariosDeUsuario(widget.userId);

      // Contar amigos usando el nuevo método
      final cant = await AmigosService.contarAmigos(widget.userId);

      setState(() {
        nombre = usuarioRes['nombre'] ?? '';
        apellido = usuarioRes['apellido'] ?? '';
        correo = usuarioRes['correo'] ?? '';
        fotoUrl = usuarioRes['foto_url'];
        calendarios = cals;
        cantidadAmigos = cant;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar perfil: $e';
        cargando = false;
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    final resultado = await AmigosService.enviarSolicitud(idDestinatario: widget.userId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado ?? 'Solicitud de amistad enviada'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(child: Text(error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de usuario'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundImage: fotoUrl != null
                    ? NetworkImage('$fotoUrl?v=${DateTime.now().millisecondsSinceEpoch}')
                    : null,
                child: fotoUrl == null ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                '$nombre $apellido',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Correo
              Text(correo, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '$cantidadAmigos',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text('Amigos'),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${calendarios.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text('Calendarios'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón enviar solicitud
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Enviar solicitud de amistad'),
                  onPressed: _enviarSolicitud,
                ),
              ),
              const SizedBox(height: 24),

              // Calendarios públicos
              if (calendarios.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Calendarios públicos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarios.length,
                  itemBuilder: (context, i) {
                    final cal = calendarios[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(cal['nombre'] ?? 'Calendario'),
                        subtitle: Text(cal['zona_horaria'] ?? 'N/A'),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No hay calendarios públicos'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
