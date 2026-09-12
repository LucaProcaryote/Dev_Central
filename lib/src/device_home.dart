import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:provider/provider.dart';

import 'screens/fleet_screen.dart';
import 'screens/simulator_screen.dart';
import 'services/simulator_controller.dart';

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

    return ChangeNotifierProvider<SimulatorController>(
      create: (_) => SimulatorController(
        repository: repository,
        publisher: EventPublisher(baseUrl: config.eaiBaseUrl),
        deviceCode: config.deviceId ?? 'DEV1',
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
