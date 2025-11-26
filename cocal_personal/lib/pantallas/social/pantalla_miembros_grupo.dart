import 'package:flutter/material.dart';
import '../../servicios/social/grupos_service.dart';

class PantallaMiembrosGrupo extends StatefulWidget {
  final GrupoResumen grupo;

  const PantallaMiembrosGrupo({
    super.key,
    required this.grupo,
  });

  @override
  State<PantallaMiembrosGrupo> createState() => _PantallaMiembrosGrupoState();
}

class _PantallaMiembrosGrupoState extends State<PantallaMiembrosGrupo> {
  bool _cargando = true;
  bool _esAdmin = false;
  List<MiembroGrupo> _miembros = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    final esAdmin = await GruposService.esAdminDeGrupo(widget.grupo.id);
    final miembros = await GruposService.obtenerMiembros(widget.grupo.id);

    if (!mounted) return;
    setState(() {
      _esAdmin = esAdmin;
      _miembros = miembros;
      _cargando = false;
    });
  }

  Future<void> _salirDelGrupo() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: Text(
            '¿Seguro que quieres salir del grupo "${widget.grupo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    final err = await GruposService.salirDeGrupo(widget.grupo.id);
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Has salido del grupo')),
    );
    Navigator.pop(context); // Volver a la lista de grupos
  }

  Future<void> _cambiarRol(MiembroGrupo m, String nuevoRol) async {
    final err = await GruposService.cambiarRolMiembro(
      idPerfilGrupo: m.idPerfilGrupo,
      nuevoRol: nuevoRol,
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rol de ${m.nombreCompleto} actualizado a $nuevoRol'),
        ),
      );
      _cargar();
    }
  }

  Future<void> _cambiarEstado(MiembroGrupo m, String nuevoEstado) async {
    final err = await GruposService.cambiarEstadoMiembro(
      idPerfilGrupo: m.idPerfilGrupo,
      nuevoEstado: nuevoEstado,
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Estado de ${m.nombreCompleto} cambiado a $nuevoEstado'),
        ),
      );
      _cargar();
    }
  }

  Future<void> _eliminarMiembro(MiembroGrupo m) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text(
            '¿Seguro que quieres eliminar a ${m.nombreCompleto} del grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    final err = await GruposService.eliminarMiembro(
      idPerfilGrupo: m.idPerfilGrupo,
    );
    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${m.nombreCompleto} ha sido eliminado del grupo'),
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
        title: Text('Miembros – ${widget.grupo.nombre}'),
        actions: [
          // Botón de salir del grupo (no para DUENO en esta pantalla)
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Salir del grupo',
            onPressed: _salirDelGrupo,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _miembros.isEmpty
          ? const Center(child: Text('Este grupo aún no tiene miembros'))
          : RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          itemCount: _miembros.length,
          itemBuilder: (_, i) {
            final m = _miembros[i];
            final iniciales = _getIniciales(m.nombre, m.apellido);

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(iniciales),
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(m.nombreCompleto)),
                    if (m.esActual)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Chip(
                          label: const Text('Tú'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.correo),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: -6,
                      children: [
                        Chip(
                          label: Text('Rol: ${m.rol}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        Chip(
                          label: Text('Estado: ${m.estado}'),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text(
                          'Miembro desde: ${m.unidoEn.toLocal()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: _buildAccionesMiembro(m, scheme),
              ),
            );
          },
        ),
      ),
      // Más adelante aquí puedes poner un FAB para "Agregar miembros"
      // floatingActionButton: _esAdmin ? FloatingActionButton(...) : null,
    );
  }

  /// Construye el menú de acciones para cada miembro
  Widget? _buildAccionesMiembro(
      MiembroGrupo m, ColorScheme scheme) {
    // Si NO soy admin, no muestro acciones
    if (!_esAdmin) return null;

    // No permitimos acciones sobre uno mismo ni sobre el DUENO
    if (m.esActual || m.rol == 'DUENO') return null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'hacer_admin':
            _cambiarRol(m, 'ADMIN');
            break;
          case 'quitar_admin':
            _cambiarRol(m, 'MIEMBRO');
            break;
          case 'suspender':
            _cambiarEstado(m, 'SUSPENDIDO');
            break;
          case 'activar':
            _cambiarEstado(m, 'ACTIVO');
            break;
          case 'eliminar':
            _eliminarMiembro(m);
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (m.rol == 'MIEMBRO')
          const PopupMenuItem(
            value: 'hacer_admin',
            child: Text('Hacer admin'),
          ),
        if (m.rol == 'ADMIN')
          const PopupMenuItem(
            value: 'quitar_admin',
            child: Text('Quitar admin'),
          ),
        const PopupMenuDivider(),
        if (m.estado == 'ACTIVO')
          const PopupMenuItem(
            value: 'suspender',
            child: Text('Suspender'),
          ),
        if (m.estado == 'SUSPENDIDO')
          const PopupMenuItem(
            value: 'activar',
            child: Text('Reactivar'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'eliminar',
          child: Text(
            'Eliminar del grupo',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  String _getIniciales(String nombre, String apellido) {
    final n = nombre.trim();
    final a = apellido.trim();

    if (n.isEmpty && a.isEmpty) return '?';

    String i1 = '';
    String i2 = '';

    if (n.isNotEmpty) i1 = n[0].toUpperCase();
    if (a.isNotEmpty) i2 = a[0].toUpperCase();

    final res = (i1 + i2).trim();
    return res.isEmpty ? '?' : res;
  }
}
