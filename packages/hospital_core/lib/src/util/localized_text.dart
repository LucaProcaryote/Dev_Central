import 'package:flutter/widgets.dart';

/// A short piece of text that exists in all three hospital languages.
///
/// Localisation files (ARB) cover the *interface*. Data that lives in the
/// database - ward names, drug labels, allergy reactions - also has to be
/// trilingual, and it cannot come from ARB because it is content, not chrome.
/// [LocalizedText] is the storage format for that content: it round-trips to a
/// single JSON object / PostgreSQL `jsonb` column.
@immutable
class LocalizedText {
  const LocalizedText({required this.en, required this.fr, required this.nl});

  /// Convenience for content that is identical in all three languages, such as
  /// a proper noun or an international unit.
  const LocalizedText.same(String value) : en = value, fr = value, nl = value;

  final String en;
  final String fr;
  final String nl;

  /// Returns the variant for [languageCode], falling back to English.
  String forLanguage(String languageCode) => switch (languageCode) {
    'fr' => fr,
    'nl' => nl,
    _ => en,
  };

  /// Returns the variant matching [locale], falling back to English.
  String forLocale(Locale locale) => forLanguage(locale.languageCode);

  /// Resolves against the ambient locale of [context].
  String of(BuildContext context) => forLocale(Localizations.localeOf(context));

  factory LocalizedText.fromJson(Object? json) {
    if (json == null) return const LocalizedText.same('');
    if (json is String) return LocalizedText.same(json);
    final map = (json as Map).cast<String, dynamic>();
    final en = (map['en'] as String?) ?? '';
    return LocalizedText(
      en: en,
      fr: (map['fr'] as String?) ?? en,
      nl: (map['nl'] as String?) ?? en,
    );
  }

  Map<String, String> toJson() => <String, String>{
    'en': en,
    'fr': fr,
    'nl': nl,
  };

  @override
  bool operator ==(Object other) =>
      other is LocalizedText &&
      other.en == en &&
      other.fr == fr &&
      other.nl == nl;

  @override
  int get hashCode => Object.hash(en, fr, nl);

  @override
  String toString() => en;
}
