//lib/pantallas/social/foro/pantalla_foro_grupo.dart
import 'package:flutter/material.dart';
import '../../../servicios/social/foros_service.dart';
import 'pantalla_tema_foro.dart';
import '../../../servicios/social/modelos_grupo.dart';
import '../../../servicios/social/modelos_foro.dart';

class PantallaForoGrupo extends StatefulWidget {
  final GrupoResumen grupo;

  const PantallaForoGrupo({
    super.key,
    required this.grupo,
  });

  @override
  State<PantallaForoGrupo> createState() => _PantallaForoGrupoState();
}

class _PantallaForoGrupoState extends State<PantallaForoGrupo> {
  bool _cargando = true;
  ForoResumen? _foro;
  List<TemaForoResumen> _temas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      // 1) obtener (o crear) el foro del grupo
      final foro = await ForosService.obtenerOCrearForoDeGrupo(widget.grupo.id);

      // 2) obtener sus temas
      final temas = await ForosService.obtenerTemas(foro.id);

      if (!mounted) return;
      setState(() {
        _foro = foro;
        _temas = temas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el foro: $e')),
      );
    }
  }

  Future<void> _crearTema() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo tema'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Título del tema',
            ),
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresá un título';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (_foro == null) return;

    final titulo = controller.text.trim();
    final err = await ForosService.crearTema(
      idForo: _foro!.id,
      titulo: titulo,
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tema creado')),
      );
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Foro – ${widget.grupo.nombre}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearTema,
        child: const Icon(Icons.add_comment),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _foro == null
          ? const Center(child: Text('No se encontró el foro del grupo'))
          : _temas.isEmpty
          ? const Center(
        child: Text('Aún no hay temas. ¡Creá el primero!'),
      )
          : RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          itemCount: _temas.length,
          itemBuilder: (_, i) {
            final t = _temas[i];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  scheme.primary.withOpacity(0.15),
                  child: Icon(
                    Icons.forum,
                    color: scheme.primary,
                  ),
                ),
                title: Text(t.titulo),
                subtitle: Text(
                  'Por ${t.autor} · ${t.creadoEn.toLocal()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaTemaForo(
                        grupo: widget.grupo,
                        tema: t,
                      ),
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
