import '../config/app_config.dart';
import 'hospital_repository.dart';
import 'memory/memory_repository.dart';
import 'rest/rest_repository.dart';

/// Builds the repository the configuration asks for.
///
/// Firebase Data Connect is reached through the same REST shape: the Data
/// Connect connector is deployed with an HTTP endpoint per operation, and the
/// generated gateway presents exactly the routes [RestHospitalRepository]
/// already calls. That keeps one client implementation for both cloud and
/// local PostgreSQL instead of two that drift apart.
HospitalRepository createRepository(AppConfig config) =>
    switch (config.backendMode) {
      BackendMode.memory => MemoryHospitalRepository(),
      BackendMode.restApi => RestHospitalRepository(baseUrl: config.apiBaseUrl),
      BackendMode.dataConnect => RestHospitalRepository(
        baseUrl: config.apiBaseUrl,
      ),
    };
