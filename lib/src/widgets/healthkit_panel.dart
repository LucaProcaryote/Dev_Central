import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:provider/provider.dart';

import '../services/simulator_controller.dart';

/// Brings readings collected by an Apple Watch into the same pipeline.
///
/// On iOS a HealthKit plugin would fill this in directly. Everywhere else -
/// including the browser the students actually use - the watch's own export is
/// pasted in, parsed here, and published exactly like a simulated reading. The
/// downstream systems cannot tell the difference, which is the point: a
/// consumer wearable is just another device on the interface.
class HealthKitPanel extends StatefulWidget {
  const HealthKitPanel({super.key});

  @override
  State<HealthKitPanel> createState() => _HealthKitPanelState();
}

class _HealthKitPanelState extends State<HealthKitPanel> {
  final _controller = TextEditingController();
  String? _error;
  bool _expanded = false;

  /// HealthKit's own type identifiers, mapped onto the LOINC-coded vitals the
  /// hospital speaks. This little table is the whole integration.
  static const Map<String, VitalSignType>
  _healthKitTypes = <String, VitalSignType>{
    'HKQuantityTypeIdentifierHeartRate': VitalSignType.heartRate,
    'HKQuantityTypeIdentifierOxygenSaturation': VitalSignType.oxygenSaturation,
    'HKQuantityTypeIdentifierBodyTemperature': VitalSignType.bodyTemperature,
    'HKQuantityTypeIdentifierBodyMass': VitalSignType.bodyWeight,
    'HKQuantityTypeIdentifierStepCount': VitalSignType.activitySteps,
    'HKQuantityTypeIdentifierRespiratoryRate': VitalSignType.respiratoryRate,
    // Short aliases, so a student can hand-write a test payload.
    'heartRate': VitalSignType.heartRate,
    'oxygenSaturation': VitalSignType.oxygenSaturation,
    'bodyTemperature': VitalSignType.bodyTemperature,
    'bodyMass': VitalSignType.bodyWeight,
    'stepCount': VitalSignType.activitySteps,
    'respiratoryRate': VitalSignType.respiratoryRate,
  };

  static const String _sample = '''
[
  {"type": "HKQuantityTypeIdentifierHeartRate", "value": 68, "date": "2026-09-12T08:15:00Z"},
  {"type": "HKQuantityTypeIdentifierOxygenSaturation", "value": 0.97, "date": "2026-09-12T08:15:00Z"},
  {"type": "HKQuantityTypeIdentifierStepCount", "value": 4210, "date": "2026-09-12T08:00:00Z"}
]''';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parses an export into readings, or throws with a message worth showing.
  List<({VitalSignType type, double value, DateTime at})> _parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array of samples');
    }

    final readings = <({VitalSignType type, double value, DateTime at})>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final typeName = entry['type']?.toString() ?? '';
      final type = _healthKitTypes[typeName];
      if (type == null) continue;

      var value = asDouble(entry['value']);
      // HealthKit reports oxygen saturation as a fraction, the hospital as a
      // percentage. Converting here rather than downstream keeps the unit
      // mismatch where it belongs - at the boundary.
      if (type == VitalSignType.oxygenSaturation && value <= 1.0) {
        value *= 100;
      }

      readings.add((
        type: type,
        value: double.parse(value.toStringAsFixed(type.decimals)),
        at:
            asDateTimeOrNull(entry['date'] ?? entry['startDate']) ??
            DateTime.now(),
      ));
    }
    return readings;
  }

  Future<void> _import() async {
    final l10n = HospitalLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<SimulatorController>();

    setState(() => _error = null);
    List<({VitalSignType type, double value, DateTime at})> readings;
    try {
      readings = _parse(_controller.text);
    } catch (_) {
      setState(() => _error = l10n.eaiInvalidJson);
      return;
    }
    if (readings.isEmpty) {
      setState(() => _error = l10n.labelNoResults);
      return;
    }

    final count = await controller.ingest(readings);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.devicePublishedCount(count))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<SimulatorController>();

    return SectionCard(
      title: l10n.deviceHealthKitTitle,
      icon: Icons.watch_outlined,
      trailing: IconButton(
        icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        onPressed: () => setState(() => _expanded = !_expanded),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.deviceHealthKitBody, style: theme.textTheme.bodySmall),
          if (_expanded) ...<Widget>[
            Gap.h8,
            Text(
              l10n.deviceHealthKitUnavailable,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.h16,
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                labelText: l10n.deviceHealthKitImport,
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
            Gap.h8,
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => setState(() {
                    _controller.text = _sample.trim();
                    _error = null;
                  }),
                  child: Text(l10n.eaiSamplePayload),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: controller.patient == null ? null : _import,
                  icon: const Icon(Icons.download, size: 16),
                  label: Text(l10n.deviceHealthKitImport),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
