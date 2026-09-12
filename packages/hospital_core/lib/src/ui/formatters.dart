import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/hospital_localizations.dart';

/// Date and time formatting that follows the interface language.
///
/// A Dutch-speaking user expects `12-09-2026`, a francophone `12/09/2026`, an
/// English one `12 Sep 2026`. `intl` already knows all three; these helpers
/// just make sure every screen asks it the same way.
class Formats {
  const Formats._();

  static String _tag(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// `12 Sep 2026`
  static String date(BuildContext context, DateTime value) =>
      DateFormat.yMMMd(_tag(context)).format(value.toLocal());

  /// `12/09/2026`
  static String shortDate(BuildContext context, DateTime value) =>
      DateFormat.yMd(_tag(context)).format(value.toLocal());

  /// `14:35`
  static String time(BuildContext context, DateTime value) =>
      DateFormat.Hm(_tag(context)).format(value.toLocal());

  /// `12 Sep 2026, 14:35`
  static String dateTime(BuildContext context, DateTime value) =>
      '${date(context, value)}, ${time(context, value)}';

  /// `12 Sep`, for dense axes and timelines within the current year.
  static String dayMonth(BuildContext context, DateTime value) =>
      DateFormat.MMMd(_tag(context)).format(value.toLocal());

  /// Today's entries show only a time; anything older shows the date too.
  static String smart(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) return time(context, local);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (isYesterday) {
      return '${HospitalLocalizations.of(context).labelYesterday} '
          '${time(context, local)}';
    }
    return dateTime(context, local);
  }

  /// `3 d 4 h`, `12 h`, `45 min` - compact enough for a table cell.
  static String duration(BuildContext context, Duration value) {
    if (value.inDays >= 1) {
      final hours = value.inHours % 24;
      return hours == 0 ? '${value.inDays} d' : '${value.inDays} d $hours h';
    }
    if (value.inHours >= 1) return '${value.inHours} h';
    return '${value.inMinutes} min';
  }

  /// `2 min ago` in the interface language, for freshness indicators.
  static String ago(BuildContext context, DateTime value) {
    final elapsed = DateTime.now().difference(value);
    final code = _tag(context);
    if (elapsed.inSeconds < 60) {
      return switch (code) {
        'fr' => "à l'instant",
        'nl' => 'zojuist',
        _ => 'just now',
      };
    }
    final amount = elapsed.inDays >= 1
        ? '${elapsed.inDays} d'
        : elapsed.inHours >= 1
        ? '${elapsed.inHours} h'
        : '${elapsed.inMinutes} min';
    return switch (code) {
      'fr' => 'il y a $amount',
      'nl' => '$amount geleden',
      _ => '$amount ago',
    };
  }

  /// Formats a measurement with the right number of decimals for its kind.
  static String number(double value, int decimals) =>
      value.toStringAsFixed(decimals);
}
