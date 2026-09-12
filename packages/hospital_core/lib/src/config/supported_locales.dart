import 'package:flutter/widgets.dart';

/// The three languages every application in the mini-hospital must speak.
///
/// The order here is the order shown in the language switcher.
class SupportedLocales {
  const SupportedLocales._();

  static const Locale english = Locale('en');
  static const Locale french = Locale('fr');
  static const Locale dutch = Locale('nl');

  static const List<Locale> all = <Locale>[english, french, dutch];

  /// Endonyms - each language is written in itself, which is what users expect
  /// in a language picker.
  static const Map<String, String> nativeNames = <String, String>{
    'en': 'English',
    'fr': 'Français',
    'nl': 'Nederlands',
  };

  /// Short badge label used in dense toolbars.
  static const Map<String, String> shortNames = <String, String>{
    'en': 'EN',
    'fr': 'FR',
    'nl': 'NL',
  };

  static String nativeNameOf(Locale locale) =>
      nativeNames[locale.languageCode] ?? locale.languageCode.toUpperCase();

  static String shortNameOf(Locale locale) =>
      shortNames[locale.languageCode] ?? locale.languageCode.toUpperCase();

  /// Picks the best supported locale for a device locale, defaulting to English.
  static Locale resolve(Locale? deviceLocale) {
    if (deviceLocale == null) return english;
    for (final locale in all) {
      if (locale.languageCode == deviceLocale.languageCode) return locale;
    }
    return english;
  }
}
