import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../l10n/generated/hospital_localizations.dart';
import '../theme.dart';

/// A strip across the top of every application saying where the data is
/// coming from.
///
/// Without it, a demonstration of the in-memory dataset looks exactly like a
/// demonstration of a live integrated hospital - and the moment a student
/// wonders why their ADT admission has not appeared in the EHR, this is the
/// answer.
class BackendBanner extends StatelessWidget {
  const BackendBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);

    // A real backend needs no explanation; only the memory mode is surprising.
    if (config.backendMode != BackendMode.memory) return const SizedBox.shrink();

    final color = HospitalTheme.warningOf(context);
    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.science_outlined, size: 16, color: color),
            Gap.w8,
            Expanded(
              child: Text(
                l10n.backendBanner(l10n.backendModeMemory),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
