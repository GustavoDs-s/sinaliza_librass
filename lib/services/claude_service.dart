import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-6';

  final String apiKey;
  ClaudeService({required this.apiKey});

  static const String _systemPrompt = '''
Você é um especialista em Libras (Língua Brasileira de Sinais).
Sua tarefa é analisar imagens e identificar sinais de Libras realizados por mãos humanas.

Diretrizes:
- Quando identificar um sinal claro: informe a palavra/frase em português de forma direta
- Se não houver mãos visíveis: responda exatamente "Nenhum sinal identificado. Posicione suas mãos na câmera."
- Se o sinal for ambíguo: liste até 3 possibilidades com a mais provável em primeiro
- Se a imagem estiver escura/borrada: oriente o usuário a melhorar a iluminação

Responda sempre em português brasileiro. Seja conciso — máximo 2 frases.
''';

  Future<String> translateSign(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 500,
      'system': _systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': 'Qual sinal de Libras está sendo feito nesta imagem? Identifique e traduza para português.',
            },
          ],
        },
      ],
    });

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>;
      return content
          .whereType<Map<String, dynamic>>()
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join(' ')
          .trim();
    } else if (response.statusCode == 401) {
      throw Exception('API Key inválida. Verifique suas credenciais.');
    } else if (response.statusCode == 429) {
      throw Exception('Limite de requisições atingido. Aguarde um momento.');
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'Erro ${response.statusCode}');
    }
  }
}
