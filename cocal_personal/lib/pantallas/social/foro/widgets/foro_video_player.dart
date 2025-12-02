// lib/pantallas/social/foro/widgets/foro_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ForoVideoPlayer extends StatefulWidget {
  final String url;

  const ForoVideoPlayer({super.key, required this.url});

  @override
  State<ForoVideoPlayer> createState() => _ForoVideoPlayerState();
}

class _ForoVideoPlayerState extends State<ForoVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: _toggle,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: VideoPlayer(_controller),
            ),
            if (!_controller.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
