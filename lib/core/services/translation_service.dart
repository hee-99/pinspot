import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  // In-memory cache for the current session
  static final Map<String, String> _memCache = {};

  static const _persistPrefix = 'tx_';

  /// Translate [text] from Korean to [targetLang].
  /// Returns original text immediately if:
  /// - targetLang is 'ko' (source language)
  /// - text is empty / whitespace
  /// Falls back to original text on any error.
  static Future<String> translate(String text, String targetLang) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || targetLang == 'ko') return text;
    // Skip single numbers, short symbols, pure English/numbers
    if (_skipTranslation(trimmed, targetLang)) return text;

    final key = '${trimmed}_$targetLang';

    // 1. Memory cache
    if (_memCache.containsKey(key)) return _memCache[key]!;

    // 2. Persistent cache
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_persistPrefix${key.hashCode}');
    if (stored != null && stored.isNotEmpty) {
      _memCache[key] = stored;
      return stored;
    }

    // 3. Network call
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=ko&tl=$targetLang&dt=t&q=${Uri.encodeComponent(trimmed)}',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final parts = (data[0] as List)
            .map((e) => (e as List?)?.first?.toString() ?? '')
            .join('');
        if (parts.isNotEmpty) {
          _memCache[key] = parts;
          await prefs.setString('$_persistPrefix${key.hashCode}', parts);
          return parts;
        }
      }
    } catch (_) {
      // Network error → return original silently
    }

    return text;
  }

  /// Translate a batch of texts. Returns a list in the same order.
  static Future<List<String>> translateBatch(
      List<String> texts, String targetLang) async {
    return Future.wait(texts.map((t) => translate(t, targetLang)));
  }

  /// Clear all cached translations (useful for testing).
  static Future<void> clearCache() async {
    _memCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_persistPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static bool _skipTranslation(String text, String targetLang) {
    // Pure numbers / coordinates
    if (RegExp(r"""^[\d.,\s\-+:/°'"]+$""").hasMatch(text)) return true;
    // Very short strings (1-2 chars)
    if (text.length <= 2) return true;
    // Already in Latin script when targeting 'en' and no Korean
    if (targetLang == 'en' && !_hasKorean(text)) return true;
    return false;
  }

  static bool _hasKorean(String text) =>
      text.runes.any((r) => r >= 0xAC00 && r <= 0xD7A3);
}
