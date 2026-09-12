import 'package:flutter/material.dart';

import '../../l10n/generated/hospital_localizations.dart';
import '../theme.dart';

/// Centred spinner with a label, for a screen that has nothing to show yet.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          Gap.h16,
          Text(message ?? l10n.labelLoading),
        ],
      ),
    );
  }
}

/// What a list shows when it has loaded successfully and is simply empty.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: theme.colorScheme.outline),
            Gap.h16,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...<Widget>[Gap.h16, action!],
          ],
        ),
      ),
    );
  }
}

/// What a screen shows when loading failed, with a way back.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = HospitalLocalizations.of(context);
    final isNetwork =
        error.toString().toLowerCase().contains('socket') ||
        error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('failed host');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 44, color: theme.colorScheme.error),
            Gap.h16,
            Text(
              isNetwork ? l10n.errorNetwork : l10n.errorGeneric,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            Gap.h8,
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              Gap.h16,
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.actionRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small coloured pill used for statuses throughout the suite.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                (dense
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A titled section with optional trailing action, used to structure long
/// screens like the patient file.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.all(Gap.md),
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.sm, Gap.sm, Gap.sm),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  Gap.w8,
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Label above value, the workhorse of every detail panel.
class LabeledValue extends StatelessWidget {
  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.monospace = false,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Identifiers read better in a monospaced face; prose does not.
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontFamily: monospace ? 'monospace' : null,
            fontWeight: monospace ? FontWeight.w500 : null,
          ),
        ),
      ],
    );
  }
}
