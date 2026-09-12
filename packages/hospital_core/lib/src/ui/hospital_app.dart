import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../auth/demo_auth_service.dart';
import '../auth/firebase_auth_service.dart';
import '../config/app_config.dart';
import '../config/supported_locales.dart';
import '../data/hospital_repository.dart';
import '../data/repository_factory.dart';
import '../l10n/generated/hospital_localizations.dart';
import 'locale_controller.dart';
import 'sign_in_screen.dart';
import 'theme.dart';
import 'widgets/state_views.dart';

/// The root widget of every application in the suite.
///
/// It owns the four things all five have in common - configuration, the
/// repository, authentication and the interface language - and hands control to
/// [homeBuilder] once a user is signed in. Each application therefore starts
/// with a `main.dart` of about fifteen lines and no boilerplate to copy wrong.
class MiniHospitalApp extends StatefulWidget {
  const MiniHospitalApp({
    super.key,
    required this.config,
    required this.title,
    required this.homeBuilder,
    this.subtitle,
    this.repositoryOverride,
    this.authOverride,
    this.localeStore,
  });

  final AppConfig config;

  /// Shown in the title bar and on the sign-in screen. Resolved per locale.
  final String Function(HospitalLocalizations l10n) title;

  /// Builds the application once authentication has succeeded.
  final WidgetBuilder homeBuilder;

  final String Function(HospitalLocalizations l10n)? subtitle;

  /// Test seams: pass a stub instead of the configured implementation.
  final HospitalRepository? repositoryOverride;
  final AuthService? authOverride;

  /// Where the language choice is remembered. Defaults to the platform's
  /// key-value store; tests pass [InMemoryLocaleStore].
  final LocalePreferenceStore? localeStore;

  @override
  State<MiniHospitalApp> createState() => _MiniHospitalAppState();
}

class _MiniHospitalAppState extends State<MiniHospitalApp> {
  late final HospitalRepository _repository;
  late final AuthService _auth;
  late final LocaleController _localeController;

  Object? _startupError;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repositoryOverride ?? createRepository(widget.config);
    _auth = widget.authOverride ??
        (widget.config.usesFirebaseAuth
            ? FirebaseAuthService()
            : DemoAuthService());
    _localeController = LocaleController(store: widget.localeStore);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // The language preference is a convenience, not a prerequisite: a failure
    // to read it must never keep the application on its splash screen.
    try {
      await _localeController.load(
        deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
      );
    } catch (_) {
      // Already defaulted to the device language inside load().
    }

    // Authentication and data access are prerequisites, so a failure here is
    // reported rather than swallowed - but it is still shown as a retryable
    // screen, not a frozen one.
    try {
      await _auth.initialize();
      await _repository.initialize();
    } catch (error) {
      if (mounted) setState(() => _startupError = error);
      return;
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _repository.dispose();
    _auth.dispose();
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: widget.config),
        ChangeNotifierProvider<LocaleController>.value(value: _localeController),
        ChangeNotifierProvider<AuthService>.value(value: _auth),
        ChangeNotifierProvider<HospitalRepository>.value(value: _repository),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeController, _) => MaterialApp(
          onGenerateTitle: (context) =>
              widget.title(HospitalLocalizations.of(context)),
          debugShowCheckedModeBanner: false,
          theme: HospitalTheme.light(widget.config.app),
          darkTheme: HospitalTheme.dark(widget.config.app),
          locale: localeController.locale,
          supportedLocales: SupportedLocales.all,
          localizationsDelegates: HospitalLocalizations.localizationsDelegates,
          home: Builder(builder: _buildHome),
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    if (_startupError != null) {
      return Scaffold(
        body: ErrorView(
          error: _startupError!,
          onRetry: () {
            setState(() => _startupError = null);
            _bootstrap();
          },
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(body: LoadingView());
    }

    final l10n = HospitalLocalizations.of(context);
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.isSignedIn) {
          return SignInScreen(
            appTitle: widget.title(l10n),
            subtitle: widget.subtitle?.call(l10n),
          );
        }
        return widget.homeBuilder(context);
      },
    );
  }
}
