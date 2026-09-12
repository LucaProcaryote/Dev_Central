import 'dart:convert';

import 'package:http/http.dart' as http;

import '../util/json.dart';

/// An error returned by the FHIR server, carrying the `OperationOutcome` text
/// when the server bothered to send one.
class FhirException implements Exception {
  const FhirException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'FhirException($statusCode): $message';
}

/// A page of search results.
class FhirBundle {
  const FhirBundle({
    required this.resources,
    required this.total,
    this.nextUrl,
  });

  final List<Map<String, dynamic>> resources;

  /// What the server says the full result count is, which may exceed
  /// [resources] when the results are paged.
  final int total;

  /// Absolute URL of the next page, or null on the last page.
  final String? nextUrl;
}

/// A thin REST client for a FHIR R4 server.
///
/// Deliberately thin: it speaks the FHIR HTTP interface and hands back decoded
/// JSON maps rather than a typed model tree. Students are meant to look at the
/// actual resources, and a heavy object layer would hide them.
class FhirClient {
  FhirClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  /// Base URL of the FHIR endpoint, e.g. `http://localhost:8080/fhir`.
  final String baseUrl;
  final http.Client _client;

  static const Map<String, String> _headers = <String, String>{
    'Accept': 'application/fhir+json',
    'Content-Type': 'application/fhir+json',
  };

  /// True when the server answers its capability statement - used by the status
  /// indicator in the EAI application.
  Future<bool> isReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/metadata'), headers: _headers)
          .timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// `GET [base]/[resourceType]/[id]`
  Future<Map<String, dynamic>?> read(String resourceType, String id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/$resourceType/$id'),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    return _decodeResource(response);
  }

  /// `GET [base]/[resourceType]?…` - a FHIR search.
  Future<FhirBundle> search(
    String resourceType, {
    Map<String, String> parameters = const <String, String>{},
    int count = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/$resourceType').replace(
      queryParameters: <String, String>{...parameters, '_count': '$count'},
    );
    final response = await _client.get(uri, headers: _headers);
    final bundle = _decodeResource(response);
    return _toBundle(bundle);
  }

  /// Follows the `next` link of a previous search.
  Future<FhirBundle> nextPage(String url) async {
    final response = await _client.get(Uri.parse(url), headers: _headers);
    return _toBundle(_decodeResource(response));
  }

  FhirBundle _toBundle(Map<String, dynamic>? bundle) {
    if (bundle == null) {
      return const FhirBundle(resources: <Map<String, dynamic>>[], total: 0);
    }
    final entries = asMapList(bundle['entry']);
    final resources = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final resource = entry['resource'];
      if (resource is Map) resources.add(resource.cast<String, dynamic>());
    }
    String? next;
    for (final link in asMapList(bundle['link'])) {
      if (link['relation'] == 'next') next = asStringOrNull(link['url']);
    }
    return FhirBundle(
      resources: resources,
      total: asInt(bundle['total'], fallback: resources.length),
      nextUrl: next,
    );
  }

  /// `POST [base]/[resourceType]` - lets the server assign the id.
  Future<Map<String, dynamic>> create(Map<String, dynamic> resource) async {
    final resourceType = resource['resourceType'];
    if (resourceType == null) {
      throw const FhirException(0, 'Resource has no resourceType');
    }
    final response = await _client.post(
      Uri.parse('$baseUrl/$resourceType'),
      headers: _headers,
      body: jsonEncode(resource),
    );
    return _decodeResource(response) ?? resource;
  }

  /// `PUT [base]/[resourceType]/[id]` - creates or replaces at a known id.
  ///
  /// This is what the integration flows use: the mini-hospital already owns
  /// stable identifiers, and update-as-create keeps the FHIR server's ids
  /// aligned with the application databases.
  Future<Map<String, dynamic>> update(Map<String, dynamic> resource) async {
    final resourceType = resource['resourceType'];
    final id = resource['id'];
    if (resourceType == null || id == null) {
      throw const FhirException(0, 'Resource needs both resourceType and id');
    }
    final response = await _client.put(
      Uri.parse('$baseUrl/$resourceType/$id'),
      headers: _headers,
      body: jsonEncode(resource),
    );
    return _decodeResource(response) ?? resource;
  }

  /// `DELETE [base]/[resourceType]/[id]`
  Future<void> delete(String resourceType, String id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/$resourceType/$id'),
      headers: _headers,
    );
    if (response.statusCode >= 300 && response.statusCode != 404) {
      throw FhirException(response.statusCode, response.body);
    }
  }

  /// Posts a transaction or batch bundle. Used by the seeding tool to load the
  /// whole fictive hospital in one call.
  Future<Map<String, dynamic>?> transaction(Map<String, dynamic> bundle) async {
    final response = await _client.post(
      Uri.parse(baseUrl),
      headers: _headers,
      body: jsonEncode(bundle),
    );
    return _decodeResource(response);
  }

  Map<String, dynamic>? _decodeResource(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    }
    throw FhirException(response.statusCode, _describeError(response.body));
  }

  /// Pulls the human-readable part out of an `OperationOutcome`, so the UI can
  /// show "Patient.name: minimum required = 1" instead of a wall of JSON.
  String _describeError(String body) {
    if (body.isEmpty) return 'The FHIR server returned an error.';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['resourceType'] == 'OperationOutcome') {
        final issues = asMapList(decoded['issue']);
        final messages = <String>[];
        for (final issue in issues) {
          final details = (issue['details'] as Map?)?['text'];
          messages.add(
            asString(details ?? issue['diagnostics'] ?? issue['code']),
          );
        }
        if (messages.isNotEmpty) return messages.join('; ');
      }
    } catch (_) {
      // Not JSON, fall through to the raw body.
    }
    return body.length > 400 ? '${body.substring(0, 400)}…' : body;
  }

  void close() => _client.close();
}
