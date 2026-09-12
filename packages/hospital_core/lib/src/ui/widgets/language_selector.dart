import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/supported_locales.dart';
import '../locale_controller.dart';

/// The EN / FR / NL switcher.
///
/// Every application puts this in its app bar. Requiring students to restart an
/// app to change language would make the trilingual requirement feel like a
/// build-time setting rather than something a user does mid-shift.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key, this.compact = false});

  /// On a phone there is no room for three labels; show a single button that
  /// cycles through the languages instead.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final current = controller.locale;

    if (compact) {
      return IconButton(
        onPressed: controller.cycle,
        tooltip: SupportedLocales.nativeNameOf(current),
        icon: Text(
          SupportedLocales.shortNameOf(current),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    }

    return SegmentedButton<Locale>(
      showSelectedIcon: false,
      segments: <ButtonSegment<Locale>>[
        for (final locale in SupportedLocales.all)
          ButtonSegment<Locale>(
            value: locale,
            label: Text(SupportedLocales.shortNameOf(locale)),
            tooltip: SupportedLocales.nativeNameOf(locale),
          ),
      ],
      selected: <Locale>{current},
      onSelectionChanged: (selection) => controller.setLocale(selection.first),
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
