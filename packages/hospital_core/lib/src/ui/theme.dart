import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// The visual identity of the mini-hospital.
///
/// Each application gets its own seed colour so that a student with five tabs
/// open knows at a glance which one they are looking at, while everything else
/// - spacing, shape, typography - stays identical across the suite.
class HospitalTheme {
  const HospitalTheme._();

  static const Map<HospitalApp, Color> seedColors = <HospitalApp, Color>{
    HospitalApp.ehr: Color(0xFF00696D), // teal - the clinical record
    HospitalApp.adt: Color(0xFF3F5AA9), // indigo - movement and logistics
    HospitalApp.pharm: Color(0xFF7A5900), // amber - the pharmacy
    HospitalApp.eai: Color(0xFF6750A4), // violet - plumbing between systems
    HospitalApp.device: Color(0xFF386A20), // green - devices and signals
  };

  /// Status colours, which must not be derived from the seed: a critical value
  /// is red in every application, whatever that application's accent is.
  ///
  /// The four are shown side by side on the bed board and in the vitals
  /// tables, so they were validated as a set rather than picked by eye - each
  /// mode clears the lightness band, the chroma floor and the normal-vision
  /// separation floor against its own surface, and the dark steps are chosen
  /// for the dark surface rather than flipped from the light ones.
  ///
  /// Two caveats the widgets honour: the deutan/protan separation of the
  /// red-amber and amber-green pairs sits in the 6-8 band, and light-mode amber
  /// falls below 3:1 on a light surface. Both are relieved the same way - every
  /// status is drawn with a written label, and never colour alone. Do not
  /// introduce a status pill without its text.
  static Color critical(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFD9455A)
      : const Color(0xFFE34948);

  static Color warning(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFFB98A00)
      : const Color(0xFFEDA100);

  static Color success(Brightness brightness) => const Color(0xFF008300);

  static Color info(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF3987E5)
      : const Color(0xFF2A78D6);

  /// The single hue every vital-sign trend is drawn in. The charts are one
  /// series each - the title names the measurement - so the line never needs to
  /// carry identity, only to be legible.
  static Color series(Brightness brightness) => info(brightness);

  /// Convenience accessors that read the brightness off the ambient theme.
  static Color criticalOf(BuildContext context) =>
      critical(Theme.of(context).brightness);
  static Color warningOf(BuildContext context) =>
      warning(Theme.of(context).brightness);
  static Color successOf(BuildContext context) =>
      success(Theme.of(context).brightness);
  static Color infoOf(BuildContext context) =>
      info(Theme.of(context).brightness);
  static Color seriesOf(BuildContext context) =>
      series(Theme.of(context).brightness);

  static ThemeData light(HospitalApp app) => _build(app, Brightness.light);
  static ThemeData dark(HospitalApp app) => _build(app, Brightness.dark);

  static ThemeData _build(HospitalApp app, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColors[app] ?? seedColors[HospitalApp.ehr]!,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Spacing scale. Using these instead of ad-hoc numbers is what keeps five
/// applications written over several weeks looking like one product.
class Gap {
  const Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const Widget h4 = SizedBox(height: xs);
  static const Widget h8 = SizedBox(height: sm);
  static const Widget h16 = SizedBox(height: md);
  static const Widget h24 = SizedBox(height: lg);
  static const Widget h32 = SizedBox(height: xl);

  static const Widget w4 = SizedBox(width: xs);
  static const Widget w8 = SizedBox(width: sm);
  static const Widget w16 = SizedBox(width: md);
  static const Widget w24 = SizedBox(width: lg);
}

/// Layout breakpoints. The applications must work on a phone in a corridor and
/// on a 27-inch screen at the nurses' station.
class Breakpoints {
  const Breakpoints._();
  static const double compact = 600;
  static const double medium = 1000;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compact && width < medium;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
}
