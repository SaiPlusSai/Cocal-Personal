import 'package:flutter/material.dart';
import '../../servicios/social/grupos_service.dart';
import '../../servicios/social/amigos_service.dart';

class PantallaInvitarAmigosAGrupo extends StatefulWidget {
  final GrupoResumen grupo;

  const PantallaInvitarAmigosAGrupo({super.key, required this.grupo});

  @override
  State<PantallaInvitarAmigosAGrupo> createState() =>
      _PantallaInvitarAmigosAGrupoState();
}

class _PantallaInvitarAmigosAGrupoState
    extends State<PantallaInvitarAmigosAGrupo> {
  bool _cargando = true;
  List<UsuarioResumen> _amigosDisponibles = [];
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    // 1) amigos del usuario actual
    final amigos = await AmigosService.obtenerAmigos();

    // 2) miembros actuales del grupo
    final miembros = await GruposService.obtenerMiembros(widget.grupo.id);
    final idsMiembros = miembros.map((m) => m.idUsuario).toSet();

    // 3) solo amigos que no sean ya miembros
    final disponibles =
    amigos.where((a) => !idsMiembros.contains(a.id)).toList();

    if (!mounted) return;
    setState(() {
      _amigosDisponibles = disponibles;
      _cargando = false;
    });
  }

  Future<void> _agregar(UsuarioResumen u) async {
    final err = await GruposService.agregarMiembro(
      idGrupo: widget.grupo.id,
      idUsuario: u.id,
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se agregó a ${u.nombre} ${u.apellido} al grupo')),
    );

    setState(() {
      _amigosDisponibles.removeWhere((x) => x.id == u.id);
    });

    // Opcional: devolver true para refrescar miembros en la pantalla anterior
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _amigosDisponibles.where((a) {
      if (_busqueda.isEmpty) return true;
      final q = _busqueda.toLowerCase();
      final nombreCompleto =
      '${a.nombre} ${a.apellido ?? ''}'.trim().toLowerCase();
      return nombreCompleto.contains(q) || a.correo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Invitar amigos a "${widget.grupo.nombre}"'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _amigosDisponibles.isEmpty
          ? const Center(
        child: Text('No tienes amigos disponibles para invitar'),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar amigo...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() => _busqueda = v);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.builder(
                itemCount: filtrados.length,
                itemBuilder: (_, i) {
                  final a = filtrados[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text('${a.nombre} ${a.apellido}'),
                    subtitle: Text(a.correo),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () => _agregar(a),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
