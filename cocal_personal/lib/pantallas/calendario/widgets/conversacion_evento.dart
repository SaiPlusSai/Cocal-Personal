import 'package:flutter/material.dart';

import '../../../servicios/social/publicaciones_service.dart';
import '../../../servicios/social/modelos_publicacion.dart';
import '../../social/widgets/publicacion_card.dart';
import '../../social/widgets/composer_publicacion.dart';

class ConversacionEvento extends StatefulWidget {
  final int eventoId;

  const ConversacionEvento({
    super.key,
    required this.eventoId,
  });

  @override
  State<ConversacionEvento> createState() => _ConversacionEventoState();
}

class _ConversacionEventoState extends State<ConversacionEvento> {
  List<PublicacionModel> _publicaciones = [];
  bool _cargandoPublicaciones = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[CONV_EVENTO] initState eventoId=${widget.eventoId}');
    _cargarPublicacionesEvento();
  }

  Future<void> _cargarPublicacionesEvento() async {
    debugPrint('[CONV_EVENTO] _cargarPublicacionesEvento() INICIO');
    setState(() => _cargandoPublicaciones = true);
    try {
      final lista = await PublicacionesService.obtenerPublicacionesDeEvento(
        widget.eventoId,
      );
      debugPrint(
          '[CONV_EVENTO] _cargarPublicacionesEvento() OK, total=${lista.length}');
      if (!mounted) {
        debugPrint('[CONV_EVENTO] _cargarPublicacionesEvento() no mounted');
        return;
      }
      setState(() {
        _publicaciones = lista;
        _cargandoPublicaciones = false;
      });
    } catch (e, st) {
      debugPrint('[CONV_EVENTO] ERROR _cargarPublicacionesEvento: $e');
      debugPrint(st.toString());
      if (!mounted) {
        debugPrint('[CONV_EVENTO] catch pero no mounted');
        return;
      }
      setState(() => _cargandoPublicaciones = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al cargar publicaciones: $e')),
      );
    }
  }

  Future<void> _nuevaPublicacionEvento() async {
    debugPrint('[CONV_EVENTO] _nuevaPublicacionEvento() PRESSED');
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          debugPrint('[CONV_EVENTO] builder de showModalBottomSheet');
          final media = MediaQuery.of(ctx);
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: media.viewInsets.bottom + 16,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Text(
                      'Nueva publicación del evento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ComposerPublicacion(
                      idEvento: widget.eventoId,
                      onPublicacionCreada: () async {
                        debugPrint(
                            '[CONV_EVENTO] onPublicacionCreada -> recargar lista');
                        Navigator.pop(ctx); // cerrar modal
                        await _cargarPublicacionesEvento();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      debugPrint('[CONV_EVENTO] showModalBottomSheet cerrado normalmente');
    } catch (e, st) {
      debugPrint('[CONV_EVENTO] ERROR en _nuevaPublicacionEvento: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir composer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[CONV_EVENTO] build() cargando=$_cargandoPublicaciones, publicaciones=${_publicaciones.length}');
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Conversación del evento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                debugPrint('[CONV_EVENTO] Botón "Publicar" onPressed');
                _nuevaPublicacionEvento();
              },
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Publicar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
          child: _cargandoPublicaciones
              ? const Center(child: CircularProgressIndicator())
              : _publicaciones.isEmpty
              ? const Center(
            child: Text(
              'Todavía no hay publicaciones para este evento.\n'
                  'Sé la primera persona en comentar.',
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            itemCount: _publicaciones.length,
            itemBuilder: (_, i) {
              debugPrint(
                  '[CONV_EVENTO] construyendo PublicacionCard index=$i id=${_publicaciones[i].id}');
              return PublicacionCard(
                publicacion: _publicaciones[i],
                mostrarEvento: false,
              );
            },
          ),
        ),
      ],
    );
  }
}
