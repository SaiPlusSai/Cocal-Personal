// lib/pantallas/social/widgets/composer_publicacion.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../servicios/social/publicaciones_service.dart';

class ComposerPublicacion extends StatefulWidget {
  final int? idEvento;
  final VoidCallback? onPublicacionCreada;

  const ComposerPublicacion({
    super.key,
    this.idEvento,
    this.onPublicacionCreada,
  });

  @override
  State<ComposerPublicacion> createState() => _ComposerPublicacionState();
}

class _ComposerPublicacionState extends State<ComposerPublicacion> {
  final _textoCtl = TextEditingController();
  final _picker = ImagePicker();

  bool _publicando = false;
  final List<XFile> _imagenes = [];
  final List<XFile> _videos = [];

  @override
  void initState() {
    super.initState();
    debugPrint('[COMPOSER] INIT idEvento=${widget.idEvento}');
  }

  @override
  void dispose() {
    _textoCtl.dispose();
    debugPrint('[COMPOSER] DISPOSE');
    super.dispose();
  }

  // ======== GALERÍA IMÁGENES ========
  Future<void> _seleccionarImagenesGaleria() async {
    debugPrint('[COMPOSER] Botón: seleccionar imágenes de galería');
    try {
      final imgs = await _picker.pickMultiImage(imageQuality: 85);
      debugPrint('[COMPOSER] Recibidas imágenes=${imgs.length}');
      if (imgs.isNotEmpty) {
        setState(() {
          _imagenes.addAll(imgs);
        });
        debugPrint('[COMPOSER] Total imágenes=${_imagenes.length}');
      }
    } catch (e, st) {
      debugPrint('[COMPOSER] ERROR imágenes galería: $e');
      debugPrint(st.toString());
    }
  }

  // ======== GALERÍA VIDEO ========
  Future<void> _seleccionarVideoGaleria() async {
    debugPrint('[COMPOSER] Botón: seleccionar video de galería');
    try {
      final vid = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      debugPrint('[COMPOSER] Recibido video=${vid?.path}');
      if (vid != null) {
        setState(() => _videos.add(vid));
        debugPrint('[COMPOSER] Total videos=${_videos.length}');
      }
    } catch (e, st) {
      debugPrint('[COMPOSER] ERROR video galería: $e');
      debugPrint(st.toString());
    }
  }

  // ======== CÁMARA FOTO ========
  Future<void> _tomarFotoCamara() async {
    debugPrint('[COMPOSER] Botón: tomar foto cámara');
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      debugPrint('[COMPOSER] Foto cámara=${foto?.path}');
      if (foto != null) {
        setState(() => _imagenes.add(foto));
        debugPrint('[COMPOSER] Total imágenes=${_imagenes.length}');
      }
    } catch (e, st) {
      debugPrint('[COMPOSER] ERROR tomar foto: $e');
      debugPrint(st.toString());
    }
  }

  // ======== CÁMARA VIDEO ========
  Future<void> _grabarVideoCamara() async {
    debugPrint('[COMPOSER] Botón: grabar video cámara');
    try {
      final vid = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      debugPrint('[COMPOSER] Video cámara=${vid?.path}');
      if (vid != null) {
        setState(() => _videos.add(vid));
        debugPrint('[COMPOSER] Total videos=${_videos.length}');
      }
    } catch (e, st) {
      debugPrint('[COMPOSER] ERROR grabar video: $e');
      debugPrint(st.toString());
    }
  }

  // ======== PUBLICAR ========
  Future<void> _publicar() async {
    debugPrint('[COMPOSER] PRESIONADO Publicar()');
    final texto = _textoCtl.text.trim();
    final media = [..._imagenes, ..._videos];

    debugPrint('[COMPOSER] Texto="${texto}", media=${media.length}');
    if (texto.isEmpty && media.isEmpty) {
      debugPrint('[COMPOSER] Nada para publicar → cancelar');
      return;
    }

    setState(() => _publicando = true);
    try {
      debugPrint('[COMPOSER] Enviando a Supabase...');
      debugPrint('[COMPOSER] idEvento=${widget.idEvento}');

      final pub = await PublicacionesService.crearPublicacion(
        contenido: texto.isEmpty ? null : texto,
        idEvento: widget.idEvento,
        visibilidad: 'PUBLICO',
        archivosMedia: media,
      );

      debugPrint('[COMPOSER] Respuesta Supabase=${pub != null}');

      if (pub == null) {
        if (!mounted) return;
        debugPrint('[COMPOSER] ERROR: pub==null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la publicación')),
        );
        return;
      }

      _textoCtl.clear();
      setState(() {
        _imagenes.clear();
        _videos.clear();
      });

      debugPrint('[COMPOSER] Publicación creada correctamente.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicación creada ✅')),
        );
      }

      debugPrint('[COMPOSER] Ejecutando callback onPublicacionCreada...');
      widget.onPublicacionCreada?.call();
    } catch (e, st) {
      debugPrint('[COMPOSER] ERROR al publicar: $e');
      debugPrint(st.toString());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _publicando = false);
        debugPrint('[COMPOSER] FIN publicar(), _publicando=false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSeleccionada = [..._imagenes, ..._videos];
    debugPrint('[COMPOSER] build() imágenes=${_imagenes.length}, videos=${_videos.length}');

    final esDeEvento = widget.idEvento != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _textoCtl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: esDeEvento
                ? '¿Qué querés comentar sobre este evento?'
                : '¿En qué estás pensando?',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        // PREVIEW DE MEDIA
        if (mediaSeleccionada.isNotEmpty) ...[
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mediaSeleccionada.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final file = mediaSeleccionada[i];
                final esVideo = file.path.toLowerCase().endsWith('.mp4') ||
                    file.path.toLowerCase().endsWith('.mov') ||
                    file.path.toLowerCase().endsWith('.m4v');

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: esVideo
                          ? Container(
                        width: 90,
                        height: 90,
                        color: Colors.black87,
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                          : Image.file(
                        File(file.path),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          debugPrint('[COMPOSER] Eliminando archivo: ${file.path}');
                          setState(() {
                            _imagenes.remove(file);
                            _videos.remove(file);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // BOTONES
        Row(
          children: [
            IconButton(
              onPressed: _publicando ? null : _seleccionarImagenesGaleria,
              icon: const Icon(Icons.photo_library),
              tooltip: 'Fotos de galería',
            ),
            IconButton(
              onPressed: _publicando ? null : _tomarFotoCamara,
              icon: const Icon(Icons.photo_camera),
              tooltip: 'Tomar foto',
            ),
            IconButton(
              onPressed: _publicando ? null : _seleccionarVideoGaleria,
              icon: const Icon(Icons.video_library),
              tooltip: 'Video de galería',
            ),
            IconButton(
              onPressed: _publicando ? null : _grabarVideoCamara,
              icon: const Icon(Icons.videocam),
              tooltip: 'Grabar video',
            ),
            const Spacer(),

            Flexible(
              child: ElevatedButton.icon(
                onPressed: _publicando ? null : _publicar,
                icon: _publicando
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(Icons.send),
                label: Text('Publicar'),
              ),
            )

          ],
        ),
      ],
    );
  }
}
