import 'providers/game_provider.dart';
import 'providers/density_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/squad_provider.dart';
import '../models/models.dart';

/// Central orchestrator that coordinates all provider timers and cross-provider events.
class SimulationEngine {
  final GameProvider game;
  final DensityProvider density;
  final AlertProvider alerts;
  final SquadProvider squad;

  bool _running = false;
  int _lastFoodAlertMinute = -10;
  int _lastTimingAlertMinute = -10;
  bool _exitAlertSent = false;

  SimulationEngine({
    required this.game,
    required this.density,
    required this.alerts,
    required this.squad,
  });

  void start() {
    if (_running) return;
    _running = true;

    // Initialize data
    density.initialize();
    squad.initialize();
    alerts.seedAlerts();

    // Wire cross-provider events
    game.onGoalScored = _handleGoal;
    game.onHalfTime = _handleHalfTime;
    game.onFullTime = _handleFullTime;

    // Listen to game clock for density + alert triggers
    game.addListener(_onGameTick);

    // Start all simulations
    game.startSimulation();
    density.startSimulation();
    squad.startSimulation();
  }

  void _onGameTick() {
    final minute = game.clockMinute;
    density.updateGameMinute(minute);

    // Timing window alert (around 40th minute, before halftime)
    if (minute >= 38 && minute <= 42 && minute - _lastTimingAlertMinute >= 5) {
      final minutesAway = 45 - minute;
      if (minutesAway > 0) {
        alerts.generateTimingAlert(45, minutesAway);
        _lastTimingAlertMinute = minute;
      }
    }

    // Food queue alerts — check cold concession zones periodically
    if (minute % 8 == 0 && minute - _lastFoodAlertMinute >= 8) {
      final coldFood = density.zones.where((z) =>
          z.name.contains('Food') &&
          (z.density == DensityLevel.low || z.density == DensityLevel.empty)).toList();
      if (coldFood.isNotEmpty) {
        final zone = coldFood.first;
        final waitMin = (zone.estimatedCount / 80).round().clamp(1, 10);
        alerts.generateFoodAlert(zone.name, waitMin);
        _lastFoodAlertMinute = minute;
      }
    }

    // Exit pre-alert at 85th minute
    if (minute >= 85 && !_exitAlertSent) {
      _exitAlertSent = true;
      density.applyExitSurge();
      // Find lowest-density gate
      final gates = density.zones.where((z) => z.name.contains('Gate')).toList()
        ..sort((a, b) => a.estimatedCount.compareTo(b.estimatedCount));
      if (gates.isNotEmpty) {
        alerts.generateExitAlert(gates.first.name);
      }
    }
  }

  void _handleGoal(bool isHome) {
    final team = isHome ? game.state.homeTeam : game.state.awayTeam;
    alerts.generateGoalAlert(team);
    density.applyGoalSurge();
  }

  void _handleHalfTime(int minute) {
    density.applyHalfTimeSurge();
    alerts.generateTimingAlert(45, 0);
  }

  void _handleFullTime(int minute) {
    density.applyExitSurge();
  }

  void stop() {
    if (!_running) return;
    _running = false;
    game.removeListener(_onGameTick);
    game.stopSimulation();
    density.stopSimulation();
    squad.stopSimulation();
  }

  void dispose() {
    stop();
  }
}
