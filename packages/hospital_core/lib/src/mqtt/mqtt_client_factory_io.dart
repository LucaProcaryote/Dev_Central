/// Builds the broker client outside the browser.
///
/// `MqttServerClient` can speak raw TCP, and deliberately is not asked to:
/// the hosted broker only listens for WebSocket, so using the same transport
/// on every platform means one thing to configure and one thing to debug.
library;

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'mqtt_transport.dart';

MqttClient createMqttClient(MqttSettings settings) {
  final uri = Uri.parse(settings.url);
  final secure = uri.scheme == 'wss';
  final port = uri.hasPort ? uri.port : (secure ? 443 : 80);

  // The library wants the scheme in the server string for WebSocket mode and
  // the port separately, which is why the URL is taken apart rather than
  // passed through.
  final client = MqttServerClient.withPort(
    '${uri.scheme}://${uri.host}${uri.path}',
    settings.clientId,
    port,
  );
  client.useWebSocket = true;
  client.secure = false; // wss:// is handled by the WebSocket layer itself.
  return client;
}
