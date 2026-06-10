import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_entry.dart';

class HistoryService {
  static const String _key = 'translation_history';
  static const int _maxEntries = 50;

  Future<List<TranslationEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => TranslationEntry.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveEntry(TranslationEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    final trimmed = raw.length > _maxEntries
        ? raw.sublist(raw.length - _maxEntries)
        : raw;
    await prefs.setStringList(_key, trimmed);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
