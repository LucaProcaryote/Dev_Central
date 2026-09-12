import 'package:flutter/foundation.dart';

import '../util/json.dart';
import '../util/localized_text.dart';

/// The kind of building block a node represents on the integration canvas.
///
/// Nodes fall into three families - sources produce messages, processors
/// change or filter them, destinations deliver them - and the editor uses
/// [family] to decide which ports a node exposes and which palette group it
/// belongs to.
enum FlowNodeType {
  // ---- Sources -------------------------------------------------------------
  httpSource(
    FlowNodeFamily.source,
    LocalizedText(en: 'HTTP endpoint', fr: 'Point HTTP', nl: 'HTTP-eindpunt'),
    LocalizedText(
      en: 'Accepts messages posted by an application.',
      fr: 'Accepte les messages envoyés par une application.',
      nl: 'Accepteert berichten die door een toepassing worden verzonden.',
    ),
  ),
  deviceSource(
    FlowNodeFamily.source,
    LocalizedText(en: 'Device feed', fr: 'Flux appareil', nl: 'Apparaatstroom'),
    LocalizedText(
      en: 'Vital signs pushed by the connected device simulators.',
      fr: 'Signes vitaux envoyés par les simulateurs d’appareils connectés.',
      nl: 'Vitale functies verzonden door de aangesloten apparaatsimulatoren.',
    ),
  ),
  adtSource(
    FlowNodeFamily.source,
    LocalizedText(
      en: 'ADT events',
      fr: 'Événements ADT',
      nl: 'ADT-gebeurtenissen',
    ),
    LocalizedText(
      en: 'Admission, transfer and discharge movements.',
      fr: 'Mouvements d’admission, de transfert et de sortie.',
      nl: 'Opname-, overplaatsings- en ontslagbewegingen.',
    ),
  ),
  timerSource(
    FlowNodeFamily.source,
    LocalizedText(en: 'Timer', fr: 'Minuterie', nl: 'Timer'),
    LocalizedText(
      en: 'Fires on a schedule, for batch jobs.',
      fr: 'Se déclenche selon un horaire, pour les traitements par lots.',
      nl: 'Start volgens een schema, voor batchverwerking.',
    ),
  ),

  // ---- Processors ----------------------------------------------------------
  filter(
    FlowNodeFamily.processor,
    LocalizedText(en: 'Filter', fr: 'Filtre', nl: 'Filter'),
    LocalizedText(
      en: 'Passes only the messages matching a condition.',
      fr: 'Ne laisse passer que les messages remplissant une condition.',
      nl: 'Laat alleen berichten door die aan een voorwaarde voldoen.',
    ),
  ),
  mapper(
    FlowNodeFamily.processor,
    LocalizedText(
      en: 'Field mapper',
      fr: 'Mappage de champs',
      nl: 'Veldtoewijzing',
    ),
    LocalizedText(
      en: 'Moves and rewrites fields from the input to the output.',
      fr: 'Déplace et réécrit les champs de l’entrée vers la sortie.',
      nl: 'Verplaatst en herschrijft velden van invoer naar uitvoer.',
    ),
  ),
  enricher(
    FlowNodeFamily.processor,
    LocalizedText(en: 'Enricher', fr: 'Enrichisseur', nl: 'Verrijker'),
    LocalizedText(
      en: 'Looks up the patient and adds demographics to the message.',
      fr: 'Recherche le patient et ajoute ses données démographiques.',
      nl: 'Zoekt de patiënt op en voegt demografische gegevens toe.',
    ),
  ),
  validator(
    FlowNodeFamily.processor,
    LocalizedText(
      en: 'FHIR validator',
      fr: 'Validateur FHIR',
      nl: 'FHIR-validator',
    ),
    LocalizedText(
      en: 'Rejects messages that are not well-formed FHIR resources.',
      fr: 'Rejette les messages qui ne sont pas des ressources FHIR valides.',
      nl: 'Weigert berichten die geen geldige FHIR-resources zijn.',
    ),
  ),
  codeTranslator(
    FlowNodeFamily.processor,
    LocalizedText(
      en: 'Code translator',
      fr: 'Traducteur de codes',
      nl: 'Codevertaler',
    ),
    LocalizedText(
      en: 'Maps local codes onto a standard terminology.',
      fr: 'Convertit les codes locaux vers une terminologie standard.',
      nl: 'Zet lokale codes om naar een standaardterminologie.',
    ),
  ),
  router(
    FlowNodeFamily.processor,
    LocalizedText(en: 'Router', fr: 'Routeur', nl: 'Router'),
    LocalizedText(
      en: 'Sends the message down a different branch per rule.',
      fr: 'Envoie le message sur une branche différente selon la règle.',
      nl: 'Stuurt het bericht per regel naar een andere tak.',
    ),
  ),

  // ---- Destinations --------------------------------------------------------
  fhirStore(
    FlowNodeFamily.destination,
    LocalizedText(en: 'FHIR store', fr: 'Serveur FHIR', nl: 'FHIR-server'),
    LocalizedText(
      en: 'Writes the resource to the HAPI FHIR repository.',
      fr: 'Écrit la ressource dans le référentiel HAPI FHIR.',
      nl: 'Schrijft de resource naar de HAPI FHIR-repository.',
    ),
  ),
  applicationDestination(
    FlowNodeFamily.destination,
    LocalizedText(en: 'Application', fr: 'Application', nl: 'Toepassing'),
    LocalizedText(
      en: 'Delivers the message to EHR, ADT or PHARM.',
      fr: 'Livre le message à l’EHR, l’ADT ou la PHARM.',
      nl: 'Levert het bericht af bij EHR, ADT of PHARM.',
    ),
  ),
  httpDestination(
    FlowNodeFamily.destination,
    LocalizedText(en: 'HTTP call', fr: 'Appel HTTP', nl: 'HTTP-aanroep'),
    LocalizedText(
      en: 'POSTs the message to any external URL.',
      fr: 'Envoie le message en POST vers une URL externe.',
      nl: 'Verstuurt het bericht via POST naar een externe URL.',
    ),
  ),
  logDestination(
    FlowNodeFamily.destination,
    LocalizedText(en: 'Log', fr: 'Journal', nl: 'Logboek'),
    LocalizedText(
      en: 'Records the message and stops. Useful while building a flow.',
      fr: 'Enregistre le message et s’arrête. Utile pendant la construction.',
      nl: 'Registreert het bericht en stopt. Handig tijdens het bouwen.',
    ),
  );

  const FlowNodeType(this.family, this.display, this.description);

  final FlowNodeFamily family;
  final LocalizedText display;
  final LocalizedText description;

  bool get hasInput => family != FlowNodeFamily.source;
  bool get hasOutput => family != FlowNodeFamily.destination;

  static FlowNodeType fromName(String value) => values.firstWhere(
    (t) => t.name == value,
    orElse: () => FlowNodeType.logDestination,
  );
}

enum FlowNodeFamily {
  source(LocalizedText(en: 'Sources', fr: 'Sources', nl: 'Bronnen')),
  processor(
    LocalizedText(en: 'Processors', fr: 'Traitements', nl: 'Bewerkingen'),
  ),
  destination(
    LocalizedText(en: 'Destinations', fr: 'Destinations', nl: 'Bestemmingen'),
  );

  const FlowNodeFamily(this.display);
  final LocalizedText display;
}

/// One block on the integration canvas.
@immutable
class FlowNode {
  const FlowNode({
    required this.id,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    this.config = const <String, dynamic>{},
  });

  final String id;
  final FlowNodeType type;

  /// User-supplied label. Falls back to the type name when empty.
  final String label;

  /// Canvas coordinates, in logical pixels from the top-left of the workspace.
  final double x;
  final double y;

  /// Node-specific settings. The shape depends on [type]:
  ///
  /// - [FlowNodeType.filter]: `{path, operator, value}`
  /// - [FlowNodeType.mapper]: `{mappings: [{source, target, transform, argument}]}`
  /// - [FlowNodeType.router]: `{path, routes: [{value, port}]}`
  /// - [FlowNodeType.applicationDestination]: `{app: 'EHR'|'ADT'|'PHARM'}`
  /// - [FlowNodeType.httpDestination]: `{url, method}`
  /// - [FlowNodeType.codeTranslator]: `{path, table: {from: to}}`
  final Map<String, dynamic> config;

  String get effectiveLabel => label.isNotEmpty ? label : type.display.en;

  FlowNode copyWith({
    String? label,
    double? x,
    double? y,
    Map<String, dynamic>? config,
  }) => FlowNode(
    id: id,
    type: type,
    label: label ?? this.label,
    x: x ?? this.x,
    y: y ?? this.y,
    config: config ?? this.config,
  );

  factory FlowNode.fromJson(Map<String, dynamic> json) => FlowNode(
    id: asString(json['id']),
    type: FlowNodeType.fromName(asString(json['type'])),
    label: asString(json['label']),
    x: asDouble(json['x']),
    y: asDouble(json['y']),
    config:
        (json['config'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'label': label,
    'x': x,
    'y': y,
    'config': config,
  };
}

/// A directed link between two nodes.
@immutable
class FlowConnection {
  const FlowConnection({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.fromPort = 'out',
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;

  /// Which output port the link leaves from. Routers expose one port per
  /// route; every other node uses the single default port `out`.
  final String fromPort;

  factory FlowConnection.fromJson(Map<String, dynamic> json) => FlowConnection(
    id: asString(json['id']),
    fromNodeId: asString(json['from_node_id'] ?? json['fromNodeId']),
    toNodeId: asString(json['to_node_id'] ?? json['toNodeId']),
    fromPort: asString(json['from_port'] ?? json['fromPort'], fallback: 'out'),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'from_node_id': fromNodeId,
    'to_node_id': toNodeId,
    'from_port': fromPort,
  };
}

/// A complete integration flow, as drawn on the canvas.
@immutable
class IntegrationFlow {
  const IntegrationFlow({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.nodes,
    required this.connections,
    required this.updatedAt,
    this.messagesProcessed = 0,
    this.messagesFailed = 0,
  });

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final bool isEnabled;
  final List<FlowNode> nodes;
  final List<FlowConnection> connections;
  final DateTime updatedAt;
  final int messagesProcessed;
  final int messagesFailed;

  Iterable<FlowNode> get sources =>
      nodes.where((n) => n.type.family == FlowNodeFamily.source);

  FlowNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Nodes reachable from [nodeId] through its outgoing links on [port].
  List<FlowNode> successorsOf(String nodeId, {String? port}) {
    final result = <FlowNode>[];
    for (final connection in connections) {
      if (connection.fromNodeId != nodeId) continue;
      if (port != null && connection.fromPort != port) continue;
      final node = nodeById(connection.toNodeId);
      if (node != null) result.add(node);
    }
    return result;
  }

  /// Structural problems that would stop the flow from running. Shown live in
  /// the editor rather than only at execution time.
  List<FlowValidationIssue> validate() {
    final issues = <FlowValidationIssue>[];
    if (nodes.isEmpty) {
      issues.add(
        const FlowValidationIssue(
          nodeId: null,
          message: LocalizedText(
            en: 'The flow is empty. Drag a source onto the canvas to start.',
            fr: 'Le flux est vide. Faites glisser une source pour commencer.',
            nl: 'De flow is leeg. Sleep een bron naar het canvas om te beginnen.',
          ),
        ),
      );
      return issues;
    }
    if (sources.isEmpty) {
      issues.add(
        const FlowValidationIssue(
          nodeId: null,
          message: LocalizedText(
            en: 'The flow has no source, so nothing can enter it.',
            fr: 'Le flux n’a pas de source, rien ne peut y entrer.',
            nl: 'De flow heeft geen bron, er kan niets binnenkomen.',
          ),
        ),
      );
    }
    if (!nodes.any((n) => n.type.family == FlowNodeFamily.destination)) {
      issues.add(
        const FlowValidationIssue(
          nodeId: null,
          message: LocalizedText(
            en: 'The flow has no destination, so messages go nowhere.',
            fr: 'Le flux n’a pas de destination, les messages ne vont nulle part.',
            nl: 'De flow heeft geen bestemming, berichten gaan nergens heen.',
          ),
        ),
      );
    }
    for (final node in nodes) {
      final hasIncoming = connections.any((c) => c.toNodeId == node.id);
      final hasOutgoing = connections.any((c) => c.fromNodeId == node.id);
      if (node.type.hasInput && !hasIncoming) {
        issues.add(
          FlowValidationIssue(
            nodeId: node.id,
            message: LocalizedText(
              en: '"${node.effectiveLabel}" has no incoming connection.',
              fr: '« ${node.effectiveLabel} » n’a aucune connexion entrante.',
              nl: '"${node.effectiveLabel}" heeft geen inkomende verbinding.',
            ),
          ),
        );
      }
      if (node.type.hasOutput && !hasOutgoing) {
        issues.add(
          FlowValidationIssue(
            nodeId: node.id,
            message: LocalizedText(
              en: '"${node.effectiveLabel}" has no outgoing connection.',
              fr: '« ${node.effectiveLabel} » n’a aucune connexion sortante.',
              nl: '"${node.effectiveLabel}" heeft geen uitgaande verbinding.',
            ),
          ),
        );
      }
    }
    return issues;
  }

  IntegrationFlow copyWith({
    LocalizedText? name,
    LocalizedText? description,
    bool? isEnabled,
    List<FlowNode>? nodes,
    List<FlowConnection>? connections,
    int? messagesProcessed,
    int? messagesFailed,
  }) => IntegrationFlow(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    isEnabled: isEnabled ?? this.isEnabled,
    nodes: nodes ?? this.nodes,
    connections: connections ?? this.connections,
    updatedAt: DateTime.now(),
    messagesProcessed: messagesProcessed ?? this.messagesProcessed,
    messagesFailed: messagesFailed ?? this.messagesFailed,
  );

  factory IntegrationFlow.fromJson(
    Map<String, dynamic> json,
  ) => IntegrationFlow(
    id: asString(json['id']),
    name: LocalizedText.fromJson(json['name']),
    description: LocalizedText.fromJson(json['description']),
    isEnabled: asBool(json['is_enabled'] ?? json['isEnabled'], fallback: true),
    nodes: asMapList(json['nodes']).map(FlowNode.fromJson).toList(),
    connections: asMapList(
      json['connections'],
    ).map(FlowConnection.fromJson).toList(),
    updatedAt: asDateTime(json['updated_at'] ?? json['updatedAt']),
    messagesProcessed: asInt(
      json['messages_processed'] ?? json['messagesProcessed'],
    ),
    messagesFailed: asInt(json['messages_failed'] ?? json['messagesFailed']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name.toJson(),
    'description': description.toJson(),
    'is_enabled': isEnabled,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'connections': connections.map((c) => c.toJson()).toList(),
    'updated_at': updatedAt.toIso8601String(),
    'messages_processed': messagesProcessed,
    'messages_failed': messagesFailed,
  };
}

@immutable
class FlowValidationIssue {
  const FlowValidationIssue({required this.nodeId, required this.message});
  final String? nodeId;
  final LocalizedText message;
}

/// Outcome of a message passing through the engine.
enum MessageStatus {
  received(LocalizedText(en: 'Received', fr: 'Reçu', nl: 'Ontvangen')),
  processing(
    LocalizedText(en: 'Processing', fr: 'En traitement', nl: 'In verwerking'),
  ),
  delivered(LocalizedText(en: 'Delivered', fr: 'Livré', nl: 'Afgeleverd')),
  filtered(LocalizedText(en: 'Filtered out', fr: 'Filtré', nl: 'Uitgefilterd')),
  failed(LocalizedText(en: 'Failed', fr: 'Échec', nl: 'Mislukt'));

  const MessageStatus(this.display);
  final LocalizedText display;

  static MessageStatus fromName(String value) => values.firstWhere(
    (s) => s.name == value,
    orElse: () => MessageStatus.received,
  );
}

/// One step of a message's journey through a flow. The trace is what makes the
/// integration engine teachable: students can see the payload before and after
/// every node.
@immutable
class TraceStep {
  const TraceStep({
    required this.nodeId,
    required this.nodeLabel,
    required this.nodeType,
    required this.status,
    required this.at,
    required this.detail,
    this.payloadAfter,
  });

  final String nodeId;
  final String nodeLabel;
  final FlowNodeType nodeType;
  final MessageStatus status;
  final DateTime at;

  /// Short human explanation of what this node did.
  final String detail;

  /// The message as it left this node. Null when the node dropped it.
  final Map<String, dynamic>? payloadAfter;

  factory TraceStep.fromJson(Map<String, dynamic> json) => TraceStep(
    nodeId: asString(json['node_id'] ?? json['nodeId']),
    nodeLabel: asString(json['node_label'] ?? json['nodeLabel']),
    nodeType: FlowNodeType.fromName(
      asString(json['node_type'] ?? json['nodeType']),
    ),
    status: MessageStatus.fromName(asString(json['status'])),
    at: asDateTime(json['at']),
    detail: asString(json['detail']),
    payloadAfter: (json['payload_after'] ?? json['payloadAfter']) is Map
        ? ((json['payload_after'] ?? json['payloadAfter']) as Map)
              .cast<String, dynamic>()
        : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'node_id': nodeId,
    'node_label': nodeLabel,
    'node_type': nodeType.name,
    'status': status.name,
    'at': at.toIso8601String(),
    'detail': detail,
    'payload_after': payloadAfter,
  };
}

/// A message handled by the integration engine.
@immutable
class IntegrationMessage {
  const IntegrationMessage({
    required this.id,
    required this.messageType,
    required this.sourceApp,
    required this.payload,
    required this.status,
    required this.receivedAt,
    this.flowId,
    this.targetApp,
    this.processedAt,
    this.error,
    this.trace = const <TraceStep>[],
    this.patientId,
  });

  final String id;

  /// e.g. `ADT^A01`, `Observation`, `MedicationRequest`.
  final String messageType;

  /// Sending application code: `ADT`, `EHR`, `PHARM`, `DEV3`.
  final String sourceApp;

  final Map<String, dynamic> payload;
  final MessageStatus status;
  final DateTime receivedAt;

  final String? flowId;
  final String? targetApp;
  final DateTime? processedAt;
  final String? error;
  final List<TraceStep> trace;
  final String? patientId;

  Duration? get latency => processedAt?.difference(receivedAt);

  IntegrationMessage copyWith({
    MessageStatus? status,
    String? flowId,
    String? targetApp,
    DateTime? processedAt,
    String? error,
    List<TraceStep>? trace,
    Map<String, dynamic>? payload,
  }) => IntegrationMessage(
    id: id,
    messageType: messageType,
    sourceApp: sourceApp,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    receivedAt: receivedAt,
    flowId: flowId ?? this.flowId,
    targetApp: targetApp ?? this.targetApp,
    processedAt: processedAt ?? this.processedAt,
    error: error ?? this.error,
    trace: trace ?? this.trace,
    patientId: patientId,
  );

  factory IntegrationMessage.fromJson(Map<String, dynamic> json) =>
      IntegrationMessage(
        id: asString(json['id']),
        messageType: asString(json['message_type'] ?? json['messageType']),
        sourceApp: asString(json['source_app'] ?? json['sourceApp']),
        payload:
            (json['payload'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        status: MessageStatus.fromName(asString(json['status'])),
        receivedAt: asDateTime(json['received_at'] ?? json['receivedAt']),
        flowId: asStringOrNull(json['flow_id'] ?? json['flowId']),
        targetApp: asStringOrNull(json['target_app'] ?? json['targetApp']),
        processedAt: asDateTimeOrNull(
          json['processed_at'] ?? json['processedAt'],
        ),
        error: asStringOrNull(json['error']),
        trace: asMapList(json['trace']).map(TraceStep.fromJson).toList(),
        patientId: asStringOrNull(json['patient_id'] ?? json['patientId']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'message_type': messageType,
    'source_app': sourceApp,
    'payload': payload,
    'status': status.name,
    'received_at': receivedAt.toIso8601String(),
    'flow_id': flowId,
    'target_app': targetApp,
    'processed_at': processedAt?.toIso8601String(),
    'error': error,
    'trace': trace.map((t) => t.toJson()).toList(),
    'patient_id': patientId,
  };
}
