import 'package:flutter/material.dart';

import '../../../servicios/social/publicaciones_service.dart';
import '../../../servicios/social/modelos_publicacion.dart';

class ComentariosPublicacionSheet extends StatefulWidget {
  final int idPublicacion;

  const ComentariosPublicacionSheet({
    super.key,
    required this.idPublicacion,
  });

  @override
  State<ComentariosPublicacionSheet> createState() =>
      _ComentariosPublicacionSheetState();
}

class _ComentariosPublicacionSheetState
    extends State<ComentariosPublicacionSheet> {
  final _textoCtl = TextEditingController();
  bool _enviando = false;
  bool _cargando = true;
  int? _miId;
  List<ComentarioPublicacionModel> _comentarios = [];

  @override
  void initState() {
    super.initState();
    _cargarMiId();
    _cargarComentarios();
  }
  Future<void> _cargarMiId() async {
    final id = await PublicacionesService.obtenerIdUsuarioActual();
    if (!mounted) return;
    setState(() => _miId = id);
  }
  @override
  void dispose() {
    _textoCtl.dispose();
    super.dispose();
  }
  Future<void> _onLongPressComentario(
      ComentarioPublicacionModel c) async {
    // solo si es mío
    if (_miId == null || _miId != c.idUsuario) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text(
            '¿Seguro que deseas eliminar este comentario?'),
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
    await PublicacionesService.eliminarComentario(c.id);

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario eliminado')),
      );
      await _cargarComentarios();
    }
  }

  Future<void> _cargarComentarios() async {
    setState(() => _cargando = true);
    try {
      final lista =
      await PublicacionesService.obtenerComentarios(widget.idPublicacion);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar comentarios: $e')),
      );
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _textoCtl.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      final error = await PublicacionesService.crearComentario(
        idPublicacion: widget.idPublicacion,
        contenido: texto,
      );

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }

      _textoCtl.clear();
      await _cargarComentarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar el comentario: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _formatearFecha(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // barrita
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Text(
                'Comentarios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // LISTA
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _comentarios.isEmpty
                    ? const Center(
                  child: Text(
                    'Todavía no hay comentarios.\nSé la primera persona en comentar.',
                    textAlign: TextAlign.center,
                  ),
                )
                    : ListView.builder(
                  itemCount: _comentarios.length,
                  itemBuilder: (_, i) {
                    final c = _comentarios[i];
                    final nombre =
                    ((c.nombreAutor ?? '') +
                        (c.apellidoAutor != null
                            ? ' ${c.apellidoAutor}'
                            : ''))
                        .trim();
                    final fecha = _formatearFecha(c.creadoEn);

                    return GestureDetector(
                      onLongPress: () => _onLongPressComentario(c),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: (c.fotoAutor != null &&
                              c.fotoAutor!.isNotEmpty)
                              ? NetworkImage(c.fotoAutor!)
                              : null,
                          child: (c.fotoAutor == null ||
                              c.fotoAutor!.isEmpty)
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.contenido,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fecha,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // CAJA DE TEXTO + ENVIAR
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoCtl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un comentario...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _enviando ? null : _enviarComentario,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: const EdgeInsets.all(10),
                    ),
                    child: _enviando
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
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
