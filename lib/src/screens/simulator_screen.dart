import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:provider/provider.dart';

import '../services/signal_generator.dart';
import '../services/simulator_controller.dart';
import '../widgets/healthkit_panel.dart';
import '../widgets/manual_reading_panel.dart';

/// The simulator this instance is: what it is attached to, what it is
/// producing, and where the readings are going.
class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SimulatorController>();
    final l10n = HospitalLocalizations.of(context);
    final device = controller.device;

    if (device == null) {
      return EmptyView(
        message: '${l10n.errorNotFound} (${l10n.deviceId})',
        icon: Icons.sensors_off_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(Gap.md),
      children: <Widget>[
        _DeviceCard(device: device),
        Gap.h16,
        const _ConfigurationCard(),
        Gap.h16,
        const _LiveFeedCard(),
        Gap.h16,
        const ManualReadingPanel(),
        Gap.h16,
        const HealthKitPanel(),
        Gap.h16,
        const _OutboxCard(),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final MedicalDevice device;

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final controller = context.watch<SimulatorController>();
    final config = context.read<AppConfig>();
    final running = controller.isRunning;

    return SectionCard(
      title: '${device.code} · ${device.kind.display.forLanguage(language)}',
      icon: Icons.sensors,
      trailing: Padding(
        padding: const EdgeInsets.only(right: Gap.sm),
        child: StatusChip(
          label: running ? l10n.deviceRunning : l10n.deviceStopped,
          color: running
              ? HospitalTheme.successOf(context)
              : Theme.of(context).colorScheme.outline,
          icon: running ? Icons.play_arrow : Icons.stop,
          dense: true,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: Gap.lg,
            runSpacing: Gap.md,
            children: <Widget>[
              LabeledValue(
                label: l10n.deviceManufacturer,
                value: device.manufacturer,
              ),
              LabeledValue(label: l10n.deviceModel, value: device.model),
              LabeledValue(
                label: l10n.deviceSerial,
                value: device.serialNumber,
                monospace: true,
              ),
              LabeledValue(
                label: l10n.deviceMeasurements,
                value: device.kind.measures
                    .map((m) => m.display.forLanguage(language))
                    .join(', '),
              ),
              LabeledValue(
                label: l10n.deviceEndpoint,
                value: config.eaiBaseUrl,
                monospace: true,
              ),
            ],
          ),
          Gap.h16,
          const _PatientAssignment(),
        ],
      ),
    );
  }
}

class _PatientAssignment extends StatelessWidget {
  const _PatientAssignment();

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final controller = context.watch<SimulatorController>();
    final patient = controller.patient;

    return RepositoryBuilder<List<Patient>>(
      query: (repository) => repository.listPatients(),
      builder: (context, patients) => Row(
        children: <Widget>[
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: patient?.id,
              decoration:
                  InputDecoration(labelText: l10n.deviceTargetPatient),
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.deviceNotAssigned),
                ),
                for (final option in patients)
                  DropdownMenuItem<String?>(
                    value: option.id,
                    child: Text('${option.listName} · ${option.mrn}'),
                  ),
              ],
              onChanged: (value) => controller.assignPatient(
                value == null
                    ? null
                    : patients.firstWhere((p) => p.id == value),
              ),
            ),
          ),
          if (patient != null && patient.hasHighRiskAllergy) ...<Widget>[
            Gap.w16,
            Icon(
              Icons.warning_amber_rounded,
              color: HospitalTheme.criticalOf(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  const _ConfigurationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final controller = context.watch<SimulatorController>();
    final canRun = controller.patient != null;

    return SectionCard(
      title: l10n.deviceConfiguration,
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.deviceScenario,
              style: Theme.of(context).textTheme.labelMedium),
          Gap.h8,
          Wrap(
            spacing: Gap.sm,
            children: <Widget>[
              for (final scenario in SimulationScenario.values)
                ChoiceChip(
                  selected: controller.scenario == scenario,
                  label: Text(scenario.display.forLanguage(language)),
                  onSelected: (_) => controller.setScenario(scenario),
                ),
            ],
          ),
          Gap.h16,
          Text(
            '${l10n.deviceInterval}: '
            '${l10n.deviceIntervalSeconds(controller.interval.inSeconds)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Slider(
            value: controller.interval.inSeconds.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: '${controller.interval.inSeconds} s',
            onChanged: (value) =>
                controller.setInterval(Duration(seconds: value.round())),
          ),
          Gap.h8,
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: !canRun
                    ? null
                    : () => controller.isRunning
                        ? controller.stop()
                        : controller.start(),
                icon: Icon(
                  controller.isRunning ? Icons.stop : Icons.play_arrow,
                  size: 18,
                ),
                label: Text(
                  controller.isRunning ? l10n.deviceStop : l10n.deviceStart,
                ),
              ),
              Gap.w16,
              Text(
                l10n.devicePublishedCount(controller.publishedCount),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (controller.failedCount > 0) ...<Widget>[
                Gap.w8,
                StatusChip(
                  label: '${controller.failedCount}',
                  color: HospitalTheme.warningOf(context),
                  icon: Icons.cloud_off,
                  dense: true,
                ),
              ],
            ],
          ),
          if (!canRun)
            Padding(
              padding: const EdgeInsets.only(top: Gap.sm),
              child: Text(
                l10n.deviceNotAssigned,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HospitalTheme.warningOf(context),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveFeedCard extends StatelessWidget {
  const _LiveFeedCard();

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final controller = context.watch<SimulatorController>();
    final device = controller.device;
    if (device == null) return const SizedBox.shrink();

    // The recent history of each measurement, newest first, for the sparklines.
    final history = <VitalSignType, List<Observation>>{};
    for (final entry in controller.outbox) {
      history
          .putIfAbsent(entry.observation.type, () => <Observation>[])
          .add(entry.observation);
    }

    return SectionCard(
      title: l10n.deviceLiveFeed,
      icon: Icons.show_chart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = (constraints.maxWidth / 190).floor().clamp(1, 5);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: Gap.sm,
              crossAxisSpacing: Gap.sm,
              mainAxisExtent: 150,
            ),
            itemCount: device.kind.measures.length,
            itemBuilder: (context, index) {
              final type = device.kind.measures[index];
              final readings = history[type] ?? const <Observation>[];
              return VitalTile(
                type: type,
                latest: readings.isEmpty ? null : readings.first,
                history: readings.take(40).toList(growable: false),
              );
            },
          );
        },
      ),
    );
  }
}

class _OutboxCard extends StatelessWidget {
  const _OutboxCard();

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final controller = context.watch<SimulatorController>();
    final entries = controller.outbox.take(25).toList();

    return SectionCard(
      title: l10n.deviceOutbox,
      icon: Icons.outbox_outlined,
      padding: EdgeInsets.zero,
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: Text(l10n.vitalsNone),
            )
          : Column(
              children: <Widget>[
                for (final entry in entries)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      entry.delivered ? Icons.cloud_done : Icons.cloud_off,
                      size: 18,
                      color: entry.delivered
                          ? HospitalTheme.successOf(context)
                          : HospitalTheme.warningOf(context),
                    ),
                    title: Text(
                      '${entry.observation.type.display.forLanguage(language)} '
                      '· ${entry.observation.formatted}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: entry.observation.isAbnormal
                            ? HospitalTheme.criticalOf(context)
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      entry.delivered
                          ? 'LOINC ${entry.observation.type.loincCode}'
                          : entry.error ?? l10n.errorGeneric,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      Formats.time(context, entry.observation.effectiveDateTime),
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
    );
  }
}
