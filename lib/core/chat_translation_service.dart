import 'package:translator/translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TranslationLanguage {
  const TranslationLanguage({required this.code, required this.label});

  final String code;
  final String label;
}

/// Lightweight translation helper for chat message previews.
class ChatTranslationService {
  ChatTranslationService._();

  static final ChatTranslationService instance = ChatTranslationService._();

  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _cache = <String, String>{};
  List<TranslationLanguage>? _languagesCache;

  Future<String> translate({
    required String text,
    required String toLanguageCode,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return normalized;
    final cacheKey = '$toLanguageCode::$normalized';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    try {
      final out = await _translator.translate(normalized, to: toLanguageCode);
      final translated = out.text.trim();
      if (translated.isNotEmpty) {
        _cache[cacheKey] = translated;
        return translated;
      }
      return normalized;
    } catch (_) {
      return normalized;
    }
  }

  Future<List<TranslationLanguage>> fetchSupportedLanguages({
    String localeCode = 'en',
  }) async {
    if (_languagesCache != null && _languagesCache!.isNotEmpty) {
      return _languagesCache!;
    }
    try {
      final client = Supabase.instance.client;
      final raw = await client.rpc<dynamic>(
        'get_chat_translation_languages',
        params: {'p_locale': localeCode},
      );
      final out = <TranslationLanguage>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final code = (row['code']?.toString() ?? '').trim().toLowerCase();
          final label = (row['label']?.toString() ?? '').trim();
          if (code.isEmpty || label.isEmpty) continue;
          out.add(TranslationLanguage(code: code, label: label));
        }
      }
      if (out.isNotEmpty) {
        _languagesCache = out;
        return out;
      }
    } catch (_) {}
    final fallback = <TranslationLanguage>[
      const TranslationLanguage(code: 'tr', label: 'Turkish'),
      const TranslationLanguage(code: 'en', label: 'English'),
      const TranslationLanguage(code: 'es', label: 'Spanish'),
      const TranslationLanguage(code: 'de', label: 'German'),
      const TranslationLanguage(code: 'fr', label: 'French'),
      const TranslationLanguage(code: 'ar', label: 'Arabic'),
      const TranslationLanguage(code: 'ru', label: 'Russian'),
    ];
    _languagesCache = fallback;
    return fallback;
  }
}
