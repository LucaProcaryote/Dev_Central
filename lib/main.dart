import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';

import 'src/device_home.dart';

/// Entry point of the connected-device simulator.
///
/// Each student runs the same build with a different identity, so the ten of
/// them together produce every vital sign the record can display:
///
/// ```
/// flutter run -d chrome --dart-define=DEVICE_ID=DEV3
/// flutter run -d chrome --dart-define=DEVICE_ID=DEV3 \
///   --dart-define=EAI_BASE=http://localhost:8084
/// ```
void main() {
  runApp(
    MiniHospitalApp(
      config: AppConfig.fromEnvironment(HospitalApp.device),
      title: (l10n) => l10n.appTitleDevice,
      subtitle: (l10n) => l10n.hospitalName,
      homeBuilder: (context) => const DeviceHome(),
    ),
  );
}
