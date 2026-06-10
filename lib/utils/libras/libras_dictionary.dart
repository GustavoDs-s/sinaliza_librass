class LibrasDictionary {
  static const Map<String, List<String>> dictionary = {
    'querer': ['1.mp4', '2.mp4', '3.mp4'],
    'agua': ['1.mp4', '2.mp4', '3.mp4'],
    'água': ['1.mp4', '2.mp4', '3.mp4'],
    'beber': ['1.mp4', '2.mp4', '3.mp4'],
    'comer': ['1.mp4', '2.mp4', '3.mp4'],
    'falar': ['1.mp4', '2.mp4', '3.mp4'],
    'ver': ['1.mp4', '2.mp4', '3.mp4'],
    'ouvir': ['1.mp4', '2.mp4', '3.mp4'],
    'dar': ['1.mp4', '2.mp4', '3.mp4'],
    'ir': ['1.mp4', '2.mp4', '3.mp4'],
    'fazer': ['1.mp4', '2.mp4', '3.mp4'],
    'estar': ['1.mp4', '2.mp4', '3.mp4'],
    'ser': ['1.mp4', '2.mp4', '3.mp4'],
    'ter': ['1.mp4', '2.mp4', '3.mp4'],
    'ajudar': ['1.mp4', '2.mp4', '3.mp4'],
    'trabalhar': ['1.mp4', '2.mp4', '3.mp4'],
    'dormir': ['1.mp4', '2.mp4', '3.mp4'],
    'acordar': ['1.mp4', '2.mp4', '3.mp4'],
    'andar': ['1.mp4', '2.mp4', '3.mp4'],
    'abrir': ['1.mp4', '2.mp4', '3.mp4'],
    'fechar': ['1.mp4', '2.mp4', '3.mp4'],
    'comprar': ['1.mp4', '2.mp4', '3.mp4'],
    'pagar': ['1.mp4', '2.mp4', '3.mp4'],
    'pessoa': ['1.mp4', '2.mp4', '3.mp4'],
    'homem': ['1.mp4', '2.mp4', '3.mp4'],
    'mulher': ['1.mp4', '2.mp4', '3.mp4'],
    'crianca': ['1.mp4', '2.mp4', '3.mp4'],
    'criança': ['1.mp4', '2.mp4', '3.mp4'],
    'amigo': ['1.mp4', '2.mp4', '3.mp4'],
    'professor': ['1.mp4', '2.mp4', '3.mp4'],
    'medico': ['1.mp4', '2.mp4', '3.mp4'],
    'médico': ['1.mp4', '2.mp4', '3.mp4'],
    'cachorro': ['1.mp4', '2.mp4', '3.mp4'],
    'gato': ['1.mp4', '2.mp4', '3.mp4'],
    'carro': ['1.mp4', '2.mp4', '3.mp4'],
    'bicicleta': ['1.mp4', '2.mp4', '3.mp4'],
    'casa': ['1.mp4', '2.mp4', '3.mp4'],
    'escola': ['1.mp4', '2.mp4', '3.mp4'],
    'hospital': ['1.mp4', '2.mp4', '3.mp4'],
    'cidade': ['1.mp4', '2.mp4', '3.mp4'],
    'fruta': ['1.mp4', '2.mp4', '3.mp4'],
    'pao': ['1.mp4', '2.mp4', '3.mp4'],
    'pão': ['1.mp4', '2.mp4', '3.mp4'],
    'cafe': ['1.mp4', '2.mp4', '3.mp4'],
    'café': ['1.mp4', '2.mp4', '3.mp4'],
    'suco': ['1.mp4', '2.mp4', '3.mp4'],
    'feliz': ['1.mp4', '2.mp4', '3.mp4'],
    'triste': ['1.mp4', '2.mp4', '3.mp4'],
    'bom': ['1.mp4', '2.mp4', '3.mp4'],
    'ruim': ['1.mp4', '2.mp4', '3.mp4'],
    'calma': ['1.mp4', '2.mp4', '3.mp4'],
    'obrigado': ['1.mp4', '2.mp4', '3.mp4'],
    'obrigada': ['1.mp4', '2.mp4', '3.mp4'],
    'ola': ['1.mp4', '2.mp4', '3.mp4'],
    'olá': ['1.mp4', '2.mp4', '3.mp4'],
    'dia': ['1.mp4', '2.mp4', '3.mp4'],
    'noite': ['1.mp4', '2.mp4', '3.mp4'],
    'hoje': ['1.mp4', '2.mp4', '3.mp4'],
    'amanha': ['1.mp4', '2.mp4', '3.mp4'],
    'amanhã': ['1.mp4', '2.mp4', '3.mp4'],
    'sim': ['1.mp4', '2.mp4', '3.mp4'],
    'nao': ['1.mp4', '2.mp4', '3.mp4'],
    'não': ['1.mp4', '2.mp4', '3.mp4'],
    'eu': ['1.mp4', '2.mp4', '3.mp4'],
    'voce': ['1.mp4', '2.mp4', '3.mp4'],
    'você': ['1.mp4', '2.mp4', '3.mp4'],
    'zero': ['1.mp4', '2.mp4', '3.mp4'],
    'um': ['1.mp4', '2.mp4', '3.mp4'],
    'dois': ['1.mp4', '2.mp4', '3.mp4'],
    'tres': ['1.mp4', '2.mp4', '3.mp4'],
    'três': ['1.mp4', '2.mp4', '3.mp4'],
    'quatro': ['1.mp4', '2.mp4', '3.mp4'],
    'cinco': ['1.mp4', '2.mp4', '3.mp4'],
    'seis': ['1.mp4', '2.mp4', '3.mp4'],
    'sete': ['1.mp4', '2.mp4', '3.mp4'],
    'oito': ['1.mp4', '2.mp4', '3.mp4'],
    'nove': ['1.mp4', '2.mp4', '3.mp4'],
  };

  static List<String>? getVideos(String word) {
    return dictionary[word];
  }

  static bool hasWord(String word) {
    return dictionary.containsKey(word);
  }

  static Set<String> getAllWords() {
    return dictionary.keys.toSet();
  }

  static String getVideoPath(String word, String videoFile) {
    return 'lib/utils/libras/$word/$videoFile';
  }

  static List<String> getVideoPathsForWord(String word) {
    final videos = dictionary[word];
    if (videos == null) {
      return [];
    }
    return videos.map((video) => getVideoPath(word, video)).toList();
  }
}
