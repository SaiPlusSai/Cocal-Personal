// lib/pantallas/social/widgets/publicacion_card.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../servicios/social/modelos_publicacion.dart';
import '../../../servicios/social/publicaciones_service.dart';
import '../../../servicios/calendario/servicio_evento.dart';
import '../../calendario/pantalla_detalle_evento.dart';

// 👇 importamos el reproductor inline del foro
import '../foro/widgets/foro_video_player.dart';
import 'comentarios_publicacion_sheet.dart';

class PublicacionCard extends StatefulWidget {
  final PublicacionModel publicacion;
  final bool mostrarEvento;
  final VoidCallback? onEliminada;

  const PublicacionCard({
    super.key,
    required this.publicacion,
    this.mostrarEvento = false,
    this.onEliminada,
  });

  @override
  State<PublicacionCard> createState() => _PublicacionCardState();
}

class _PublicacionCardState extends State<PublicacionCard> {
  int _likes = 0;
  bool _cargandoLikes = true;

  int _comentarios = 0;
  bool _cargandoComentarios = true;

  int? _miId;
  @override
  void initState() {
    super.initState();
    _cargarLikes();
    _cargarComentarios();
    _cargarMiId();
  }

  Future<void> _cargarMiId() async {
    final id = await PublicacionesService.obtenerIdUsuarioActual();
    if (mounted) {
      setState(() => _miId = id);
    }
  }

  Future<void> _cargarLikes() async {
    setState(() => _cargandoLikes = true);
    final cant = await PublicacionesService.contarLikes(widget.publicacion.id);
    if (mounted) {
      setState(() {
        _likes = cant;
        _cargandoLikes = false;
      });
    }
  }

  Future<void> _cargarComentarios() async {
    setState(() => _cargandoComentarios = true);
    final cant =
        await PublicacionesService.contarComentarios(widget.publicacion.id);
    if (!mounted) return;
    setState(() {
      _comentarios = cant;
      _cargandoComentarios = false;
    });
  }

  Future<void> _eliminarPublicacion() async {
    // solo si es mía
    if (_miId == null || _miId != widget.publicacion.idUsuario) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text('¿Seguro que deseas eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final err =
        await PublicacionesService.eliminarPublicacion(widget.publicacion.id);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación eliminada')),
      );
      widget.onEliminada?.call(); // que el padre recargue la lista
    }
  }

  Future<void> _toggleLike() async {
    final err = await PublicacionesService.toggleLike(widget.publicacion.id);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
    await _cargarLikes();
  }

  Future<void> _abrirComentarios() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return ComentariosPublicacionSheet(
          idPublicacion: widget.publicacion.id,
        );
      },
    );
    await _cargarComentarios();
  }

  String _formatearFecha(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm  $hh:$mi';
  }

  Widget _buildHeader() {
    final p = widget.publicacion;
    final nombre = (p.nombreAutor ?? '') +
        (p.apellidoAutor != null ? ' ${p.apellidoAutor}' : '');
    final fecha = _formatearFecha(p.creadoEn);

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: (p.fotoAutor != null && p.fotoAutor!.isNotEmpty)
              ? NetworkImage(p.fotoAutor!)
              : null,
          child: (p.fotoAutor == null || p.fotoAutor!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.isEmpty ? 'Usuario' : nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                fecha,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarruselMedia() {
    final media = widget.publicacion.media;
    if (media.isEmpty) return const SizedBox.shrink();

    if (media.length == 1) {
      final m = media.first;
      return _MediaPreview(
        media: m,
      );
    }

    return _CarouselMedia(media: media);
  }

  Widget _buildResumenEvento() {
    final idEvento = widget.publicacion.idEvento;
    if (!widget.mostrarEvento || idEvento == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: ServicioEvento.obtenerEventoPorId(idEvento),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        final titulo = (data['titulo'] ?? 'Evento').toString();
        final desc = (data['descripcion'] ?? '').toString();
        DateTime? fecha;
        String fechaTexto = '';
        try {
          fecha = DateTime.parse(data['horario'].toString()).toLocal();
          fechaTexto = _formatearFecha(fecha);
        } catch (_) {}

        final tema = data['tema']?.toString();
        final estado = data['estado']?.toString();

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (fechaTexto.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '📅 $fechaTexto',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (tema != null || estado != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    if (tema != null)
                      Chip(
                        label: Text('Tema: $tema'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (estado != null)
                      Chip(
                        label: Text('Estado: $estado'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final ev =
                        await ServicioEvento.obtenerEventoPorId(idEvento);
                    if (ev == null || !context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaDetalleEvento(
                          evento: ev,
                          onGuardado: () {},
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ver evento'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.publicacion;
    return GestureDetector(
      onLongPress: _eliminarPublicacion,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              if ((p.contenido ?? '').isNotEmpty) ...[
                Text(p.contenido!),
                const SizedBox(height: 8),
              ],
              _buildCarruselMedia(),
              _buildResumenEvento(),
              const SizedBox(height: 8),
              const Divider(),
              Row(
                children: [
                  IconButton(
                    onPressed: _toggleLike,
                    icon: const Icon(Icons.favorite, color: Colors.red),
                  ),
                  if (_cargandoLikes)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text('$_likes'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _abrirComentarios,
                    icon: const Icon(Icons.comment_outlined),
                    label: Text(
                      _cargandoComentarios
                          ? 'Comentarios'
                          : 'Comentarios ($_comentarios)',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview de media (imagen o video inline)
class _MediaPreview extends StatelessWidget {
  final MediaPublicacion media;

  const _MediaPreview({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.esVideo) {
      // 👇 ahora reproducimos inline, sin navegar a otra pantalla
      return ForoVideoPlayer(url: media.urlImagen);
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          media.urlImagen,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Carrusel de media mixta
class _CarouselMedia extends StatefulWidget {
  final List<MediaPublicacion> media;

  const _CarouselMedia({required this.media});

  @override
  State<_CarouselMedia> createState() => _CarouselMediaState();
}

class _CarouselMediaState extends State<_CarouselMedia> {
  int _paginaActual = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              itemCount: widget.media.length,
              onPageChanged: (i) => setState(() => _paginaActual = i),
              itemBuilder: (_, i) {
                final m = widget.media[i];
                return _MediaPreview(media: m);
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.media.length, (i) {
            final activo = i == _paginaActual;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: activo ? 10 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: activo
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}
