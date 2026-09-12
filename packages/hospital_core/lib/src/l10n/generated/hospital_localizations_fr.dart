// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'hospital_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class HospitalLocalizationsFr extends HospitalLocalizations {
  HospitalLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitleEhr => 'Dossier patient informatisé';

  @override
  String get appTitleAdt => 'Admission, transfert et sortie';

  @override
  String get appTitlePharm => 'Armoire de pharmacie';

  @override
  String get appTitleEai => 'Serveur d\'interopérabilité';

  @override
  String get appTitleDevice => 'Simulateur d\'appareil';

  @override
  String get hospitalName => 'Mini-Hôpital 2026';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionNext => 'Suivant';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionRefresh => 'Actualiser';

  @override
  String get actionSearch => 'Rechercher';

  @override
  String get actionFilter => 'Filtrer';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionSelect => 'Sélectionner';

  @override
  String get actionView => 'Consulter';

  @override
  String get actionExport => 'Exporter';

  @override
  String get actionCopy => 'Copier';

  @override
  String get actionCopied => 'Copié dans le presse-papiers';

  @override
  String get actionSign => 'Signer';

  @override
  String get actionPrint => 'Imprimer';

  @override
  String get labelYes => 'Oui';

  @override
  String get labelNo => 'Non';

  @override
  String get labelAll => 'Tous';

  @override
  String get labelNone => 'Aucun';

  @override
  String get labelStatus => 'Statut';

  @override
  String get labelDate => 'Date';

  @override
  String get labelTime => 'Heure';

  @override
  String get labelDetails => 'Détails';

  @override
  String get labelActions => 'Actions';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelReason => 'Motif';

  @override
  String get labelQuantity => 'Quantité';

  @override
  String get labelUnknown => 'Inconnu';

  @override
  String get labelOptional => 'facultatif';

  @override
  String get labelRequired => 'obligatoire';

  @override
  String get labelLoading => 'Chargement…';

  @override
  String get labelNoResults => 'Aucun résultat';

  @override
  String get labelToday => 'Aujourd\'hui';

  @override
  String get labelYesterday => 'Hier';

  @override
  String get labelLanguage => 'Langue';

  @override
  String get labelTheme => 'Thème';

  @override
  String get labelSettings => 'Paramètres';

  @override
  String get labelAbout => 'À propos';

  @override
  String get labelVersion => 'Version';

  @override
  String get labelFrom => 'De';

  @override
  String get labelTo => 'Vers';

  @override
  String get labelBy => 'par';

  @override
  String get labelUnsavedChanges =>
      'Vous avez des modifications non enregistrées.';

  @override
  String get labelDiscardChanges => 'Abandonner les modifications';

  @override
  String get errorGeneric => 'Une erreur s\'est produite.';

  @override
  String get errorNetwork =>
      'Impossible de joindre le serveur. Vérifiez que le backend est démarré.';

  @override
  String get errorNotFound => 'Introuvable.';

  @override
  String get errorNotAllowed => 'Votre rôle ne permet pas cette action.';

  @override
  String get errorFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get errorInvalidNumber => 'Saisissez un nombre valide.';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignOut => 'Se déconnecter';

  @override
  String get authEmail => 'Adresse e-mail';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String authSignedInAs(String name) {
    return 'Connecté en tant que $name';
  }

  @override
  String get authDemoModeTitle => 'Mode démonstration';

  @override
  String get authDemoModeBody =>
      'Aucune authentification réelle. Choisissez un compte ci-dessous ; le mot de passe n\'est pas vérifié.';

  @override
  String get authQuickSignIn => 'Connexion rapide';

  @override
  String get authErrorInvalidCredentials =>
      'L\'adresse e-mail ou le mot de passe est incorrect.';

  @override
  String get authErrorUserNotFound => 'Aucun compte avec cette adresse e-mail.';

  @override
  String get authErrorNetwork =>
      'Impossible de joindre le service d\'authentification.';

  @override
  String get authErrorNotConfigured =>
      'L\'authentification Firebase n\'est pas configurée pour cette version.';

  @override
  String get authRole => 'Rôle';

  @override
  String get patients => 'Patients';

  @override
  String get patient => 'Patient';

  @override
  String get patientFile => 'Fiche patient';

  @override
  String get patientSearchHint => 'Rechercher par nom, NDM ou numéro national';

  @override
  String get patientMrn => 'Numéro de dossier médical';

  @override
  String get patientMrnShort => 'NDM';

  @override
  String get patientNationalNumber => 'Numéro de registre national';

  @override
  String get patientDateOfBirth => 'Date de naissance';

  @override
  String get patientAge => 'Âge';

  @override
  String patientAgeYears(int years) {
    return '$years ans';
  }

  @override
  String get patientGender => 'Sexe';

  @override
  String get patientAddress => 'Adresse';

  @override
  String get patientPhone => 'Téléphone';

  @override
  String get patientEmail => 'E-mail';

  @override
  String get patientPreferredLanguage => 'Langue préférée';

  @override
  String get patientBloodGroup => 'Groupe sanguin';

  @override
  String get patientGeneralPractitioner => 'Médecin généraliste';

  @override
  String get patientDeceased => 'Décédé(e)';

  @override
  String get patientAllergies => 'Allergies';

  @override
  String get patientNoAllergies => 'Aucune allergie connue';

  @override
  String patientAllergyBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allergies au dossier',
      one: '1 allergie au dossier',
    );
    return '$_temp0';
  }

  @override
  String get patientHighRiskAllergy => 'Allergie à haut risque';

  @override
  String get patientDemographics => 'Données démographiques';

  @override
  String patientCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count patients',
      one: '1 patient',
      zero: 'Aucun patient',
    );
    return '$_temp0';
  }

  @override
  String get patientNotFound => 'Patient introuvable.';

  @override
  String get patientSelectPrompt =>
      'Sélectionnez un patient pour afficher sa fiche.';

  @override
  String get encounter => 'Séjour';

  @override
  String get encounters => 'Séjours';

  @override
  String get encounterActive => 'Séjour en cours';

  @override
  String get encounterNone => 'Pas actuellement hospitalisé';

  @override
  String get encounterVisitNumber => 'Numéro de séjour';

  @override
  String get encounterAdmittedOn => 'Admis le';

  @override
  String get encounterDischargedOn => 'Sorti le';

  @override
  String get encounterLengthOfStay => 'Durée du séjour';

  @override
  String encounterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
      zero: 'moins d’un jour',
    );
    return '$_temp0';
  }

  @override
  String get encounterAttending => 'Médecin responsable';

  @override
  String get encounterReason => 'Motif d\'admission';

  @override
  String get locationWard => 'Unité de soins';

  @override
  String get locationWards => 'Unités de soins';

  @override
  String get locationRoom => 'Chambre';

  @override
  String get locationBed => 'Lit';

  @override
  String get locationBeds => 'Lits';

  @override
  String get locationFloor => 'Étage';

  @override
  String get locationIsolation => 'Chambre d\'isolement';

  @override
  String get locationNotPlaced => 'Aucun lit attribué';

  @override
  String get vitals => 'Signes vitaux';

  @override
  String get vitalsLatest => 'Dernières mesures';

  @override
  String get vitalsNone => 'Aucune mesure enregistrée.';

  @override
  String get vitalsTrend => 'Évolution';

  @override
  String get vitalsAbnormal => 'Hors des valeurs normales';

  @override
  String vitalsNormalRange(String low, String high, String unit) {
    return 'Valeurs normales : $low – $high $unit';
  }

  @override
  String vitalsMeasuredAt(String time) {
    return 'Mesuré à $time';
  }

  @override
  String get vitalsSource => 'Source';

  @override
  String get vitalsLast24h => 'Dernières 24 heures';

  @override
  String get vitalsLast72h => 'Dernières 72 heures';

  @override
  String get vitalsAllTime => 'Tout le séjour';

  @override
  String vitalsObservationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesures',
      one: '1 mesure',
    );
    return '$_temp0';
  }

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get prescription => 'Prescription';

  @override
  String get prescriptionNew => 'Nouvelle prescription';

  @override
  String get prescriptionActive => 'Prescriptions actives';

  @override
  String get prescriptionNone => 'Aucune prescription.';

  @override
  String get prescriptionMedication => 'Médicament';

  @override
  String get prescriptionDose => 'Dose';

  @override
  String get prescriptionFrequency => 'Fréquence';

  @override
  String get prescriptionRoute => 'Voie';

  @override
  String get prescriptionPrescriber => 'Prescripteur';

  @override
  String get prescriptionStartDate => 'Date de début';

  @override
  String get prescriptionEndDate => 'Date de fin';

  @override
  String get prescriptionIndication => 'Indication';

  @override
  String get prescriptionInstructions => 'Instructions';

  @override
  String get prescriptionAsNeeded => 'Si besoin';

  @override
  String prescriptionTimesPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fois par jour',
      one: 'une fois par jour',
    );
    return '$_temp0';
  }

  @override
  String get prescriptionStop => 'Arrêter la prescription';

  @override
  String get prescriptionHold => 'Suspendre';

  @override
  String get prescriptionResume => 'Reprendre';

  @override
  String prescriptionAllergyWarning(String substance) {
    return 'Ce patient présente une allergie documentée à $substance.';
  }

  @override
  String get prescriptionAllergyProceed => 'Prescrire malgré tout';

  @override
  String get formulary => 'Formulaire thérapeutique';

  @override
  String get formularySearchHint => 'Rechercher dans le formulaire';

  @override
  String get medicationControlled => 'Stupéfiant';

  @override
  String get notesTitle => 'Notes et observations';

  @override
  String get noteNew => 'Nouvelle note';

  @override
  String get noteType => 'Type de note';

  @override
  String get noteTitleField => 'Titre';

  @override
  String get noteBody => 'Contenu';

  @override
  String get noteAuthor => 'Auteur';

  @override
  String noteWrittenIn(String language) {
    return 'Rédigé en $language';
  }

  @override
  String get noteSigned => 'Signée';

  @override
  String get noteUnsigned => 'Brouillon';

  @override
  String get noteSignConfirm =>
      'Une fois signée, une note ne peut plus être modifiée. Signer ?';

  @override
  String get noteNone => 'Aucune note.';

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
  String get adtDashboard => 'Tableau des lits';

  @override
  String get adtAdmission => 'Admission';

  @override
  String get adtTransfer => 'Transfert';

  @override
  String get adtDischarge => 'Sortie';

  @override
  String get adtAdmitPatient => 'Admettre un patient';

  @override
  String get adtTransferPatient => 'Transférer le patient';

  @override
  String get adtDischargePatient => 'Faire sortir le patient';

  @override
  String get adtSelectPatient => 'Sélectionner le patient';

  @override
  String get adtSelectWard => 'Sélectionner une unité';

  @override
  String get adtSelectBed => 'Sélectionner un lit';

  @override
  String get adtEncounterClass => 'Type de séjour';

  @override
  String get adtDischargeDisposition => 'Destination de sortie';

  @override
  String get adtMovements => 'Mouvements';

  @override
  String get adtMovementHistory => 'Historique des mouvements';

  @override
  String get adtNoMovements => 'Aucun mouvement enregistré.';

  @override
  String get adtOccupancy => 'Taux d’occupation';

  @override
  String adtBedsFree(int count) {
    return '$count libres';
  }

  @override
  String adtBedsOccupied(int count) {
    return '$count occupés';
  }

  @override
  String get adtNoFreeBed => 'Aucun lit libre dans cette unité.';

  @override
  String adtAdmissionSuccess(String name, String bed) {
    return '$name admis au lit $bed.';
  }

  @override
  String adtTransferSuccess(String name, String bed) {
    return '$name transféré au lit $bed.';
  }

  @override
  String adtDischargeSuccess(String name) {
    return '$name est sorti.';
  }

  @override
  String adtDischargeConfirm(String name, String bed) {
    return 'Faire sortir $name du lit $bed ? Le lit passera en nettoyage.';
  }

  @override
  String get adtWaitingForBed => 'En attente d\'un lit';

  @override
  String get adtAlreadyAdmitted => 'Ce patient est déjà hospitalisé.';

  @override
  String get pharmCabinet => 'Armoire';

  @override
  String get pharmCabinets => 'Armoires';

  @override
  String get pharmStock => 'Stock';

  @override
  String get pharmQueue => 'File de délivrance';

  @override
  String get pharmDispense => 'Délivrer';

  @override
  String get pharmDispensed => 'Délivré';

  @override
  String get pharmRefuse => 'Refuser';

  @override
  String get pharmRefusalReason => 'Motif du refus';

  @override
  String get pharmOpenDrawer => 'Ouvrir le tiroir';

  @override
  String get pharmCloseDrawer => 'Fermer le tiroir';

  @override
  String pharmDrawerOpen(String slot) {
    return 'Le tiroir $slot est ouvert';
  }

  @override
  String get pharmUnlock => 'Déverrouiller l\'armoire';

  @override
  String get pharmLock => 'Verrouiller l\'armoire';

  @override
  String get pharmLocked => 'Verrouillée';

  @override
  String get pharmUnlocked => 'Déverrouillée';

  @override
  String get pharmSlot => 'Emplacement';

  @override
  String get pharmOnHand => 'En stock';

  @override
  String get pharmParLevel => 'Seuil de réapprovisionnement';

  @override
  String get pharmExpiry => 'Péremption';

  @override
  String get pharmLot => 'Lot';

  @override
  String get pharmLowStock => 'Stock bas';

  @override
  String get pharmOutOfStock => 'Rupture de stock';

  @override
  String get pharmExpiredLot => 'Lot périmé';

  @override
  String get pharmNearExpiry => 'Périme bientôt';

  @override
  String get pharmRestock => 'Réapprovisionner';

  @override
  String get pharmRestockAmount => 'Quantité à ajouter';

  @override
  String get pharmWitnessRequired =>
      'Une seconde signature est requise pour les stupéfiants.';

  @override
  String get pharmWitnessName => 'Témoin';

  @override
  String get pharmBlockedOutOfStock =>
      'Délivrance impossible : emplacement vide.';

  @override
  String get pharmBlockedExpired =>
      'Délivrance impossible : le lot est périmé.';

  @override
  String get pharmBlockedLocked =>
      'Délivrance impossible : l\'armoire est verrouillée.';

  @override
  String get pharmBlockedNotActive =>
      'Délivrance impossible : la prescription n\'est pas active.';

  @override
  String get pharmBlockedAllergy =>
      'Délivrance impossible : le patient est allergique à ce produit.';

  @override
  String pharmDispenseSuccess(String medication, String patient) {
    return '$medication délivré pour $patient.';
  }

  @override
  String get pharmQueueEmpty => 'Rien en attente de délivrance.';

  @override
  String pharmPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doses en attente',
      one: '1 dose en attente',
      zero: 'Rien en attente',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlows => 'Flux d\'intégration';

  @override
  String get eaiFlow => 'Flux';

  @override
  String get eaiNewFlow => 'Nouveau flux';

  @override
  String get eaiFlowName => 'Nom du flux';

  @override
  String get eaiFlowDescription => 'Description';

  @override
  String get eaiEnabled => 'Activé';

  @override
  String get eaiDisabled => 'Désactivé';

  @override
  String get eaiPalette => 'Blocs de construction';

  @override
  String get eaiCanvas => 'Canevas';

  @override
  String get eaiProperties => 'Propriétés';

  @override
  String get eaiNodeLabel => 'Étiquette';

  @override
  String get eaiConnect => 'Connecter';

  @override
  String get eaiDisconnect => 'Supprimer la connexion';

  @override
  String get eaiDeleteNode => 'Supprimer le bloc';

  @override
  String get eaiDragHint =>
      'Faites glisser un bloc sur le canevas pour commencer.';

  @override
  String get eaiConnectHint =>
      'Cliquez sur la sortie d\'un bloc, puis sur l\'entrée d\'un autre.';

  @override
  String get eaiTestFlow => 'Tester le flux';

  @override
  String get eaiTestPayload => 'Message de test';

  @override
  String get eaiRunTest => 'Exécuter';

  @override
  String get eaiTrace => 'Trace';

  @override
  String get eaiTraceEmpty =>
      'Exécutez le flux pour voir ce qui se passe à chaque étape.';

  @override
  String get eaiPayloadBefore => 'Entrée';

  @override
  String get eaiPayloadAfter => 'Sortie';

  @override
  String get eaiMessages => 'Journal des messages';

  @override
  String get eaiMessageType => 'Type de message';

  @override
  String get eaiSourceApp => 'Source';

  @override
  String get eaiTargetApp => 'Destination';

  @override
  String get eaiLatency => 'Latence';

  @override
  String get eaiReplay => 'Rejouer';

  @override
  String get eaiNoMessages => 'Aucun message.';

  @override
  String eaiValidationIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes à corriger',
      one: '1 problème à corriger',
    );
    return '$_temp0';
  }

  @override
  String get eaiFlowValid => 'Le flux est prêt à être exécuté.';

  @override
  String get eaiFhirResources => 'Ressources FHIR';

  @override
  String get eaiResourceType => 'Type de ressource';

  @override
  String eaiResourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ressources',
      one: '1 ressource',
      zero: 'Aucune ressource',
    );
    return '$_temp0';
  }

  @override
  String get eaiServerStatus => 'Serveur FHIR';

  @override
  String get eaiServerOnline => 'En ligne';

  @override
  String get eaiServerOffline => 'Hors ligne';

  @override
  String get eaiFieldMappings => 'Correspondances de champs';

  @override
  String get eaiAddMapping => 'Ajouter une correspondance';

  @override
  String get eaiSourceField => 'Champ source';

  @override
  String get eaiTargetField => 'Champ cible';

  @override
  String get eaiTransform => 'Transformation';

  @override
  String get eaiTransformArgument => 'Valeur';

  @override
  String get eaiCondition => 'Condition';

  @override
  String get eaiFieldPath => 'Champ';

  @override
  String get eaiOperator => 'Opérateur';

  @override
  String get eaiRoutes => 'Routes';

  @override
  String get eaiKeepUnmapped => 'Conserver les champs non mappés';

  @override
  String get deviceSimulator => 'Simulateur d\'appareil';

  @override
  String get devices => 'Appareils';

  @override
  String get device => 'Appareil';

  @override
  String get deviceFleet => 'Parc d\'appareils';

  @override
  String get deviceId => 'Identifiant de l\'appareil';

  @override
  String get deviceKind => 'Type d\'appareil';

  @override
  String get deviceManufacturer => 'Fabricant';

  @override
  String get deviceModel => 'Modèle';

  @override
  String get deviceSerial => 'Numéro de série';

  @override
  String get deviceBattery => 'Batterie';

  @override
  String get deviceLastSeen => 'Vu pour la dernière fois';

  @override
  String get deviceNeverSeen => 'N\'a jamais émis';

  @override
  String get deviceAssignedTo => 'Attribué à';

  @override
  String get deviceNotAssigned => 'Non attribué à un patient';

  @override
  String get deviceStart => 'Démarrer la publication';

  @override
  String get deviceStop => 'Arrêter la publication';

  @override
  String get deviceRunning => 'Publication en cours';

  @override
  String get deviceStopped => 'Arrêté';

  @override
  String get deviceInterval => 'Intervalle entre les mesures';

  @override
  String deviceIntervalSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get deviceScenario => 'Scénario';

  @override
  String get deviceScenarioStable => 'Stable';

  @override
  String get deviceScenarioDeteriorating => 'Dégradation';

  @override
  String get deviceScenarioRecovering => 'Amélioration';

  @override
  String get deviceScenarioArtefact => 'Signal bruité';

  @override
  String get deviceManualReading => 'Envoyer une mesure manuellement';

  @override
  String get deviceSend => 'Envoyer';

  @override
  String get deviceSent => 'Mesure envoyée.';

  @override
  String deviceSendFailed(String error) {
    return 'Impossible d\'envoyer la mesure : $error';
  }

  @override
  String get deviceLiveFeed => 'Flux en direct';

  @override
  String devicePublishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mesures envoyées',
      one: '1 mesure envoyée',
      zero: 'Rien envoyé',
    );
    return '$_temp0';
  }

  @override
  String get deviceAppleWatch => 'Apple Watch';

  @override
  String get deviceHealthKitTitle => 'Apple Watch / HealthKit';

  @override
  String get deviceHealthKitBody =>
      'Les mesures collectées par une Apple Watch peuvent être importées ici et sont publiées exactement comme celles d\'un simulateur.';

  @override
  String get deviceHealthKitImport => 'Importer depuis HealthKit';

  @override
  String get deviceHealthKitUnavailable =>
      'HealthKit n\'est disponible que sur iOS. Sur les autres plateformes, vous pouvez coller un export.';

  @override
  String get deviceTargetPatient => 'Envoyer les mesures pour';

  @override
  String get deviceEndpoint => 'Publication vers';

  @override
  String get navOverview => 'Vue d\'ensemble';

  @override
  String get navPatients => 'Patients';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navAdmissions => 'Admissions';

  @override
  String get navPharmacy => 'Pharmacie';

  @override
  String get navIntegration => 'Intégration';

  @override
  String get navDevices => 'Appareils';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get dashboardAdmittedPatients => 'Patients hospitalisés';

  @override
  String get dashboardFreeBeds => 'Lits libres';

  @override
  String get dashboardPendingDoses => 'Doses à délivrer';

  @override
  String get dashboardActiveDevices => 'Appareils actifs';

  @override
  String get dashboardAbnormalVitals => 'Mesures anormales';

  @override
  String get dashboardRecentActivity => 'Activité récente';

  @override
  String get backendModeMemory => 'Données de démonstration en mémoire';

  @override
  String get backendModeRest => 'Connecté à l\'API locale';

  @override
  String get backendModeDataConnect => 'Connecté à Firebase Data Connect';

  @override
  String backendBanner(String mode) {
    return '$mode — les données ne sont pas partagées avec les autres applications tant que vous n’utilisez pas un vrai backend.';
  }

  @override
  String get safetyChecks => 'Contrôles de sécurité';

  @override
  String get safetyNoIssues => 'Aucun problème de sécurité détecté.';

  @override
  String get safetyBlocked =>
      'Cette action est bloquée et ne peut pas aboutir.';

  @override
  String get safetyAcknowledge =>
      'J\'ai lu les avertissements et j\'en accepte la responsabilité.';

  @override
  String get safetyOverrideReason => 'Motif du passage outre';

  @override
  String get safetySeverityBlocking => 'Bloquant';

  @override
  String get safetySeverityWarning => 'Avertissement';

  @override
  String get safetySeverityAdvisory => 'Pour information';

  @override
  String get prescriptionSaved => 'Prescription enregistrée.';

  @override
  String get noteSaved => 'Note enregistrée.';

  @override
  String get prescriptionSelectMedication => 'Choisir un médicament';

  @override
  String pharmRestocked(String slot) {
    return 'Emplacement $slot réapprovisionné.';
  }

  @override
  String get pharmDrawerClosedAutomatically =>
      'Le tiroir s\'est refermé automatiquement.';

  @override
  String get pharmAlerts => 'Alertes armoire';

  @override
  String get pharmNoAlerts =>
      'Aucune alerte. Les niveaux de stock et les dates de péremption sont corrects.';

  @override
  String pharmForPatient(String patient) {
    return 'Pour $patient';
  }

  @override
  String pharmDue(String time) {
    return 'Prévu $time';
  }

  @override
  String get pharmOverdue => 'En retard';

  @override
  String get pharmHistory => 'Historique des délivrances';

  @override
  String get adtNewAdmission => 'Nouvelle admission';

  @override
  String get adtStepReviewPatient => 'Patient';

  @override
  String get adtStepPlacement => 'Placement';

  @override
  String get adtStepConfirm => 'Confirmer';

  @override
  String get adtChooseAnotherWard => 'Choisir une autre unité';

  @override
  String get adtCleaningNote =>
      'Les lits en nettoyage ne peuvent pas être attribués.';

  @override
  String get adtEmitEvent => 'Événement envoyé au moteur d\'intégration.';

  @override
  String get adtEmitFailed =>
      'Le moteur d\'intégration est injoignable ; le mouvement a tout de même été enregistré.';

  @override
  String get adtWardOverview => 'Vue d\'ensemble des unités';

  @override
  String get adtCurrentPatients => 'Patients dans l’unité';

  @override
  String get adtSetBedStatus => 'Modifier le statut du lit';

  @override
  String get eaiOpenEditor => 'Ouvrir l\'éditeur';

  @override
  String get eaiSaveFlow => 'Enregistrer le flux';

  @override
  String get eaiFlowSaved => 'Flux enregistré.';

  @override
  String get eaiDeleteFlowConfirm =>
      'Supprimer ce flux ? Cette action est irréversible.';

  @override
  String get eaiSelectNode =>
      'Sélectionnez un bloc pour modifier ses propriétés.';

  @override
  String get eaiSamplePayload => 'Exemples de messages';

  @override
  String get eaiInvalidJson => 'Ce n\'est pas du JSON valide.';

  @override
  String get eaiStepPassed => 'Réussi';

  @override
  String get eaiStepDropped => 'Écarté ici';

  @override
  String get eaiStepFailed => 'Échec ici';

  @override
  String get eaiTotalResources => 'Ressources sur le serveur FHIR';

  @override
  String get eaiSeedFhir => 'Charger les patients fictifs dans FHIR';

  @override
  String eaiSeedDone(int count) {
    return '$count ressources écrites sur le serveur FHIR.';
  }

  @override
  String get deviceAutoAssign => 'Attribuer automatiquement selon le lit';

  @override
  String get deviceWaveform => 'Signal';

  @override
  String get deviceOutbox => 'Envoyés récemment';

  @override
  String get deviceConfiguration => 'Configuration';

  @override
  String get deviceMeasurements => 'Mesures produites';

  @override
  String deviceOfflineQueue(int count) {
    return '$count mesures en attente d’envoi';
  }
}
