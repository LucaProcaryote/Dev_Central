import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../l10n/generated/hospital_localizations.dart';
import '../models/hospital_user.dart';
import 'theme.dart';
import 'widgets/language_selector.dart';

/// The sign-in screen shared by all five applications.
///
/// In demo mode it lists the staff accounts as one-click buttons and says so
/// in as many words. Dressing a demo up as real authentication is the kind of
/// thing that later gets mistaken for a security control.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.appTitle, this.subtitle});

  final String appTitle;
  final String? subtitle;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _errorCode;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(
      () => context.read<AuthService>().signIn(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _quickSignIn(HospitalUser user) =>
      _run(() => context.read<AuthService>().signInAs(user));

  Future<void> _run(Future<HospitalUser> Function() action) async {
    setState(() {
      _busy = true;
      _errorCode = null;
    });
    try {
      await action();
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _errorCode = failure.code);
    } catch (_) {
      if (mounted) setState(() => _errorCode = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorMessage(HospitalLocalizations l10n, String code) =>
      switch (code) {
        'invalid-credentials' => l10n.authErrorInvalidCredentials,
        'user-not-found' => l10n.authErrorUserNotFound,
        'network' => l10n.authErrorNetwork,
        'not-configured' => l10n.authErrorNotConfigured,
        _ => l10n.errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = HospitalLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final config = context.watch<AppConfig>();
    final language = Localizations.localeOf(context).languageCode;
    final quickAccounts = auth.quickSignInAccounts;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.local_hospital_rounded,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      Gap.w16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.hospitalName,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.appTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const LanguageSelector(compact: true),
                    ],
                  ),
                  if (widget.subtitle != null) ...<Widget>[
                    Gap.h8,
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  Gap.h24,

                  if (config.authMode == AuthMode.demo)
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(Gap.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                Gap.w8,
                                Text(
                                  l10n.authDemoModeTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Gap.h8,
                            Text(
                              l10n.authDemoModeBody,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Gap.h16,
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          controller: _emailController,
                          autofillHints: const <String>[AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.authEmail,
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? l10n.errorFieldRequired
                              : null,
                        ),
                        Gap.h16,
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const <String>[AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: l10n.authPassword,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) =>
                              config.authMode == AuthMode.firebase &&
                                  (value ?? '').isEmpty
                              ? l10n.errorFieldRequired
                              : null,
                        ),
                      ],
                    ),
                  ),

                  if (_errorCode != null) ...<Widget>[
                    Gap.h16,
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        Gap.w8,
                        Expanded(
                          child: Text(
                            _errorMessage(l10n, _errorCode!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  Gap.h24,
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authSignIn),
                  ),

                  if (quickAccounts.isNotEmpty) ...<Widget>[
                    Gap.h32,
                    Text(
                      l10n.authQuickSignIn,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Gap.h8,
                    for (final account in quickAccounts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _quickSignIn(account),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Gap.md,
                              vertical: Gap.sm,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Text(
                                  account.initials,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                              Gap.w16,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      account.displayName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      account.role.display.forLanguage(
                                        language,
                                      ),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
