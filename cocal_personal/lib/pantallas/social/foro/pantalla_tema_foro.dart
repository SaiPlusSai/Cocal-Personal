// lib/pantallas/social/foro/pantalla_tema_foro.dart
import 'package:flutter/material.dart';
import '../../../servicios/social/foros_service.dart';
import '../../../servicios/social/modelos_foro.dart';
import '../../../servicios/social/modelos_grupo.dart';

class PantallaTemaForo extends StatefulWidget {
  final GrupoResumen grupo;
  final TemaForoResumen tema;

  const PantallaTemaForo({
    super.key,
    required this.grupo,
    required this.tema,
  });

  @override
  State<PantallaTemaForo> createState() => _PantallaTemaForoState();
}

class _PantallaTemaForoState extends State<PantallaTemaForo> {
  bool _cargando = true;
  bool _enviando = false;
  List<PostForo> _posts = [];
  final TextEditingController _mensajeCtl = TextEditingController();

  /// Deben coincidir EXACTO con tu enum lista_reacciones
  static const Map<String, String> _reaccionesDisponibles = {
    'LIKE': '👍',
    'LOVE': '❤️',
    'CARA_FELIZ': '😊',
    'CARITA_TRISTE': '😢',
    'CARA_ENOJADA': '😡',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _mensajeCtl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    final posts = await ForosService.obtenerPosts(widget.tema.id);

    if (!mounted) return;
    setState(() {
      _posts = posts;
      _cargando = false;
    });
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeCtl.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    final err = await ForosService.crearPost(
      idTema: widget.tema.id,
      contenido: texto,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    _mensajeCtl.clear();
    await _cargar();
  }

  Future<void> _toggleReaccion(PostForo post, String tipo) async {
    final err = await ForosService.toggleReaccion(
      idPost: post.id,
      tipo: tipo,
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      await _cargar();
    }
  }

  Future<void> _mostrarSelectorReacciones(PostForo post) async {
    final tipoSeleccionado = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Reaccionar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _reaccionesDisponibles.entries.map((entry) {
                  final tipo = entry.key;
                  final emoji = entry.value;
                  final esActual = post.miReaccion == tipo;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, tipo),
                      child: Column(
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          if (esActual)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Tu reacción',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (tipoSeleccionado == null) return;

    await _toggleReaccion(post, tipoSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final scheme = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tema.titulo),
            Text(
              widget.grupo.nombre,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                ? const Center(
              child: Text('Aún no hay mensajes en este tema'),
            )
                : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _posts.length,
                itemBuilder: (_, i) {
                  final p = _posts[i];
                  final soyYo = p.esActual;

                  final alignment = soyYo
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start;
                  final bubbleColor = soyYo
                      ? scheme.primary.withOpacity(0.15)
                      : scheme.surfaceVariant.withOpacity(0.6);

                  return Row(
                    mainAxisAlignment: alignment,
                    children: [
                      Flexible(
                        child: GestureDetector(
                          onLongPress: () =>
                              _mostrarSelectorReacciones(p),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                // autor + fecha
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text(
                                      p.autor,
                                      style: t.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      p.creadoEn
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                      style: t.textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(p.contenido),
                                const SizedBox(height: 6),
                                _buildChipsReacciones(p, scheme),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Caja de texto inferior
          SafeArea(
            top: false,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(
                    color: scheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeCtl,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Escribí un mensaje...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _enviando
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.send),
                    color: scheme.primary,
                    onPressed: _enviando ? null : _enviarMensaje,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chips de reacciones bajo el mensaje (solo lectura con conteos)
  Widget _buildChipsReacciones(PostForo p, ColorScheme scheme) {
    final hayConteo = p.reacciones.values.any((c) => c > 0);
    if (!hayConteo) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: _reaccionesDisponibles.entries.map((entry) {
        final tipo = entry.key;
        final emoji = entry.value;
        final count = p.reacciones[tipo] ?? 0;

        if (count == 0) return const SizedBox.shrink();

        final esMiReaccion = p.miReaccion == tipo;

        return Chip(
          avatar: Text(emoji),
          label: Text(count.toString()),
          backgroundColor: esMiReaccion
              ? scheme.primary.withOpacity(0.2)
              : scheme.surface,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList()
        ..removeWhere((w) => w is SizedBox),
    );
  }
}
