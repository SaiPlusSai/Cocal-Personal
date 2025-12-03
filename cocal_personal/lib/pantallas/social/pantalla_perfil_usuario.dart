// lib/pantallas/social/pantalla_perfil_usuario.dart
import 'package:flutter/material.dart';
import '../../servicios/supabase_service.dart';
import '../../servicios/social/amigos_service.dart';
import '../../servicios/social/modelos_amigos.dart';
import '../../servicios/servicio_calendario.dart';
import '../../servicios/temas_interes_service.dart';

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
  bool sonAmigos = false;
  List<TemaInteres> temas = [];

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

      // Verificar si ya son amigos
      final amigos = await AmigosService.sonAmigos(widget.userId);

      // Cargar temas de interés del usuario
      final temasUsuario = await TemasInteresService.obtenerTemasDeUsuario(widget.userId);

      setState(() {
        nombre = usuarioRes['nombre'] ?? '';
        apellido = usuarioRes['apellido'] ?? '';
        correo = usuarioRes['correo'] ?? '';
        fotoUrl = usuarioRes['foto_url'];
        calendarios = cals;
        cantidadAmigos = cant;
        sonAmigos = amigos;
        temas = temasUsuario;
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

  Future<void> _mostrarListaAmigos() async {
    showDialog(
      context: context,
      builder: (context) => _DialogoListaAmigos(userId: widget.userId),
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

              // Temas de interés
              if (temas.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Temas de interés',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: temas.map((tema) {
                    return Chip(
                      label: Text(tema.nombre),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _mostrarListaAmigos,
                    child: Column(
                      children: [
                        Text(
                          '$cantidadAmigos',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('Amigos'),
                      ],
                    ),
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

              // Botón enviar solicitud o mostrar estado de amigos
              SizedBox(
                width: double.infinity,
                child: sonAmigos
                    ? ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Amigos'),
                      onPressed: null, // Deshabilitado porque ya son amigos
                    )
                    : ElevatedButton.icon(
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

class _DialogoListaAmigos extends StatefulWidget {
  final int userId;

  const _DialogoListaAmigos({required this.userId});

  @override
  State<_DialogoListaAmigos> createState() => _DialogoListaAmigosState();
}

class _DialogoListaAmigosState extends State<_DialogoListaAmigos> {
  late Future<List<UsuarioResumen>> _futureAmigos;

  @override
  void initState() {
    super.initState();
    _futureAmigos = AmigosService.obtenerAmigosDeUsuario(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lista de amigos'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<UsuarioResumen>>(
          future: _futureAmigos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final amigos = snapshot.data ?? [];

            if (amigos.isEmpty) {
              return const Center(child: Text('No tiene amigos'));
            }

            return ListView.builder(
              itemCount: amigos.length,
              itemBuilder: (context, index) {
                final amigo = amigos[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${amigo.nombre} ${amigo.apellido}'),
                  subtitle: Text(amigo.correo),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
