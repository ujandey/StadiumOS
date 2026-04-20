import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_screen.dart';
import 'features/pulse/pulse_screen.dart';
import 'features/squad/squad_screen.dart';
import 'features/profile/profile_screen.dart';
import 'services/providers/game_provider.dart';
import 'services/providers/density_provider.dart';
import 'services/providers/alert_provider.dart';
import 'services/providers/squad_provider.dart';
import 'services/providers/user_provider.dart';
import 'services/simulation_engine.dart';
import 'models/models.dart';

class StadiumOSApp extends StatefulWidget {
  const StadiumOSApp({super.key});
  @override State<StadiumOSApp> createState() => _StadiumOSAppState();
}

class _StadiumOSAppState extends State<StadiumOSApp> {
  late final GameProvider _gameProvider;
  late final DensityProvider _densityProvider;
  late final AlertProvider _alertProvider;
  late final SquadProvider _squadProvider;
  late final UserProvider _userProvider;
  late final SimulationEngine _engine;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _gameProvider = GameProvider();
    _densityProvider = DensityProvider();
    _alertProvider = AlertProvider();
    _squadProvider = SquadProvider();
    _userProvider = UserProvider();

    _engine = SimulationEngine(
      game: _gameProvider,
      density: _densityProvider,
      alerts: _alertProvider,
      squad: _squadProvider,
    );

    _initAsync();
  }

  Future<void> _initAsync() async {
    await _userProvider.loadPreferences();
    // Sync user alert prefs to alert provider
    if (!_userProvider.alertsFood) _alertProvider.setMuted(AlertType.food, true);
    if (!_userProvider.alertsTiming) _alertProvider.setMuted(AlertType.timing, true);
    if (!_userProvider.alertsExit) _alertProvider.setMuted(AlertType.exit, true);
    if (!_userProvider.alertsView) _alertProvider.setMuted(AlertType.view, true);

    setState(() => _initialized = true);

    // Start simulation if already onboarded
    if (_userProvider.isOnboarded) {
      _engine.start();
    }
  }

  void _onOnboardingComplete() {
    _userProvider.completeOnboarding();
    _engine.start();
  }

  @override
  void dispose() {
    _engine.dispose();
    _gameProvider.dispose();
    _densityProvider.dispose();
    _alertProvider.dispose();
    _squadProvider.dispose();
    _userProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          backgroundColor: AppColors.bg900,
          body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _gameProvider),
        ChangeNotifierProvider.value(value: _densityProvider),
        ChangeNotifierProvider.value(value: _alertProvider),
        ChangeNotifierProvider.value(value: _squadProvider),
        ChangeNotifierProvider.value(value: _userProvider),
      ],
      child: MaterialApp(
        title: 'StadiumOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: _userProvider.isOnboarded
            ? const _MainScaffold()
            : OnboardingScreen(onComplete: _onOnboardingComplete),
      ),
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();
  @override State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _currentTab = 0;

  static const _screens = [
    HomeScreen(),
    MapScreen(),
    PulseScreen(),
    SquadScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertCount = context.watch<AlertProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.bg900,
      body: IndexedStack(index: _currentTab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bg700,
          border: Border(top: BorderSide(color: AppColors.bg400)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: AppTypography.label.copyWith(fontSize: 10),
          unselectedLabelStyle: AppTypography.label.copyWith(fontSize: 10),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
            BottomNavigationBarItem(
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined),
                if (alertCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$alertCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ]),
              label: 'Pulse',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Squad'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
          ],
        ),
      ),
    );
  }
}
