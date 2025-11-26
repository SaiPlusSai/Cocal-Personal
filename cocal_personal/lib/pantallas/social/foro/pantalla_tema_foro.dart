// lib/pantallas/social/foro/pantalla_tema_foro.dart
import 'package:flutter/material.dart';
import '../../../servicios/social/grupos_service.dart';
import '../../../servicios/social/foros_service.dart';

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
              style: t.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
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
                  return Container(
                    margin:
                    const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.autor,
                          style:
                          t.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(p.contenido),
                        const SizedBox(height: 4),
                        Text(
                          p.creadoEn.toLocal().toString(),
                          style:
                          t.textTheme.labelSmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
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
                      child:
                      CircularProgressIndicator(strokeWidth: 2),
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
}
