import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';

/// Every device in the hospital and what it is doing.
///
/// During a lab session this is the screen on the projector: ten simulators
/// coming online one by one as the students start them.
class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return RepositoryBuilder<
      ({List<MedicalDevice> devices, Map<String, Patient> patients})
    >(
      query: (repository) async {
        final devices = await repository.listDevices();
        final patients = <String, Patient>{};
        for (final device in devices) {
          final id = device.assignedPatientId;
          if (id == null || patients.containsKey(id)) continue;
          final patient = await repository.findPatient(id);
          if (patient != null) patients[id] = patient;
        }
        return (devices: devices, patients: patients);
      },
      builder: (context, data) {
        final active = data.devices.where((d) => d.isConnected).length;

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: Gap.sm,
                  children: <Widget>[
                    StatusChip(
                      label: '${l10n.dashboardActiveDevices}: $active',
                      color: HospitalTheme.successOf(context),
                      icon: Icons.sensors,
                    ),
                    StatusChip(
                      label: '${l10n.devices}: ${data.devices.length}',
                      color: HospitalTheme.infoOf(context),
                      icon: Icons.devices_other,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(Gap.md),
                itemCount: data.devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final device = data.devices[index];
                  final patient = device.assignedPatientId == null
                      ? null
                      : data.patients[device.assignedPatientId];

                  final (Color color, String label) = switch (device.status) {
                    DeviceStatus.active =>
                      device.isStale
                          ? (
                              HospitalTheme.warningOf(context),
                              '${device.status.display.forLanguage(language)} '
                                  '· ${l10n.deviceLastSeen} '
                                  '${Formats.ago(context, device.lastSeenAt!)}',
                            )
                          : (
                              HospitalTheme.successOf(context),
                              device.status.display.forLanguage(language),
                            ),
                    DeviceStatus.standby => (
                      HospitalTheme.infoOf(context),
                      device.status.display.forLanguage(language),
                    ),
                    DeviceStatus.maintenance => (
                      HospitalTheme.warningOf(context),
                      device.status.display.forLanguage(language),
                    ),
                    DeviceStatus.offline => (
                      theme.colorScheme.outline,
                      device.status.display.forLanguage(language),
                    ),
                  };

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        device.code.replaceAll(RegExp('[^0-9]'), '').isEmpty
                            ? device.code.substring(0, 2)
                            : device.code.replaceAll(RegExp('[^0-9]'), ''),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${device.code} · '
                            '${device.kind.display.forLanguage(language)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // The state is written out, not only coloured.
                        StatusChip(label: label, color: color, dense: true),
                      ],
                    ),
                    subtitle: Text(
                      <String>[
                        '${device.manufacturer} ${device.model}',
                        if (device.ownerStudent != null) device.ownerStudent!,
                        patient == null
                            ? l10n.deviceNotAssigned
                            : '${l10n.deviceAssignedTo} ${patient.fullName}',
                        if (device.batteryPercent != null)
                          '${l10n.deviceBattery} ${device.batteryPercent}%',
                      ].join(' · '),
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      device.kind.measures
                          .map((m) => m.unit)
                          .toSet()
                          .join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
