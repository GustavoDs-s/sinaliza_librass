class TranslationEntry {
  final String text;
  final DateTime timestamp;
  final bool isError;

  TranslationEntry({
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory TranslationEntry.fromJson(Map<String, dynamic> json) =>
      TranslationEntry(
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
      );
}
