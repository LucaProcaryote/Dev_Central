import 'package:flutter/material.dart';

import '../../l10n/generated/hospital_localizations.dart';
import '../../models/codes.dart';
import '../../models/patient.dart';
import '../formatters.dart';
import '../theme.dart';
import 'state_views.dart';

/// Circular initials avatar. Colour is derived from the patient id so the same
/// person is always the same colour, which helps when scanning a ward list.
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.patient, this.radius = 20});

  final Patient patient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hue = (patient.id.hashCode.abs() % 360).toDouble();
    final background = HSLColor.fromAHSL(
      1,
      hue,
      0.35,
      Theme.of(context).brightness == Brightness.dark ? 0.32 : 0.86,
    ).toColor();
    final foreground = HSLColor.fromAHSL(
      1,
      hue,
      0.55,
      Theme.of(context).brightness == Brightness.dark ? 0.85 : 0.28,
    ).toColor();

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        patient.initials,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

/// The allergy banner.
///
/// Placed at the top of the patient file and repeated on the prescribing and
/// dispensing screens. A high-risk allergy is red and cannot be collapsed;
/// low-risk allergies are amber. Hiding this behind a tab would be the wrong
/// lesson to teach.
class AllergyBanner extends StatelessWidget {
  const AllergyBanner({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;

    if (patient.allergies.isEmpty) {
      return Row(
        children: <Widget>[
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Gap.w8,
          Text(
            l10n.patientNoAllergies,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final isHighRisk = patient.hasHighRiskAllergy;
    final color = isHighRisk
        ? HospitalTheme.criticalOf(context)
        : HospitalTheme.warningOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.sm + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 18, color: color),
              Gap.w8,
              Text(
                l10n.patientAllergyBanner(patient.allergies.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Gap.h8,
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: <Widget>[
              for (final allergy in patient.allergies)
                Tooltip(
                  message: allergy.reaction.forLanguage(language),
                  child: StatusChip(
                    label: allergy.substance.forLanguage(language),
                    color: allergy.criticality == AllergyCriticality.high
                        ? HospitalTheme.criticalOf(context)
                        : HospitalTheme.warningOf(context),
                    icon: allergy.criticality == AllergyCriticality.high
                        ? Icons.priority_high
                        : null,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A one-line patient identity strip: avatar, name, and the identifiers a
/// clinician uses to confirm they have the right person.
class PatientIdentityBar extends StatelessWidget {
  const PatientIdentityBar({
    super.key,
    required this.patient,
    this.trailing,
    this.dense = false,
  });

  final Patient patient;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = HospitalLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;

    return Row(
      children: <Widget>[
        PatientAvatar(patient: patient, radius: dense ? 16 : 24),
        Gap.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      patient.fullName,
                      style:
                          (dense
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (patient.isDeceased) ...<Widget>[
                    Gap.w8,
                    StatusChip(
                      label: l10n.patientDeceased,
                      color: theme.colorScheme.outline,
                      dense: true,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${patient.gender.display.forLanguage(language)} · '
                '${l10n.patientAgeYears(patient.ageAt())} · '
                '${Formats.shortDate(context, patient.birthDate)} · '
                '${l10n.patientMrnShort} ${patient.mrn}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[Gap.w8, trailing!],
      ],
    );
  }
}
