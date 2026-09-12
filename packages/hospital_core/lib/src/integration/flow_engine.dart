import '../models/integration.dart';
import '../models/patient.dart';
import 'json_path.dart';
import 'transforms.dart';

/// Side effects the engine needs from the outside world.
///
/// Passing these in rather than reaching for a global keeps the engine
/// testable: the unit tests hand it recording stubs, the app hands it the real
/// FHIR client and repositories.
class FlowExecutionContext {
  const FlowExecutionContext({
    required this.lookupPatient,
    required this.writeToFhirStore,
    required this.deliverToApplication,
    required this.postToUrl,
  });

  /// Resolves a patient by id or MRN, for the enricher node.
  final Future<Patient?> Function(String patientRef) lookupPatient;

  /// Persists a FHIR resource. Returns the stored resource id.
  final Future<String> Function(Map<String, dynamic> resource) writeToFhirStore;

  /// Hands the payload to one of the hospital applications.
  final Future<void> Function(String appCode, Map<String, dynamic> payload)
      deliverToApplication;

  /// Generic outbound HTTP POST.
  final Future<void> Function(String url, Map<String, dynamic> payload) postToUrl;

  /// A context that performs no side effects, for previewing a flow in the
  /// editor without touching any real system.
  static FlowExecutionContext dryRun() => FlowExecutionContext(
        lookupPatient: (_) async => null,
        writeToFhirStore: (_) async => 'preview',
        deliverToApplication: (_, __) async {},
        postToUrl: (_, __) async {},
      );
}

/// Executes integration flows and records what happened at every step.
///
/// The engine walks the graph breadth-first from the node the message entered
/// on. A node that drops the message ends that branch; other branches carry on.
class FlowEngine {
  const FlowEngine(this.context);

  final FlowExecutionContext context;

  /// Runs [message] through [flow], starting at [entryNodeId] (defaults to the
  /// flow's first source). Returns the message with its final status and a
  /// full [TraceStep] list attached.
  Future<IntegrationMessage> run(
    IntegrationFlow flow,
    IntegrationMessage message, {
    String? entryNodeId,
  }) async {
    final trace = <TraceStep>[];

    if (!flow.isEnabled) {
      return message.copyWith(
        status: MessageStatus.filtered,
        flowId: flow.id,
        processedAt: DateTime.now(),
        error: 'Flow is disabled',
        trace: trace,
      );
    }

    final entry = entryNodeId != null
        ? flow.nodeById(entryNodeId)
        : (flow.sources.isEmpty ? null : flow.sources.first);

    if (entry == null) {
      return message.copyWith(
        status: MessageStatus.failed,
        flowId: flow.id,
        processedAt: DateTime.now(),
        error: 'Flow has no source node to enter on',
        trace: trace,
      );
    }

    var delivered = false;
    var failed = false;
    String? failure;

    // Each queue entry is a node plus the payload arriving at it.
    final queue = <_Pending>[_Pending(entry, message.payload)];
    // Guard against a cycle a student may have drawn on the canvas.
    var steps = 0;
    const maxSteps = 200;

    while (queue.isNotEmpty && steps < maxSteps) {
      steps++;
      final pending = queue.removeAt(0);
      final node = pending.node;
      final input = pending.payload;

      _NodeResult result;
      try {
        result = await _executeNode(node, input);
      } catch (error) {
        result = _NodeResult.failure('$error');
      }

      trace.add(TraceStep(
        nodeId: node.id,
        nodeLabel: node.effectiveLabel,
        nodeType: node.type,
        status: result.status,
        at: DateTime.now(),
        detail: result.detail,
        payloadAfter: result.payload,
      ));

      switch (result.status) {
        case MessageStatus.failed:
          failed = true;
          failure ??= result.detail;
          continue;
        case MessageStatus.filtered:
          // Branch ends here, quietly. Other branches continue.
          continue;
        case MessageStatus.delivered:
          delivered = true;
          continue;
        case MessageStatus.received:
        case MessageStatus.processing:
          break;
      }

      final payload = result.payload ?? input;
      for (final next in flow.successorsOf(node.id, port: result.outputPort)) {
        queue.add(_Pending(next, payload));
      }
    }

    if (steps >= maxSteps) {
      failed = true;
      failure ??= 'Flow stopped after $maxSteps steps - check for a loop';
    }

    final status = failed
        ? MessageStatus.failed
        : (delivered ? MessageStatus.delivered : MessageStatus.filtered);

    return message.copyWith(
      status: status,
      flowId: flow.id,
      processedAt: DateTime.now(),
      error: failure,
      trace: trace,
    );
  }

  Future<_NodeResult> _executeNode(
    FlowNode node,
    Map<String, dynamic> input,
  ) async {
    switch (node.type) {
      // Sources simply hand the payload on; the message already entered here.
      case FlowNodeType.httpSource:
      case FlowNodeType.deviceSource:
      case FlowNodeType.adtSource:
      case FlowNodeType.timerSource:
        return _NodeResult.pass(input, 'Message entered the flow');

      case FlowNodeType.filter:
        final path = (node.config['path'] ?? '').toString();
        final operator =
            FilterOperator.fromName((node.config['operator'] ?? 'equals').toString());
        final expected = (node.config['value'] ?? '').toString();
        final actual = readPath(input, path);
        final passes = operator.evaluate(actual, expected);
        final rendered =
            '$path ${operator.symbol}${operator.takesValue ? ' $expected' : ''}';
        return passes
            ? _NodeResult.pass(input, 'Passed: $rendered')
            : _NodeResult.filtered(
                'Dropped: $rendered (actual: ${actual ?? 'null'})');

      case FlowNodeType.mapper:
        final mappings = (node.config['mappings'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((m) => FieldMapping.fromJson(m.cast<String, dynamic>()))
            .toList();
        final keepUnmapped = node.config['keepUnmapped'] == true;
        var output = keepUnmapped
            ? Map<String, dynamic>.from(input)
            : <String, dynamic>{};
        for (final mapping in mappings) {
          if (mapping.targetPath.isEmpty) continue;
          final raw = mapping.transform == FieldTransform.constant
              ? null
              : readPath(input, mapping.sourcePath);
          final value = mapping.transform.apply(raw, mapping.argument);
          output = writePath(output, mapping.targetPath, value);
        }
        return _NodeResult.pass(
          output,
          'Applied ${mappings.length} field '
          '${mappings.length == 1 ? 'mapping' : 'mappings'}',
        );

      case FlowNodeType.enricher:
        final path = (node.config['path'] ?? 'subject.reference').toString();
        final targetPath = (node.config['target'] ?? 'patient').toString();
        final reference = readPath(input, path)?.toString() ?? '';
        final id = reference.contains('/')
            ? reference.split('/').last
            : reference;
        if (id.isEmpty) {
          return _NodeResult.pass(input, 'No patient reference at "$path"');
        }
        final patient = await context.lookupPatient(id);
        if (patient == null) {
          return _NodeResult.pass(input, 'Patient "$id" not found, left as is');
        }
        final enriched = writePath(input, targetPath, <String, dynamic>{
          'id': patient.id,
          'mrn': patient.mrn,
          'family_name': patient.familyName,
          'given_name': patient.givenName,
          'birth_date': patient.birthDate.toIso8601String().substring(0, 10),
          'gender': patient.gender.name,
          'preferred_language': patient.preferredLanguage,
        });
        return _NodeResult.pass(enriched, 'Added demographics for ${patient.fullName}');

      case FlowNodeType.validator:
        final resourceType = readPath(input, 'resourceType')?.toString();
        if (resourceType == null || resourceType.isEmpty) {
          return _NodeResult.failure('Not a FHIR resource: "resourceType" is missing');
        }
        final requiredPaths = switch (resourceType) {
          'Observation' => <String>['status', 'code', 'subject'],
          'Patient' => <String>['name'],
          'Encounter' => <String>['status', 'class', 'subject'],
          'MedicationRequest' => <String>['status', 'intent', 'subject'],
          _ => const <String>[],
        };
        final missing = requiredPaths
            .where((p) => readPath(input, p) == null)
            .toList();
        if (missing.isNotEmpty) {
          return _NodeResult.failure(
            '$resourceType is missing required element(s): ${missing.join(', ')}',
          );
        }
        return _NodeResult.pass(input, 'Valid $resourceType');

      case FlowNodeType.codeTranslator:
        final path = (node.config['path'] ?? '').toString();
        final table = (node.config['table'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
        final current = readPath(input, path)?.toString();
        if (current == null) {
          return _NodeResult.pass(input, 'Nothing to translate at "$path"');
        }
        if (!table.containsKey(current)) {
          final onMissing = (node.config['onMissing'] ?? 'pass').toString();
          if (onMissing == 'fail') {
            return _NodeResult.failure('No translation for code "$current"');
          }
          return _NodeResult.pass(input, 'No translation for "$current", left as is');
        }
        final translated = table[current];
        return _NodeResult.pass(
          writePath(input, path, translated),
          'Translated "$current" to "$translated"',
        );

      case FlowNodeType.router:
        final path = (node.config['path'] ?? '').toString();
        final routes = (node.config['routes'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .toList();
        final actual = readPath(input, path)?.toString();
        for (final route in routes) {
          if (route['value'].toString() == actual) {
            final port = (route['port'] ?? 'out').toString();
            return _NodeResult.pass(
              input,
              'Routed "$actual" to port "$port"',
              outputPort: port,
            );
          }
        }
        final fallback = (node.config['defaultPort'] ?? '').toString();
        if (fallback.isEmpty) {
          return _NodeResult.filtered('No route matched "$actual"');
        }
        return _NodeResult.pass(
          input,
          'No route matched "$actual", used default port',
          outputPort: fallback,
        );

      case FlowNodeType.fhirStore:
        final id = await context.writeToFhirStore(input);
        return _NodeResult.delivered(
          input,
          'Stored ${readPath(input, 'resourceType') ?? 'resource'} as $id',
        );

      case FlowNodeType.applicationDestination:
        final app = (node.config['app'] ?? 'EHR').toString();
        await context.deliverToApplication(app, input);
        return _NodeResult.delivered(input, 'Delivered to $app');

      case FlowNodeType.httpDestination:
        final url = (node.config['url'] ?? '').toString();
        if (url.isEmpty) return _NodeResult.failure('No URL configured');
        await context.postToUrl(url, input);
        return _NodeResult.delivered(input, 'POSTed to $url');

      case FlowNodeType.logDestination:
        return _NodeResult.delivered(input, 'Logged');
    }
  }
}

class _Pending {
  const _Pending(this.node, this.payload);
  final FlowNode node;
  final Map<String, dynamic> payload;
}

class _NodeResult {
  const _NodeResult({
    required this.status,
    required this.detail,
    this.payload,
    this.outputPort,
  });

  factory _NodeResult.pass(
    Map<String, dynamic> payload,
    String detail, {
    String? outputPort,
  }) =>
      _NodeResult(
        status: MessageStatus.processing,
        detail: detail,
        payload: payload,
        outputPort: outputPort,
      );

  factory _NodeResult.filtered(String detail) =>
      _NodeResult(status: MessageStatus.filtered, detail: detail);

  factory _NodeResult.failure(String detail) =>
      _NodeResult(status: MessageStatus.failed, detail: detail);

  factory _NodeResult.delivered(Map<String, dynamic> payload, String detail) =>
      _NodeResult(
        status: MessageStatus.delivered,
        detail: detail,
        payload: payload,
      );

  final MessageStatus status;
  final String detail;
  final Map<String, dynamic>? payload;

  /// Which output port the message left on. Only routers set this.
  final String? outputPort;
}
