/// The topic tree the connected devices publish on.
///
/// A topic tree is a design decision, not a detail. Everything a subscriber
/// can ask for cheaply is what the tree makes addressable with a wildcard,
/// and everything else has to be filtered after the fact by whoever receives
/// it. That is the whole trade-off, and it is worth making the students argue
/// about before they see the answer here.
///
/// The shape chosen is:
///
///     hospital/ward/<ward>/bed/<bed>/device/<device>/<metric>
///
/// which buys the subscriptions a ward actually wants:
///
///     hospital/ward/ward-icu/#                     everything in intensive care
///     hospital/ward/+/bed/+/device/+/heartRate     every heart rate anywhere
///     hospital/ward/+/bed/bed-204b/#               one bed, whatever is on it
///
/// The price is that location is baked into the address. Move a monitor to
/// another bed and its topic changes, so a subscriber holding the old one
/// goes quiet rather than reporting an error - which is the failure mode to
/// warn students about, because nothing anywhere logs it.
///
/// Liveness is kept out of that tree, at `hospital/device/<device>/status`,
/// because whether a device is talking is a property of the device and not of
/// where it happens to be standing.
library;

/// Segment used when a device is not assigned to a ward or a bed.
///
/// A wearable at home has no bed, and an empty topic segment is legal MQTT
/// but reads as a missing value rather than a known absence.
const String unassigned = 'unassigned';

/// Root of every topic this hospital uses.
const String topicRoot = 'hospital';

/// Where a device is, as far as the topic tree is concerned.
class DeviceLocation {
  const DeviceLocation({this.wardId, this.bedId});

  final String? wardId;
  final String? bedId;

  static const DeviceLocation nowhere = DeviceLocation();

  String get wardSegment => _segment(wardId);
  String get bedSegment => _segment(bedId);

  static String _segment(String? value) =>
      (value == null || value.trim().isEmpty) ? unassigned : _clean(value);

  /// Strips the three characters that mean something to a broker.
  ///
  /// A `/` would silently add a level to the tree, and `+` or `#` would turn
  /// a published topic into something no subscriber matches. Identifiers here
  /// never contain them, but a topic built from a name one day would.
  static String _clean(String value) =>
      value.replaceAll(RegExp(r'[/+#]'), '-').trim();

  @override
  String toString() => 'ward/$wardSegment/bed/$bedSegment';
}

/// Builds and reads the topics. All of it is string handling, which is why it
/// is separated from anything that opens a socket: the rules can be tested
/// without a broker.
class MqttTopics {
  const MqttTopics._();

  /// Where one measurement is published.
  static String reading({
    required String deviceId,
    required String metric,
    DeviceLocation location = DeviceLocation.nowhere,
  }) =>
      '$topicRoot/ward/${location.wardSegment}/bed/${location.bedSegment}'
      '/device/${DeviceLocation._clean(deviceId)}/${DeviceLocation._clean(metric)}';

  /// Where a device's liveness is published: retained, and also registered as
  /// the last will so the broker publishes it if the device stops answering.
  static String status(String deviceId) =>
      '$topicRoot/device/${DeviceLocation._clean(deviceId)}/status';

  /// Every reading from every device.
  static const String allReadings = '$topicRoot/ward/#';

  /// Every reading from one ward.
  static String wardReadings(String wardId) =>
      '$topicRoot/ward/${DeviceLocation._clean(wardId)}/#';

  /// One measurement from every device, wherever it is. `+` matches exactly
  /// one level, which is what makes this different from `#`.
  static String metricEverywhere(String metric) =>
      '$topicRoot/ward/+/bed/+/device/+/${DeviceLocation._clean(metric)}';

  /// Every device's liveness.
  static const String allStatus = '$topicRoot/device/+/status';

  /// Takes a published reading topic apart again, or null when [topic] is not
  /// one - a status message, or something another tenant of the broker put
  /// there.
  static ReadingTopic? parseReading(String topic) {
    final parts = topic.split('/');
    if (parts.length != 8) return null;
    if (parts[0] != topicRoot ||
        parts[1] != 'ward' ||
        parts[3] != 'bed' ||
        parts[5] != 'device') {
      return null;
    }
    return ReadingTopic(
      location: DeviceLocation(
        wardId: parts[2] == unassigned ? null : parts[2],
        bedId: parts[4] == unassigned ? null : parts[4],
      ),
      deviceId: parts[6],
      metric: parts[7],
    );
  }

  /// The device id in a status topic, or null when [topic] is not one.
  static String? parseStatus(String topic) {
    final parts = topic.split('/');
    if (parts.length != 4) return null;
    if (parts[0] != topicRoot || parts[1] != 'device' || parts[3] != 'status') {
      return null;
    }
    return parts[2];
  }

  /// Whether a topic published as [topic] would reach a subscriber holding
  /// [filter].
  ///
  /// Implemented here rather than left to the broker because the fake
  /// transport the tests use has to route messages the same way a real broker
  /// would - and because a student who cannot predict what `+` matches will
  /// not be able to debug a flow that receives nothing.
  static bool matches(String filter, String topic) {
    final filterParts = filter.split('/');
    final topicParts = topic.split('/');

    for (var i = 0; i < filterParts.length; i++) {
      // `#` matches the rest, including nothing, but only as the last level.
      if (filterParts[i] == '#') return i == filterParts.length - 1;
      if (i >= topicParts.length) return false;
      if (filterParts[i] == '+') continue;
      if (filterParts[i] != topicParts[i]) return false;
    }
    return filterParts.length == topicParts.length;
  }
}

/// A reading topic, taken apart.
class ReadingTopic {
  const ReadingTopic({
    required this.location,
    required this.deviceId,
    required this.metric,
  });

  final DeviceLocation location;
  final String deviceId;

  /// The measurement's name, matching a `VitalSignType`.
  final String metric;
}
