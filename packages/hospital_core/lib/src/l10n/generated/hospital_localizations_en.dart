// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'hospital_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HospitalLocalizationsEn extends HospitalLocalizations {
  HospitalLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitleEhr => 'Electronic Health Record';

  @override
  String get appTitleAdt => 'Admission, Transfer & Discharge';

  @override
  String get appTitlePharm => 'Pharmacy Cabinet';

  @override
  String get appTitleEai => 'Interoperability Server';

  @override
  String get appTitleDevice => 'Device Simulator';

  @override
  String get hospitalName => 'Mini-Hospital 2026';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionBack => 'Back';

  @override
  String get actionNext => 'Next';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionFilter => 'Filter';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionSelect => 'Select';

  @override
  String get actionView => 'View';

  @override
  String get actionExport => 'Export';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionCopied => 'Copied to clipboard';

  @override
  String get actionSign => 'Sign';

  @override
  String get actionPrint => 'Print';

  @override
  String get labelYes => 'Yes';

  @override
  String get labelNo => 'No';

  @override
  String get labelAll => 'All';

  @override
  String get labelNone => 'None';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelDate => 'Date';

  @override
  String get labelTime => 'Time';

  @override
  String get labelDetails => 'Details';

  @override
  String get labelActions => 'Actions';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelReason => 'Reason';

  @override
  String get labelQuantity => 'Quantity';

  @override
  String get labelUnknown => 'Unknown';

  @override
  String get labelOptional => 'optional';

  @override
  String get labelRequired => 'required';

  @override
  String get labelLoading => 'Loading…';

  @override
  String get labelNoResults => 'No results';

  @override
  String get labelToday => 'Today';

  @override
  String get labelYesterday => 'Yesterday';

  @override
  String get labelLanguage => 'Language';

  @override
  String get labelTheme => 'Theme';

  @override
  String get labelSettings => 'Settings';

  @override
  String get labelAbout => 'About';

  @override
  String get labelVersion => 'Version';

  @override
  String get labelFrom => 'From';

  @override
  String get labelTo => 'To';

  @override
  String get labelBy => 'by';

  @override
  String get labelUnsavedChanges => 'You have unsaved changes.';

  @override
  String get labelDiscardChanges => 'Discard changes';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check that the backend is running.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorNotAllowed => 'Your role does not allow this action.';

  @override
  String get errorFieldRequired => 'This field is required.';

  @override
  String get errorInvalidNumber => 'Enter a valid number.';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authEmail => 'E-mail address';

  @override
  String get authPassword => 'Password';

  @override
  String authSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get authDemoModeTitle => 'Demo mode';

  @override
  String get authDemoModeBody =>
      'No real authentication. Pick any account below; the password is not checked.';

  @override
  String get authQuickSignIn => 'Quick sign-in';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail address or password is incorrect.';

  @override
  String get authErrorUserNotFound => 'No account with that e-mail address.';

  @override
  String get authErrorNetwork => 'Cannot reach the authentication service.';

  @override
  String get authErrorNotConfigured =>
      'Firebase authentication is not configured for this build.';

  @override
  String get authRole => 'Role';

  @override
  String get patients => 'Patients';

  @override
  String get patient => 'Patient';

  @override
  String get patientFile => 'Patient file';

  @override
  String get patientSearchHint => 'Search by name, MRN or national number';

  @override
  String get patientMrn => 'Medical record number';

  @override
  String get patientMrnShort => 'MRN';

  @override
  String get patientNationalNumber => 'National register number';

  @override
  String get patientDateOfBirth => 'Date of birth';

  @override
  String get patientAge => 'Age';

  @override
  String patientAgeYears(int years) {
    return '$years years';
  }

  @override
  String get patientGender => 'Gender';

  @override
  String get patientAddress => 'Address';

  @override
  String get patientPhone => 'Phone';

  @override
  String get patientEmail => 'E-mail';

  @override
  String get patientPreferredLanguage => 'Preferred language';

  @override
  String get patientBloodGroup => 'Blood group';

  @override
  String get patientGeneralPractitioner => 'General practitioner';

  @override
  String get patientDeceased => 'Deceased';

  @override
  String get patientAllergies => 'Allergies';

  @override
  String get patientNoAllergies => 'No known allergies';

  @override
  String patientAllergyBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allergies on file',
      one: '1 allergy on file',
    );
    return '$_temp0';
  }

  @override
  String get patientHighRiskAllergy => 'High-risk allergy';

  @override
  String get patientDemographics => 'Demographics';

  @override
  String patientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count patients',
      one: '1 patient',
      zero: 'No patients',
    );
    return '$_temp0';
  }

  @override
  String get patientNotFound => 'Patient not found.';

  @override
  String get patientSelectPrompt => 'Select a patient to see their file.';

  @override
  String get encounter => 'Encounter';

  @override
  String get encounters => 'Encounters';

  @override
  String get encounterActive => 'Current stay';

  @override
  String get encounterNone => 'Not currently admitted';

  @override
  String get encounterVisitNumber => 'Visit number';

  @override
  String get encounterAdmittedOn => 'Admitted on';

  @override
  String get encounterDischargedOn => 'Discharged on';

  @override
  String get encounterLengthOfStay => 'Length of stay';

  @override
  String encounterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'less than a day',
    );
    return '$_temp0';
  }

  @override
  String get encounterAttending => 'Attending physician';

  @override
  String get encounterReason => 'Reason for admission';

  @override
  String get locationWard => 'Ward';

  @override
  String get locationWards => 'Wards';

  @override
  String get locationRoom => 'Room';

  @override
  String get locationBed => 'Bed';

  @override
  String get locationBeds => 'Beds';

  @override
  String get locationFloor => 'Floor';

  @override
  String get locationIsolation => 'Isolation room';

  @override
  String get locationNotPlaced => 'No bed assigned';

  @override
  String get vitals => 'Vital signs';

  @override
  String get vitalsLatest => 'Latest measurements';

  @override
  String get vitalsNone => 'No measurements recorded yet.';

  @override
  String get vitalsTrend => 'Trend';

  @override
  String get vitalsAbnormal => 'Outside the normal range';

  @override
  String vitalsNormalRange(String low, String high, String unit) {
    return 'Normal range: $low – $high $unit';
  }

  @override
  String vitalsMeasuredAt(String time) {
    return 'Measured at $time';
  }

  @override
  String get vitalsSource => 'Source';

  @override
  String get vitalsLast24h => 'Last 24 hours';

  @override
  String get vitalsLast72h => 'Last 72 hours';

  @override
  String get vitalsAllTime => 'Whole stay';

  @override
  String vitalsObservationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count measurements',
      one: '1 measurement',
    );
    return '$_temp0';
  }

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get prescription => 'Prescription';

  @override
  String get prescriptionNew => 'New prescription';

  @override
  String get prescriptionActive => 'Active prescriptions';

  @override
  String get prescriptionNone => 'No prescriptions.';

  @override
  String get prescriptionMedication => 'Medication';

  @override
  String get prescriptionDose => 'Dose';

  @override
  String get prescriptionFrequency => 'Frequency';

  @override
  String get prescriptionRoute => 'Route';

  @override
  String get prescriptionPrescriber => 'Prescriber';

  @override
  String get prescriptionStartDate => 'Start date';

  @override
  String get prescriptionEndDate => 'End date';

  @override
  String get prescriptionIndication => 'Indication';

  @override
  String get prescriptionInstructions => 'Instructions';

  @override
  String get prescriptionAsNeeded => 'As needed';

  @override
  String prescriptionTimesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times a day',
      one: 'once a day',
    );
    return '$_temp0';
  }

  @override
  String get prescriptionStop => 'Stop prescription';

  @override
  String get prescriptionHold => 'Put on hold';

  @override
  String get prescriptionResume => 'Resume';

  @override
  String prescriptionAllergyWarning(String substance) {
    return 'This patient has a recorded allergy to $substance.';
  }

  @override
  String get prescriptionAllergyProceed => 'Prescribe anyway';

  @override
  String get formulary => 'Formulary';

  @override
  String get formularySearchHint => 'Search the formulary';

  @override
  String get medicationControlled => 'Controlled substance';

  @override
  String get notesTitle => 'Notes and observations';

  @override
  String get noteNew => 'New note';

  @override
  String get noteType => 'Note type';

  @override
  String get noteTitleField => 'Title';

  @override
  String get noteBody => 'Content';

  @override
  String get noteAuthor => 'Author';

  @override
  String noteWrittenIn(String language) {
    return 'Written in $language';
  }

  @override
  String get noteSigned => 'Signed';

  @override
  String get noteUnsigned => 'Draft';

  @override
  String get noteSignConfirm =>
      'Once signed, a note can no longer be edited. Sign it?';

  @override
  String get noteNone => 'No notes yet.';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String get adtDashboard => 'Bed board';

  @override
  String get adtAdmission => 'Admission';

  @override
  String get adtTransfer => 'Transfer';

  @override
  String get adtDischarge => 'Discharge';

  @override
  String get adtAdmitPatient => 'Admit a patient';

  @override
  String get adtTransferPatient => 'Transfer patient';

  @override
  String get adtDischargePatient => 'Discharge patient';

  @override
  String get adtSelectPatient => 'Select the patient';

  @override
  String get adtSelectWard => 'Select a ward';

  @override
  String get adtSelectBed => 'Select a bed';

  @override
  String get adtEncounterClass => 'Type of stay';

  @override
  String get adtDischargeDisposition => 'Discharge destination';

  @override
  String get adtMovements => 'Movements';

  @override
  String get adtMovementHistory => 'Movement history';

  @override
  String get adtNoMovements => 'No movements recorded.';

  @override
  String get adtOccupancy => 'Occupancy';

  @override
  String adtBedsFree(int count) {
    return '$count free';
  }

  @override
  String adtBedsOccupied(int count) {
    return '$count occupied';
  }

  @override
  String get adtNoFreeBed => 'No free bed in this ward.';

  @override
  String adtAdmissionSuccess(String name, String bed) {
    return '$name admitted to bed $bed.';
  }

  @override
  String adtTransferSuccess(String name, String bed) {
    return '$name transferred to bed $bed.';
  }

  @override
  String adtDischargeSuccess(String name) {
    return '$name discharged.';
  }

  @override
  String adtDischargeConfirm(String name, String bed) {
    return 'Discharge $name from bed $bed? The bed will be released for cleaning.';
  }

  @override
  String get adtWaitingForBed => 'Waiting for a bed';

  @override
  String get adtAlreadyAdmitted => 'This patient is already admitted.';

  @override
  String get pharmCabinet => 'Cabinet';

  @override
  String get pharmCabinets => 'Cabinets';

  @override
  String get pharmStock => 'Stock';

  @override
  String get pharmQueue => 'Dispensing queue';

  @override
  String get pharmDispense => 'Dispense';

  @override
  String get pharmDispensed => 'Dispensed';

  @override
  String get pharmRefuse => 'Refuse';

  @override
  String get pharmRefusalReason => 'Reason for refusal';

  @override
  String get pharmOpenDrawer => 'Open drawer';

  @override
  String get pharmCloseDrawer => 'Close drawer';

  @override
  String pharmDrawerOpen(String slot) {
    return 'Drawer $slot is open';
  }

  @override
  String get pharmUnlock => 'Unlock cabinet';

  @override
  String get pharmLock => 'Lock cabinet';

  @override
  String get pharmLocked => 'Locked';

  @override
  String get pharmUnlocked => 'Unlocked';

  @override
  String get pharmSlot => 'Slot';

  @override
  String get pharmOnHand => 'On hand';

  @override
  String get pharmParLevel => 'Par level';

  @override
  String get pharmExpiry => 'Expiry';

  @override
  String get pharmLot => 'Lot';

  @override
  String get pharmLowStock => 'Low stock';

  @override
  String get pharmOutOfStock => 'Out of stock';

  @override
  String get pharmExpiredLot => 'Expired lot';

  @override
  String get pharmNearExpiry => 'Expires soon';

  @override
  String get pharmRestock => 'Restock';

  @override
  String get pharmRestockAmount => 'Quantity to add';

  @override
  String get pharmWitnessRequired =>
      'A second signature is required for controlled substances.';

  @override
  String get pharmWitnessName => 'Witness';

  @override
  String get pharmBlockedOutOfStock => 'Cannot dispense: the slot is empty.';

  @override
  String get pharmBlockedExpired => 'Cannot dispense: the lot has expired.';

  @override
  String get pharmBlockedLocked => 'Cannot dispense: the cabinet is locked.';

  @override
  String get pharmBlockedNotActive =>
      'Cannot dispense: the prescription is not active.';

  @override
  String get pharmBlockedAllergy =>
      'Cannot dispense: the patient is allergic to this product.';

  @override
  String pharmDispenseSuccess(String medication, String patient) {
    return '$medication dispensed for $patient.';
  }

  @override
  String get pharmQueueEmpty => 'Nothing waiting to be dispensed.';

  @override
  String pharmPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses pending',
      one: '1 dose pending',
      zero: 'Nothing pending',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlows => 'Integration flows';

  @override
  String get eaiFlow => 'Flow';

  @override
  String get eaiNewFlow => 'New flow';

  @override
  String get eaiFlowName => 'Flow name';

  @override
  String get eaiFlowDescription => 'Description';

  @override
  String get eaiEnabled => 'Enabled';

  @override
  String get eaiDisabled => 'Disabled';

  @override
  String get eaiPalette => 'Building blocks';

  @override
  String get eaiCanvas => 'Canvas';

  @override
  String get eaiProperties => 'Properties';

  @override
  String get eaiNodeLabel => 'Label';

  @override
  String get eaiConnect => 'Connect';

  @override
  String get eaiDisconnect => 'Remove connection';

  @override
  String get eaiDeleteNode => 'Delete block';

  @override
  String get eaiDragHint => 'Drag a building block onto the canvas to start.';

  @override
  String get eaiConnectHint =>
      'Click the output of one block, then the input of another.';

  @override
  String get eaiTestFlow => 'Test the flow';

  @override
  String get eaiTestPayload => 'Test message';

  @override
  String get eaiRunTest => 'Run';

  @override
  String get eaiTrace => 'Trace';

  @override
  String get eaiTraceEmpty => 'Run the flow to see what happens at each step.';

  @override
  String get eaiPayloadBefore => 'Input';

  @override
  String get eaiPayloadAfter => 'Output';

  @override
  String get eaiMessages => 'Message log';

  @override
  String get eaiMessageType => 'Message type';

  @override
  String get eaiSourceApp => 'Source';

  @override
  String get eaiTargetApp => 'Destination';

  @override
  String get eaiLatency => 'Latency';

  @override
  String get eaiReplay => 'Replay';

  @override
  String get eaiNoMessages => 'No messages yet.';

  @override
  String eaiValidationIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems to fix',
      one: '1 problem to fix',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlowValid => 'The flow is ready to run.';

  @override
  String get eaiFhirResources => 'FHIR resources';

  @override
  String get eaiResourceType => 'Resource type';

  @override
  String eaiResourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resources',
      one: '1 resource',
      zero: 'No resources',
    );
    return '$_temp0';
  }

  @override
  String get eaiServerStatus => 'FHIR server';

  @override
  String get eaiServerOnline => 'Online';

  @override
  String get eaiServerOffline => 'Offline';

  @override
  String get eaiFieldMappings => 'Field mappings';

  @override
  String get eaiAddMapping => 'Add a mapping';

  @override
  String get eaiSourceField => 'Source field';

  @override
  String get eaiTargetField => 'Target field';

  @override
  String get eaiTransform => 'Transformation';

  @override
  String get eaiTransformArgument => 'Value';

  @override
  String get eaiCondition => 'Condition';

  @override
  String get eaiFieldPath => 'Field';

  @override
  String get eaiOperator => 'Operator';

  @override
  String get eaiRoutes => 'Routes';

  @override
  String get eaiKeepUnmapped => 'Keep the fields that are not mapped';

  @override
  String get deviceSimulator => 'Device simulator';

  @override
  String get devices => 'Devices';

  @override
  String get device => 'Device';

  @override
  String get deviceFleet => 'Device fleet';

  @override
  String get deviceId => 'Device identifier';

  @override
  String get deviceKind => 'Device type';

  @override
  String get deviceManufacturer => 'Manufacturer';

  @override
  String get deviceModel => 'Model';

  @override
  String get deviceSerial => 'Serial number';

  @override
  String get deviceBattery => 'Battery';

  @override
  String get deviceLastSeen => 'Last seen';

  @override
  String get deviceNeverSeen => 'Never reported';

  @override
  String get deviceAssignedTo => 'Assigned to';

  @override
  String get deviceNotAssigned => 'Not assigned to a patient';

  @override
  String get deviceStart => 'Start publishing';

  @override
  String get deviceStop => 'Stop publishing';

  @override
  String get deviceRunning => 'Publishing';

  @override
  String get deviceStopped => 'Stopped';

  @override
  String get deviceInterval => 'Interval between readings';

  @override
  String deviceIntervalSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get deviceScenario => 'Scenario';

  @override
  String get deviceScenarioStable => 'Stable';

  @override
  String get deviceScenarioDeteriorating => 'Deteriorating';

  @override
  String get deviceScenarioRecovering => 'Recovering';

  @override
  String get deviceScenarioArtefact => 'Noisy signal';

  @override
  String get deviceManualReading => 'Send a reading by hand';

  @override
  String get deviceSend => 'Send';

  @override
  String get deviceSent => 'Reading sent.';

  @override
  String deviceSendFailed(String error) {
    return 'Could not send the reading: $error';
  }

  @override
  String get deviceLiveFeed => 'Live feed';

  @override
  String devicePublishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readings sent',
      one: '1 reading sent',
      zero: 'Nothing sent yet',
    );
    return '$_temp0';
  }

  @override
  String get deviceAppleWatch => 'Apple Watch';

  @override
  String get deviceHealthKitTitle => 'Apple Watch / HealthKit';

  @override
  String get deviceHealthKitBody =>
      'Readings collected by an Apple Watch can be imported here and are published exactly like a simulator reading.';

  @override
  String get deviceHealthKitImport => 'Import from HealthKit';

  @override
  String get deviceHealthKitUnavailable =>
      'HealthKit is only available on iOS. On other platforms you can paste an export instead.';

  @override
  String get deviceTargetPatient => 'Send readings for';

  @override
  String get deviceEndpoint => 'Publishing to';

  @override
  String get navOverview => 'Overview';

  @override
  String get navPatients => 'Patients';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAdmissions => 'Admissions';

  @override
  String get navPharmacy => 'Pharmacy';

  @override
  String get navIntegration => 'Integration';

  @override
  String get navDevices => 'Devices';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardAdmittedPatients => 'Patients in the hospital';

  @override
  String get dashboardFreeBeds => 'Free beds';

  @override
  String get dashboardPendingDoses => 'Doses to dispense';

  @override
  String get dashboardActiveDevices => 'Active devices';

  @override
  String get dashboardAbnormalVitals => 'Abnormal measurements';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get backendModeMemory => 'In-memory demo data';

  @override
  String get backendModeRest => 'Connected to the local API';

  @override
  String get backendModeDataConnect => 'Connected to Firebase Data Connect';

  @override
  String backendBanner(String mode) {
    return '$mode — data is not shared with the other applications until you switch to a real backend.';
  }

  @override
  String get safetyChecks => 'Safety checks';

  @override
  String get safetyNoIssues => 'No safety issues found.';

  @override
  String get safetyBlocked => 'This action is blocked and cannot be completed.';

  @override
  String get safetyAcknowledge =>
      'I have read the warnings and accept responsibility.';

  @override
  String get safetyOverrideReason => 'Reason for overriding';

  @override
  String get safetySeverityBlocking => 'Blocking';

  @override
  String get safetySeverityWarning => 'Warning';

  @override
  String get safetySeverityAdvisory => 'For information';

  @override
  String get prescriptionSaved => 'Prescription saved.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get prescriptionSelectMedication => 'Choose a medication';

  @override
  String pharmRestocked(String slot) {
    return 'Slot $slot restocked.';
  }

  @override
  String get pharmDrawerClosedAutomatically =>
      'The drawer closed automatically.';

  @override
  String get pharmAlerts => 'Cabinet alerts';

  @override
  String get pharmNoAlerts =>
      'No alerts. Stock levels and expiry dates are fine.';

  @override
  String pharmForPatient(String patient) {
    return 'For $patient';
  }

  @override
  String pharmDue(String time) {
    return 'Due $time';
  }

  @override
  String get pharmOverdue => 'Overdue';

  @override
  String get pharmHistory => 'Dispensing history';

  @override
  String get adtNewAdmission => 'New admission';

  @override
  String get adtStepReviewPatient => 'Patient';

  @override
  String get adtStepPlacement => 'Placement';

  @override
  String get adtStepConfirm => 'Confirm';

  @override
  String get adtChooseAnotherWard => 'Choose another ward';

  @override
  String get adtCleaningNote => 'Beds being cleaned cannot be assigned.';

  @override
  String get adtEmitEvent => 'Event sent to the integration engine.';

  @override
  String get adtEmitFailed =>
      'The integration engine could not be reached; the movement was still recorded.';

  @override
  String get adtWardOverview => 'Ward overview';

  @override
  String get adtCurrentPatients => 'Patients on the ward';

  @override
  String get adtSetBedStatus => 'Change bed status';

  @override
  String get eaiOpenEditor => 'Open the editor';

  @override
  String get eaiSaveFlow => 'Save the flow';

  @override
  String get eaiFlowSaved => 'Flow saved.';

  @override
  String get eaiDeleteFlowConfirm => 'Delete this flow? This cannot be undone.';

  @override
  String get eaiSelectNode => 'Select a block to edit its properties.';

  @override
  String get eaiSamplePayload => 'Sample messages';

  @override
  String get eaiInvalidJson => 'This is not valid JSON.';

  @override
  String get eaiStepPassed => 'Passed';

  @override
  String get eaiStepDropped => 'Dropped here';

  @override
  String get eaiStepFailed => 'Failed here';

  @override
  String get eaiTotalResources => 'Resources on the FHIR server';

  @override
  String get eaiSeedFhir => 'Load the fictive patients into FHIR';

  @override
  String eaiSeedDone(int count) {
    return '$count resources written to the FHIR server.';
  }

  @override
  String get deviceAutoAssign => 'Assign automatically from the bed';

  @override
  String get deviceWaveform => 'Signal';

  @override
  String get deviceOutbox => 'Recently sent';

  @override
  String get deviceConfiguration => 'Configuration';

  @override
  String get deviceMeasurements => 'Measurements produced';

  @override
  String deviceOfflineQueue(int count) {
    return '$count readings waiting to be sent';
  }
}
