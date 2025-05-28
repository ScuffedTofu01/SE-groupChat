import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.color,
    required this.viewOnly,
  });

  final String videoUrl;
  final Color color;
  final bool viewOnly;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

// ...existing code...
class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late CachedVideoPlayerPlusController videoPlayerController;
  bool isPlaying = false;
  bool isLoading = true;
  String? errorMessage; // Add this line

  @override
  void initState() {
    super.initState();

    final String trimmedVideoUrl = widget.videoUrl.trim();
    print("Attempting to parse URL: '$trimmedVideoUrl'");

    if (trimmedVideoUrl.isEmpty ||
        !(trimmedVideoUrl.startsWith('http://') ||
            trimmedVideoUrl.startsWith('https://'))) {
      print("Invalid or empty video URL: '$trimmedVideoUrl'");
      setState(() {
        isLoading = false;
        errorMessage = "Invalid or empty video URL.";
      });
      return;
    }

    try {
      videoPlayerController =
          CachedVideoPlayerPlusController.network(trimmedVideoUrl)
            ..addListener(() {
              if (!mounted) return;
              final bool playing = videoPlayerController.value.isPlaying;
              if (playing != isPlaying) {
                setState(() {
                  isPlaying = playing;
                });
              }
            })
            ..initialize()
                .then((_) {
                  if (!mounted) return;
                  videoPlayerController.setVolume(1);
                  setState(() {
                    isLoading = false;
                  });
                })
                .catchError((error) {
                  if (!mounted) return;
                  print("Error initializing video player: $error");
                  setState(() {
                    isLoading = false;
                    errorMessage = "Failed to load video.";
                  });
                });
    } on FormatException catch (e) {
      if (!mounted) return;
      print("Invalid URL format: '$trimmedVideoUrl' - Error: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Invalid video URL format.";
      });
    }
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            CachedVideoPlayerPlus(videoPlayerController),
          if (!isLoading && errorMessage == null)
            Center(
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: widget.color,
                ),
                onPressed:
                    widget.viewOnly
                        ? null
                        : () {
                          setState(() {
                            isPlaying = !isPlaying;
                            isPlaying
                                ? videoPlayerController.play()
                                : videoPlayerController.pause();
                          });
                        },
              ),
            ),
        ],
      ),
    );
  }
}
