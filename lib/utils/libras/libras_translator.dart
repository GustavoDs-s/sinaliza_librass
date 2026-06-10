import 'libras_dictionary.dart';
import 'text_normalizer.dart';

class TranslatedSign {
  TranslatedSign({
    required this.word,
    required this.videoPaths,
    required this.isFound,
    this.fallbackReason,
  });

  final String word;
  final List<String> videoPaths;
  final bool isFound;
  final String? fallbackReason;

  @override
  String toString() {
    return 'TranslatedSign(word: $word, videos: ${videoPaths.length}, found: $isFound, fallback: $fallbackReason)';
  }
}

class LibrasTranslator {
  static const Map<String, List<String>> manualAlphabet = {
    'a': ['1.mp4', '2.mp4', '3.mp4'],
    'b': ['1.mp4', '2.mp4', '3.mp4'],
    'c': ['1.mp4', '2.mp4', '3.mp4'],
    'd': ['1.mp4', '2.mp4', '3.mp4'],
    'e': ['1.mp4', '2.mp4', '3.mp4'],
    'f': ['1.mp4', '2.mp4', '3.mp4'],
    'g': ['1.mp4', '2.mp4', '3.mp4'],
    'h': ['1.mp4', '2.mp4', '3.mp4'],
    'i': ['1.mp4', '2.mp4', '3.mp4'],
    'j': ['1.mp4', '2.mp4', '3.mp4'],
    'k': ['1.mp4', '2.mp4', '3.mp4'],
    'l': ['1.mp4', '2.mp4', '3.mp4'],
    'm': ['1.mp4', '2.mp4', '3.mp4'],
    'n': ['1.mp4', '2.mp4', '3.mp4'],
    'o': ['1.mp4', '2.mp4', '3.mp4'],
    'p': ['1.mp4', '2.mp4', '3.mp4'],
    'q': ['1.mp4', '2.mp4', '3.mp4'],
    'r': ['1.mp4', '2.mp4', '3.mp4'],
    's': ['1.mp4', '2.mp4', '3.mp4'],
    't': ['1.mp4', '2.mp4', '3.mp4'],
    'u': ['1.mp4', '2.mp4', '3.mp4'],
    'v': ['1.mp4', '2.mp4', '3.mp4'],
    'w': ['1.mp4', '2.mp4', '3.mp4'],
    'x': ['1.mp4', '2.mp4', '3.mp4'],
    'y': ['1.mp4', '2.mp4', '3.mp4'],
    'z': ['1.mp4', '2.mp4', '3.mp4'],
  };

  static const Map<String, List<String>> synonyms = {
    'oi': ['ola', 'olá'],
    'carro': ['automovel', 'automóvel', 'veiculo', 'veículo'],
    'bicicleta': ['bike'],
    'comida': ['alimento', 'refeicao', 'refeição'],
    'bebida': ['liquido', 'líquido', 'agua', 'água', 'suco'],
    'feliz': ['alegre', 'contente'],
    'triste': ['infeliz'],
  };

  static List<TranslatedSign> translate(String text, {bool useLemmatization = true}) {
    final processedWords = TextNormalizer.processText(text, useLemmatization: useLemmatization);

    final signs = <TranslatedSign>[];
    for (final word in processedWords) {
      signs.addAll(_translateWordToSigns(word));
    }
    return signs;
  }

  static List<TranslatedSign> _translateWordToSigns(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      return [
        TranslatedSign(
          word: trimmed,
          videoPaths: const [],
          isFound: false,
          fallbackReason: 'Palavra vazia',
        ),
      ];
    }

    if (LibrasDictionary.hasWord(trimmed)) {
      return [
        TranslatedSign(
          word: trimmed,
          videoPaths: LibrasDictionary.getVideoPathsForWord(trimmed),
          isFound: true,
        ),
      ];
    }

    final normalizedMatch = _findDictionaryWordByNormalizedForm(trimmed);
    if (normalizedMatch != null) {
      return [
        TranslatedSign(
          word: normalizedMatch,
          videoPaths: LibrasDictionary.getVideoPathsForWord(normalizedMatch),
          isFound: true,
          fallbackReason: 'Equivalencia: $normalizedMatch',
        ),
      ];
    }

    final directCandidates = _buildDirectWordAssetCandidates(trimmed);
    if (directCandidates.isNotEmpty) {
      return [
        TranslatedSign(
          word: trimmed,
          videoPaths: directCandidates,
          isFound: true,
          fallbackReason: 'Tentando variações 1/2/3 para "$trimmed"',
        ),
      ];
    }

    final synonym = _findSynonym(trimmed);
    if (synonym != null && LibrasDictionary.hasWord(synonym)) {
      return [
        TranslatedSign(
          word: trimmed,
          videoPaths: LibrasDictionary.getVideoPathsForWord(synonym),
          isFound: true,
          fallbackReason: 'Sinonimo: $synonym',
        ),
      ];
    }

    final prefixMatch = _findPrefixMatch(trimmed);
    if (prefixMatch != null) {
      return [
        TranslatedSign(
          word: trimmed,
          videoPaths: LibrasDictionary.getVideoPathsForWord(prefixMatch),
          isFound: true,
          fallbackReason: 'Prefixo: $prefixMatch',
        ),
      ];
    }

    final spelledSigns = _spellWordToSigns(trimmed);
    if (spelledSigns.isNotEmpty) {
      return spelledSigns;
    }

    return [
      TranslatedSign(
        word: trimmed,
        videoPaths: const [],
        isFound: false,
        fallbackReason: 'Palavra nao encontrada',
      ),
    ];
  }

  static String? _findDictionaryWordByNormalizedForm(String word) {
    final normalized = TextNormalizer.normalize(word);

    for (final candidate in LibrasDictionary.getAllWords()) {
      if (TextNormalizer.normalize(candidate) == normalized) {
        return candidate;
      }
    }

    return null;
  }

  static List<String> _buildDirectWordAssetCandidates(String word) {
    final normalized = TextNormalizer.normalize(word);
    final variants = <String>{
      word,
      normalized,
      word.replaceAll(' ', '_'),
      normalized.replaceAll(' ', '_'),
      word.replaceAll(' ', '-'),
      normalized.replaceAll(' ', '-'),
    }..removeWhere((item) => item.trim().isEmpty);

    final candidates = <String>[];
    for (final variant in variants) {
      for (final suffix in const ['1.mp4', '2.mp4', '3.mp4']) {
        candidates.add('lib/utils/libras/$variant/$suffix');
      }
    }

    return candidates;
  }

  static String? _findSynonym(String word) {
    for (final entry in synonyms.entries) {
      if (entry.value.contains(word) && LibrasDictionary.hasWord(entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  static String? _findPrefixMatch(String word) {
    for (var i = word.length; i > 2; i--) {
      final prefix = word.substring(0, i);
      if (LibrasDictionary.hasWord(prefix)) {
        return prefix;
      }
    }
    return null;
  }

  static List<TranslatedSign> _spellWordToSigns(String originalWord) {
    final normalizedWord = TextNormalizer.normalize(originalWord);
    final signs = <TranslatedSign>[];

    for (var i = 0; i < normalizedWord.length; i++) {
      final char = normalizedWord[i];

      if (manualAlphabet.containsKey(char)) {
        signs.add(
          TranslatedSign(
            word: char,
            videoPaths: _buildLetterVideoCandidates(char),
            isFound: false,
            fallbackReason: 'Soletrando "$originalWord"',
          ),
        );
        continue;
      }

      if (char.contains(RegExp(r'[0-9]'))) {
        final numberWord = _numberToWord(char);
        if (numberWord != null && LibrasDictionary.hasWord(numberWord)) {
          signs.add(
            TranslatedSign(
              word: numberWord,
              videoPaths: LibrasDictionary.getVideoPathsForWord(numberWord),
              isFound: true,
              fallbackReason: 'Numero em "$originalWord"',
            ),
          );
        }
      }
    }

    return signs;
  }

  static List<TranslatedSign> getSpellingFallbackSigns(String word) {
    return _spellWordToSigns(word);
  }

  static List<String> _buildLetterVideoCandidates(String letter) {
    final variants = manualAlphabet[letter] ?? const ['1.mp4'];
    final candidates = <String>[];

    for (final fileName in variants) {
      candidates.add('lib/utils/libras/letras/$letter/$fileName');
    }

    return candidates;
  }

  static String? _numberToWord(String number) {
    const numberWords = {
      '0': 'zero',
      '1': 'um',
      '2': 'dois',
      '3': 'três',
      '4': 'quatro',
      '5': 'cinco',
      '6': 'seis',
      '7': 'sete',
      '8': 'oito',
      '9': 'nove',
    };

    return numberWords[number];
  }

  static Map<String, dynamic> getTranslationStats(String text) {
    final signs = translate(text);
    final foundSigns = signs.where((s) => s.isFound).length;
    final fallbackSigns = signs.where((s) => !s.isFound && s.videoPaths.isNotEmpty).length;
    final totalVideos = signs.fold<int>(0, (sum, sign) => sum + sign.videoPaths.length);

    return {
      'totalSigns': signs.length,
      'foundSigns': foundSigns,
      'fallbackSigns': fallbackSigns,
      'notFoundSigns': signs.length - foundSigns - fallbackSigns,
      'totalVideoFrames': totalVideos,
      'signs': signs,
    };
  }

  static String getTranslationReport(String text) {
    final stats = getTranslationStats(text);
    final signs = stats['signs'] as List<TranslatedSign>;

    final report = StringBuffer();
    report.writeln('=== RELATORIO DE TRADUCAO ===\n');
    report.writeln('Texto original: "$text"\n');
    report.writeln('Total de sinais: ${stats['totalSigns']}');
    report.writeln('Sinais encontrados: ${stats['foundSigns']}');
    report.writeln('Com fallback: ${stats['fallbackSigns']}');
    report.writeln('Nao encontrados: ${stats['notFoundSigns']}');
    report.writeln('Total de quadros de video: ${stats['totalVideoFrames']}\n');

    report.writeln('=== DETALHES ===');
    for (var i = 0; i < signs.length; i++) {
      final sign = signs[i];
      report.writeln(
        '${i + 1}. ${sign.word} - Videos: ${sign.videoPaths.length} | Encontrado: ${sign.isFound} | Motivo: ${sign.fallbackReason ?? 'N/A'}',
      );
    }

    return report.toString();
  }
}
