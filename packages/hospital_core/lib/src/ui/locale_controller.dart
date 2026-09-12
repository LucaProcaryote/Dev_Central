import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supported_locales.dart';

/// Where the chosen interface language is remembered between sessions.
///
/// Abstracted rather than calling `SharedPreferences` directly so the
/// controller has no hard dependency on a platform plugin: widget tests inject
/// [InMemoryLocaleStore] and neither hang on a channel that nobody answers nor
/// leave a timeout timer running after the tree is torn down.
abstract class LocalePreferenceStore {
  /// The stored language code, or null if none was ever saved.
  Future<String?> read();

  Future<void> write(String languageCode);
}

/// The real implementation, backed by the platform's key-value store.
class SharedPreferencesLocaleStore implements LocalePreferenceStore {
  const SharedPreferencesLocaleStore();

  static const String _key = 'mini_hospital.locale';

  /// Local storage must never be able to stop the application from starting.
  /// It can hang indefinitely - a browser with site data blocked, a platform
  /// channel with nothing on the other end - and an application that will not
  /// open because it could not recall a language preference is a far worse
  /// failure than one that opens in the wrong language.
  static const Duration timeout = Duration(seconds: 1);

  @override
  Future<String?> read() async {
    final preferences =
        await SharedPreferences.getInstance().timeout(timeout);
    return preferences.getString(_key);
  }

  @override
  Future<void> write(String languageCode) async {
    final preferences =
        await SharedPreferences.getInstance().timeout(timeout);
    await preferences.setString(_key, languageCode);
  }
}

/// Remembers the language for the lifetime of the object only. Used by tests
/// and by any host where persistence is deliberately switched off.
class InMemoryLocaleStore implements LocalePreferenceStore {
  InMemoryLocaleStore([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String languageCode) async => _value = languageCode;
}

/// Holds the language the interface is currently displayed in.
///
/// The choice is per user and per device, remembered across reloads, and
/// deliberately separate from the patient's own preferred language: a Dutch
/// speaking nurse reading a francophone patient's file keeps a Dutch interface
/// while the patient's documents stay French.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initial, LocalePreferenceStore? store})
      : _locale = initial ?? SupportedLocales.english,
        _store = store ?? const SharedPreferencesLocaleStore();

  final LocalePreferenceStore _store;

  Locale _locale;
  Locale get locale => _locale;

  /// Restores the saved choice, falling back to the device language when the
  /// user has never picked one or when storage does not answer in time.
  Future<void> load({Locale? deviceLocale}) async {
    // Settle on a usable language first, so there is always something to
    // render even if the next step never returns.
    _locale = SupportedLocales.resolve(deviceLocale);

    try {
      final saved = await _store.read();
      if (saved != null && _isSupported(saved)) {
        _locale = Locale(saved);
      }
    } catch (_) {
      // Timed out or unavailable. Keep the device language.
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      await _store.write(locale.languageCode);
    } catch (_) {
      // A language that does not persist is a small loss; do not surface it,
      // and never let it break the switch the user just made.
    }
  }

  /// Cycles EN -> FR -> NL -> EN, for the compact toolbar button.
  Future<void> cycle() async {
    final index = SupportedLocales.all.indexOf(_locale);
    final next = SupportedLocales.all[(index + 1) % SupportedLocales.all.length];
    await setLocale(next);
  }

  static bool _isSupported(String languageCode) => SupportedLocales.all
      .any((locale) => locale.languageCode == languageCode);
}
