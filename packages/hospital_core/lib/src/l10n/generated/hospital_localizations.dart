import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'hospital_localizations_en.dart';
import 'hospital_localizations_fr.dart';
import 'hospital_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of HospitalLocalizations
/// returned by `HospitalLocalizations.of(context)`.
///
/// Applications need to include `HospitalLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/hospital_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: HospitalLocalizations.localizationsDelegates,
///   supportedLocales: HospitalLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the HospitalLocalizations.supportedLocales
/// property.
abstract class HospitalLocalizations {
  HospitalLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static HospitalLocalizations of(BuildContext context) {
    return Localizations.of<HospitalLocalizations>(
      context,
      HospitalLocalizations,
    )!;
  }

  static const LocalizationsDelegate<HospitalLocalizations> delegate =
      _HospitalLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('nl'),
  ];

  /// Application titles: Electronic Health Record
  ///
  /// In en, this message translates to:
  /// **'Electronic Health Record'**
  String get appTitleEhr;

  /// Application titles: Admission, Transfer & Discharge
  ///
  /// In en, this message translates to:
  /// **'Admission, Transfer & Discharge'**
  String get appTitleAdt;

  /// Application titles: Pharmacy Cabinet
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Cabinet'**
  String get appTitlePharm;

  /// Application titles: Interoperability Server
  ///
  /// In en, this message translates to:
  /// **'Interoperability Server'**
  String get appTitleEai;

  /// Application titles: Device Simulator
  ///
  /// In en, this message translates to:
  /// **'Device Simulator'**
  String get appTitleDevice;

  /// Application titles: Mini-Hospital 2026
  ///
  /// In en, this message translates to:
  /// **'Mini-Hospital 2026'**
  String get hospitalName;

  /// Generic actions and labels: Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic actions and labels: Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic actions and labels: Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic actions and labels: Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Generic actions and labels: Add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Generic actions and labels: Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Generic actions and labels: Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Generic actions and labels: Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Generic actions and labels: Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Generic actions and labels: Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Generic actions and labels: Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// Generic actions and labels: Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// Generic actions and labels: Filter
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get actionFilter;

  /// Generic actions and labels: Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Generic actions and labels: Select
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// Generic actions and labels: View
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// Generic actions and labels: Export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// Generic actions and labels: Copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// Generic actions and labels: Copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get actionCopied;

  /// Generic actions and labels: Sign
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get actionSign;

  /// Generic actions and labels: Print
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get actionPrint;

  /// Generic actions and labels: Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get labelYes;

  /// Generic actions and labels: No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get labelNo;

  /// Generic actions and labels: All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// Generic actions and labels: None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get labelNone;

  /// Generic actions and labels: Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// Generic actions and labels: Date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// Generic actions and labels: Time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// Generic actions and labels: Details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get labelDetails;

  /// Generic actions and labels: Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get labelActions;

  /// Generic actions and labels: Notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// Generic actions and labels: Reason
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get labelReason;

  /// Generic actions and labels: Quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get labelQuantity;

  /// Generic actions and labels: Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labelUnknown;

  /// Generic actions and labels: optional
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get labelOptional;

  /// Generic actions and labels: required
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get labelRequired;

  /// Generic actions and labels: Loading…
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get labelLoading;

  /// Generic actions and labels: No results
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get labelNoResults;

  /// Generic actions and labels: Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get labelToday;

  /// Generic actions and labels: Yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get labelYesterday;

  /// Generic actions and labels: Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelLanguage;

  /// Generic actions and labels: Theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get labelTheme;

  /// Generic actions and labels: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get labelSettings;

  /// Generic actions and labels: About
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get labelAbout;

  /// Generic actions and labels: Version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get labelVersion;

  /// Generic actions and labels: From
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get labelFrom;

  /// Generic actions and labels: To
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get labelTo;

  /// Generic actions and labels: by
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get labelBy;

  /// Generic actions and labels: You have unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes.'**
  String get labelUnsavedChanges;

  /// Generic actions and labels: Discard changes
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get labelDiscardChanges;

  /// Errors: Something went wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// Errors: Cannot reach the server. Check that the backend is running.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check that the backend is running.'**
  String get errorNetwork;

  /// Errors: Not found.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// Errors: Your role does not allow this action.
  ///
  /// In en, this message translates to:
  /// **'Your role does not allow this action.'**
  String get errorNotAllowed;

  /// Errors: This field is required.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get errorFieldRequired;

  /// Errors: Enter a valid number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get errorInvalidNumber;

  /// Authentication: Sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Authentication: Sign out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// Authentication: E-mail address
  ///
  /// In en, this message translates to:
  /// **'E-mail address'**
  String get authEmail;

  /// Authentication: Password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// Authentication: Signed in as {name}
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String authSignedInAs(String name);

  /// Authentication: Demo mode
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get authDemoModeTitle;

  /// Authentication: No real authentication. Pick any account below; the password is not checked.
  ///
  /// In en, this message translates to:
  /// **'No real authentication. Pick any account below; the password is not checked.'**
  String get authDemoModeBody;

  /// Authentication: Quick sign-in
  ///
  /// In en, this message translates to:
  /// **'Quick sign-in'**
  String get authQuickSignIn;

  /// Authentication: E-mail address or password is incorrect.
  ///
  /// In en, this message translates to:
  /// **'E-mail address or password is incorrect.'**
  String get authErrorInvalidCredentials;

  /// Authentication: No account with that e-mail address.
  ///
  /// In en, this message translates to:
  /// **'No account with that e-mail address.'**
  String get authErrorUserNotFound;

  /// Authentication: Cannot reach the authentication service.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the authentication service.'**
  String get authErrorNetwork;

  /// Authentication: Firebase authentication is not configured for this build.
  ///
  /// In en, this message translates to:
  /// **'Firebase authentication is not configured for this build.'**
  String get authErrorNotConfigured;

  /// Authentication: Role
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get authRole;

  /// Patient: Patients
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// Patient: Patient
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// Patient: Patient file
  ///
  /// In en, this message translates to:
  /// **'Patient file'**
  String get patientFile;

  /// Patient: Search by name, MRN or national number
  ///
  /// In en, this message translates to:
  /// **'Search by name, MRN or national number'**
  String get patientSearchHint;

  /// Patient: Medical record number
  ///
  /// In en, this message translates to:
  /// **'Medical record number'**
  String get patientMrn;

  /// Patient: MRN
  ///
  /// In en, this message translates to:
  /// **'MRN'**
  String get patientMrnShort;

  /// Patient: National register number
  ///
  /// In en, this message translates to:
  /// **'National register number'**
  String get patientNationalNumber;

  /// Patient: Date of birth
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get patientDateOfBirth;

  /// Patient: Age
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get patientAge;

  /// Patient: {years} years
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String patientAgeYears(int years);

  /// Patient: Gender
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get patientGender;

  /// Patient: Address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get patientAddress;

  /// Patient: Phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get patientPhone;

  /// Patient: E-mail
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get patientEmail;

  /// Patient: Preferred language
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get patientPreferredLanguage;

  /// Patient: Blood group
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get patientBloodGroup;

  /// Patient: General practitioner
  ///
  /// In en, this message translates to:
  /// **'General practitioner'**
  String get patientGeneralPractitioner;

  /// Patient: Deceased
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get patientDeceased;

  /// Patient: Allergies
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get patientAllergies;

  /// Patient: No known allergies
  ///
  /// In en, this message translates to:
  /// **'No known allergies'**
  String get patientNoAllergies;

  /// Patient: {count, plural, =1{1 allergy on file} other{{count} allergies on file}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 allergy on file} other{{count} allergies on file}}'**
  String patientAllergyBanner(int count);

  /// Patient: High-risk allergy
  ///
  /// In en, this message translates to:
  /// **'High-risk allergy'**
  String get patientHighRiskAllergy;

  /// Patient: Demographics
  ///
  /// In en, this message translates to:
  /// **'Demographics'**
  String get patientDemographics;

  /// Patient: {count, plural, =0{No patients} =1{1 patient} other{{count} patients}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No patients} =1{1 patient} other{{count} patients}}'**
  String patientCount(int count);

  /// Patient: Patient not found.
  ///
  /// In en, this message translates to:
  /// **'Patient not found.'**
  String get patientNotFound;

  /// Patient: Select a patient to see their file.
  ///
  /// In en, this message translates to:
  /// **'Select a patient to see their file.'**
  String get patientSelectPrompt;

  /// Encounter and location: Encounter
  ///
  /// In en, this message translates to:
  /// **'Encounter'**
  String get encounter;

  /// Encounter and location: Encounters
  ///
  /// In en, this message translates to:
  /// **'Encounters'**
  String get encounters;

  /// Encounter and location: Current stay
  ///
  /// In en, this message translates to:
  /// **'Current stay'**
  String get encounterActive;

  /// Encounter and location: Not currently admitted
  ///
  /// In en, this message translates to:
  /// **'Not currently admitted'**
  String get encounterNone;

  /// Encounter and location: Visit number
  ///
  /// In en, this message translates to:
  /// **'Visit number'**
  String get encounterVisitNumber;

  /// Encounter and location: Admitted on
  ///
  /// In en, this message translates to:
  /// **'Admitted on'**
  String get encounterAdmittedOn;

  /// Encounter and location: Discharged on
  ///
  /// In en, this message translates to:
  /// **'Discharged on'**
  String get encounterDischargedOn;

  /// Encounter and location: Length of stay
  ///
  /// In en, this message translates to:
  /// **'Length of stay'**
  String get encounterLengthOfStay;

  /// Encounter and location: {days, plural, =0{less than a day} =1{1 day} other{{days} days}}
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{less than a day} =1{1 day} other{{days} days}}'**
  String encounterDays(int days);

  /// Encounter and location: Attending physician
  ///
  /// In en, this message translates to:
  /// **'Attending physician'**
  String get encounterAttending;

  /// Encounter and location: Reason for admission
  ///
  /// In en, this message translates to:
  /// **'Reason for admission'**
  String get encounterReason;

  /// Encounter and location: Ward
  ///
  /// In en, this message translates to:
  /// **'Ward'**
  String get locationWard;

  /// Encounter and location: Wards
  ///
  /// In en, this message translates to:
  /// **'Wards'**
  String get locationWards;

  /// Encounter and location: Room
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get locationRoom;

  /// Encounter and location: Bed
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get locationBed;

  /// Encounter and location: Beds
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get locationBeds;

  /// Encounter and location: Floor
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get locationFloor;

  /// Encounter and location: Isolation room
  ///
  /// In en, this message translates to:
  /// **'Isolation room'**
  String get locationIsolation;

  /// Encounter and location: No bed assigned
  ///
  /// In en, this message translates to:
  /// **'No bed assigned'**
  String get locationNotPlaced;

  /// Vital signs: Vital signs
  ///
  /// In en, this message translates to:
  /// **'Vital signs'**
  String get vitals;

  /// Vital signs: Latest measurements
  ///
  /// In en, this message translates to:
  /// **'Latest measurements'**
  String get vitalsLatest;

  /// Vital signs: No measurements recorded yet.
  ///
  /// In en, this message translates to:
  /// **'No measurements recorded yet.'**
  String get vitalsNone;

  /// Vital signs: Trend
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get vitalsTrend;

  /// Vital signs: Outside the normal range
  ///
  /// In en, this message translates to:
  /// **'Outside the normal range'**
  String get vitalsAbnormal;

  /// Vital signs: Normal range: {low} – {high} {unit}
  ///
  /// In en, this message translates to:
  /// **'Normal range: {low} – {high} {unit}'**
  String vitalsNormalRange(String low, String high, String unit);

  /// Vital signs: Measured at {time}
  ///
  /// In en, this message translates to:
  /// **'Measured at {time}'**
  String vitalsMeasuredAt(String time);

  /// Vital signs: Source
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get vitalsSource;

  /// Vital signs: Last 24 hours
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get vitalsLast24h;

  /// Vital signs: Last 72 hours
  ///
  /// In en, this message translates to:
  /// **'Last 72 hours'**
  String get vitalsLast72h;

  /// Vital signs: Whole stay
  ///
  /// In en, this message translates to:
  /// **'Whole stay'**
  String get vitalsAllTime;

  /// Vital signs: {count, plural, =1{1 measurement} other{{count} measurements}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 measurement} other{{count} measurements}}'**
  String vitalsObservationCount(int count);

  /// Prescriptions: Prescriptions
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get prescriptions;

  /// Prescriptions: Prescription
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// Prescriptions: New prescription
  ///
  /// In en, this message translates to:
  /// **'New prescription'**
  String get prescriptionNew;

  /// Prescriptions: Active prescriptions
  ///
  /// In en, this message translates to:
  /// **'Active prescriptions'**
  String get prescriptionActive;

  /// Prescriptions: No prescriptions.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions.'**
  String get prescriptionNone;

  /// Prescriptions: Medication
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get prescriptionMedication;

  /// Prescriptions: Dose
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get prescriptionDose;

  /// Prescriptions: Frequency
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get prescriptionFrequency;

  /// Prescriptions: Route
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get prescriptionRoute;

  /// Prescriptions: Prescriber
  ///
  /// In en, this message translates to:
  /// **'Prescriber'**
  String get prescriptionPrescriber;

  /// Prescriptions: Start date
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get prescriptionStartDate;

  /// Prescriptions: End date
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get prescriptionEndDate;

  /// Prescriptions: Indication
  ///
  /// In en, this message translates to:
  /// **'Indication'**
  String get prescriptionIndication;

  /// Prescriptions: Instructions
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get prescriptionInstructions;

  /// Prescriptions: As needed
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get prescriptionAsNeeded;

  /// Prescriptions: {count, plural, =1{once a day} other{{count} times a day}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once a day} other{{count} times a day}}'**
  String prescriptionTimesPerDay(int count);

  /// Prescriptions: Stop prescription
  ///
  /// In en, this message translates to:
  /// **'Stop prescription'**
  String get prescriptionStop;

  /// Prescriptions: Put on hold
  ///
  /// In en, this message translates to:
  /// **'Put on hold'**
  String get prescriptionHold;

  /// Prescriptions: Resume
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get prescriptionResume;

  /// Prescriptions: This patient has a recorded allergy to {substance}.
  ///
  /// In en, this message translates to:
  /// **'This patient has a recorded allergy to {substance}.'**
  String prescriptionAllergyWarning(String substance);

  /// Prescriptions: Prescribe anyway
  ///
  /// In en, this message translates to:
  /// **'Prescribe anyway'**
  String get prescriptionAllergyProceed;

  /// Prescriptions: Formulary
  ///
  /// In en, this message translates to:
  /// **'Formulary'**
  String get formulary;

  /// Prescriptions: Search the formulary
  ///
  /// In en, this message translates to:
  /// **'Search the formulary'**
  String get formularySearchHint;

  /// Prescriptions: Controlled substance
  ///
  /// In en, this message translates to:
  /// **'Controlled substance'**
  String get medicationControlled;

  /// Clinical notes: Notes and observations
  ///
  /// In en, this message translates to:
  /// **'Notes and observations'**
  String get notesTitle;

  /// Clinical notes: New note
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get noteNew;

  /// Clinical notes: Note type
  ///
  /// In en, this message translates to:
  /// **'Note type'**
  String get noteType;

  /// Clinical notes: Title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleField;

  /// Clinical notes: Content
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get noteBody;

  /// Clinical notes: Author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get noteAuthor;

  /// Clinical notes: Written in {language}
  ///
  /// In en, this message translates to:
  /// **'Written in {language}'**
  String noteWrittenIn(String language);

  /// Clinical notes: Signed
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get noteSigned;

  /// Clinical notes: Draft
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get noteUnsigned;

  /// Clinical notes: Once signed, a note can no longer be edited. Sign it?
  ///
  /// In en, this message translates to:
  /// **'Once signed, a note can no longer be edited. Sign it?'**
  String get noteSignConfirm;

  /// Clinical notes: No notes yet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noteNone;

  /// Clinical notes: {count, plural, =1{1 note} other{{count} notes}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String noteCount(int count);

  /// ADT: Bed board
  ///
  /// In en, this message translates to:
  /// **'Bed board'**
  String get adtDashboard;

  /// ADT: Admission
  ///
  /// In en, this message translates to:
  /// **'Admission'**
  String get adtAdmission;

  /// ADT: Transfer
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get adtTransfer;

  /// ADT: Discharge
  ///
  /// In en, this message translates to:
  /// **'Discharge'**
  String get adtDischarge;

  /// ADT: Admit a patient
  ///
  /// In en, this message translates to:
  /// **'Admit a patient'**
  String get adtAdmitPatient;

  /// ADT: Transfer patient
  ///
  /// In en, this message translates to:
  /// **'Transfer patient'**
  String get adtTransferPatient;

  /// ADT: Discharge patient
  ///
  /// In en, this message translates to:
  /// **'Discharge patient'**
  String get adtDischargePatient;

  /// ADT: Select the patient
  ///
  /// In en, this message translates to:
  /// **'Select the patient'**
  String get adtSelectPatient;

  /// ADT: Select a ward
  ///
  /// In en, this message translates to:
  /// **'Select a ward'**
  String get adtSelectWard;

  /// ADT: Select a bed
  ///
  /// In en, this message translates to:
  /// **'Select a bed'**
  String get adtSelectBed;

  /// ADT: Type of stay
  ///
  /// In en, this message translates to:
  /// **'Type of stay'**
  String get adtEncounterClass;

  /// ADT: Discharge destination
  ///
  /// In en, this message translates to:
  /// **'Discharge destination'**
  String get adtDischargeDisposition;

  /// ADT: Movements
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get adtMovements;

  /// ADT: Movement history
  ///
  /// In en, this message translates to:
  /// **'Movement history'**
  String get adtMovementHistory;

  /// ADT: No movements recorded.
  ///
  /// In en, this message translates to:
  /// **'No movements recorded.'**
  String get adtNoMovements;

  /// ADT: Occupancy
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get adtOccupancy;

  /// ADT: {count} free
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String adtBedsFree(int count);

  /// ADT: {count} occupied
  ///
  /// In en, this message translates to:
  /// **'{count} occupied'**
  String adtBedsOccupied(int count);

  /// ADT: No free bed in this ward.
  ///
  /// In en, this message translates to:
  /// **'No free bed in this ward.'**
  String get adtNoFreeBed;

  /// ADT: {name} admitted to bed {bed}.
  ///
  /// In en, this message translates to:
  /// **'{name} admitted to bed {bed}.'**
  String adtAdmissionSuccess(String name, String bed);

  /// ADT: {name} transferred to bed {bed}.
  ///
  /// In en, this message translates to:
  /// **'{name} transferred to bed {bed}.'**
  String adtTransferSuccess(String name, String bed);

  /// ADT: {name} discharged.
  ///
  /// In en, this message translates to:
  /// **'{name} discharged.'**
  String adtDischargeSuccess(String name);

  /// ADT: Discharge {name} from bed {bed}? The bed will be released for cleaning.
  ///
  /// In en, this message translates to:
  /// **'Discharge {name} from bed {bed}? The bed will be released for cleaning.'**
  String adtDischargeConfirm(String name, String bed);

  /// ADT: Waiting for a bed
  ///
  /// In en, this message translates to:
  /// **'Waiting for a bed'**
  String get adtWaitingForBed;

  /// ADT: This patient is already admitted.
  ///
  /// In en, this message translates to:
  /// **'This patient is already admitted.'**
  String get adtAlreadyAdmitted;

  /// Pharmacy: Cabinet
  ///
  /// In en, this message translates to:
  /// **'Cabinet'**
  String get pharmCabinet;

  /// Pharmacy: Cabinets
  ///
  /// In en, this message translates to:
  /// **'Cabinets'**
  String get pharmCabinets;

  /// Pharmacy: Stock
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get pharmStock;

  /// Pharmacy: Dispensing queue
  ///
  /// In en, this message translates to:
  /// **'Dispensing queue'**
  String get pharmQueue;

  /// Pharmacy: Dispense
  ///
  /// In en, this message translates to:
  /// **'Dispense'**
  String get pharmDispense;

  /// Pharmacy: Dispensed
  ///
  /// In en, this message translates to:
  /// **'Dispensed'**
  String get pharmDispensed;

  /// Pharmacy: Refuse
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get pharmRefuse;

  /// Pharmacy: Reason for refusal
  ///
  /// In en, this message translates to:
  /// **'Reason for refusal'**
  String get pharmRefusalReason;

  /// Pharmacy: Open drawer
  ///
  /// In en, this message translates to:
  /// **'Open drawer'**
  String get pharmOpenDrawer;

  /// Pharmacy: Close drawer
  ///
  /// In en, this message translates to:
  /// **'Close drawer'**
  String get pharmCloseDrawer;

  /// Pharmacy: Drawer {slot} is open
  ///
  /// In en, this message translates to:
  /// **'Drawer {slot} is open'**
  String pharmDrawerOpen(String slot);

  /// Pharmacy: Unlock cabinet
  ///
  /// In en, this message translates to:
  /// **'Unlock cabinet'**
  String get pharmUnlock;

  /// Pharmacy: Lock cabinet
  ///
  /// In en, this message translates to:
  /// **'Lock cabinet'**
  String get pharmLock;

  /// Pharmacy: Locked
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get pharmLocked;

  /// Pharmacy: Unlocked
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get pharmUnlocked;

  /// Pharmacy: Slot
  ///
  /// In en, this message translates to:
  /// **'Slot'**
  String get pharmSlot;

  /// Pharmacy: On hand
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get pharmOnHand;

  /// Pharmacy: Par level
  ///
  /// In en, this message translates to:
  /// **'Par level'**
  String get pharmParLevel;

  /// Pharmacy: Expiry
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get pharmExpiry;

  /// Pharmacy: Lot
  ///
  /// In en, this message translates to:
  /// **'Lot'**
  String get pharmLot;

  /// Pharmacy: Low stock
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get pharmLowStock;

  /// Pharmacy: Out of stock
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get pharmOutOfStock;

  /// Pharmacy: Expired lot
  ///
  /// In en, this message translates to:
  /// **'Expired lot'**
  String get pharmExpiredLot;

  /// Pharmacy: Expires soon
  ///
  /// In en, this message translates to:
  /// **'Expires soon'**
  String get pharmNearExpiry;

  /// Pharmacy: Restock
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get pharmRestock;

  /// Pharmacy: Quantity to add
  ///
  /// In en, this message translates to:
  /// **'Quantity to add'**
  String get pharmRestockAmount;

  /// Pharmacy: A second signature is required for controlled substances.
  ///
  /// In en, this message translates to:
  /// **'A second signature is required for controlled substances.'**
  String get pharmWitnessRequired;

  /// Pharmacy: Witness
  ///
  /// In en, this message translates to:
  /// **'Witness'**
  String get pharmWitnessName;

  /// Pharmacy: Cannot dispense: the slot is empty.
  ///
  /// In en, this message translates to:
  /// **'Cannot dispense: the slot is empty.'**
  String get pharmBlockedOutOfStock;

  /// Pharmacy: Cannot dispense: the lot has expired.
  ///
  /// In en, this message translates to:
  /// **'Cannot dispense: the lot has expired.'**
  String get pharmBlockedExpired;

  /// Pharmacy: Cannot dispense: the cabinet is locked.
  ///
  /// In en, this message translates to:
  /// **'Cannot dispense: the cabinet is locked.'**
  String get pharmBlockedLocked;

  /// Pharmacy: Cannot dispense: the prescription is not active.
  ///
  /// In en, this message translates to:
  /// **'Cannot dispense: the prescription is not active.'**
  String get pharmBlockedNotActive;

  /// Pharmacy: Cannot dispense: the patient is allergic to this product.
  ///
  /// In en, this message translates to:
  /// **'Cannot dispense: the patient is allergic to this product.'**
  String get pharmBlockedAllergy;

  /// Pharmacy: {medication} dispensed for {patient}.
  ///
  /// In en, this message translates to:
  /// **'{medication} dispensed for {patient}.'**
  String pharmDispenseSuccess(String medication, String patient);

  /// Pharmacy: Nothing waiting to be dispensed.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to be dispensed.'**
  String get pharmQueueEmpty;

  /// Pharmacy: {count, plural, =0{Nothing pending} =1{1 dose pending} other{{count} doses pending}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing pending} =1{1 dose pending} other{{count} doses pending}}'**
  String pharmPendingCount(int count);

  /// EAI: Integration flows
  ///
  /// In en, this message translates to:
  /// **'Integration flows'**
  String get eaiFlows;

  /// EAI: Flow
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get eaiFlow;

  /// EAI: New flow
  ///
  /// In en, this message translates to:
  /// **'New flow'**
  String get eaiNewFlow;

  /// EAI: Flow name
  ///
  /// In en, this message translates to:
  /// **'Flow name'**
  String get eaiFlowName;

  /// EAI: Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eaiFlowDescription;

  /// EAI: Enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get eaiEnabled;

  /// EAI: Disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get eaiDisabled;

  /// EAI: Building blocks
  ///
  /// In en, this message translates to:
  /// **'Building blocks'**
  String get eaiPalette;

  /// EAI: Canvas
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get eaiCanvas;

  /// EAI: Properties
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get eaiProperties;

  /// EAI: Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get eaiNodeLabel;

  /// EAI: Connect
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get eaiConnect;

  /// EAI: Remove connection
  ///
  /// In en, this message translates to:
  /// **'Remove connection'**
  String get eaiDisconnect;

  /// EAI: Delete block
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get eaiDeleteNode;

  /// EAI: Drag a building block onto the canvas to start.
  ///
  /// In en, this message translates to:
  /// **'Drag a building block onto the canvas to start.'**
  String get eaiDragHint;

  /// EAI: Click the output of one block, then the input of another.
  ///
  /// In en, this message translates to:
  /// **'Click the output of one block, then the input of another.'**
  String get eaiConnectHint;

  /// EAI: Test the flow
  ///
  /// In en, this message translates to:
  /// **'Test the flow'**
  String get eaiTestFlow;

  /// EAI: Test message
  ///
  /// In en, this message translates to:
  /// **'Test message'**
  String get eaiTestPayload;

  /// EAI: Run
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get eaiRunTest;

  /// EAI: Trace
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get eaiTrace;

  /// EAI: Run the flow to see what happens at each step.
  ///
  /// In en, this message translates to:
  /// **'Run the flow to see what happens at each step.'**
  String get eaiTraceEmpty;

  /// EAI: Input
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get eaiPayloadBefore;

  /// EAI: Output
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get eaiPayloadAfter;

  /// EAI: Message log
  ///
  /// In en, this message translates to:
  /// **'Message log'**
  String get eaiMessages;

  /// EAI: Message type
  ///
  /// In en, this message translates to:
  /// **'Message type'**
  String get eaiMessageType;

  /// EAI: Source
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get eaiSourceApp;

  /// EAI: Destination
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get eaiTargetApp;

  /// EAI: Latency
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get eaiLatency;

  /// EAI: Replay
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get eaiReplay;

  /// EAI: No messages yet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get eaiNoMessages;

  /// EAI: {count, plural, =1{1 problem to fix} other{{count} problems to fix}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem to fix} other{{count} problems to fix}}'**
  String eaiValidationIssues(int count);

  /// EAI: The flow is ready to run.
  ///
  /// In en, this message translates to:
  /// **'The flow is ready to run.'**
  String get eaiFlowValid;

  /// EAI: FHIR resources
  ///
  /// In en, this message translates to:
  /// **'FHIR resources'**
  String get eaiFhirResources;

  /// EAI: Resource type
  ///
  /// In en, this message translates to:
  /// **'Resource type'**
  String get eaiResourceType;

  /// EAI: {count, plural, =0{No resources} =1{1 resource} other{{count} resources}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No resources} =1{1 resource} other{{count} resources}}'**
  String eaiResourceCount(int count);

  /// EAI: FHIR server
  ///
  /// In en, this message translates to:
  /// **'FHIR server'**
  String get eaiServerStatus;

  /// EAI: Online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get eaiServerOnline;

  /// EAI: Offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get eaiServerOffline;

  /// EAI: Field mappings
  ///
  /// In en, this message translates to:
  /// **'Field mappings'**
  String get eaiFieldMappings;

  /// EAI: Add a mapping
  ///
  /// In en, this message translates to:
  /// **'Add a mapping'**
  String get eaiAddMapping;

  /// EAI: Source field
  ///
  /// In en, this message translates to:
  /// **'Source field'**
  String get eaiSourceField;

  /// EAI: Target field
  ///
  /// In en, this message translates to:
  /// **'Target field'**
  String get eaiTargetField;

  /// EAI: Transformation
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get eaiTransform;

  /// EAI: Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get eaiTransformArgument;

  /// EAI: Condition
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get eaiCondition;

  /// EAI: Field
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get eaiFieldPath;

  /// EAI: Operator
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get eaiOperator;

  /// EAI: Routes
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get eaiRoutes;

  /// EAI: Keep the fields that are not mapped
  ///
  /// In en, this message translates to:
  /// **'Keep the fields that are not mapped'**
  String get eaiKeepUnmapped;

  /// Devices: Device simulator
  ///
  /// In en, this message translates to:
  /// **'Device simulator'**
  String get deviceSimulator;

  /// Devices: Devices
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// Devices: Device
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// Devices: Device fleet
  ///
  /// In en, this message translates to:
  /// **'Device fleet'**
  String get deviceFleet;

  /// Devices: Device identifier
  ///
  /// In en, this message translates to:
  /// **'Device identifier'**
  String get deviceId;

  /// Devices: Device type
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get deviceKind;

  /// Devices: Manufacturer
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get deviceManufacturer;

  /// Devices: Model
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get deviceModel;

  /// Devices: Serial number
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get deviceSerial;

  /// Devices: Battery
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get deviceBattery;

  /// Devices: Last seen
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get deviceLastSeen;

  /// Devices: Never reported
  ///
  /// In en, this message translates to:
  /// **'Never reported'**
  String get deviceNeverSeen;

  /// Devices: Assigned to
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get deviceAssignedTo;

  /// Devices: Not assigned to a patient
  ///
  /// In en, this message translates to:
  /// **'Not assigned to a patient'**
  String get deviceNotAssigned;

  /// Devices: Start publishing
  ///
  /// In en, this message translates to:
  /// **'Start publishing'**
  String get deviceStart;

  /// Devices: Stop publishing
  ///
  /// In en, this message translates to:
  /// **'Stop publishing'**
  String get deviceStop;

  /// Devices: Publishing
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get deviceRunning;

  /// Devices: Stopped
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get deviceStopped;

  /// Devices: Interval between readings
  ///
  /// In en, this message translates to:
  /// **'Interval between readings'**
  String get deviceInterval;

  /// Devices: {seconds} s
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String deviceIntervalSeconds(int seconds);

  /// Devices: Scenario
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get deviceScenario;

  /// Devices: Stable
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get deviceScenarioStable;

  /// Devices: Deteriorating
  ///
  /// In en, this message translates to:
  /// **'Deteriorating'**
  String get deviceScenarioDeteriorating;

  /// Devices: Recovering
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get deviceScenarioRecovering;

  /// Devices: Noisy signal
  ///
  /// In en, this message translates to:
  /// **'Noisy signal'**
  String get deviceScenarioArtefact;

  /// Devices: Send a reading by hand
  ///
  /// In en, this message translates to:
  /// **'Send a reading by hand'**
  String get deviceManualReading;

  /// Devices: Send
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get deviceSend;

  /// Devices: Reading sent.
  ///
  /// In en, this message translates to:
  /// **'Reading sent.'**
  String get deviceSent;

  /// Devices: Could not send the reading: {error}
  ///
  /// In en, this message translates to:
  /// **'Could not send the reading: {error}'**
  String deviceSendFailed(String error);

  /// Devices: Live feed
  ///
  /// In en, this message translates to:
  /// **'Live feed'**
  String get deviceLiveFeed;

  /// Devices: {count, plural, =0{Nothing sent yet} =1{1 reading sent} other{{count} readings sent}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing sent yet} =1{1 reading sent} other{{count} readings sent}}'**
  String devicePublishedCount(int count);

  /// Devices: Apple Watch
  ///
  /// In en, this message translates to:
  /// **'Apple Watch'**
  String get deviceAppleWatch;

  /// Devices: Apple Watch / HealthKit
  ///
  /// In en, this message translates to:
  /// **'Apple Watch / HealthKit'**
  String get deviceHealthKitTitle;

  /// Devices: Readings collected by an Apple Watch can be imported here and are published exactly like a simulator reading.
  ///
  /// In en, this message translates to:
  /// **'Readings collected by an Apple Watch can be imported here and are published exactly like a simulator reading.'**
  String get deviceHealthKitBody;

  /// Devices: Import from HealthKit
  ///
  /// In en, this message translates to:
  /// **'Import from HealthKit'**
  String get deviceHealthKitImport;

  /// Devices: HealthKit is only available on iOS. On other platforms you can paste an export instead.
  ///
  /// In en, this message translates to:
  /// **'HealthKit is only available on iOS. On other platforms you can paste an export instead.'**
  String get deviceHealthKitUnavailable;

  /// Devices: Send readings for
  ///
  /// In en, this message translates to:
  /// **'Send readings for'**
  String get deviceTargetPatient;

  /// Devices: Publishing to
  ///
  /// In en, this message translates to:
  /// **'Publishing to'**
  String get deviceEndpoint;

  /// Navigation and dashboards: Overview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Navigation and dashboards: Patients
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// Navigation and dashboards: Dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Navigation and dashboards: Admissions
  ///
  /// In en, this message translates to:
  /// **'Admissions'**
  String get navAdmissions;

  /// Navigation and dashboards: Pharmacy
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get navPharmacy;

  /// Navigation and dashboards: Integration
  ///
  /// In en, this message translates to:
  /// **'Integration'**
  String get navIntegration;

  /// Navigation and dashboards: Devices
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get navDevices;

  /// Navigation and dashboards: Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Navigation and dashboards: Patients in the hospital
  ///
  /// In en, this message translates to:
  /// **'Patients in the hospital'**
  String get dashboardAdmittedPatients;

  /// Navigation and dashboards: Free beds
  ///
  /// In en, this message translates to:
  /// **'Free beds'**
  String get dashboardFreeBeds;

  /// Navigation and dashboards: Doses to dispense
  ///
  /// In en, this message translates to:
  /// **'Doses to dispense'**
  String get dashboardPendingDoses;

  /// Navigation and dashboards: Active devices
  ///
  /// In en, this message translates to:
  /// **'Active devices'**
  String get dashboardActiveDevices;

  /// Navigation and dashboards: Abnormal measurements
  ///
  /// In en, this message translates to:
  /// **'Abnormal measurements'**
  String get dashboardAbnormalVitals;

  /// Navigation and dashboards: Recent activity
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// Navigation and dashboards: In-memory demo data
  ///
  /// In en, this message translates to:
  /// **'In-memory demo data'**
  String get backendModeMemory;

  /// Navigation and dashboards: Connected to the local API
  ///
  /// In en, this message translates to:
  /// **'Connected to the local API'**
  String get backendModeRest;

  /// Navigation and dashboards: Connected to Firebase Data Connect
  ///
  /// In en, this message translates to:
  /// **'Connected to Firebase Data Connect'**
  String get backendModeDataConnect;

  /// Navigation and dashboards: {mode} — data is not shared with the other applications until you switch to a real backend.
  ///
  /// In en, this message translates to:
  /// **'{mode} — data is not shared with the other applications until you switch to a real backend.'**
  String backendBanner(String mode);

  /// Clinical safety: Safety checks
  ///
  /// In en, this message translates to:
  /// **'Safety checks'**
  String get safetyChecks;

  /// Clinical safety: No safety issues found.
  ///
  /// In en, this message translates to:
  /// **'No safety issues found.'**
  String get safetyNoIssues;

  /// Clinical safety: This action is blocked and cannot be completed.
  ///
  /// In en, this message translates to:
  /// **'This action is blocked and cannot be completed.'**
  String get safetyBlocked;

  /// Clinical safety: I have read the warnings and accept responsibility.
  ///
  /// In en, this message translates to:
  /// **'I have read the warnings and accept responsibility.'**
  String get safetyAcknowledge;

  /// Clinical safety: Reason for overriding
  ///
  /// In en, this message translates to:
  /// **'Reason for overriding'**
  String get safetyOverrideReason;

  /// Clinical safety: Blocking
  ///
  /// In en, this message translates to:
  /// **'Blocking'**
  String get safetySeverityBlocking;

  /// Clinical safety: Warning
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get safetySeverityWarning;

  /// Clinical safety: For information
  ///
  /// In en, this message translates to:
  /// **'For information'**
  String get safetySeverityAdvisory;

  /// Additional pharmacy and prescribing: Prescription saved.
  ///
  /// In en, this message translates to:
  /// **'Prescription saved.'**
  String get prescriptionSaved;

  /// Additional pharmacy and prescribing: Note saved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// Additional pharmacy and prescribing: Choose a medication
  ///
  /// In en, this message translates to:
  /// **'Choose a medication'**
  String get prescriptionSelectMedication;

  /// Additional pharmacy and prescribing: Slot {slot} restocked.
  ///
  /// In en, this message translates to:
  /// **'Slot {slot} restocked.'**
  String pharmRestocked(String slot);

  /// Additional pharmacy and prescribing: The drawer closed automatically.
  ///
  /// In en, this message translates to:
  /// **'The drawer closed automatically.'**
  String get pharmDrawerClosedAutomatically;

  /// Additional pharmacy and prescribing: Cabinet alerts
  ///
  /// In en, this message translates to:
  /// **'Cabinet alerts'**
  String get pharmAlerts;

  /// Additional pharmacy and prescribing: No alerts. Stock levels and expiry dates are fine.
  ///
  /// In en, this message translates to:
  /// **'No alerts. Stock levels and expiry dates are fine.'**
  String get pharmNoAlerts;

  /// Additional pharmacy and prescribing: For {patient}
  ///
  /// In en, this message translates to:
  /// **'For {patient}'**
  String pharmForPatient(String patient);

  /// Additional pharmacy and prescribing: Due {time}
  ///
  /// In en, this message translates to:
  /// **'Due {time}'**
  String pharmDue(String time);

  /// Additional pharmacy and prescribing: Overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get pharmOverdue;

  /// Additional pharmacy and prescribing: Dispensing history
  ///
  /// In en, this message translates to:
  /// **'Dispensing history'**
  String get pharmHistory;

  /// Additional ADT: New admission
  ///
  /// In en, this message translates to:
  /// **'New admission'**
  String get adtNewAdmission;

  /// Additional ADT: Patient
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get adtStepReviewPatient;

  /// Additional ADT: Placement
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get adtStepPlacement;

  /// Additional ADT: Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get adtStepConfirm;

  /// Additional ADT: Choose another ward
  ///
  /// In en, this message translates to:
  /// **'Choose another ward'**
  String get adtChooseAnotherWard;

  /// Additional ADT: Beds being cleaned cannot be assigned.
  ///
  /// In en, this message translates to:
  /// **'Beds being cleaned cannot be assigned.'**
  String get adtCleaningNote;

  /// Additional ADT: Event sent to the integration engine.
  ///
  /// In en, this message translates to:
  /// **'Event sent to the integration engine.'**
  String get adtEmitEvent;

  /// Additional ADT: The integration engine could not be reached; the movement was still recorded.
  ///
  /// In en, this message translates to:
  /// **'The integration engine could not be reached; the movement was still recorded.'**
  String get adtEmitFailed;

  /// Additional ADT: Ward overview
  ///
  /// In en, this message translates to:
  /// **'Ward overview'**
  String get adtWardOverview;

  /// Additional ADT: Patients on the ward
  ///
  /// In en, this message translates to:
  /// **'Patients on the ward'**
  String get adtCurrentPatients;

  /// Additional ADT: Change bed status
  ///
  /// In en, this message translates to:
  /// **'Change bed status'**
  String get adtSetBedStatus;

  /// Additional EAI and devices: Open the editor
  ///
  /// In en, this message translates to:
  /// **'Open the editor'**
  String get eaiOpenEditor;

  /// Additional EAI and devices: Save the flow
  ///
  /// In en, this message translates to:
  /// **'Save the flow'**
  String get eaiSaveFlow;

  /// Additional EAI and devices: Flow saved.
  ///
  /// In en, this message translates to:
  /// **'Flow saved.'**
  String get eaiFlowSaved;

  /// Additional EAI and devices: Delete this flow? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete this flow? This cannot be undone.'**
  String get eaiDeleteFlowConfirm;

  /// Additional EAI and devices: Select a block to edit its properties.
  ///
  /// In en, this message translates to:
  /// **'Select a block to edit its properties.'**
  String get eaiSelectNode;

  /// Additional EAI and devices: Sample messages
  ///
  /// In en, this message translates to:
  /// **'Sample messages'**
  String get eaiSamplePayload;

  /// Additional EAI and devices: This is not valid JSON.
  ///
  /// In en, this message translates to:
  /// **'This is not valid JSON.'**
  String get eaiInvalidJson;

  /// Additional EAI and devices: Passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get eaiStepPassed;

  /// Additional EAI and devices: Dropped here
  ///
  /// In en, this message translates to:
  /// **'Dropped here'**
  String get eaiStepDropped;

  /// Additional EAI and devices: Failed here
  ///
  /// In en, this message translates to:
  /// **'Failed here'**
  String get eaiStepFailed;

  /// Additional EAI and devices: Resources on the FHIR server
  ///
  /// In en, this message translates to:
  /// **'Resources on the FHIR server'**
  String get eaiTotalResources;

  /// Additional EAI and devices: Load the fictive patients into FHIR
  ///
  /// In en, this message translates to:
  /// **'Load the fictive patients into FHIR'**
  String get eaiSeedFhir;

  /// Additional EAI and devices: {count} resources written to the FHIR server.
  ///
  /// In en, this message translates to:
  /// **'{count} resources written to the FHIR server.'**
  String eaiSeedDone(int count);

  /// Additional EAI and devices: Assign automatically from the bed
  ///
  /// In en, this message translates to:
  /// **'Assign automatically from the bed'**
  String get deviceAutoAssign;

  /// Additional EAI and devices: Signal
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get deviceWaveform;

  /// Additional EAI and devices: Recently sent
  ///
  /// In en, this message translates to:
  /// **'Recently sent'**
  String get deviceOutbox;

  /// Additional EAI and devices: Configuration
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get deviceConfiguration;

  /// Additional EAI and devices: Measurements produced
  ///
  /// In en, this message translates to:
  /// **'Measurements produced'**
  String get deviceMeasurements;

  /// Additional EAI and devices: {count} readings waiting to be sent
  ///
  /// In en, this message translates to:
  /// **'{count} readings waiting to be sent'**
  String deviceOfflineQueue(int count);
}

class _HospitalLocalizationsDelegate
    extends LocalizationsDelegate<HospitalLocalizations> {
  const _HospitalLocalizationsDelegate();

  @override
  Future<HospitalLocalizations> load(Locale locale) {
    return SynchronousFuture<HospitalLocalizations>(
      lookupHospitalLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_HospitalLocalizationsDelegate old) => false;
}

HospitalLocalizations lookupHospitalLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return HospitalLocalizationsEn();
    case 'fr':
      return HospitalLocalizationsFr();
    case 'nl':
      return HospitalLocalizationsNl();
  }

  throw FlutterError(
    'HospitalLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
