import '../util/localized_text.dart';

/// The per-field transformation a mapper node can apply.
///
/// Kept small and total: every transform accepts any input and returns
/// something sensible, so a student experimenting on the canvas never sees a
/// crash, only a surprising value they can reason about.
enum FieldTransform {
  none(
    LocalizedText(
      en: 'Copy as is',
      fr: 'Copier tel quel',
      nl: 'Ongewijzigd kopiëren',
    ),
    takesArgument: false,
  ),
  uppercase(
    LocalizedText(en: 'UPPERCASE', fr: 'MAJUSCULES', nl: 'HOOFDLETTERS'),
    takesArgument: false,
  ),
  lowercase(
    LocalizedText(en: 'lowercase', fr: 'minuscules', nl: 'kleine letters'),
    takesArgument: false,
  ),
  trim(
    LocalizedText(
      en: 'Trim spaces',
      fr: 'Supprimer les espaces',
      nl: 'Spaties verwijderen',
    ),
    takesArgument: false,
  ),
  dateOnly(
    LocalizedText(
      en: 'Date only (YYYY-MM-DD)',
      fr: 'Date seule (AAAA-MM-JJ)',
      nl: 'Alleen datum (JJJJ-MM-DD)',
    ),
    takesArgument: false,
  ),
  toNumber(
    LocalizedText(en: 'To number', fr: 'Vers nombre', nl: 'Naar getal'),
    takesArgument: false,
  ),
  toText(
    LocalizedText(en: 'To text', fr: 'Vers texte', nl: 'Naar tekst'),
    takesArgument: false,
  ),
  constant(
    LocalizedText(en: 'Fixed value', fr: 'Valeur fixe', nl: 'Vaste waarde'),
    takesArgument: true,
  ),
  prefix(
    LocalizedText(
      en: 'Add prefix',
      fr: 'Ajouter un préfixe',
      nl: 'Voorvoegsel toevoegen',
    ),
    takesArgument: true,
  ),
  suffix(
    LocalizedText(
      en: 'Add suffix',
      fr: 'Ajouter un suffixe',
      nl: 'Achtervoegsel toevoegen',
    ),
    takesArgument: true,
  ),
  stripPrefix(
    LocalizedText(
      en: 'Remove prefix',
      fr: 'Retirer un préfixe',
      nl: 'Voorvoegsel verwijderen',
    ),
    takesArgument: true,
  ),
  defaultIfEmpty(
    LocalizedText(
      en: 'Default if empty',
      fr: 'Valeur par défaut si vide',
      nl: 'Standaardwaarde indien leeg',
    ),
    takesArgument: true,
  );

  const FieldTransform(this.display, {required this.takesArgument});

  final LocalizedText display;

  /// Whether the editor should show the argument text field for this transform.
  final bool takesArgument;

  static FieldTransform fromName(String value) => values.firstWhere(
    (t) => t.name == value,
    orElse: () => FieldTransform.none,
  );

  /// Applies the transform. [argument] is ignored when [takesArgument] is false.
  Object? apply(Object? input, String? argument) {
    final arg = argument ?? '';
    switch (this) {
      case FieldTransform.none:
        return input;
      case FieldTransform.uppercase:
        return input?.toString().toUpperCase();
      case FieldTransform.lowercase:
        return input?.toString().toLowerCase();
      case FieldTransform.trim:
        return input?.toString().trim();
      case FieldTransform.dateOnly:
        final text = input?.toString() ?? '';
        final parsed = DateTime.tryParse(text);
        if (parsed != null) return parsed.toIso8601String().substring(0, 10);
        return text.length >= 10 ? text.substring(0, 10) : text;
      case FieldTransform.toNumber:
        if (input is num) return input;
        return num.tryParse(input?.toString() ?? '');
      case FieldTransform.toText:
        return input?.toString();
      case FieldTransform.constant:
        return arg;
      case FieldTransform.prefix:
        return '$arg${input ?? ''}';
      case FieldTransform.suffix:
        return '${input ?? ''}$arg';
      case FieldTransform.stripPrefix:
        final text = input?.toString() ?? '';
        return text.startsWith(arg) ? text.substring(arg.length) : text;
      case FieldTransform.defaultIfEmpty:
        final text = input?.toString() ?? '';
        return text.isEmpty ? arg : input;
    }
  }
}

/// One row of a field-mapper node.
class FieldMapping {
  const FieldMapping({
    required this.sourcePath,
    required this.targetPath,
    this.transform = FieldTransform.none,
    this.argument,
  });

  final String sourcePath;
  final String targetPath;
  final FieldTransform transform;
  final String? argument;

  factory FieldMapping.fromJson(Map<String, dynamic> json) => FieldMapping(
    sourcePath: (json['source'] ?? json['sourcePath'] ?? '').toString(),
    targetPath: (json['target'] ?? json['targetPath'] ?? '').toString(),
    transform: FieldTransform.fromName(
      (json['transform'] ?? 'none').toString(),
    ),
    argument: json['argument']?.toString(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'source': sourcePath,
    'target': targetPath,
    'transform': transform.name,
    'argument': argument,
  };
}

/// Comparison used by filter and router nodes.
enum FilterOperator {
  equals('=', LocalizedText(en: 'equals', fr: 'égal à', nl: 'gelijk aan')),
  notEquals(
    '≠',
    LocalizedText(en: 'is not', fr: 'différent de', nl: 'niet gelijk aan'),
  ),
  contains('∋', LocalizedText(en: 'contains', fr: 'contient', nl: 'bevat')),
  startsWith(
    '^',
    LocalizedText(en: 'starts with', fr: 'commence par', nl: 'begint met'),
  ),
  exists(
    '∃',
    LocalizedText(en: 'is present', fr: 'est présent', nl: 'is aanwezig'),
  ),
  notExists(
    '∄',
    LocalizedText(en: 'is absent', fr: 'est absent', nl: 'is afwezig'),
  ),
  greaterThan(
    '>',
    LocalizedText(en: 'greater than', fr: 'supérieur à', nl: 'groter dan'),
  ),
  lessThan(
    '<',
    LocalizedText(en: 'less than', fr: 'inférieur à', nl: 'kleiner dan'),
  );

  const FilterOperator(this.symbol, this.display);

  final String symbol;
  final LocalizedText display;

  bool get takesValue =>
      this != FilterOperator.exists && this != FilterOperator.notExists;

  static FilterOperator fromName(String value) => values.firstWhere(
    (o) => o.name == value,
    orElse: () => FilterOperator.equals,
  );

  /// Evaluates `actual <op> expected`.
  bool evaluate(Object? actual, String expected) {
    switch (this) {
      case FilterOperator.exists:
        return actual != null && actual.toString().isNotEmpty;
      case FilterOperator.notExists:
        return actual == null || actual.toString().isEmpty;
      case FilterOperator.equals:
        return actual?.toString() == expected;
      case FilterOperator.notEquals:
        return actual?.toString() != expected;
      case FilterOperator.contains:
        return (actual?.toString() ?? '').contains(expected);
      case FilterOperator.startsWith:
        return (actual?.toString() ?? '').startsWith(expected);
      case FilterOperator.greaterThan:
        final a = _asNum(actual);
        final b = num.tryParse(expected);
        return a != null && b != null && a > b;
      case FilterOperator.lessThan:
        final a = _asNum(actual);
        final b = num.tryParse(expected);
        return a != null && b != null && a < b;
    }
  }

  static num? _asNum(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');
}
