import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hospital_core/hospital_core.dart';
import 'package:uuid/uuid.dart';

import 'signal_generator.dart';

/// One reading and what became of it.
@immutable
class PublishedReading {
  const PublishedReading({
    required this.observation,
    required this.delivered,
    this.error,
  });

  final Observation observation;

  /// Whether the integration engine accepted it. False also covers "there was
  /// no engine configured", which the interface distinguishes.
  final bool delivered;
  final String? error;
}

/// Drives one device simulator.
///
/// Each student runs this with a different `DEVICE_ID`, so the ten of them
/// together produce every vital sign the record can display. The controller
/// owns the timer, the signal generator and the outbox.
class SimulatorController extends ChangeNotifier {
  SimulatorController({
    required this.repository,
    required this.publisher,
    required this.deviceCode,
    this.feed,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       _generator = SignalGenerator(scenario: SimulationScenario.stable);

  final HospitalRepository repository;

  /// Null when nothing should leave the machine - readings are still written
  /// to the local repository so the simulator is useful on its own.
  final EventPublisher? publisher;

  /// The broker connection, or null when none is configured.
  ///
  /// A real bedside monitor publishes to MQTT and does not know or care who
  /// is listening. Keeping this beside the HTTP publisher rather than
  /// replacing it lets a lab compare the two: same reading, same instant, two
  /// transports, and only one of them tells the ward when the device stops.
  final DeviceFeed? feed;

  /// `DEV1`..`DEV10`, from `--dart-define=DEVICE_ID=`.
  final String deviceCode;

  /// Counts what this device has put on the broker, and the sequence number
  /// it stamps each reading with. A gap in that number is how a receiver
  /// learns something was lost - which at-most-once delivery makes possible
  /// and nothing else reveals.
  int _published = 0;
  int get publishedToBroker => _published;

  bool get usesBroker => feed != null;

  final Uuid _uuid;
  final SignalGenerator _generator;

  MedicalDevice? _device;
  MedicalDevice? get device => _device;

  Patient? _patient;
  Patient? get patient => _patient;

  Encounter? _encounter;

  Timer? _timer;
  DateTime? _lastTick;

  bool _running = false;
  bool get isRunning => _running;

  Duration _interval = const Duration(seconds: 5);
  Duration get interval => _interval;

  SimulationScenario get scenario => _generator.scenario;

  int _publishedCount = 0;
  int get publishedCount => _publishedCount;

  int _failedCount = 0;
  int get failedCount => _failedCount;

  /// Most recent readings, newest first, capped so a simulator left running
  /// overnight does not grow without bound.
  final List<PublishedReading> _outbox = <PublishedReading>[];
  List<PublishedReading> get outbox =>
      List<PublishedReading>.unmodifiable(_outbox);
  static const int _outboxLimit = 200;

  Map<VitalSignType, double> get currentValues => _generator.current;

  /// Loads this device and whoever it is attached to.
  Future<void> load() async {
    _device = await repository.findDeviceByCode(deviceCode);
    final assigned = _device?.assignedPatientId;
    if (assigned != null) {
      _patient = await repository.findPatient(assigned);
      _encounter = await repository.activeEncounterFor(assigned);
    }
    notifyListeners();
  }

  /// Points the simulator at a different patient, and follows the bed.
  Future<void> assignPatient(Patient? patient) async {
    _patient = patient;
    _encounter = patient == null
        ? null
        : await repository.activeEncounterFor(patient.id);
    final device = _device;
    if (device != null) {
      _device = await repository.saveDevice(
        patient == null
            ? device.copyWith(clearAssignment: true)
            : device.copyWith(
                assignedPatientId: patient.id,
                assignedBedId: _encounter?.bedId,
                wardId: _encounter?.wardId,
              ),
      );
    }
    notifyListeners();
  }

  void setScenario(SimulationScenario scenario) {
    _generator.scenario = scenario;
    notifyListeners();
  }

  void setInterval(Duration interval) {
    _interval = interval;
    if (_running) {
      // Restart so the new interval takes effect immediately rather than after
      // the current one has elapsed.
      _timer?.cancel();
      _startTimer();
    }
    notifyListeners();
  }

  /// Overrides one measurement, for demonstrating a specific value on demand.
  void setValue(VitalSignType type, double value) {
    _generator.setValue(type, value);
    notifyListeners();
  }

  void start() {
    if (_running) return;
    _running = true;
    _lastTick = DateTime.now();
    _startTimer();
    _markDeviceActive();
    notifyListeners();
    // Emit immediately so the student sees something without waiting out the
    // first interval.
    unawaited(_tick());
  }

  void stop() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  Future<void> _markDeviceActive() async {
    final device = _device;
    if (device == null) return;
    _device = await repository.saveDevice(
      device.copyWith(status: DeviceStatus.active, lastSeenAt: DateTime.now()),
    );
  }

  Future<void> _tick() async {
    final device = _device;
    final patient = _patient;
    if (device == null || patient == null) return;

    final now = DateTime.now();
    final since = _lastTick == null ? _interval : now.difference(_lastTick!);
    _lastTick = now;

    final readings = _generator.sample(
      device: device,
      patientId: patient.id,
      encounterId: _encounter?.id,
      since: since,
      at: now,
      nextId: () => 'obs-${_uuid.v4()}',
    );

    for (final observation in readings) {
      await _emit(observation);
    }

    _device = await repository.saveDevice(
      device.copyWith(status: DeviceStatus.active, lastSeenAt: now),
    );
    notifyListeners();
  }

  /// Sends one reading: to the integration engine if there is one, and always
  /// to the local repository so the simulator stands on its own.
  Future<PublishedReading> _emit(Observation observation) async {
    await repository.addObservation(observation);

    // On the broker first, because that is the transport a monitor actually
    // has: fire and forget, no reply, no failure to report. The reading is
    // gone if the link is down, and the next one is a second away.
    final broker = feed;
    if (broker != null) {
      broker.publishReading(
        DeviceReading.of(
          observation,
          location: DeviceLocation(
            wardId: _encounter?.wardId,
            bedId: _encounter?.bedId,
          ),
          sequence: ++_published,
        ),
      );
    }

    var delivered = false;
    String? error;
    if (publisher != null) {
      // Fetched for PID: an ORU^R01 identifies its patient by name and
      // medical record number, not by the internal id the FHIR resource
      // uses. No patient, no v2 message - the FHIR one still goes.
      final patient = await repository.findPatient(observation.patientId);
      final result = await publisher!.publishObservation(
        observation,
        patient: patient,
      );
      delivered = result.delivered;
      error = result.error;
    } else {
      error = 'No integration engine configured';
    }

    if (delivered) {
      _publishedCount++;
    } else {
      _failedCount++;
    }

    final entry = PublishedReading(
      observation: observation,
      delivered: delivered,
      error: error,
    );
    _outbox.insert(0, entry);
    if (_outbox.length > _outboxLimit) _outbox.removeLast();
    return entry;
  }

  /// Sends one reading the user typed in by hand.
  Future<PublishedReading?> sendManual(VitalSignType type, double value) async {
    final device = _device;
    final patient = _patient;
    if (device == null || patient == null) return null;

    _generator.setValue(type, value);
    final entry = await _emit(
      Observation(
        id: 'obs-${_uuid.v4()}',
        patientId: patient.id,
        encounterId: _encounter?.id,
        type: type,
        value: value,
        effectiveDateTime: DateTime.now(),
        deviceId: device.code,
      ),
    );
    notifyListeners();
    return entry;
  }

  /// Ingests readings collected elsewhere - an Apple Watch export, or any
  /// other source - and publishes them exactly like generated ones.
  ///
  /// Accepts a list of `{type, value, at}` records so the caller does the
  /// parsing and this stays independent of any particular export format.
  Future<int> ingest(
    List<({VitalSignType type, double value, DateTime at})> readings, {
    String sourceCode = 'APPLE-WATCH',
  }) async {
    final patient = _patient;
    if (patient == null) return 0;

    var count = 0;
    for (final reading in readings) {
      await _emit(
        Observation(
          id: 'obs-${_uuid.v4()}',
          patientId: patient.id,
          encounterId: _encounter?.id,
          type: reading.type,
          value: reading.value,
          effectiveDateTime: reading.at,
          deviceId: sourceCode,
        ),
      );
      count++;
    }
    notifyListeners();
    return count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    publisher?.close();
    super.dispose();
  }
}
