/// Small, forgiving JSON readers.
///
/// API payloads arrive from three different backends (in-memory, the Dart REST
/// server, Firebase Data Connect) and PostgreSQL happily returns a numeric
/// column as `int` where JSON gave us `double`. These helpers absorb that
/// variation in one place instead of at every call site.
library;

String? asStringOrNull(Object? value) => value?.toString();

String asString(Object? value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

int? asIntOrNull(Object? value) => switch (value) {
      null => null,
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };

int asInt(Object? value, {int fallback = 0}) => asIntOrNull(value) ?? fallback;

double? asDoubleOrNull(Object? value) => switch (value) {
      null => null,
      final double v => v,
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };

double asDouble(Object? value, {double fallback = 0}) =>
    asDoubleOrNull(value) ?? fallback;

bool asBool(Object? value, {bool fallback = false}) => switch (value) {
      null => fallback,
      final bool v => v,
      final num v => v != 0,
      'true' || 't' || '1' || 'yes' => true,
      'false' || 'f' || '0' || 'no' => false,
      _ => fallback,
    };

/// Parses an ISO-8601 timestamp, tolerating nulls and malformed values.
DateTime? asDateTimeOrNull(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

DateTime asDateTime(Object? value, {DateTime? fallback}) =>
    asDateTimeOrNull(value) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Formats a [DateTime] as a FHIR `dateTime` (always UTC, second precision).
String toFhirDateTime(DateTime value) =>
    '${value.toUtc().toIso8601String().split('.').first}Z';

/// Formats a [DateTime] as a FHIR `date` (`YYYY-MM-DD`).
String toFhirDate(DateTime value) =>
    value.toIso8601String().substring(0, 10);

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList(growable: false);
}

List<String> asStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.map((e) => e.toString()).toList(growable: false);
}

/// Removes `null` values so generated FHIR JSON stays free of empty elements,
/// which the FHIR specification forbids.
Map<String, dynamic> pruneNulls(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    if (value == null) return;
    if (value is List && value.isEmpty) return;
    if (value is Map && value.isEmpty) return;
    result[key] = value;
  });
  return result;
}
