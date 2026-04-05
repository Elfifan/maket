import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoLessonPlayer extends StatefulWidget {
  final String videoUrl;

  const VideoLessonPlayer({super.key, required this.videoUrl});

  @override
  State<VideoLessonPlayer> createState() => _VideoLessonPlayerState();
}

class _VideoLessonPlayerState extends State<VideoLessonPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoPlayerController.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          )
        : const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
  }
}