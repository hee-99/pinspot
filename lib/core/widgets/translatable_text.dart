import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../services/translation_service.dart';

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

class _TranslatableTextState extends State<TranslatableText> {
  String _displayed = '';
  String _lastText = '';
  String _lastLang = '';

  @override
  void initState() {
    super.initState();
    _displayed = widget.text;
    LocaleService.localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void didUpdateWidget(TranslatableText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _displayed = widget.text;
      _translate();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translate();
  }

  @override
  void dispose() {
    LocaleService.localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    _translate();
  }

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
