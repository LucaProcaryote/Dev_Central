// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'hospital_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class HospitalLocalizationsNl extends HospitalLocalizations {
  HospitalLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitleEhr => 'Elektronisch patiëntendossier';

  @override
  String get appTitleAdt => 'Opname, overplaatsing en ontslag';

  @override
  String get appTitlePharm => 'Apotheekkast';

  @override
  String get appTitleEai => 'Interoperabiliteitsserver';

  @override
  String get appTitleDevice => 'Apparaatsimulator';

  @override
  String get hospitalName => 'Mini-Ziekenhuis 2026';

  @override
  String get actionSave => 'Opslaan';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionDelete => 'Verwijderen';

  @override
  String get actionEdit => 'Bewerken';

  @override
  String get actionAdd => 'Toevoegen';

  @override
  String get actionClose => 'Sluiten';

  @override
  String get actionConfirm => 'Bevestigen';

  @override
  String get actionBack => 'Terug';

  @override
  String get actionNext => 'Volgende';

  @override
  String get actionRetry => 'Opnieuw proberen';

  @override
  String get actionRefresh => 'Vernieuwen';

  @override
  String get actionSearch => 'Zoeken';

  @override
  String get actionFilter => 'Filteren';

  @override
  String get actionClear => 'Wissen';

  @override
  String get actionSelect => 'Selecteren';

  @override
  String get actionView => 'Bekijken';

  @override
  String get actionExport => 'Exporteren';

  @override
  String get actionCopy => 'Kopiëren';

  @override
  String get actionCopied => 'Gekopieerd naar klembord';

  @override
  String get actionSign => 'Ondertekenen';

  @override
  String get actionPrint => 'Afdrukken';

  @override
  String get labelYes => 'Ja';

  @override
  String get labelNo => 'Nee';

  @override
  String get labelAll => 'Alle';

  @override
  String get labelNone => 'Geen';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelDate => 'Datum';

  @override
  String get labelTime => 'Tijd';

  @override
  String get labelDetails => 'Details';

  @override
  String get labelActions => 'Acties';

  @override
  String get labelNotes => 'Notities';

  @override
  String get labelReason => 'Reden';

  @override
  String get labelQuantity => 'Hoeveelheid';

  @override
  String get labelUnknown => 'Onbekend';

  @override
  String get labelOptional => 'optioneel';

  @override
  String get labelRequired => 'verplicht';

  @override
  String get labelLoading => 'Laden…';

  @override
  String get labelNoResults => 'Geen resultaten';

  @override
  String get labelToday => 'Vandaag';

  @override
  String get labelYesterday => 'Gisteren';

  @override
  String get labelLanguage => 'Taal';

  @override
  String get labelTheme => 'Thema';

  @override
  String get labelSettings => 'Instellingen';

  @override
  String get labelAbout => 'Over';

  @override
  String get labelVersion => 'Versie';

  @override
  String get labelFrom => 'Van';

  @override
  String get labelTo => 'Naar';

  @override
  String get labelBy => 'door';

  @override
  String get labelUnsavedChanges => 'Je hebt niet-opgeslagen wijzigingen.';

  @override
  String get labelDiscardChanges => 'Wijzigingen verwerpen';

  @override
  String get errorGeneric => 'Er is iets misgegaan.';

  @override
  String get errorNetwork =>
      'Kan de server niet bereiken. Controleer of de backend draait.';

  @override
  String get errorNotFound => 'Niet gevonden.';

  @override
  String get errorNotAllowed => 'Je rol staat deze actie niet toe.';

  @override
  String get errorFieldRequired => 'Dit veld is verplicht.';

  @override
  String get errorInvalidNumber => 'Voer een geldig getal in.';

  @override
  String get authSignIn => 'Aanmelden';

  @override
  String get authSignOut => 'Afmelden';

  @override
  String get authEmail => 'E-mailadres';

  @override
  String get authPassword => 'Wachtwoord';

  @override
  String authSignedInAs(String name) {
    return 'Aangemeld als $name';
  }

  @override
  String get authDemoModeTitle => 'Demomodus';

  @override
  String get authDemoModeBody =>
      'Geen echte authenticatie. Kies hieronder een account; het wachtwoord wordt niet gecontroleerd.';

  @override
  String get authQuickSignIn => 'Snel aanmelden';

  @override
  String get authErrorInvalidCredentials =>
      'E-mailadres of wachtwoord is onjuist.';

  @override
  String get authErrorUserNotFound => 'Geen account met dat e-mailadres.';

  @override
  String get authErrorNetwork => 'Kan de authenticatiedienst niet bereiken.';

  @override
  String get authErrorNotConfigured =>
      'Firebase-authenticatie is niet geconfigureerd voor deze build.';

  @override
  String get authRole => 'Rol';

  @override
  String get patients => 'Patiënten';

  @override
  String get patient => 'Patiënt';

  @override
  String get patientFile => 'Patiëntendossier';

  @override
  String get patientSearchHint => 'Zoek op naam, MRN of rijksregisternummer';

  @override
  String get patientMrn => 'Medisch dossiernummer';

  @override
  String get patientMrnShort => 'MRN';

  @override
  String get patientNationalNumber => 'Rijksregisternummer';

  @override
  String get patientDateOfBirth => 'Geboortedatum';

  @override
  String get patientAge => 'Leeftijd';

  @override
  String patientAgeYears(int years) {
    return '$years jaar';
  }

  @override
  String get patientGender => 'Geslacht';

  @override
  String get patientAddress => 'Adres';

  @override
  String get patientPhone => 'Telefoon';

  @override
  String get patientEmail => 'E-mail';

  @override
  String get patientPreferredLanguage => 'Voorkeurstaal';

  @override
  String get patientBloodGroup => 'Bloedgroep';

  @override
  String get patientGeneralPractitioner => 'Huisarts';

  @override
  String get patientDeceased => 'Overleden';

  @override
  String get patientAllergies => 'Allergieën';

  @override
  String get patientNoAllergies => 'Geen bekende allergieën';

  @override
  String patientAllergyBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allergieën in dossier',
      one: '1 allergie in dossier',
    );
    return '$_temp0';
  }

  @override
  String get patientHighRiskAllergy => 'Hoogrisico-allergie';

  @override
  String get patientDemographics => 'Demografische gegevens';

  @override
  String patientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count patiënten',
      one: '1 patiënt',
      zero: 'Geen patiënten',
    );
    return '$_temp0';
  }

  @override
  String get patientNotFound => 'Patiënt niet gevonden.';

  @override
  String get patientSelectPrompt =>
      'Selecteer een patiënt om het dossier te bekijken.';

  @override
  String get encounter => 'Contact';

  @override
  String get encounters => 'Contacten';

  @override
  String get encounterActive => 'Huidig verblijf';

  @override
  String get encounterNone => 'Momenteel niet opgenomen';

  @override
  String get encounterVisitNumber => 'Contactnummer';

  @override
  String get encounterAdmittedOn => 'Opgenomen op';

  @override
  String get encounterDischargedOn => 'Ontslagen op';

  @override
  String get encounterLengthOfStay => 'Verblijfsduur';

  @override
  String encounterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagen',
      one: '1 dag',
      zero: 'minder dan een dag',
    );
    return '$_temp0';
  }

  @override
  String get encounterAttending => 'Behandelend arts';

  @override
  String get encounterReason => 'Reden van opname';

  @override
  String get locationWard => 'Afdeling';

  @override
  String get locationWards => 'Afdelingen';

  @override
  String get locationRoom => 'Kamer';

  @override
  String get locationBed => 'Bed';

  @override
  String get locationBeds => 'Bedden';

  @override
  String get locationFloor => 'Verdieping';

  @override
  String get locationIsolation => 'Isolatiekamer';

  @override
  String get locationNotPlaced => 'Geen bed toegewezen';

  @override
  String get vitals => 'Vitale functies';

  @override
  String get vitalsLatest => 'Laatste metingen';

  @override
  String get vitalsNone => 'Nog geen metingen geregistreerd.';

  @override
  String get vitalsTrend => 'Verloop';

  @override
  String get vitalsAbnormal => 'Buiten het normale bereik';

  @override
  String vitalsNormalRange(String low, String high, String unit) {
    return 'Normaal bereik: $low – $high $unit';
  }

  @override
  String vitalsMeasuredAt(String time) {
    return 'Gemeten om $time';
  }

  @override
  String get vitalsSource => 'Bron';

  @override
  String get vitalsLast24h => 'Laatste 24 uur';

  @override
  String get vitalsLast72h => 'Laatste 72 uur';

  @override
  String get vitalsAllTime => 'Volledig verblijf';

  @override
  String vitalsObservationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metingen',
      one: '1 meting',
    );
    return '$_temp0';
  }

  @override
  String get prescriptions => 'Voorschriften';

  @override
  String get prescription => 'Voorschrift';

  @override
  String get prescriptionNew => 'Nieuw voorschrift';

  @override
  String get prescriptionActive => 'Actieve voorschriften';

  @override
  String get prescriptionNone => 'Geen voorschriften.';

  @override
  String get prescriptionMedication => 'Geneesmiddel';

  @override
  String get prescriptionDose => 'Dosis';

  @override
  String get prescriptionFrequency => 'Frequentie';

  @override
  String get prescriptionRoute => 'Toedieningsweg';

  @override
  String get prescriptionPrescriber => 'Voorschrijver';

  @override
  String get prescriptionStartDate => 'Startdatum';

  @override
  String get prescriptionEndDate => 'Einddatum';

  @override
  String get prescriptionIndication => 'Indicatie';

  @override
  String get prescriptionInstructions => 'Instructies';

  @override
  String get prescriptionAsNeeded => 'Zo nodig';

  @override
  String prescriptionTimesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maal daags',
      one: 'eenmaal daags',
    );
    return '$_temp0';
  }

  @override
  String get prescriptionStop => 'Voorschrift stoppen';

  @override
  String get prescriptionHold => 'Onderbreken';

  @override
  String get prescriptionResume => 'Hervatten';

  @override
  String prescriptionAllergyWarning(String substance) {
    return 'Deze patiënt heeft een geregistreerde allergie voor $substance.';
  }

  @override
  String get prescriptionAllergyProceed => 'Toch voorschrijven';

  @override
  String get formulary => 'Formularium';

  @override
  String get formularySearchHint => 'Zoek in het formularium';

  @override
  String get medicationControlled => 'Verdovend middel';

  @override
  String get notesTitle => 'Notities en observaties';

  @override
  String get noteNew => 'Nieuwe notitie';

  @override
  String get noteType => 'Soort notitie';

  @override
  String get noteTitleField => 'Titel';

  @override
  String get noteBody => 'Inhoud';

  @override
  String get noteAuthor => 'Auteur';

  @override
  String noteWrittenIn(String language) {
    return 'Geschreven in het $language';
  }

  @override
  String get noteSigned => 'Ondertekend';

  @override
  String get noteUnsigned => 'Concept';

  @override
  String get noteSignConfirm =>
      'Eenmaal ondertekend kan een notitie niet meer worden bewerkt. Ondertekenen?';

  @override
  String get noteNone => 'Nog geen notities.';

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notities',
      one: '1 notitie',
    );
    return '$_temp0';
  }

  @override
  String get adtDashboard => 'Bedoverzicht';

  @override
  String get adtAdmission => 'Opname';

  @override
  String get adtTransfer => 'Overplaatsing';

  @override
  String get adtDischarge => 'Ontslag';

  @override
  String get adtAdmitPatient => 'Een patiënt opnemen';

  @override
  String get adtTransferPatient => 'Patiënt overplaatsen';

  @override
  String get adtDischargePatient => 'Patiënt ontslaan';

  @override
  String get adtSelectPatient => 'Selecteer de patiënt';

  @override
  String get adtSelectWard => 'Selecteer een afdeling';

  @override
  String get adtSelectBed => 'Selecteer een bed';

  @override
  String get adtEncounterClass => 'Type verblijf';

  @override
  String get adtDischargeDisposition => 'Ontslagbestemming';

  @override
  String get adtMovements => 'Bewegingen';

  @override
  String get adtMovementHistory => 'Bewegingsgeschiedenis';

  @override
  String get adtNoMovements => 'Geen bewegingen geregistreerd.';

  @override
  String get adtOccupancy => 'Bezettingsgraad';

  @override
  String adtBedsFree(int count) {
    return '$count vrij';
  }

  @override
  String adtBedsOccupied(int count) {
    return '$count bezet';
  }

  @override
  String get adtNoFreeBed => 'Geen vrij bed op deze afdeling.';

  @override
  String adtAdmissionSuccess(String name, String bed) {
    return '$name opgenomen in bed $bed.';
  }

  @override
  String adtTransferSuccess(String name, String bed) {
    return '$name overgeplaatst naar bed $bed.';
  }

  @override
  String adtDischargeSuccess(String name) {
    return '$name is ontslagen.';
  }

  @override
  String adtDischargeConfirm(String name, String bed) {
    return '$name ontslaan uit bed $bed? Het bed gaat naar schoonmaak.';
  }

  @override
  String get adtWaitingForBed => 'Wacht op een bed';

  @override
  String get adtAlreadyAdmitted => 'Deze patiënt is al opgenomen.';

  @override
  String get pharmCabinet => 'Kast';

  @override
  String get pharmCabinets => 'Kasten';

  @override
  String get pharmStock => 'Voorraad';

  @override
  String get pharmQueue => 'Afleverwachtrij';

  @override
  String get pharmDispense => 'Afleveren';

  @override
  String get pharmDispensed => 'Afgeleverd';

  @override
  String get pharmRefuse => 'Weigeren';

  @override
  String get pharmRefusalReason => 'Reden van weigering';

  @override
  String get pharmOpenDrawer => 'Lade openen';

  @override
  String get pharmCloseDrawer => 'Lade sluiten';

  @override
  String pharmDrawerOpen(String slot) {
    return 'Lade $slot is open';
  }

  @override
  String get pharmUnlock => 'Kast ontgrendelen';

  @override
  String get pharmLock => 'Kast vergrendelen';

  @override
  String get pharmLocked => 'Vergrendeld';

  @override
  String get pharmUnlocked => 'Ontgrendeld';

  @override
  String get pharmSlot => 'Vak';

  @override
  String get pharmOnHand => 'Op voorraad';

  @override
  String get pharmParLevel => 'Bestelniveau';

  @override
  String get pharmExpiry => 'Vervaldatum';

  @override
  String get pharmLot => 'Lot';

  @override
  String get pharmLowStock => 'Lage voorraad';

  @override
  String get pharmOutOfStock => 'Niet op voorraad';

  @override
  String get pharmExpiredLot => 'Vervallen lot';

  @override
  String get pharmNearExpiry => 'Vervalt binnenkort';

  @override
  String get pharmRestock => 'Aanvullen';

  @override
  String get pharmRestockAmount => 'Toe te voegen hoeveelheid';

  @override
  String get pharmWitnessRequired =>
      'Een tweede handtekening is vereist voor verdovende middelen.';

  @override
  String get pharmWitnessName => 'Getuige';

  @override
  String get pharmBlockedOutOfStock => 'Afleveren onmogelijk: het vak is leeg.';

  @override
  String get pharmBlockedExpired =>
      'Afleveren onmogelijk: het lot is vervallen.';

  @override
  String get pharmBlockedLocked =>
      'Afleveren onmogelijk: de kast is vergrendeld.';

  @override
  String get pharmBlockedNotActive =>
      'Afleveren onmogelijk: het voorschrift is niet actief.';

  @override
  String get pharmBlockedAllergy =>
      'Afleveren onmogelijk: de patiënt is allergisch voor dit product.';

  @override
  String pharmDispenseSuccess(String medication, String patient) {
    return '$medication afgeleverd voor $patient.';
  }

  @override
  String get pharmQueueEmpty => 'Niets in afwachting van aflevering.';

  @override
  String pharmPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses in behandeling',
      one: '1 dosis in behandeling',
      zero: 'Niets in behandeling',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlows => 'Integratiestromen';

  @override
  String get eaiFlow => 'Stroom';

  @override
  String get eaiNewFlow => 'Nieuwe stroom';

  @override
  String get eaiFlowName => 'Naam van de stroom';

  @override
  String get eaiFlowDescription => 'Beschrijving';

  @override
  String get eaiEnabled => 'Ingeschakeld';

  @override
  String get eaiDisabled => 'Uitgeschakeld';

  @override
  String get eaiPalette => 'Bouwstenen';

  @override
  String get eaiCanvas => 'Canvas';

  @override
  String get eaiProperties => 'Eigenschappen';

  @override
  String get eaiNodeLabel => 'Label';

  @override
  String get eaiConnect => 'Verbinden';

  @override
  String get eaiDisconnect => 'Verbinding verwijderen';

  @override
  String get eaiDeleteNode => 'Blok verwijderen';

  @override
  String get eaiDragHint =>
      'Sleep een bouwsteen naar het canvas om te beginnen.';

  @override
  String get eaiConnectHint =>
      'Klik op de uitgang van een blok en daarna op de ingang van een ander.';

  @override
  String get eaiTestFlow => 'Stroom testen';

  @override
  String get eaiTestPayload => 'Testbericht';

  @override
  String get eaiRunTest => 'Uitvoeren';

  @override
  String get eaiTrace => 'Trace';

  @override
  String get eaiTraceEmpty =>
      'Voer de stroom uit om te zien wat er bij elke stap gebeurt.';

  @override
  String get eaiPayloadBefore => 'Invoer';

  @override
  String get eaiPayloadAfter => 'Uitvoer';

  @override
  String get eaiMessages => 'Berichtenlogboek';

  @override
  String get eaiMessageType => 'Berichttype';

  @override
  String get eaiSourceApp => 'Bron';

  @override
  String get eaiTargetApp => 'Bestemming';

  @override
  String get eaiLatency => 'Latentie';

  @override
  String get eaiReplay => 'Opnieuw afspelen';

  @override
  String get eaiNoMessages => 'Nog geen berichten.';

  @override
  String eaiValidationIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problemen op te lossen',
      one: '1 probleem op te lossen',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlowValid => 'De stroom is klaar om uit te voeren.';

  @override
  String get eaiFhirResources => 'FHIR-resources';

  @override
  String get eaiResourceType => 'Resourcetype';

  @override
  String eaiResourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resources',
      one: '1 resource',
      zero: 'Geen resources',
    );
    return '$_temp0';
  }

  @override
  String get eaiServerStatus => 'FHIR-server';

  @override
  String get eaiServerOnline => 'Online';

  @override
  String get eaiServerOffline => 'Offline';

  @override
  String get eaiFieldMappings => 'Veldtoewijzingen';

  @override
  String get eaiAddMapping => 'Toewijzing toevoegen';

  @override
  String get eaiSourceField => 'Bronveld';

  @override
  String get eaiTargetField => 'Doelveld';

  @override
  String get eaiTransform => 'Transformatie';

  @override
  String get eaiTransformArgument => 'Waarde';

  @override
  String get eaiCondition => 'Voorwaarde';

  @override
  String get eaiFieldPath => 'Veld';

  @override
  String get eaiOperator => 'Operator';

  @override
  String get eaiRoutes => 'Routes';

  @override
  String get eaiKeepUnmapped => 'Niet-toegewezen velden behouden';

  @override
  String get deviceSimulator => 'Apparaatsimulator';

  @override
  String get devices => 'Apparaten';

  @override
  String get device => 'Apparaat';

  @override
  String get deviceFleet => 'Apparatenpark';

  @override
  String get deviceId => 'Apparaat-ID';

  @override
  String get deviceKind => 'Apparaattype';

  @override
  String get deviceManufacturer => 'Fabrikant';

  @override
  String get deviceModel => 'Model';

  @override
  String get deviceSerial => 'Serienummer';

  @override
  String get deviceBattery => 'Batterij';

  @override
  String get deviceLastSeen => 'Laatst gezien';

  @override
  String get deviceNeverSeen => 'Nooit gerapporteerd';

  @override
  String get deviceAssignedTo => 'Toegewezen aan';

  @override
  String get deviceNotAssigned => 'Niet aan een patiënt toegewezen';

  @override
  String get deviceStart => 'Publiceren starten';

  @override
  String get deviceStop => 'Publiceren stoppen';

  @override
  String get deviceRunning => 'Publiceert';

  @override
  String get deviceStopped => 'Gestopt';

  @override
  String get deviceInterval => 'Interval tussen metingen';

  @override
  String deviceIntervalSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get deviceScenario => 'Scenario';

  @override
  String get deviceScenarioStable => 'Stabiel';

  @override
  String get deviceScenarioDeteriorating => 'Verslechterend';

  @override
  String get deviceScenarioRecovering => 'Herstellend';

  @override
  String get deviceScenarioArtefact => 'Ruisachtig signaal';

  @override
  String get deviceManualReading => 'Handmatig een meting versturen';

  @override
  String get deviceSend => 'Versturen';

  @override
  String get deviceSent => 'Meting verstuurd.';

  @override
  String deviceSendFailed(String error) {
    return 'Kon de meting niet versturen: $error';
  }

  @override
  String get deviceLiveFeed => 'Live stroom';

  @override
  String devicePublishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count metingen verstuurd',
      one: '1 meting verstuurd',
      zero: 'Nog niets verstuurd',
    );
    return '$_temp0';
  }

  @override
  String get deviceAppleWatch => 'Apple Watch';

  @override
  String get deviceHealthKitTitle => 'Apple Watch / HealthKit';

  @override
  String get deviceHealthKitBody =>
      'Metingen van een Apple Watch kunnen hier worden geïmporteerd en worden precies zoals een simulatormeting gepubliceerd.';

  @override
  String get deviceHealthKitImport => 'Importeren uit HealthKit';

  @override
  String get deviceHealthKitUnavailable =>
      'HealthKit is alleen beschikbaar op iOS. Op andere platformen kun je een export plakken.';

  @override
  String get deviceTargetPatient => 'Metingen versturen voor';

  @override
  String get deviceEndpoint => 'Publiceert naar';

  @override
  String get navOverview => 'Overzicht';

  @override
  String get navPatients => 'Patiënten';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAdmissions => 'Opnames';

  @override
  String get navPharmacy => 'Apotheek';

  @override
  String get navIntegration => 'Integratie';

  @override
  String get navDevices => 'Apparaten';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get dashboardAdmittedPatients => 'Opgenomen patiënten';

  @override
  String get dashboardFreeBeds => 'Vrije bedden';

  @override
  String get dashboardPendingDoses => 'Af te leveren doses';

  @override
  String get dashboardActiveDevices => 'Actieve apparaten';

  @override
  String get dashboardAbnormalVitals => 'Afwijkende metingen';

  @override
  String get dashboardRecentActivity => 'Recente activiteit';

  @override
  String get backendModeMemory => 'Demogegevens in het geheugen';

  @override
  String get backendModeRest => 'Verbonden met de lokale API';

  @override
  String get backendModeDataConnect => 'Verbonden met Firebase Data Connect';

  @override
  String backendBanner(String mode) {
    return '$mode — gegevens worden niet gedeeld met de andere toepassingen tot je een echte backend gebruikt.';
  }

  @override
  String get safetyChecks => 'Veiligheidscontroles';

  @override
  String get safetyNoIssues => 'Geen veiligheidsproblemen gevonden.';

  @override
  String get safetyBlocked =>
      'Deze actie is geblokkeerd en kan niet worden voltooid.';

  @override
  String get safetyAcknowledge =>
      'Ik heb de waarschuwingen gelezen en aanvaard de verantwoordelijkheid.';

  @override
  String get safetyOverrideReason => 'Reden voor het negeren';

  @override
  String get safetySeverityBlocking => 'Blokkerend';

  @override
  String get safetySeverityWarning => 'Waarschuwing';

  @override
  String get safetySeverityAdvisory => 'Ter informatie';

  @override
  String get prescriptionSaved => 'Voorschrift opgeslagen.';

  @override
  String get noteSaved => 'Notitie opgeslagen.';

  @override
  String get prescriptionSelectMedication => 'Kies een geneesmiddel';

  @override
  String pharmRestocked(String slot) {
    return 'Vak $slot aangevuld.';
  }

  @override
  String get pharmDrawerClosedAutomatically =>
      'De lade is automatisch gesloten.';

  @override
  String get pharmAlerts => 'Kastmeldingen';

  @override
  String get pharmNoAlerts =>
      'Geen meldingen. Voorraden en vervaldata zijn in orde.';

  @override
  String pharmForPatient(String patient) {
    return 'Voor $patient';
  }

  @override
  String pharmDue(String time) {
    return 'Gepland $time';
  }

  @override
  String get pharmOverdue => 'Te laat';

  @override
  String get pharmHistory => 'Afleveringsgeschiedenis';

  @override
  String get adtNewAdmission => 'Nieuwe opname';

  @override
  String get adtStepReviewPatient => 'Patiënt';

  @override
  String get adtStepPlacement => 'Plaatsing';

  @override
  String get adtStepConfirm => 'Bevestigen';

  @override
  String get adtChooseAnotherWard => 'Kies een andere afdeling';

  @override
  String get adtCleaningNote =>
      'Bedden in schoonmaak kunnen niet worden toegewezen.';

  @override
  String get adtEmitEvent => 'Gebeurtenis naar de integratiemotor verzonden.';

  @override
  String get adtEmitFailed =>
      'De integratiemotor is onbereikbaar; de beweging is toch geregistreerd.';

  @override
  String get adtWardOverview => 'Afdelingsoverzicht';

  @override
  String get adtCurrentPatients => 'Patiënten op de afdeling';

  @override
  String get adtSetBedStatus => 'Bedstatus wijzigen';

  @override
  String get eaiOpenEditor => 'Editor openen';

  @override
  String get eaiSaveFlow => 'Stroom opslaan';

  @override
  String get eaiFlowSaved => 'Stroom opgeslagen.';

  @override
  String get eaiDeleteFlowConfirm =>
      'Deze stroom verwijderen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String get eaiSelectNode =>
      'Selecteer een blok om de eigenschappen te bewerken.';

  @override
  String get eaiSamplePayload => 'Voorbeeldberichten';

  @override
  String get eaiInvalidJson => 'Dit is geen geldige JSON.';

  @override
  String get eaiStepPassed => 'Geslaagd';

  @override
  String get eaiStepDropped => 'Hier weggefilterd';

  @override
  String get eaiStepFailed => 'Hier mislukt';

  @override
  String get eaiTotalResources => 'Resources op de FHIR-server';

  @override
  String get eaiSeedFhir => 'Fictieve patiënten in FHIR laden';

  @override
  String eaiSeedDone(int count) {
    return '$count resources naar de FHIR-server geschreven.';
  }

  @override
  String get deviceAutoAssign => 'Automatisch toewijzen op basis van het bed';

  @override
  String get deviceWaveform => 'Signaal';

  @override
  String get deviceOutbox => 'Recent verzonden';

  @override
  String get deviceConfiguration => 'Configuratie';

  @override
  String get deviceMeasurements => 'Geproduceerde metingen';

  @override
  String deviceOfflineQueue(int count) {
    return '$count metingen wachten op verzending';
  }
}
