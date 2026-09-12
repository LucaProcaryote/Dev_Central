import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../config/app_config.dart';
import '../l10n/generated/hospital_localizations.dart';
import 'app_badge.dart';
import 'theme.dart';
import 'widgets/backend_banner.dart';
import 'widgets/language_selector.dart';

/// One destination in an application's primary navigation.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  /// Resolved against the current locale by the caller, which owns the
  /// application-specific strings.
  final String Function(HospitalLocalizations l10n) label;

  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// The chrome every application shares: title bar, language switcher, user
/// menu, backend banner, and a navigation surface that adapts to the width.
///
/// Below 600px it is a bottom bar (a phone in a corridor), between 600 and
/// 1000 a rail, and above that an expanded rail with labels (a workstation).
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    this.actions = const <Widget>[],
    this.initialIndex = 0,
  });

  final String title;
  final List<ShellDestination> destinations;
  final List<Widget> actions;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final isExpanded = Breakpoints.isExpanded(context);

    // Guard against a destination list that shrank between builds.
    final index = _index.clamp(0, widget.destinations.length - 1);
    final body = widget.destinations[index].builder(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            AppBadge(app: context.watch<AppConfig>().app, size: 26),
            Gap.w8,
            Flexible(
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          ...widget.actions,
          LanguageSelector(compact: isCompact),
          Gap.w8,
          const _UserMenu(),
          Gap.w8,
        ],
      ),
      body: Column(
        children: <Widget>[
          const BackendBanner(),
          Expanded(
            child: isCompact
                ? body
                : Row(
                    children: <Widget>[
                      NavigationRail(
                        extended: isExpanded,
                        selectedIndex: index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        labelType: isExpanded
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        destinations: <NavigationRailDestination>[
                          for (final destination in widget.destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label(l10n)),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isCompact
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: <Widget>[
                for (final destination in widget.destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label(l10n),
                  ),
              ],
            )
          : null,
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final l10n = HospitalLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: user.displayName,
      offset: const Offset(0, 44),
      onSelected: (value) {
        if (value == 'signOut') auth.signOut();
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                user.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user.role.display.forLanguage(language),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (user.email.isNotEmpty)
                Text(
                  user.email,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'signOut',
          child: Row(
            children: <Widget>[
              const Icon(Icons.logout, size: 18),
              Gap.w8,
              Text(l10n.authSignOut),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          user.initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
