/// Shared foundation for the Mini-Hospital 2026 teaching platform.
///
/// The five applications - EHR, ADT, PHARM, EAI and the device simulators -
/// each depend on this package and on nothing else in common. It holds the
/// domain model, the FHIR mapping, the trilingual interface strings, the
/// authentication and data-access layers, and the design system.
library;

// Configuration
export 'src/config/app_config.dart';
export 'src/config/supported_locales.dart';

// Domain model
export 'src/models/clinical_note.dart';
export 'src/models/codes.dart';
export 'src/models/device.dart';
export 'src/models/encounter.dart';
export 'src/models/hospital_user.dart';
export 'src/models/integration.dart';
export 'src/models/location.dart';
export 'src/models/observation.dart';
export 'src/models/patient.dart';
export 'src/models/pharmacy.dart';
export 'src/models/prescription.dart';

// Clinical safety
export 'src/clinical/safety_checks.dart';

// FHIR
export 'src/fhir/fhir_client.dart';

// Integration engine
export 'src/integration/event_publisher.dart';
export 'src/integration/flow_engine.dart';
export 'src/integration/json_path.dart';
export 'src/integration/transforms.dart';

// Authentication
export 'src/auth/auth_service.dart';
export 'src/auth/demo_auth_service.dart';
export 'src/auth/firebase_auth_service.dart';

// Data access
export 'src/data/hospital_repository.dart';
export 'src/data/memory/memory_repository.dart';
export 'src/data/repository_factory.dart';
export 'src/data/rest/rest_repository.dart';

// Seed data
export 'src/seed/hospital_seed.dart';
export 'src/seed/seed_formulary.dart';
export 'src/seed/seed_users.dart';

// Localisation
export 'src/l10n/generated/hospital_localizations.dart';

// User interface
export 'src/ui/app_shell.dart';
export 'src/ui/formatters.dart';
export 'src/ui/hospital_app.dart';
export 'src/ui/locale_controller.dart';
export 'src/ui/sign_in_screen.dart';
export 'src/ui/theme.dart';
export 'src/ui/widgets/backend_banner.dart';
export 'src/ui/widgets/language_selector.dart';
export 'src/ui/widgets/patient_widgets.dart';
export 'src/ui/widgets/repository_builder.dart';
export 'src/ui/widgets/state_views.dart';
export 'src/ui/widgets/vital_chart.dart';

// Utilities
export 'src/util/json.dart';
export 'src/util/localized_text.dart';
