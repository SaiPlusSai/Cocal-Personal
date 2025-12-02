// lib/pantallas/social/foro/pantalla_tema_foro.dart
import 'package:flutter/material.dart';
import '../../../servicios/social/foros_service.dart';
import '../../../servicios/social/modelos_foro.dart';
import '../../../servicios/social/modelos_grupo.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'pantalla_preview_media_foro.dart';
import 'widgets/foro_video_player.dart';


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
  late final Stream<List<PostForo>> _streamPosts;
  final TextEditingController _mensajeCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _enviando = false;

  /// Reacciones disponibles
  static const Map<String, String> _reaccionesDisponibles = {
    'LIKE': '👍',
    'LOVE': '❤️',
    'CARA_FELIZ': '😊',
    'CARITA_TRISTE': '😢',
    'CARA_ENOJADA': '😡',
  };

  PostForo? _respuestaA; // Para crear respuesta a un post

  @override
  void initState() {
    super.initState();
    // Suscribimos el stream en tiempo real
    _streamPosts = ForosService.escucharPostsDeTema(widget.tema.id);
  }

  @override
  void dispose() {
    _mensajeCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    if (!_scrollCtl.hasClients) return;
    _scrollCtl.animateTo(
      _scrollCtl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeCtl.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    final err = await ForosService.crearPost(
      idTema: widget.tema.id,
      contenido: texto,
      idComentarioPadre: _respuestaA?.id,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    _mensajeCtl.clear();
    _respuestaA = null;

    // Después de enviar, baja al final (cuando ya se pintó el nuevo mensaje)
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollAlFinal());
  }

  Future<void> _toggleReaccion(PostForo post, String tipo) async {
    final err =
    await ForosService.toggleReaccion(idPost: post.id, tipo: tipo);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
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
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
  Future<void> _abrirPreviewImagen(File file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPreviewMediaForo(
          file: file,
          esVideo: false,
          onSend: (caption) async {
            final url = await ForosService.subirMediaForo(
              idTema: widget.tema.id,
              file: file,
              carpeta: 'imagenes',
            );

            if (url == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo subir la imagen'),
                  ),
                );
              }
              return;
            }

            final err = await ForosService.crearPost(
              idTema: widget.tema.id,
              contenido: caption,
              tipoContenido: 'IMAGEN',
              mediaUrl: url,
            );

            if (err != null && mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
        ),
      ),
    );
  }


  Future<void> _abrirPreviewVideo(File file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPreviewMediaForo(
          file: file,
          esVideo: true,
          onSend: (caption) async {
            final url = await ForosService.subirMediaForo(
              idTema: widget.tema.id,
              file: file,
              carpeta: 'videos',
            );

            if (url == null) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo subir el video'),
                  ),
                );
              }
              return;
            }

            final err = await ForosService.crearPost(
              idTema: widget.tema.id,
              contenido: caption,
              tipoContenido: 'VIDEO',
              mediaUrl: url,
            );

            if (err != null && mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
        ),
      ),
    );
  }


  Future<void> _enviarImagenDesdeGaleria() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    await _abrirPreviewImagen(File(picked.path));
  }

  Future<void> _tomarFotoYCargar() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    await _abrirPreviewImagen(File(picked.path));
  }

  Future<void> _enviarVideoDesdeGaleria() async {
    final XFile? picked =
    await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _abrirPreviewVideo(File(picked.path));
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
          // LISTA DE MENSAJES EN VIVO
          Expanded(
            child: StreamBuilder<List<PostForo>>(
              stream: _streamPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay mensajes en este tema'),
                  );
                }

                // Cuando hay datos, baja automáticamente al final
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollAlFinal();
                });

                return ListView.builder(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (_, i) {
                    final p = posts[i];
                    return _buildMensajeBubble(
                      context: context,
                      post: p,
                      scheme: scheme,
                      theme: t,
                    );
                  },
                );
              },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_respuestaA != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Respondiendo a ${_respuestaA!.autor}: '
                                  '${_respuestaA!.contenido}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() => _respuestaA = null);
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // 📎 Botones de adjuntar
                      IconButton(
                        icon: const Icon(Icons.photo),
                        tooltip: 'Imagen de galería',
                        onPressed: _enviarImagenDesdeGaleria,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'Tomar foto',
                        onPressed: _tomarFotoYCargar,
                      ),
                      IconButton(
                        icon: const Icon(Icons.videocam),
                        tooltip: 'Video desde galería',
                        onPressed: _enviarVideoDesdeGaleria,
                      ),

                      Expanded(
                        child: TextField(
                          controller: _mensajeCtl,
                          maxLines: 3,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _enviando
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _enviarMensaje,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeBubble({
    required BuildContext context,
    required PostForo post,
    required ColorScheme scheme,
    required ThemeData theme,
  }) {
    final soyYo = post.esActual;
    final alignment =
    soyYo ? MainAxisAlignment.end : MainAxisAlignment.start;

    final bubbleColor = soyYo
        ? scheme.primary
        : scheme.surfaceVariant.withOpacity(0.9);

    final textColor = soyYo ? Colors.white : Colors.black87;

    final esRespuesta = post.idComentarioPadre != null;
    final margenHorizontal = esRespuesta ? 52.0 : 40.0;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Flexible(
          child: GestureDetector(
            onLongPress: () => _mostrarSelectorReacciones(post),
            onTap: () {
              // Preparar para responder
              setState(() => _respuestaA = post);
              _mensajeCtl.text = '@${post.autor} ';
              _mensajeCtl.selection = TextSelection.fromPosition(
                TextPosition(offset: _mensajeCtl.text.length),
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4).copyWith(
                left: soyYo ? margenHorizontal : 8,
                right: soyYo ? 8 : margenHorizontal,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: soyYo
                      ? const Radius.circular(14)
                      : const Radius.circular(4),
                  bottomRight: soyYo
                      ? const Radius.circular(4)
                      : const Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + hora
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.autor,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        post.creadoEn
                            .toLocal()
                            .toString()
                            .substring(0, 16),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.contenido,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  //contenido multimedia
                  if (post.tipoContenido == 'IMAGEN' && post.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.mediaUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              height: 160,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                      (progress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (post.tipoContenido == 'VIDEO' && post.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ForoVideoPlayer(
                        url: post.mediaUrl!,
                      ),
                    ),
                  //FIN multimedia
                  const SizedBox(height: 2),
                  _buildChipsReacciones(post, scheme),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipsReacciones(PostForo post, ColorScheme scheme) {
    if (post.reacciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: post.reacciones.entries.map((e) {
        final tipo = e.key;
        final count = e.value;
        final emoji = _reaccionesDisponibles[tipo] ?? tipo;
        return Chip(
          label: Text('$emoji $count'),
          backgroundColor: scheme.primary.withOpacity(0.2),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
