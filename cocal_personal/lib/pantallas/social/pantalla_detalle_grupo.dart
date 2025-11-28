//lib/pantallas/social/pantalla_detalle_grupo.dart
import 'package:flutter/material.dart';
import '../../servicios/social/grupos_service.dart';
import 'pantalla_invitar_amigos_grupo.dart';
import 'pantalla_miembros_grupo.dart';
import 'foro/pantalla_foro_grupo.dart';
import '../../servicios/social/modelos_grupo.dart';
import '../calendario/pantalla_eventos_calendario.dart';
import '../../servicios/calendario/servicio_calendario.dart';

class PantallaDetalleGrupo extends StatefulWidget {
  final GrupoResumen grupo;

  const PantallaDetalleGrupo({super.key, required this.grupo});

  @override
  State<PantallaDetalleGrupo> createState() => _PantallaDetalleGrupoState();
}

class _PantallaDetalleGrupoState extends State<PantallaDetalleGrupo> {
  bool _cargandoMiembros = true;
  List<MiembroGrupo> _miembros = [];

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
  }

  Future<void> _cargarMiembros() async {
    setState(() => _cargandoMiembros = true);
    final res = await GruposService.obtenerMiembros(widget.grupo.id);
    if (!mounted) return;
    setState(() {
      _miembros = res;
      _cargandoMiembros = false;
    });
  }

  Future<void> _salir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text('¿Seguro que quieres salir de este grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final err = await GruposService.salirDeGrupo(widget.grupo.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saliste del grupo')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grupo;

    return Scaffold(
      appBar: AppBar(
        title: Text(g.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invitar amigos',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaInvitarAmigosAGrupo(grupo: g),
                ),
              );

              if (added == true) {
                _cargarMiembros(); // tu función para recargar miembros
              }
            },
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g.descripcion ?? 'Sin descripción',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Visibilidad: ${g.visibilidad}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: 8),
                    Text(
                      'Miembros',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaMiembrosGrupo(grupo: widget.grupo),
                      ),
                    );
                  },
                  child: const Text("Administrar"),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaForoGrupo(grupo: widget.grupo),
                    ),
                  );
                },
                icon: const Icon(Icons.forum),
                label: const Text('Ir al foro del grupo'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final g = widget.grupo;

                  final calGrupo =
                  await ServicioCalendario.obtenerOCrearCalendarioDeGrupo(
                    g.id,
                    nombre: 'Calendario – ${g.nombre}',
                  );

                  if (!mounted) return;

                  if (calGrupo == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'No se pudo obtener el calendario del grupo'),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaEventosCalendario(
                        idCalendario: calGrupo.id,
                        nombreCalendario: calGrupo.nombre,
                        idGrupo: g.id, // 👈 importante para coincidencias
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Ver calendario del grupo'),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _cargandoMiembros
                  ? const Center(child: CircularProgressIndicator())
                  : _miembros.isEmpty
                  ? const Center(child: Text('Este grupo no tiene miembros'))
                  : RefreshIndicator(
                onRefresh: _cargarMiembros,
                child: ListView.builder(
                  itemCount: _miembros.length,
                  itemBuilder: (_, i) {
                    final m = _miembros[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(m.nombreCompleto),
                      subtitle: Text(
                          'Rol: ${m.rol} · Estado: ${m.estado}'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (g.rol != 'DUENO') // dueño no puede salir con esta acción
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _salir,
                  icon: const Icon(Icons.logout),
                  label: const Text('Salir del grupo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),

    );

  }
}
