// lib/pantallas/social/foro/pantalla_foro_grupo.dart
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

  Stream<List<TemaForoResumen>>? _streamTemas; // 👈 ahora usamos stream

  @override
  void initState() {
    super.initState();
    _initForoYStream();
  }

  Future<void> _initForoYStream() async {
    setState(() => _cargando = true);

    try {
      // 1) obtener (o crear) el foro del grupo
      final foro =
      await ForosService.obtenerOCrearForoDeGrupo(widget.grupo.id);

      // 2) preparar stream realtime de temas
      final streamTemas = ForosService.escucharTemasDeForo(foro.id);

      if (!mounted) return;
      setState(() {
        _foro = foro;
        _streamTemas = streamTemas;
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
      // ❌ Antes: _cargar();
      // ✅ Ahora: NO hace falta, el stream se actualiza solo
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
          ? const Center(
        child: Text('No se encontró el foro del grupo'),
      )
          : _streamTemas == null
          ? const Center(child: Text('Cargando temas...'))
          : RefreshIndicator(
        onRefresh:
        _initForoYStream, // por si quieres “rearmar” el stream y el foro
        child: StreamBuilder<List<TemaForoResumen>>(
          stream: _streamTemas,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final temas = snapshot.data ?? [];

            if (temas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Aún no hay temas. ¡Creá el primero!',
                    ),
                  ),
                ],
              );
            }


            return ListView.builder(
              itemCount: temas.length,
              itemBuilder: (_, i) {
                final t = temas[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary
                          .withOpacity(0.15),
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
            );
          },
        ),
      ),
    );
  }
}
