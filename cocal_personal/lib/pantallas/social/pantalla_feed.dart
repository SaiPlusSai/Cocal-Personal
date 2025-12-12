// lib/pantallas/social/pantalla_feed.dart
import 'package:flutter/material.dart';
import '../../servicios/social/publicaciones_service.dart';
import '../../servicios/social/modelos_publicacion.dart';
import 'widgets/publicacion_card.dart';
import 'widgets/composer_publicacion.dart';

class PantallaFeed extends StatefulWidget {
  const PantallaFeed({super.key});

  @override
  State<PantallaFeed> createState() => _PantallaFeedState();
}

class _PantallaFeedState extends State<PantallaFeed> {
  List<PublicacionModel> _publicaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFeed();
  }

  Future<void> _cargarFeed() async {
    setState(() => _cargando = true);
    try {
      // 🔹 Ahora solo publicaciones de amigos que sigues
      final lista = await PublicacionesService.obtenerFeedGeneral();
      setState(() {
        _publicaciones = lista;
      });
    } catch (e) {
      debugPrint('[FEED] Error cargando feed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar feed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirComposer() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SafeArea(
            child: ComposerPublicacion(
              onPublicacionCreada: () async {
                Navigator.pop(ctx);      // cerrar modal
                await _cargarFeed();      // recargar feed
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 Botón flotante tipo "¿En qué estás pensando?"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirComposer,
        icon: const Icon(Icons.edit),
        label: const Text('¿En qué estás pensando?'),
        backgroundColor: Colors.indigo,
      ),

      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _publicaciones.isEmpty
          ? const Center(
        child: Text('Aún no hay publicaciones de tus amigos'),
      )
          : RefreshIndicator(
        onRefresh: _cargarFeed,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _publicaciones.length,
          itemBuilder: (_, i) {
            final pub = _publicaciones[i];
            return PublicacionCard(
              publicacion: pub,
              mostrarEvento: true,
            );
          },
        ),
      ),
    );
  }
}
