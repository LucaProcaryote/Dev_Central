import 'package:flutter/material.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:provider/provider.dart';

import '../services/simulator_controller.dart';

/// Sends one reading the user types in.
///
/// Needed for demonstrations: to show the low-SpO2 alert flow firing you have
/// to be able to produce an SpO2 of 86 on demand, not wait for the
/// deteriorating scenario to get there.
class ManualReadingPanel extends StatefulWidget {
  const ManualReadingPanel({super.key});

  @override
  State<ManualReadingPanel> createState() => _ManualReadingPanelState();
}

class _ManualReadingPanelState extends State<ManualReadingPanel> {
  final _valueController = TextEditingController();
  VitalSignType? _type;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final controller = context.watch<SimulatorController>();
    final device = controller.device;
    if (device == null) return const SizedBox.shrink();

    final types = device.kind.measures;
    final type = _type ?? types.first;

    return SectionCard(
      title: l10n.deviceManualReading,
      icon: Icons.edit_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<VitalSignType>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: l10n.deviceWaveform),
                  items: <DropdownMenuItem<VitalSignType>>[
                    for (final option in types)
                      DropdownMenuItem<VitalSignType>(
                        value: option,
                        child: Text(option.display.forLanguage(language)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                ),
              ),
              Gap.w16,
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: type.unit,
                    hintText: '${type.normalLow} – ${type.normalHigh}',
                  ),
                ),
              ),
              Gap.w16,
              FilledButton.tonal(
                onPressed: controller.patient == null
                    ? null
                    : () => _send(type),
                child: Text(l10n.deviceSend),
              ),
            ],
          ),
          Gap.h8,
          Text(
            l10n.vitalsNormalRange(
              Formats.number(type.normalLow, type.decimals),
              Formats.number(type.normalHigh, type.decimals),
              type.unit,
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(VitalSignType type) async {
    final l10n = HospitalLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<SimulatorController>();

    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorInvalidNumber)));
      return;
    }

    final entry = await controller.sendManual(type, value);
    if (entry == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          entry.delivered
              ? l10n.deviceSent
              : l10n.deviceSendFailed(entry.error ?? ''),
        ),
      ),
    );
  }
}
