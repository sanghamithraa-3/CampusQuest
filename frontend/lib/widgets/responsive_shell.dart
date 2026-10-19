import 'package:flutter/material.dart';

import '../theme/campus_theme.dart';

class CampusDestination {
  const CampusDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<CampusDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        if (!wide) {
          return Scaffold(
            appBar: AppBar(
              title: _BrandTitle(title: title),
              actions: [
                ...actions,
                IconButton(
                  onPressed: onLogout,
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 280,
                decoration: const BoxDecoration(
                  color: CampusColors.surface,
                  border: Border(right: BorderSide(color: CampusColors.line)),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 26, 16, 32),
                        child: _BrandMark(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: NavigationRail(
                            extended: true,
                            minExtendedWidth: 220,
                            selectedIndex: selectedIndex,
                            onDestinationSelected: onDestinationSelected,
                            backgroundColor: CampusColors.surface,
                            indicatorColor: CampusColors.lavender,
                            labelType: NavigationRailLabelType.none,
                            destinations: destinations
                                .map(
                                  (destination) => NavigationRailDestination(
                                    icon: Icon(destination.icon),
                                    selectedIcon: Icon(
                                      destination.selectedIcon,
                                    ),
                                    label: Text(destination.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 76,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              ...actions,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(compact: true),
        const SizedBox(width: 12),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: CampusColors.lavender,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: CampusColors.indigo,
            size: 21,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(
            'CAMPUS QUEST',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: CampusColors.navy,
            ),
          ),
        ],
      ],
    );
  }
}
