/// The one adapter between this platform and `package:mqtt_client`.
///
/// Everything library-specific is here, so the rest of the code - and the
/// tests - see only [MqttTransport].
library;

import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_client_factory_io.dart'
    if (dart.library.js_interop) 'mqtt_client_factory_web.dart';
import 'mqtt_transport.dart';

/// Raised when the broker refuses or the link cannot be opened.
class MqttConnectionException implements Exception {
  const MqttConnectionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MqttClientTransport implements MqttTransport {
  MqttClientTransport(this.settings);

  final MqttSettings settings;

  MqttClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updates;

  final _messages = StreamController<MqttEnvelope>.broadcast();
  final _states = StreamController<MqttLinkState>.broadcast();

  MqttLinkState _state = MqttLinkState.disconnected;

  @override
  MqttLinkState get state => _state;

  @override
  Stream<MqttEnvelope> get messages => _messages.stream;

  @override
  Stream<MqttLinkState> get states => _states.stream;

  void _moveTo(MqttLinkState next) {
    if (_state == next) return;
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  @override
  Future<void> connect({MqttWill? will}) async {
    if (!settings.isConfigured) {
      throw const MqttConnectionException('No broker URL is configured.');
    }
    _moveTo(MqttLinkState.connecting);

    final client = createMqttClient(settings)
      ..keepAlivePeriod = settings.keepAlive.inSeconds
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..onDisconnected = _onDisconnected
      ..onConnected = () => _moveTo(MqttLinkState.connected);

    // startClean because a session the broker remembers would replay
    // everything a device published while a browser tab was closed - which
    // for vital signs means a wall of stale readings on reconnect.
    var message = MqttConnectMessage()
        .withClientIdentifier(settings.clientId)
        .startClean();
    if (will != null) {
      message = message
          .withWillTopic(will.topic)
          .withWillMessage(will.payload)
          .withWillQos(MqttQos.atLeastOnce);
      if (will.retain) message = message.withWillRetain();
    }
    client.connectionMessage = message;
    _client = client;

    try {
      await client.connect(
        settings.username.isEmpty ? null : settings.username,
        settings.password.isEmpty ? null : settings.password,
      );
    } catch (error) {
      _moveTo(MqttLinkState.failed);
      client.disconnect();
      _client = null;
      throw MqttConnectionException('Could not reach the broker: $error');
    }

    final status = client.connectionStatus;
    if (status?.state != MqttConnectionState.connected) {
      _moveTo(MqttLinkState.failed);
      _client = null;
      // returnCode says "not authorized" when the credentials are wrong,
      // which is the single most likely misconfiguration and worth naming.
      throw MqttConnectionException(
        'The broker refused the connection: ${status?.returnCode?.name ?? 'no reason given'}',
      );
    }

    _moveTo(MqttLinkState.connected);
    _updates = client.updates?.listen(_onUpdates);
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final payload = event.payload;
      if (payload is! MqttPublishMessage) continue;
      _messages.add(
        MqttEnvelope(
          topic: event.topic,
          payload: MqttPublishPayload.bytesToStringAsString(
            payload.payload.message,
          ),
          retained: payload.header?.retain ?? false,
        ),
      );
    }
  }

  void _onDisconnected() => _moveTo(MqttLinkState.disconnected);

  @override
  Future<void> disconnect() async {
    await _updates?.cancel();
    _updates = null;
    _client?.disconnect();
    _client = null;
    _moveTo(MqttLinkState.disconnected);
  }

  @override
  void subscribe(
    String filter, {
    MqttDelivery delivery = MqttDelivery.atLeastOnce,
  }) => _client?.subscribe(filter, _qos(delivery));

  @override
  void unsubscribe(String filter) => _client?.unsubscribe(filter);

  @override
  void publish(
    String topic,
    String payload, {
    MqttDelivery delivery = MqttDelivery.atMostOnce,
    bool retain = false,
  }) {
    final client = _client;
    if (client == null) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    final bytes = builder.payload;
    if (bytes == null) return;
    client.publishMessage(topic, _qos(delivery), bytes, retain: retain);
  }

  static MqttQos _qos(MqttDelivery delivery) => switch (delivery) {
    MqttDelivery.atMostOnce => MqttQos.atMostOnce,
    MqttDelivery.atLeastOnce => MqttQos.atLeastOnce,
  };

  Future<void> close() async {
    await disconnect();
    await _messages.close();
    await _states.close();
  }
}
