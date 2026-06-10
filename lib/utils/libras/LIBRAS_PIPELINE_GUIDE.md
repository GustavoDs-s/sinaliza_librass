# Pipeline de Conversão Texto → Libras

Este documento descreve o pipeline completo de tradução de texto em português para sequência de sinais em Libras.

## 📋 Arquitetura

```
Texto (entrada)
    ↓
TextNormalizer.processText()
    - lowercase
    - remover pontuação
    - remover stopwords (artigos, preposições)
    - lematização opcional
    → List<String> (palavras processadas)
    ↓
LibrasTranslator.translate()
    - mapear palavras para sinais no dicionário
    - se não encontrar: buscar sinônimos
    - se não encontrar: buscar prefixo
    - se não encontrar: soletrar (alfabeto manual)
    - fallback final: vazio
    → List<TranslatedSign> (com caminhos de vídeos)
    ↓
VideoPlaybackService
    - organizar em fila de reprodução
    - gerenciar cache
    - reproduzir com transições
    → Player Widget (com progresso visual)
```

## 🔧 Componentes

### 1. **TextNormalizer** (`text_normalizer.dart`)
Responsável pela normalização do texto em português.

**Funções principais:**
- `normalize(text)` - Texto normalizado (lowercase, sem pontuação)
- `tokenize(text)` - Quebra em palavras
- `removeStopwords(words)` - Remove artigos, preposições, etc
- `lemmatize(word)` - Converte para forma canônica (ex: "quero" → "querer")
- `processText(text)` - Pipeline completo

**Stopwords removidos:**
- Artigos: o, a, os, as, um, uma, uns, umas
- Preposições: de, da, do, em, no, na, para, com, sem, sob, entre, etc
- Conjunções: e, ou, mas, que, se, como, porque, etc
- Pronomes: eu, tu, ele, ela, nós, vós, eles, elas
- Verbos auxiliares: ser, estar, ter, haver
- Outros: não, sim, já, ainda, sempre, nunca, muito, pouco, bem, mal

**Exemplo:**
```dart
TextNormalizer.processText("Eu quero beber água!")
// Resultado: ["querer", "beber", "água"]
```

### 2. **LibrasDictionary** (`libras_dictionary.dart`)
Dicionário de palavras em português → vídeos em Libras.

**Estrutura:**
- Cada palavra mapeia para variações de vídeos (1.mp4, 2.mp4, 3.mp4)
- As 3 variações representam 3 pessoas diferentes executando o sinal
- Caminho completo: `assets/libras/palavra/1.mp4`

**Funções principais:**
- `getVideos(word)` - Obtém lista de vídeos
- `hasWord(word)` - Verifica se palavra existe
- `getVideoPathsForWord(word)` - Retorna caminhos completos

**Exemplo:**
```dart
LibrasDictionary.getVideoPathsForWord("água")
// Resultado: ["assets/libras/água/1.mp4", "assets/libras/água/2.mp4", "assets/libras/água/3.mp4"]
```

### 3. **LibrasTranslator** (`libras_translator.dart`)
Tradutor principal que converte palavras em sinais com estratégias de fallback.

**Funções principais:**
- `translate(text)` - Traduz texto completo → List<TranslatedSign>
- Estratégias de fallback em ordem:
  1. Busca exata no dicionário
  2. Busca por sinônimos
  3. Busca por prefixo (deletar letras progressivamente)
  4. Soletrar com alfabeto manual (letra por letra)
  5. Ignorar (vazio)

**Estrutura TranslatedSign:**
```dart
TranslatedSign {
  word: String,                    // Palavra original
  videoPaths: List<String>,        // Caminhos dos vídeos
  isFound: bool,                   // Se foi encontrada no dicionário
  fallbackReason: String?          // Motivo do fallback (se usado)
}
```

**Exemplo:**
```dart
final signs = LibrasTranslator.translate("Eu quero beber água");
// Resultado: [
//   TranslatedSign(word: "querer", videoPaths: [...], isFound: true),
//   TranslatedSign(word: "beber", videoPaths: [...], isFound: true),
//   TranslatedSign(word: "água", videoPaths: [...], isFound: true)
// ]

// Palavra desconhecida:
final signs = LibrasTranslator.translate("xyz");
// Resultado: [
//   TranslatedSign(
//     word: "xyz", 
//     videoPaths: ["assets/libras/alfabeto_manual/x/...", ...],
//     isFound: false,
//     fallbackReason: "Alfabeto manual (soletrado)"
//   )
// ]
```

### 4. **VideoQueue** (`video_queue.dart`)
Gerencia fila de reprodução de vídeos.

**Classes:**
- `VideoQueue` - Fila completa
- `VideoItem` - Item individual
- `VideoPlaybackConfig` - Configurações

**Funções principales:**
- `getCurrentVideo()` - Vídeo atual
- `getNextVideo()` / `hasNext()`
- `getPreviousVideo()` / `hasPrevious()`
- `getProgress()` - 0.0 a 1.0

### 5. **VideoPlaybackService** (`video_playback_service.dart`)
Serviço singleton para gerenciar reprodução e cache.

**Gerenciamento de cache:**
```dart
final service = VideoPlaybackService();

// Marcar como carregando
service.markVideoLoading("assets/libras/água/1.mp4");

// Marcar como carregado
service.markVideoLoaded("assets/libras/água/1.mp4");

// Verificar estado
if (service.isVideoCached("assets/libras/água/1.mp4")) {
  // Usar vídeo em cache
}

// Limpar cache
service.clearCache();

// Estatísticas
final stats = service.getCacheStats();
// { total: 150, loaded: 145, loading: 0, error: 5 }
```

**Widgets auxiliares:**
- `VideoPlayerWithTransition` - Player com fade in/out
- `VideoProgressBar` - Barra de progresso
- `SignList` - Lista de sinais com status visual

## 📱 Integração na Interface

Na página `TextToSignPage`:

```dart
// 1. Quando usuário clica "Traduzir"
_translateText() {
  final signs = LibrasTranslator.translate(_controller.text);
  _translatedSigns = signs;
}

// 2. Reproduzir automaticamente
_playSignSequence() async {
  for (final sign in _translatedSigns) {
    // Mostrar vídeo por 2s + 300ms de transição
    await Future.delayed(Duration(milliseconds: 2300));
  }
}

// 3. UI mostra:
// - Vídeo atual com animação de fade
// - Barra de progresso
// - Lista de sinais com status (atual, concluído, pendente)
// - Botões de controle (play, info, compartilhar)
```

## 📊 Exemplo Completo

```dart
// Entrada
String portuguese = "Eu quero beber água por favor";

// 1. Normalização
List<String> tokens = TextNormalizer.processText(portuguese);
// → ["querer", "beber", "água"]

// 2. Tradução
List<TranslatedSign> signs = LibrasTranslator.translate(portuguese);
// → [
//     TranslatedSign(word: "querer", videoPaths: 3, isFound: true),
//     TranslatedSign(word: "beber", videoPaths: 3, isFound: true),
//     TranslatedSign(word: "água", videoPaths: 3, isFound: true),
//   ]

// 3. Fila
VideoQueue queue = VideoQueue(items: signs);

// 4. Reprodução
// - Mostra "querer" por 2s com fade
// - Transição 300ms
// - Mostra "beber" por 2s com fade
// - Transição 300ms
// - Mostra "água" por 2s com fade
// - Fim
```

## ⚠️ Notas sobre Libras

Português e Libras têm estruturas diferentes:
- Português: SVO (Sujeito-Verbo-Objeto)
- Libras: OSV ou SOV dependendo do contexto
- Artigos são geralmente omitidos em Libras
- Preposições são expressas através de classificadores

**Exemplo:**
- PT: "Eu quero beber água"
- LIBRAS: "ÁGUA BEBER QUERER" (com aspectos e classificadores)

O sistema atual remove stopwords automaticamente, aproximando a ordem do português ao padrão da Libras.

## 🔄 Fluxo de Processamento Detalhado

```
"Olá, eu sou João e quero beber água!"
              ↓ normalize()
"ola eu sou joao e quero beber agua"
              ↓ tokenize()
["ola", "eu", "sou", "joao", "e", "quero", "beber", "agua"]
              ↓ removeStopwords()
["ola", "joao", "quero", "beber", "agua"]
              ↓ lemmatize()
["ola", "joao", "querer", "beber", "agua"]
              ↓ translate()
[
  Sign(word: "ola", videos: 3, found: true),
  Sign(word: "joao", videos: 3, found: false, fallback: "Alfabeto manual"),
  Sign(word: "querer", videos: 3, found: true),
  Sign(word: "beber", videos: 3, found: true),
  Sign(word: "agua", videos: 3, found: true),
]
```

## 🎯 Tarefas Implementadas

✅ **Obrigatórias:**
- [x] JSON de dicionário (palavra → vídeos)
- [x] Função de normalização
- [x] Função de tradução
- [x] Fallback (alfabeto manual com soletração)

✅ **Recomendadas:**
- [x] Lematização (mapping de formas verbais)
- [x] Lista de stopwords
- [x] Cache de vídeos (VideoPlaybackService)

## 🚀 Próximas Melhorias Possíveis

1. Integração com spaCy ou Natural NLP para lematização mais sofisticada
2. Busca por sinônimos mais inteligente (usando word embeddings)
3. Suporte a classificadores de Libras (maneiras/formas de fazer sinais)
4. Reconhecimento de contexto para melhor seleção de sinais
5. Verificação de concordância verbal e nominal
6. Suporte a velocidades de sinais diferentes (rápido, normal, lento)
7. Transcrição automática de Libras para Português (caminho inverso)
8. Avatar 3D para reproduzir sinais dinamicamente
9. Integração com TTS para pronúncia em português
10. Análise de áudio para melhor pontuação no processamento

---

**Versão:** 1.0  
**Data:** 2026-03-25  
**Status:** Produção
