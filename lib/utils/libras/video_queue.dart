 class VideoQueue {
  VideoQueue({
    required this.items,
    this.currentIndex = 0,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
  });

  final List<VideoItem> items;
  int currentIndex;
  bool isPlaying;
  double playbackSpeed;

  VideoItem? getCurrentVideo() {
    if (currentIndex >= 0 && currentIndex < items.length) {
      return items[currentIndex];
    }
    return null;
  }

  VideoItem? getNextVideo() {
    if (hasNext()) {
      currentIndex++;
      return items[currentIndex];
    }
    return null;
  }

  bool hasNext() => currentIndex < items.length - 1;

  VideoItem? getPreviousVideo() {
    if (hasPrevious()) {
      currentIndex--;
      return items[currentIndex];
    }
    return null;
  }

  bool hasPrevious() => currentIndex > 0;

  void reset() {
    currentIndex = 0;
    isPlaying = false;
  }

  double getProgress() {
    if (items.isEmpty) {
      return 0.0;
    }
    return (currentIndex + 1) / items.length;
  }

  @override
  String toString() {
    return 'VideoQueue(total: ${items.length}, current: $currentIndex, playing: $isPlaying)';
  }
}

class VideoItem {
  VideoItem({
    required this.path,
    required this.word,
    this.fallbackReason,
    Duration? duration,
  }) : _duration = duration;

  final String path;
  final String word;
  final String? fallbackReason;
  Duration? _duration;

  Duration? get duration => _duration;

  set duration(Duration? value) {
    _duration = value;
  }

  bool get isFallback => fallbackReason != null;

  @override
  String toString() {
    return 'VideoItem(word: $word, path: $path, fallback: $isFallback)';
  }
}

class VideoPlaybackConfig {
  const VideoPlaybackConfig({
    this.transitionDuration = const Duration(milliseconds: 300),
    this.autoPlay = true,
    this.loopOnEnd = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.showControls = true,
    this.defaultVideoDuration = const Duration(seconds: 2),
  });

  final Duration transitionDuration;
  final bool autoPlay;
  final bool loopOnEnd;
  final double volume;
  final double playbackSpeed;
  final bool showControls;
  final Duration defaultVideoDuration;

  VideoPlaybackConfig copyWith({
    Duration? transitionDuration,
    bool? autoPlay,
    bool? loopOnEnd,
    double? volume,
    double? playbackSpeed,
    bool? showControls,
    Duration? defaultVideoDuration,
  }) {
    return VideoPlaybackConfig(
      transitionDuration: transitionDuration ?? this.transitionDuration,
      autoPlay: autoPlay ?? this.autoPlay,
      loopOnEnd: loopOnEnd ?? this.loopOnEnd,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      showControls: showControls ?? this.showControls,
      defaultVideoDuration: defaultVideoDuration ?? this.defaultVideoDuration,
    );
  }
}
