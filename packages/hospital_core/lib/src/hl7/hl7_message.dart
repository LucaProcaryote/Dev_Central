/// HL7 v2 "pipehat" (ER7) encoding and decoding.
///
/// FHIR is what the course teaches as the modern interface; HL7 v2 is what the
/// students will actually meet in a hospital corridor. The difference is worth
/// seeing rather than being told about, so the platform speaks both and the
/// integration canvas shows the translation between them as an explicit step.
///
/// This is a teaching implementation of the encoding layer, not a conformance
/// engine: it knows how a message is written down - segments, fields,
/// components, repetitions, escape sequences - and nothing about which fields
/// a given message type requires. Message structure lives in
/// `hl7_builder.dart`, and the mapping to FHIR in `hl7_to_fhir.dart`.
library;

/// The five delimiters that every HL7 v2 message declares in its own header.
///
/// They are not fixed by the standard: MSH-1 is the field separator and MSH-2
/// carries the other four, which is why a parser has to read them out of the
/// message before it can split anything. In practice everyone uses `|^~\&`,
/// and a message that does not is exactly the kind of thing that breaks a
/// naive integration.
class Hl7Encoding {
  const Hl7Encoding({
    this.field = '|',
    this.component = '^',
    this.repetition = '~',
    this.escape = r'\',
    this.subcomponent = '&',
  });

  final String field;
  final String component;
  final String repetition;
  final String escape;
  final String subcomponent;

  static const Hl7Encoding standard = Hl7Encoding();

  /// The four characters written into MSH-2, in their fixed order.
  String get encodingCharacters => '$component$repetition$escape$subcomponent';

  /// Reads the delimiters out of a message that starts with `MSH`.
  ///
  /// Falls back to the standard set when the header is too short to carry
  /// them, because a half-written header is better parsed optimistically than
  /// rejected: the student sees their message and the error in it.
  factory Hl7Encoding.fromHeader(String message) {
    if (message.length < 8 || !message.startsWith('MSH')) return standard;
    return Hl7Encoding(
      field: message[3],
      component: message[4],
      repetition: message[5],
      escape: message[6],
      subcomponent: message[7],
    );
  }

  /// Replaces delimiter characters in [value] with their escape sequences.
  ///
  /// Without this, a patient named `O'Brien^Smith` would silently become two
  /// name components - the classic way a v2 interface corrupts data.
  String encode(String value) => value
      .replaceAll(escape, '${escape}E$escape')
      .replaceAll(field, '${escape}F$escape')
      .replaceAll(component, '${escape}S$escape')
      .replaceAll(repetition, '${escape}R$escape')
      .replaceAll(subcomponent, '${escape}T$escape');

  /// Turns escape sequences back into the characters they stand for.
  String decode(String value) {
    if (!value.contains(escape)) return value;
    final buffer = StringBuffer();
    var index = 0;
    while (index < value.length) {
      if (value[index] != escape) {
        buffer.write(value[index]);
        index++;
        continue;
      }
      final end = value.indexOf(escape, index + 1);
      if (end == -1) {
        // Unterminated escape: keep it verbatim rather than losing the tail.
        buffer.write(value.substring(index));
        break;
      }
      final code = value.substring(index + 1, end);
      buffer.write(switch (code) {
        'F' => field,
        'S' => component,
        'R' => repetition,
        'E' => escape,
        'T' => subcomponent,
        // \X0D\ and friends are hex escapes; anything else is left as written
        // so nothing is silently discarded.
        _ => '$escape$code$escape',
      });
      index = end + 1;
    }
    return buffer.toString();
  }
}

/// One line of a message: a three-letter name followed by its fields.
///
/// Fields are held as written, so a segment survives a parse-and-serialise
/// round trip unchanged even where this code does not understand the content.
class Hl7Segment {
  Hl7Segment(this.name, List<String> fields)
    : _fields = List<String>.unmodifiable(fields);

  /// `MSH`, `PID`, `PV1`, `OBX`...
  final String name;

  /// Field 1 onwards, as raw strings. MSH is stored with its field separator
  /// already removed, so [field] can present the same numbering for every
  /// segment.
  final List<String> _fields;

  List<String> get fields => _fields;

  /// Field [number] using HL7's own 1-based numbering, or an empty string.
  ///
  /// MSH is the exception the standard builds in: MSH-1 *is* the field
  /// separator, so MSH-2 is the first thing stored and every later number is
  /// off by one against the other segments.
  String field(int number) {
    if (name == 'MSH') {
      if (number == 1) return '|';
      final index = number - 2;
      return index >= 0 && index < _fields.length ? _fields[index] : '';
    }
    final index = number - 1;
    return index >= 0 && index < _fields.length ? _fields[index] : '';
  }

  /// Component [component] of field [number], 1-based, or an empty string.
  String component(
    int number,
    int component, {
    Hl7Encoding encoding = Hl7Encoding.standard,
  }) {
    final parts = field(number).split(encoding.component);
    final index = component - 1;
    return index >= 0 && index < parts.length
        ? encoding.decode(parts[index])
        : '';
  }

  /// Writes the segment back out, trailing empty fields trimmed.
  String toEr7([Hl7Encoding encoding = Hl7Encoding.standard]) {
    final parts = List<String>.from(_fields);
    while (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    if (name == 'MSH') {
      // MSH-1 is the separator itself, so it is written by the join rather
      // than stored: `MSH` + `|` + `^~\&` + `|` + MSH-3...
      return '$name${encoding.field}${parts.join(encoding.field)}';
    }
    return [name, ...parts].join(encoding.field);
  }

  /// The segment as nested maps, for the integration canvas.
  ///
  /// The shape is deliberately predictable rather than clever:
  ///
  /// - a field with no delimiters is a plain string, at `PID.3`
  /// - a field with components is a map of numbered components, at `PID.5.1`
  /// - a field with repetitions is a list of the two forms above
  ///
  /// So a mapper node reads `PID.5.1` for a family name, which is the same
  /// notation the HL7 documentation uses. The editor's field picker lists the
  /// paths that are actually present, so nobody has to guess.
  Map<String, dynamic> toJson([Hl7Encoding encoding = Hl7Encoding.standard]) {
    final result = <String, dynamic>{};
    final first = name == 'MSH' ? 2 : 1;
    for (var i = 0; i < _fields.length; i++) {
      final raw = _fields[i];
      if (raw.isEmpty) continue;
      result['${first + i}'] = _fieldToJson(raw, encoding);
    }
    if (name == 'MSH') result['1'] = encoding.field;
    return result;
  }

  static Object _fieldToJson(String raw, Hl7Encoding encoding) {
    if (raw.contains(encoding.repetition)) {
      return raw
          .split(encoding.repetition)
          .map((r) => _repetitionToJson(r, encoding))
          .toList();
    }
    return _repetitionToJson(raw, encoding);
  }

  static Object _repetitionToJson(String raw, Hl7Encoding encoding) {
    if (!raw.contains(encoding.component)) return encoding.decode(raw);
    final parts = raw.split(encoding.component);
    final map = <String, dynamic>{};
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      map['${i + 1}'] = encoding.decode(parts[i]);
    }
    return map;
  }
}

/// A complete HL7 v2 message.
class Hl7Message {
  Hl7Message(List<Hl7Segment> segments, {this.encoding = Hl7Encoding.standard})
    : segments = List<Hl7Segment>.unmodifiable(segments);

  final List<Hl7Segment> segments;
  final Hl7Encoding encoding;

  /// Segments that carry more than one instance in the message types this
  /// platform builds, and are therefore always presented as a list.
  ///
  /// Without a fixed list the JSON shape would depend on the data - one
  /// observation gives a map, two give a list - and a flow that worked on
  /// Monday would break on Tuesday. Deciding it by segment name instead makes
  /// the shape a property of the message type, which is what a student can
  /// reason about.
  static const Set<String> repeatingSegments = <String>{
    'OBX',
    'OBR',
    'NK1',
    'AL1',
    'DG1',
    'NTE',
  };

  /// Parses an ER7 message. Segments are separated by carriage returns in the
  /// standard; real files arrive with `\n` or `\r\n` just as often, so all
  /// three are accepted.
  factory Hl7Message.parse(String source) {
    final trimmed = source.trim();
    final encoding = Hl7Encoding.fromHeader(trimmed);
    final lines = trimmed
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final segments = <Hl7Segment>[];
    for (final line in lines) {
      // Splitting on the field separator drops it, which is exactly right for
      // MSH too: what remains starts at MSH-2, the encoding characters, and
      // [Hl7Segment.field] puts the numbering back.
      final parts = line.split(encoding.field);
      segments.add(Hl7Segment(parts.first, parts.sublist(1)));
    }
    return Hl7Message(segments, encoding: encoding);
  }

  /// The first segment named [name], or null.
  Hl7Segment? segment(String name) {
    for (final segment in segments) {
      if (segment.name == name) return segment;
    }
    return null;
  }

  /// Every segment named [name], in document order.
  List<Hl7Segment> allSegments(String name) =>
      segments.where((s) => s.name == name).toList();

  /// MSH-9 as written, e.g. `ADT^A01` or `ORU^R01`.
  ///
  /// MSH-9 has three components - message code, trigger event, structure - and
  /// the first two are what everyone means by "the message type".
  String get messageType {
    final header = segment('MSH');
    if (header == null) return '';
    final raw = header.field(9);
    final parts = raw.split(encoding.component);
    if (parts.length >= 2) return '${parts[0]}^${parts[1]}';
    return raw;
  }

  /// MSH-10, the sender's unique id for this message. What you quote when you
  /// telephone the other hospital's integration team.
  String get controlId => segment('MSH')?.field(10) ?? '';

  /// MSH-3, the sending application.
  String get sendingApplication => segment('MSH')?.field(3) ?? '';

  /// Writes the message out. Segments are joined with `\r`, which is what the
  /// standard says and what an MLLP listener expects.
  String toEr7() => segments.map((s) => s.toEr7(encoding)).join('\r');

  /// The message as JSON for the integration engine.
  ///
  /// Carries the original text under `hl7` as well as the parsed segments, so
  /// a flow can route on a parsed field and still deliver the message exactly
  /// as it arrived - which is what an interface engine is expected to do when
  /// it is only a router.
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'hl7': toEr7(),
      'message_type': messageType,
      'message_control_id': controlId,
      'sending_application': sendingApplication,
    };
    final seen = <String>{};
    for (final segment in segments) {
      if (!seen.add(segment.name)) continue;
      final instances = allSegments(segment.name);
      if (repeatingSegments.contains(segment.name)) {
        result[segment.name] = instances
            .map((s) => s.toJson(encoding))
            .toList();
      } else if (instances.length == 1) {
        result[segment.name] = instances.first.toJson(encoding);
      } else {
        // An unexpected repeat still has to be representable, or the extra
        // instances would vanish without anyone noticing.
        result[segment.name] = instances
            .map((s) => s.toJson(encoding))
            .toList();
      }
    }
    return result;
  }

  @override
  String toString() => toEr7();
}
