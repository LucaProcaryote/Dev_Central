/// The hospital's view of the broker: readings out, readings in, and which
/// devices are still talking.
///
/// Sits on [MqttTransport], so every rule below is testable against the fake
/// broker without a network.
library;

import 'dart:async';
import 'dart:convert';

import 'device_reading.dart';
import 'mqtt_topics.dart';
import 'mqtt_transport.dart';

/// What arrived, already taken apart.
sealed class FeedEvent {
  const FeedEvent(this.topic);

  /// The topic it was published on, kept because it is the only place the
  /// location lives when a payload omits it.
  final String topic;
}

class ReadingEvent extends FeedEvent {
  const ReadingEvent(super.topic, this.reading);
  final DeviceReading reading;
}

class PresenceEvent extends FeedEvent {
  const PresenceEvent(super.topic, this.status, {required this.retained});
  final PresenceMessage status;

  /// True when the broker replayed a stored state rather than reporting a
  /// change. A screen should show it; an alarm should not fire on it.
  final bool retained;
}

/// A message that could not be read, kept rather than dropped.
///
/// Something publishing malformed JSON onto a shared broker is a real
/// classroom event, and a feed that silently ignored it would leave the
/// student staring at a screen that shows nothing and says nothing.
class MalformedEvent extends FeedEvent {
  const MalformedEvent(super.topic, this.payload, this.reason);
  final String payload;
  final String reason;
}

/// Publishes and receives device traffic.
class DeviceFeed {
  DeviceFeed(this.transport);

  final MqttTransport transport;

  StreamSubscription<MqttEnvelope>? _subscription;
  final _events = StreamController<FeedEvent>.broadcast();

  /// Last known state of every device that has said anything.
  final Map<String, PresenceMessage> _presence = <String, PresenceMessage>{};

  Stream<FeedEvent> get events => _events.stream;

  Map<String, PresenceMessage> get presence => Map.unmodifiable(_presence);

  /// Whether [deviceId] is currently believed to be talking. A device that has
  /// never said anything is not online - absence of evidence is reported as
  /// offline here, because a monitor nobody has heard from is exactly as
  /// useful as one that has stopped.
  bool isOnline(String deviceId) =>
      _presence[deviceId]?.presence == DevicePresence.online;

  /// Connects as a device: announces itself online, and registers the message
  /// the broker should publish if it stops answering.
  ///
  /// The will is the piece with no HTTP equivalent. Nothing has to poll, and
  /// nothing has to notice: the broker itself tells every subscriber, within
  /// the keepalive, that this device went quiet.
  Future<void> connectAsDevice(String deviceId, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final offline = PresenceMessage(
      deviceId: deviceId,
      presence: DevicePresence.offline,
      at: at,
    );
    await transport.connect(
      will: MqttWill(topic: offline.topic, payload: offline.encode()),
    );
    announce(deviceId, DevicePresence.online, now: at);
  }

  /// Connects as a listener - the integration engine, or a ward screen.
  Future<void> connectAsObserver({
    String readings = MqttTopics.allReadings,
    bool withPresence = true,
  }) async {
    await transport.connect();
    _listen();
    transport.subscribe(readings);
    if (withPresence) {
      // at-least-once for presence: a reading missed is repeated a second
      // later, a device going offline is not.
      transport.subscribe(
        MqttTopics.allStatus,
        delivery: MqttDelivery.atLeastOnce,
      );
    }
  }

  void _listen() {
    _subscription ??= transport.messages.listen(_onMessage);
  }

  /// Publishes a device's own state, retained so a subscriber arriving later
  /// still learns it.
  void announce(String deviceId, DevicePresence presence, {DateTime? now}) {
    final status = PresenceMessage(
      deviceId: deviceId,
      presence: presence,
      at: now ?? DateTime.now(),
    );
    transport.publish(
      status.topic,
      status.encode(),
      delivery: MqttDelivery.atLeastOnce,
      retain: true,
    );
  }

  /// Publishes one measurement.
  ///
  /// At most once, and not retained: a vital sign is a moment, not a state.
  /// Retaining it would hand the next subscriber a heart rate from an hour
  /// ago as though it had just been taken, which is worse than no reading.
  void publishReading(DeviceReading reading) => transport.publish(
    reading.topic,
    reading.encode(),
    delivery: MqttDelivery.atMostOnce,
  );

  void _onMessage(MqttEnvelope envelope) {
    final statusOf = MqttTopics.parseStatus(envelope.topic);
    if (statusOf != null) {
      _decode(envelope, (json) {
        final status = PresenceMessage.fromJson(json);
        _presence[status.deviceId] = status;
        return PresenceEvent(
          envelope.topic,
          status,
          retained: envelope.retained,
        );
      });
      return;
    }

    final readingTopic = MqttTopics.parseReading(envelope.topic);
    if (readingTopic != null) {
      _decode(
        envelope,
        (json) => ReadingEvent(
          envelope.topic,
          DeviceReading.fromJson(json, topic: readingTopic),
        ),
      );
      return;
    }

    _events.add(
      MalformedEvent(
        envelope.topic,
        envelope.payload,
        'Topic does not belong to this hospital\'s tree',
      ),
    );
  }

  void _decode(
    MqttEnvelope envelope,
    FeedEvent Function(Map<String, dynamic> json) build,
  ) {
    try {
      final decoded = jsonDecode(envelope.payload);
      if (decoded is! Map) {
        _events.add(
          MalformedEvent(
            envelope.topic,
            envelope.payload,
            'Payload is not a JSON object',
          ),
        );
        return;
      }
      _events.add(build(decoded.cast<String, dynamic>()));
    } on FormatException catch (error) {
      _events.add(
        MalformedEvent(envelope.topic, envelope.payload, error.message),
      );
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _events.close();
  }
}
