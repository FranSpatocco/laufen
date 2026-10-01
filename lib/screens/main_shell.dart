import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/laufen_wordmark.dart';
import 'dashboard_tab.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'train_screen.dart';

/// App shell: navigation across the 4 main sections (see CLAUDE.md >
/// Diseño). Each tab is a plain content widget — this is the only
/// Scaffold/AppBar for the whole area. Works for guests too: tabs get the
/// current user (or null) and adapt.
///
/// Responsive: bottom NavigationBar on phones, a side NavigationRail with
/// width-capped content on desktop browsers, so the same code doesn't look
/// like a stretched phone app on a 1920px screen.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _authService = AuthService();
  late final Stream<User?> _authStateChanges = _authService.authStateChanges;
  int _index = 0;

  static const _titles = ['Inicio', 'Entrenar', 'Historial', 'Perfil'];
  static const _wideBreakpoint = 840.0;

  static const _destinations = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.directions_run_outlined, Icons.directions_run, 'Entrenar'),
    (Icons.history_outlined, Icons.history, 'Historial'),
    (Icons.person_outline, Icons.person, 'Perfil'),
  ];

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final tabs = [
          DashboardTab(
            uid: user?.uid,
            onStartTraining: () => _goToTab(1),
            onViewHistory: () => _goToTab(2),
          ),
          TrainScreen(isGuest: user == null),
          HistoryScreen(uid: user?.uid),
          ProfileScreen(user: user, onTryRun: () => _goToTab(1)),
        ];
        final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

        final content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // Keyed on the user too, so signing in/out replays the tab's
          // entrance and resubscribes to the right runs.
          child: KeyedSubtree(key: ValueKey('$_index-${user?.uid}'), child: tabs[_index]),
        );

        return Scaffold(
          appBar: AppBar(
            title: _index == 0 || wide
                ? LaufenWordmark(fontSize: 22, color: AppTheme.accentDark)
                : Text(_titles[_index]),
          ),
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _goToTab,
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.transparent,
                        indicatorColor: AppTheme.accent.withValues(alpha: 0.15),
                        groupAlignment: -0.85,
                        destinations: [
                          for (final d in _destinations)
                            NavigationRailDestination(
                              icon: Icon(d.$1),
                              selectedIcon: Icon(d.$2, color: AppTheme.accentDark),
                              label: Text(d.$3),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  )
                : content,
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _goToTab,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
                  ],
                ),
        );
      },
    );
  }
}
