import '../models/device.dart';

/// The device fleet: ten simulators, one per student, plus two consumer
/// wearables feeding the same pipeline.
///
/// Each simulator is deliberately given a different [DeviceKind] so the class
/// as a whole produces every vital sign the EHR can display, and so no two
/// students are debugging exactly the same payload.
class _DeviceSpec {
  const _DeviceSpec(
    this.code,
    this.kind,
    this.manufacturer,
    this.model,
    this.wardId,
    this.patientId,
    this.bedId,
  );

  final String code;
  final DeviceKind kind;
  final String manufacturer;
  final String model;
  final String? wardId;
  final String? patientId;
  final String? bedId;
}

const List<_DeviceSpec> _specs = <_DeviceSpec>[
  _DeviceSpec(
    'DEV1',
    DeviceKind.multiparameter,
    'Simulated Medical Systems',
    'VitalPro 5000',
    'ward-icu',
    'pat-008',
    'bed-icu-221a',
  ),
  _DeviceSpec(
    'DEV2',
    DeviceKind.cardiacMonitor,
    'Simulated Medical Systems',
    'CardioTrack C2',
    'ward-card',
    'pat-001',
    'bed-card-301a',
  ),
  _DeviceSpec(
    'DEV3',
    DeviceKind.pulseOximeter,
    'Nordic Simulation AB',
    'OxiSense 210',
    'ward-int',
    'pat-002',
    'bed-int-401a',
  ),
  _DeviceSpec(
    'DEV4',
    DeviceKind.weightScale,
    'Belgian Med Devices',
    'ScaleLink W3',
    'ward-card',
    'pat-001',
    'bed-card-301a',
  ),
  _DeviceSpec(
    'DEV5',
    DeviceKind.thermometer,
    'Belgian Med Devices',
    'ThermoLink T1',
    'ward-ped',
    'pat-010',
    'bed-ped-501a',
  ),
  _DeviceSpec(
    'DEV6',
    DeviceKind.activityTracker,
    'Nordic Simulation AB',
    'MoveTrack A4',
    'ward-geri',
    'pat-013',
    'bed-geri-601a',
  ),
  _DeviceSpec(
    'DEV7',
    DeviceKind.bloodPressureMonitor,
    'Simulated Medical Systems',
    'TensioLink B7',
    'ward-card',
    'pat-015',
    'bed-card-302a',
  ),
  _DeviceSpec(
    'DEV8',
    DeviceKind.multiparameter,
    'Simulated Medical Systems',
    'VitalPro 5000',
    'ward-int',
    'pat-018',
    'bed-int-402a',
  ),
  _DeviceSpec(
    'DEV9',
    DeviceKind.pulseOximeter,
    'Nordic Simulation AB',
    'OxiSense 210',
    'ward-ped',
    'pat-016',
    'bed-ped-502a',
  ),
  _DeviceSpec(
    'DEV10',
    DeviceKind.cardiacMonitor,
    'Simulated Medical Systems',
    'CardioTrack C2',
    'ward-card',
    'pat-020',
    'bed-card-303a',
  ),
  _DeviceSpec(
    'WATCH-1',
    DeviceKind.activityTracker,
    'Apple',
    'Apple Watch Series 9',
    null,
    'pat-005',
    null,
  ),
  _DeviceSpec(
    'WATCH-2',
    DeviceKind.activityTracker,
    'Apple',
    'Apple Watch Series 10',
    null,
    'pat-011',
    null,
  ),
];

List<MedicalDevice> buildSeedDevices(DateTime now) {
  final devices = <MedicalDevice>[];
  for (var i = 0; i < _specs.length; i++) {
    final spec = _specs[i];
    final isWearable = spec.code.startsWith('WATCH');
    devices.add(
      MedicalDevice(
        id: 'dev-${spec.code.toLowerCase()}',
        code: spec.code,
        kind: spec.kind,
        manufacturer: spec.manufacturer,
        model: spec.model,
        serialNumber: 'SN-${(2026000 + i * 137).toString()}',
        // The fleet starts idle: a simulator becomes active when a student
        // actually launches it, which is what makes the fleet board worth
        // watching during a lab session.
        status: isWearable ? DeviceStatus.standby : DeviceStatus.offline,
        assignedPatientId: spec.patientId,
        assignedBedId: spec.bedId,
        wardId: spec.wardId,
        lastSeenAt: isWearable ? now.subtract(Duration(minutes: 12 + i)) : null,
        batteryPercent: 100 - (i * 6) % 45,
        ownerStudent: isWearable ? null : 'Student ${i + 1}',
      ),
    );
  }
  return devices;
}
