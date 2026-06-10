import 'package:flutter/material.dart';

import 'video_queue.dart';

class VideoPlaybackService {
  VideoPlaybackService._internal() {
    _config = const VideoPlaybackConfig();
  }

  static final VideoPlaybackService _instance = VideoPlaybackService._internal();

  factory VideoPlaybackService() {
    return _instance;
  }

  late VideoPlaybackConfig _config;
  VideoQueue? _currentQueue;
  final Map<String, VideoLoadState> _videoCache = {};

  VideoPlaybackConfig get config => _config;

  void setConfig(VideoPlaybackConfig config) {
    _config = config;
  }

  VideoQueue? get currentQueue => _currentQueue;

  void setQueue(VideoQueue queue) {
    _currentQueue = queue;
  }

  VideoQueue createQueueFromVideos(List<VideoItem> videos) {
    final queue = VideoQueue(items: videos);
    _currentQueue = queue;
    return queue;
  }

  bool isVideoCached(String videoPath) {
    return _videoCache.containsKey(videoPath) && _videoCache[videoPath] == VideoLoadState.loaded;
  }

  void markVideoLoading(String videoPath) {
    _videoCache[videoPath] = VideoLoadState.loading;
  }

  void markVideoLoaded(String videoPath) {
    _videoCache[videoPath] = VideoLoadState.loaded;
  }

  void markVideoError(String videoPath) {
    _videoCache[videoPath] = VideoLoadState.error;
  }

  VideoLoadState getVideoState(String videoPath) {
    return _videoCache[videoPath] ?? VideoLoadState.notLoaded;
  }

  void clearCache() {
    _videoCache.clear();
  }

  Map<String, int> getCacheStats() {
    var loaded = 0;
    var loading = 0;
    var error = 0;

    for (final state in _videoCache.values) {
      if (state == VideoLoadState.loaded) {
        loaded++;
      }
      if (state == VideoLoadState.loading) {
        loading++;
      }
      if (state == VideoLoadState.error) {
        error++;
      }
    }

    return {
      'total': _videoCache.length,
      'loaded': loaded,
      'loading': loading,
      'error': error,
    };
  }

  Map<String, dynamic>? getCurrentQueueInfo() {
    if (_currentQueue == null) {
      return null;
    }

    return {
      'totalVideos': _currentQueue!.items.length,
      'currentIndex': _currentQueue!.currentIndex,
      'isPlaying': _currentQueue!.isPlaying,
      'progress': _currentQueue!.getProgress(),
      'currentVideo': _currentQueue!.getCurrentVideo()?.toString(),
    };
  }
}

enum VideoLoadState { notLoaded, loading, loaded, error }

class VideoPlayerWithTransition extends StatefulWidget {
  const VideoPlayerWithTransition({
    super.key,
    required this.videoPath,
    required this.wordLabel,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.onComplete,
    this.autoStart = true,
  });

  final String videoPath;
  final String wordLabel;
  final Duration transitionDuration;
  final VoidCallback? onComplete;
  final bool autoStart;

  @override
  State<VideoPlayerWithTransition> createState() => _VideoPlayerWithTransitionState();
}

class _VideoPlayerWithTransitionState extends State<VideoPlayerWithTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(duration: widget.transitionDuration, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    if (widget.autoStart) {
      _fadeController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          _fadeController.reverse().then((_) {
            widget.onComplete?.call();
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              widget.wordLabel,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoPath.split('/').last,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoProgressBar extends StatelessWidget {
  const VideoProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalVideos,
    this.isPlaying = false,
  });

  final int currentIndex;
  final int totalVideos;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final progress = totalVideos > 0 ? (currentIndex + 1) / totalVideos : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentIndex + 1} / $totalVideos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(isPlaying ? Colors.blue : Colors.green),
          ),
        ),
      ],
    );
  }
}

class SignList extends StatelessWidget {
  const SignList({super.key, required this.videos, this.currentIndex = 0});

  final List<VideoItem> videos;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final item = videos[index];
        final isCurrentSign = index == currentIndex;
        final isCompleted = index < currentIndex;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentSign
                ? Colors.blue.withValues(alpha: 0.1)
                : isCompleted
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentSign
                  ? Colors.blue
                  : isCompleted
                      ? Colors.green
                      : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrentSign
                      ? Colors.blue
                      : isCompleted
                          ? Colors.green
                          : Colors.grey.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrentSign || isCompleted ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.word,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isFallback ? 'Fallback: ${item.fallbackReason}' : 'Sinal encontrado',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentSign)
                const AnimatedIcon(
                  icon: AnimatedIcons.play_pause,
                  progress: AlwaysStoppedAnimation(1),
                  color: Colors.blue,
                )
              else if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        );
      },
    );
  }
}
