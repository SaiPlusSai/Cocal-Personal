import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PantallaPreviewMediaForo extends StatefulWidget {
  final File file;
  final bool esVideo;

  /// callback que se ejecuta cuando el usuario pulsa "Enviar"
  /// debe subir el archivo + crear el post
  final Future<void> Function(String caption) onSend;

  const PantallaPreviewMediaForo({
    super.key,
    required this.file,
    required this.esVideo,
    required this.onSend,
  });

  @override
  State<PantallaPreviewMediaForo> createState() =>
      _PantallaPreviewMediaForoState();
}

class _PantallaPreviewMediaForoState extends State<PantallaPreviewMediaForo> {
  final TextEditingController _captionCtl = TextEditingController();
  VideoPlayerController? _videoCtl;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    if (widget.esVideo) {
      _videoCtl = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _captionCtl.dispose();
    _videoCtl?.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    final caption = _captionCtl.text.trim();
    await widget.onSend(caption);
    if (!mounted) return;
    setState(() => _enviando = false);
    Navigator.pop(context); // cierra la pantalla de preview
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Vista previa',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // MEDIA
            Expanded(
              child: Center(
                child: widget.esVideo
                    ? (_videoCtl != null && _videoCtl!.value.isInitialized
                    ? AspectRatio(
                  aspectRatio: _videoCtl!.value.aspectRatio,
                  child: GestureDetector(
                    onTap: () {
                      if (_videoCtl!.value.isPlaying) {
                        _videoCtl!.pause();
                      } else {
                        _videoCtl!.play();
                      }
                      setState(() {});
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_videoCtl!),
                        if (!_videoCtl!.value.isPlaying)
                          const Icon(
                            Icons.play_circle_fill,
                            size: 64,
                            color: Colors.white70,
                          ),
                      ],
                    ),
                  ),
                )
                    : const CircularProgressIndicator(color: Colors.white))
                    : InteractiveViewer(
                  child: Image.file(
                    widget.file,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // CAPTION + ENVIAR
            Container(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 6,
                bottom: bottomInset + 6,
              ),
              color: Colors.black87,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionCtl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF1E1E1E),
                        hintText: 'Añadir un comentario...',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _enviando
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.greenAccent,
                    ),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
