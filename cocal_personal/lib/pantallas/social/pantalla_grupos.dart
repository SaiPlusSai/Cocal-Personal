import 'package:flutter/material.dart';
import '../../servicios/social/grupos_service.dart';
import 'pantalla_crear_grupo.dart';
import 'pantalla_detalle_grupo.dart';
import '../../servicios/social/modelos_grupo.dart';

class PantallaGrupos extends StatefulWidget {
  const PantallaGrupos({super.key});

  @override
  State<PantallaGrupos> createState() => _PantallaGruposState();
}

class _PantallaGruposState extends State<PantallaGrupos> {
  bool _cargando = true;
  List<GrupoResumen> _grupos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await GruposService.obtenerMisGrupos();
    if (!mounted) return;
    setState(() {
      _grupos = res;
      _cargando = false;
    });
  }

  void _nuevoGrupo() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaCrearGrupo()),
    );

    if (creado == true) {
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _nuevoGrupo,
        child: const Icon(Icons.group_add),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _grupos.isEmpty
          ? const Center(child: Text('Todavía no perteneces a ningún grupo'))
          : RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          itemCount: _grupos.length,
          itemBuilder: (_, i) {
            final g = _grupos[i];
            return Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withOpacity(0.2),
                  child: Icon(Icons.group, color: scheme.primary),
                ),
                title: Text(g.nombre),
                subtitle: Text(
                  '${g.descripcion ?? 'Sin descripción'}\nRol: ${g.rol}',
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaDetalleGrupo(grupo: g),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
