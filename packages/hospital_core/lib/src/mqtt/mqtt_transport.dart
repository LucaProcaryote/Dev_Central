/// The narrow slice of MQTT this platform needs, behind an interface.
///
/// Everything above this line - topics, payloads, presence, the integration
/// node - is ordinary Dart that can be tested without a broker, a network or
/// a timer. Everything below it is one adapter over `package:mqtt_client`.
/// The split is deliberate: a classroom broker that is down should not make
/// the test suite red, and a student reading the code should meet the
/// hospital's rules before meeting the library's.
library;

import 'dart:async';

import 'mqtt_topics.dart';

/// One message, as it crosses the wire.
class MqttEnvelope {
  const MqttEnvelope({
    required this.topic,
    required this.payload,
    this.retained = false,
  });

  final String topic;
  final String payload;

  /// True when the broker replayed a stored message rather than a live one.
  /// A subscriber that treats a retained `offline` as news would raise an
  /// alarm about a device that failed yesterday.
  final bool retained;

  @override
  String toString() => '$topic${retained ? ' (retained)' : ''}: $payload';
}

/// Delivery guarantee. Only the two that differ in practice are offered.
enum MqttDelivery {
  /// At most once. The reading is gone if the link drops, which is usually
  /// the right answer for a measurement that will be repeated in a second.
  atMostOnce,

  /// At least once. The broker keeps asking until it is acknowledged, and the
  /// receiver may therefore see the same message twice - which matters for a
  /// device going offline, because that message is not repeated.
  atLeastOnce,
}

enum MqttLinkState { disconnected, connecting, connected, failed }

/// What a client needs to reach the broker.
class MqttSettings {
  const MqttSettings({
    required this.url,
    required this.clientId,
    this.username = '',
    this.password = '',
    this.keepAlive = const Duration(seconds: 30),
  });

  /// `wss://host` in the browser, `ws://host:port` locally. Not `mqtt://`:
  /// a browser cannot open a TCP socket, so every client here - web or not -
  /// speaks MQTT over WebSocket, and using one transport everywhere means the
  /// students debug one thing.
  final String url;

  /// Unique per connection. A broker disconnects the older client when a
  /// second one arrives with the same id, which is a confusing way to
  /// discover that two browser tabs share a constant.
  final String clientId;

  final String username;
  final String password;

  /// How long the broker waits, without hearing anything, before deciding the
  /// client is gone and publishing its last will.
  final Duration keepAlive;

  bool get isConfigured => url.isNotEmpty;
}

/// A message registered with the broker at connection time, to be published
/// on the client's behalf if it stops answering.
class MqttWill {
  const MqttWill({
    required this.topic,
    required this.payload,
    this.retain = true,
  });

  final String topic;
  final String payload;
  final bool retain;
}

/// What the rest of the platform is allowed to ask of a broker.
abstract class MqttTransport {
  /// Current link state, for the interface to show.
  MqttLinkState get state;

  /// Every message matching a subscription, in arrival order.
  Stream<MqttEnvelope> get messages;

  /// State changes, so a screen can show a connection dropping.
  Stream<MqttLinkState> get states;

  /// Opens the connection, registering [will] if one is given. Completes when
  /// the broker has acknowledged, or throws with a reason worth showing.
  Future<void> connect({MqttWill? will});

  Future<void> disconnect();

  void subscribe(String filter, {MqttDelivery delivery});

  void unsubscribe(String filter);

  void publish(
    String topic,
    String payload, {
    MqttDelivery delivery,
    bool retain,
  });
}

/// An in-memory broker: routes by topic filter, keeps retained messages,
/// publishes a will on [fail].
///
/// Complete enough that the tests exercise the behaviour that actually
/// matters - wildcard matching, retention, and a device's last will - rather
/// than asserting that a mock was called.
class FakeMqttTransport implements MqttTransport {
  FakeMqttTransport();

  final _messages = StreamController<MqttEnvelope>.broadcast();
  final _states = StreamController<MqttLinkState>.broadcast();
  final _subscriptions = <String>{};
  final _retained = <String, MqttEnvelope>{};

  /// Everything published through this transport, for assertions.
  final published = <MqttEnvelope>[];

  MqttWill? _will;
  MqttLinkState _state = MqttLinkState.disconnected;

  @override
  MqttLinkState get state => _state;

  @override
  Stream<MqttEnvelope> get messages => _messages.stream;

  @override
  Stream<MqttLinkState> get states => _states.stream;

  void _moveTo(MqttLinkState next) {
    _state = next;
    _states.add(next);
  }

  @override
  Future<void> connect({MqttWill? will}) async {
    _will = will;
    _moveTo(MqttLinkState.connected);
  }

  @override
  Future<void> disconnect() async {
    _will = null;
    _moveTo(MqttLinkState.disconnected);
  }

  @override
  void subscribe(String filter, {MqttDelivery delivery = MqttDelivery.atLeastOnce}) {
    _subscriptions.add(filter);
    // A real broker replays what it has kept the moment a subscription is
    // made, which is how a screen opened at noon learns about a device that
    // went offline at ten.
    for (final envelope in _retained.values) {
      if (MqttTopics.matches(filter, envelope.topic)) {
        _messages.add(envelope);
      }
    }
  }

  @override
  void unsubscribe(String filter) => _subscriptions.remove(filter);

  @override
  void publish(
    String topic,
    String payload, {
    MqttDelivery delivery = MqttDelivery.atMostOnce,
    bool retain = false,
  }) {
    final envelope = MqttEnvelope(topic: topic, payload: payload);
    published.add(envelope);
    if (retain) {
      _retained[topic] = MqttEnvelope(
        topic: topic,
        payload: payload,
        retained: true,
      );
    }
    _deliver(envelope);
  }

  /// Simulates the client dying: the broker publishes its will.
  void fail() {
    final will = _will;
    _moveTo(MqttLinkState.failed);
    if (will == null) return;
    if (will.retain) {
      _retained[will.topic] = MqttEnvelope(
        topic: will.topic,
        payload: will.payload,
        retained: true,
      );
    }
    _deliver(MqttEnvelope(topic: will.topic, payload: will.payload));
  }

  /// Delivers a message as if another client had published it.
  void inject(String topic, String payload) =>
      _deliver(MqttEnvelope(topic: topic, payload: payload));

  void _deliver(MqttEnvelope envelope) {
    for (final filter in _subscriptions) {
      if (MqttTopics.matches(filter, envelope.topic)) {
        _messages.add(envelope);
        return;
      }
    }
  }

  Future<void> close() async {
    await _messages.close();
    await _states.close();
  }
}
