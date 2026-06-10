class TextNormalizer {
  static const Set<String> stopwords = {
    'o',
    'a',
    'os',
    'as',
    'um',
    'uma',
    'de',
    'da',
    'do',
    'em',
    'no',
    'na',
    'para',
    'com',
    'sem',
    'e',
    'ou',
    'mas',
    'que',
    'se',
    'como',
    'porque',
    'eu',
    'tu',
    'ele',
    'ela',
    'nos',
    'nós',
    'eles',
    'elas',
    'ser',
    'estar',
    'ter',
    'haver',
    'nao',
    'não',
    'sim',
    'ja',
    'já',
    'ainda',
    'sempre',
    'nunca',
    'muito',
    'pouco',
    'bem',
    'mal',
  };

  static const Map<String, String> lemmatizationMap = {
    'quero': 'querer',
    'quer': 'querer',
    'queremos': 'querer',
    'estou': 'estar',
    'esta': 'estar',
    'está': 'estar',
    'estamos': 'estar',
    'tenho': 'ter',
    'tem': 'ter',
    'faz': 'fazer',
    'faco': 'fazer',
    'faço': 'fazer',
    'homens': 'homem',
    'mulheres': 'mulher',
    'criancas': 'crianca',
    'crianças': 'criança',
  };

  static String normalize(String text) {
    var normalized = text.toLowerCase();
    normalized = _removeAccents(normalized);
    normalized = normalized.replaceAll(RegExp(r'[^\\w\\s]', multiLine: true), '');
    normalized = normalized.replaceAll(RegExp(r'\\s+'), ' ').trim();
    return normalized;
  }

  static String _removeAccents(String str) {
    const source = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const target = 'aaaaaeeeeiiiiooooouuuucn';

    var result = str;
    for (var i = 0; i < source.length; i++) {
      result = result.replaceAll(source[i], target[i]);
    }
    return result;
  }

  static List<String> tokenize(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) {
      return [];
    }
    return normalized.split(RegExp(r'\\s+'));
  }

  static List<String> removeStopwords(List<String> words) {
    return words.where((word) => !stopwords.contains(word) && word.isNotEmpty).toList();
  }

  static String lemmatize(String word) {
    final normalized = normalize(word);
    return lemmatizationMap[normalized] ?? normalized;
  }

  static List<String> processText(String text, {bool useLemmatization = true}) {
    var tokens = tokenize(text);
    tokens = removeStopwords(tokens);

    if (useLemmatization) {
      tokens = tokens.map(lemmatize).toList();
    }

    return tokens;
  }

  static Map<String, dynamic> getStats(String text) {
    final normalized = normalize(text);
    final tokens = tokenize(text);
    final processed = processText(text);

    return {
      'original': text,
      'normalized': normalized,
      'totalTokens': tokens.length,
      'uniqueTokens': tokens.toSet().length,
      'processedLength': processed.length,
      'removedStopwords': tokens.length - processed.length,
      'tokens': tokens,
      'processedTokens': processed,
    };
  }
}
