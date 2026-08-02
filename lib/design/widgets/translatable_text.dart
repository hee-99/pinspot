import 'package:flutter/material.dart';
import 'package:pinspot/account/settings/services/locale_service.dart';
import 'package:pinspot/core/services/translation_service.dart';

// 현재 앱 언어에 맞춰 텍스트를 자동 번역해 보여주는 위젯 (번역 완료 전까지는 원문을 우선 표시)
/// A Text widget that automatically translates its content based on the current
/// app locale. Shows original text immediately while translation loads.
class TranslatableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const TranslatableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

// TranslatableText의 상태 클래스 — 번역 결과 캐싱과 언어 변경 감지를 담당
class _TranslatableTextState extends State<TranslatableText> {
  String _displayed = '';
  String _lastText = '';
  String _lastLang = '';

  @override
  void initState() {
    super.initState();
    // 최초에는 원문을 즉시 표시하고, 언어 변경 이벤트를 구독
    _displayed = widget.text;
    LocaleService.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void didUpdateWidget(TranslatableText old) {
    super.didUpdateWidget(old);
    // 부모가 전달하는 원문 텍스트가 바뀌면 다시 번역
    if (old.text != widget.text) {
      _displayed = widget.text;
      _translate();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 위젯이 처음 빌드되거나 의존성이 바뀔 때 번역 시도
    _translate();
  }

  @override
  void dispose() {
    // 언어 변경 리스너 해제로 메모리 누수 방지
    LocaleService.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  // 앱 언어 설정이 바뀔 때 호출되어 재번역을 트리거
  void _onLocaleChanged() {
    _translate();
  }

  // 번역 서비스를 호출해 결과를 반영 — 비동기 응답 도중 텍스트/언어가 또 바뀌었으면(stale 응답) 무시
  Future<void> _translate() async {
    final text = widget.text;
    final lang = LocaleService.currentCode;
    if (text == _lastText && lang == _lastLang) return;
    _lastText = text;
    _lastLang = lang;

    final result = await TranslationService.translate(text, lang);
    if (mounted && _lastText == text && _lastLang == lang) {
      setState(() => _displayed = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
    );
  }
}
