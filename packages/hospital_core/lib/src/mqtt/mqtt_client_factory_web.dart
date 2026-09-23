/// Builds the broker client in the browser.
///
/// This is the whole reason the platform speaks MQTT over WebSocket: a page
/// cannot open a TCP socket, so `MqttBrowserClient` is the only client a
/// Flutter web build can use, and the broker has to be listening for it.
library;

import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_transport.dart';

MqttClient createMqttClient(MqttSettings settings) {
  final uri = Uri.parse(settings.url);
  final port = uri.hasPort ? uri.port : (uri.scheme == 'wss' ? 443 : 80);
  return MqttBrowserClient.withPort(
    '${uri.scheme}://${uri.host}${uri.path}',
    settings.clientId,
    port,
  );
}
