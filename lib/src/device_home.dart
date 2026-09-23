import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:provider/provider.dart';

import 'screens/fleet_screen.dart';
import 'screens/simulator_screen.dart';
import 'services/simulator_controller.dart';

/// Opens the broker connection for this simulator, or returns null when no
/// broker is configured.
///
/// The connection announces the device online and registers a last will, so
/// the ward learns from the broker itself - not from a timeout somewhere -
/// when this tab is closed or the network goes. That announcement is the
/// reason to use MQTT here at all, and it has to happen at connection time
/// or not at all: a will cannot be added to a link that is already open.
DeviceFeed? _connectToBroker(AppConfig config, String deviceCode) {
  if (!config.usesMqtt) return null;
  final feed = DeviceFeed(
    MqttClientTransport(
      MqttSettings(
        url: config.mqttUrl,
        // Per device and per tab: a broker disconnects the older client when
        // a second arrives with the same identifier, and two students who
        // both forgot to set DEVICE_ID would otherwise take turns knocking
        // each other off.
        clientId: '$deviceCode-${DateTime.now().microsecondsSinceEpoch}',
        username: config.mqttUsername,
        password: config.mqttPassword,
      ),
    ),
  );
  // Nothing awaits this: a simulator whose broker is unreachable still runs,
  // still writes to its own repository and still posts over HTTP.
  unawaited(feed.connectAsDevice(deviceCode));
  return feed;
}

/// Navigation for the device application.
///
/// Two screens: the simulator this instance *is*, and the fleet board showing
/// what everybody else's simulator is doing.
class DeviceHome extends StatelessWidget {
  const DeviceHome({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final config = context.read<AppConfig>();
    final repository = context.read<HospitalRepository>();

    final deviceCode = config.deviceId ?? 'DEV1';

    return ChangeNotifierProvider<SimulatorController>(
      create: (_) => SimulatorController(
        repository: repository,
        publisher: EventPublisher(baseUrl: config.eaiBaseUrl),
        deviceCode: deviceCode,
        feed: _connectToBroker(config, deviceCode),
      )..load(),
      child: AppShell(
        title: '${l10n.appTitleDevice} · ${config.deviceId ?? 'DEV1'}',
        destinations: <ShellDestination>[
          ShellDestination(
            label: (l10n) => l10n.deviceSimulator,
            icon: Icons.sensors_outlined,
            selectedIcon: Icons.sensors,
            builder: (context) => const SimulatorScreen(),
          ),
          ShellDestination(
            label: (l10n) => l10n.deviceFleet,
            icon: Icons.devices_other_outlined,
            selectedIcon: Icons.devices_other,
            builder: (context) => const FleetScreen(),
          ),
        ],
      ),
    );
  }
}
