import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/landmark_info_model.dart';

const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

class LandmarkInfoService {
  static const _geminiModel = 'gemini-flash-lite-latest';
  static const _cachePrefix = 'landmark_v1_';

  static String _cacheKey(String name) =>
      _cachePrefix + name.trim().toLowerCase().replaceAll(RegExp(r'[\s/\\]+'), '_');

  static Future<LandmarkInfo?> getCached(String placeName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(placeName));
    if (raw == null) return null;
    return LandmarkInfo.tryParse(raw);
  }

  static Future<void> _save(LandmarkInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(info.placeName), jsonEncode(info.toJson()));
  }

  /// 1순위 Wikipedia(정확도 높음) → 실패 시 Gemini AI 폴백 → 모두 실패 시 기존 캐시 반환
  static Future<LandmarkInfo?> fetchInfo({
    required String placeName,
    double? lat,
    double? lng,
  }) async {
    if (placeName.trim().isEmpty) return null;

    final cached = await getCached(placeName);
    if (cached != null && !cached.isStale) return cached;

    LandmarkInfo? info = await _fetchFromWikipedia(placeName);
    info ??= await _fetchFromGemini(placeName, lat, lng);

    if (info != null) {
      await _save(info);
      return info;
    }
    return cached;
  }

  // ── Gemini API ─────────────────────────────────────────────────────────────

  static Future<LandmarkInfo?> _fetchFromGemini(
    String placeName,
    double? lat,
    double? lng,
  ) async {
    try {
      final locationHint = (lat != null && lng != null)
          ? ' (coordinates: lat ${lat.toStringAsFixed(4)}, lng ${lng.toStringAsFixed(4)})'
          : '';

      final prompt =
          'Tell me about this Korean landmark: $placeName$locationHint. '
          'Respond ONLY with this exact JSON format, no markdown, no explanation: '
          '{"origin": "history and origin in Korean 2-3 sentences", '
          '"highlights": "main attractions and features in Korean 2-3 sentences", '
          '"bestTime": "best visit time/season in Korean 1 sentence or null", '
          '"tip": "practical visit tip in Korean 1 sentence or null"}';

      final resp = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$kGeminiApiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {
                    'text':
                        'You are a Korean tourist information expert. Always respond with pure JSON only, no markdown, no explanation.',
                  },
                ],
              },
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'maxOutputTokens': 600,
                'temperature': 0.1,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = (candidates.first['content']?['parts'] as List?) ?? [];
      if (parts.isEmpty) return null;
      final text = parts.first['text'] as String? ?? '';

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text.trim());
      if (jsonMatch == null) return null;

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      return LandmarkInfo(
        placeName: placeName,
        origin: parsed['origin'] as String? ?? '',
        highlights: parsed['highlights'] as String? ?? '',
        bestTime: parsed['bestTime'] as String?,
        tip: parsed['tip'] as String?,
        fetchedAt: DateTime.now(),
        source: 'gemini',
      );
    } catch (_) {
      return null;
    }
  }

  // ── Wikipedia API ──────────────────────────────────────────────────────────

  static Future<LandmarkInfo?> _fetchFromWikipedia(String placeName) async {
    try {
      // 1) 장소명으로 한국어 위키백과 검색
      final searchResp = await http
          .get(
            Uri.parse(
              'https://ko.wikipedia.org/w/api.php'
              '?action=query&list=search'
              '&srsearch=${Uri.encodeComponent(placeName)}'
              '&format=json&utf8=1&srlimit=1&origin=*',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (searchResp.statusCode != 200) return null;

      final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
      final hits = (searchData['query']?['search'] as List?) ?? [];
      if (hits.isEmpty) return null;

      final wikiTitle = hits.first['title'] as String;

      // 2) 페이지 요약(extract) 가져오기
      final summaryResp = await http
          .get(
            Uri.parse(
              'https://ko.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(wikiTitle)}',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (summaryResp.statusCode != 200) return null;

      final summaryData = jsonDecode(summaryResp.body) as Map<String, dynamic>;
      final extract = summaryData['extract'] as String? ?? '';
      final description = summaryData['description'] as String? ?? '';

      if (extract.isEmpty) return null;

      // 문장 분리: 앞 절반 → 유래/역사, 뒷 절반 → 볼거리/특징
      final sentences = extract
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();

      final mid = max(1, min(3, sentences.length ~/ 2));
      final origin = sentences.take(mid).join(' ');
      final highlightsRaw = sentences.skip(mid).take(3).join(' ');
      final highlights =
          highlightsRaw.isNotEmpty ? highlightsRaw : description;

      return LandmarkInfo(
        placeName: placeName,
        origin: origin,
        highlights: highlights.isNotEmpty
            ? highlights
            : '위키백과에서 추가 정보를 찾을 수 없습니다.',
        bestTime: null,
        tip: '출처: 한국어 위키백과 "$wikiTitle"',
        fetchedAt: DateTime.now(),
        source: 'wikipedia',
      );
    } catch (_) {
      return null;
    }
  }

  // ── 앱 시작 시 만료 캐시 백그라운드 갱신 ───────────────────────────────────

  static Future<void> refreshStaleCacheInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final staleKeys = prefs
        .getKeys()
        .where((k) => k.startsWith(_cachePrefix))
        .where((k) {
      final info = LandmarkInfo.tryParse(prefs.getString(k) ?? '');
      return info != null && info.isStale;
    }).toList();

    for (final key in staleKeys) {
      final info = LandmarkInfo.tryParse(prefs.getString(key) ?? '');
      if (info != null) {
        fetchInfo(placeName: info.placeName).ignore();
      }
    }
  }
}
