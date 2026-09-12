import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../util/json.dart';
import 'codes.dart';

/// A free-text clinical note or observation entry (FHIR `DocumentReference` /
/// `Composition` in a real system; kept as a first-class row here so students
/// can see the plain relational shape before meeting the FHIR one).
@immutable
class ClinicalNote {
  const ClinicalNote({
    required this.id,
    required this.patientId,
    required this.type,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.encounterId,
    this.updatedAt,
    this.isSigned = false,
    this.language = 'fr',
  });

  final String id;
  final String patientId;
  final NoteType type;
  final String title;
  final String body;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final String? encounterId;
  final DateTime? updatedAt;

  /// A signed note is locked: the UI stops offering the edit action.
  final bool isSigned;

  /// The language the note was written in. Clinical text is never
  /// machine-translated here - we show it as written and label it.
  final String language;

  /// First line, for use in collapsed list tiles.
  String get preview {
    final flattened = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flattened.length <= 120
        ? flattened
        : '${flattened.substring(0, 117)}...';
  }

  ClinicalNote copyWith({
    String? title,
    String? body,
    NoteType? type,
    bool? isSigned,
    DateTime? updatedAt,
  }) => ClinicalNote(
    id: id,
    patientId: patientId,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    authorName: authorName,
    authorRole: authorRole,
    createdAt: createdAt,
    encounterId: encounterId,
    updatedAt: updatedAt ?? DateTime.now(),
    isSigned: isSigned ?? this.isSigned,
    language: language,
  );

  factory ClinicalNote.fromJson(Map<String, dynamic> json) => ClinicalNote(
    id: asString(json['id']),
    patientId: asString(json['patient_id'] ?? json['patientId']),
    type: NoteType.fromName(asString(json['type'], fallback: 'progress')),
    title: asString(json['title']),
    body: asString(json['body']),
    authorName: asString(json['author_name'] ?? json['authorName']),
    authorRole: asString(json['author_role'] ?? json['authorRole']),
    createdAt: asDateTime(json['created_at'] ?? json['createdAt']),
    encounterId: asStringOrNull(json['encounter_id'] ?? json['encounterId']),
    updatedAt: asDateTimeOrNull(json['updated_at'] ?? json['updatedAt']),
    isSigned: asBool(json['is_signed'] ?? json['isSigned']),
    language: asString(json['language'], fallback: 'fr'),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'patient_id': patientId,
    'type': type.name,
    'title': title,
    'body': body,
    'author_name': authorName,
    'author_role': authorRole,
    'created_at': createdAt.toIso8601String(),
    'encounter_id': encounterId,
    'updated_at': updatedAt?.toIso8601String(),
    'is_signed': isSigned,
    'language': language,
  };

  /// Renders the note as a FHIR `DocumentReference` with the text inlined as
  /// base64, which is how a document repository would actually carry it.
  Map<String, dynamic> toFhir() => pruneNulls(<String, dynamic>{
    'resourceType': 'DocumentReference',
    'id': id,
    'status': 'current',
    'docStatus': isSigned ? 'final' : 'preliminary',
    'type': <String, dynamic>{
      'coding': <dynamic>[
        <String, dynamic>{
          'system': CodeSystems.localNoteType,
          'code': type.name,
          'display': type.display.en,
        },
      ],
      'text': title,
    },
    'subject': <String, dynamic>{'reference': 'Patient/$patientId'},
    'date': toFhirDateTime(createdAt),
    'author': <dynamic>[
      <String, dynamic>{'display': '$authorName ($authorRole)'},
    ],
    'description': title,
    'content': <dynamic>[
      <String, dynamic>{
        'attachment': <String, dynamic>{
          'contentType': 'text/plain; charset=utf-8',
          'language': language,
          'data': base64Encode(utf8.encode(body)),
          'title': title,
          'creation': toFhirDateTime(createdAt),
        },
      },
    ],
    if (encounterId != null)
      'context': <String, dynamic>{
        'encounter': <dynamic>[
          <String, dynamic>{'reference': 'Encounter/$encounterId'},
        ],
      },
  });
}
