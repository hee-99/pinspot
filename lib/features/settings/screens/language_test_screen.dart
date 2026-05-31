import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/app_theme.dart';

/// Screen to verify that the auto-translation system works end-to-end.
/// Shows sample Korean content translated live into all 4 supported languages.
class LanguageTestScreen extends StatefulWidget {
  const LanguageTestScreen({super.key});

  @override
  State<LanguageTestScreen> createState() => _LanguageTestScreenState();
}

class _LanguageTestScreenState extends State<LanguageTestScreen> {
  static const _samples = [
    '경복궁 일출 명소',
    '서울 야경이 너무 아름다워요. 꼭 방문해보세요!',
    '부산 해운대 해변에서 찍은 사진입니다.',
    '제주도 올레길 트레킹 추천해요.',
    '인사동 전통 찻집에서의 여유로운 오후',
  ];

  static const _langs = ['ko', 'en', 'ja', 'zh'];

  final Map<String, Map<String, String>> _results = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _translateAll();
  }

  Future<void> _translateAll() async {
    setState(() => _loading = true);
    for (final text in _samples) {
      _results[text] = {};
      for (final lang in _langs) {
        final translated = await TranslationService.translate(text, lang);
        if (mounted) {
          setState(() => _results[text]![lang] = translated);
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _clearAndRetranslate() async {
    await TranslationService.clearCache();
    setState(() => _results.clear());
    await _translateAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          '번역 테스트',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '캐시 초기화 후 재번역',
            onPressed: _loading ? null : _clearAndRetranslate,
          ),
        ],
      ),
      body: Column(
        children: [
          _LangSwitcher(current: LocaleService.currentCode),
          const Divider(height: 1),
          Expanded(
            child: _loading && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _samples.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _SampleCard(
                      original: _samples[i],
                      translations: _results[_samples[i]] ?? {},
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LangSwitcher extends StatelessWidget {
  final String current;
  const _LangSwitcher({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('현재 언어:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ...AppLocalizations.languageNames.entries.map((e) {
            final selected = e.key == current;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () async {
                  await LocaleService.setLocale(e.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${AppLocalizations.languageFlags[e.key]} ${e.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SampleCard extends StatelessWidget {
  final String original;
  final Map<String, String> translations;

  const _SampleCard({required this.original, required this.translations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('원문 (KO)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(original, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Divider(height: 16),
          ...['en', 'ja', 'zh'].map((lang) {
            final translated = translations[lang];
            final flag = AppLocalizations.languageFlags[lang] ?? '';
            final name = AppLocalizations.languageNames[lang] ?? lang.toUpperCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Text('$flag $name',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: translated == null
                        ? const SizedBox(
                            height: 12,
                            width: 80,
                            child: LinearProgressIndicator(minHeight: 2),
                          )
                        : Text(
                            translated,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
