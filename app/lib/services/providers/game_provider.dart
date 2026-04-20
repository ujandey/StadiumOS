import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';

class GameProvider extends ChangeNotifier {
  final Random _rng = Random();
  Timer? _clockTimer;
  Timer? _eventTimer;

  GameState _state = const GameState(
    homeTeam: 'MAN UTD',
    awayTeam: 'ARSENAL',
    homeScore: 0,
    awayScore: 0,
    clock: "0'",
    isLive: true,
    clockMinute: 0,
    isHalfTime: false,
  );

  GameState get state => _state;
  int get clockMinute => _state.clockMinute;
  bool get isHalfTime => _state.isHalfTime;
  bool get isFullTime => _state.isFullTime;
  bool get isLive => _state.isLive;

  // Callbacks for cross-provider events
  void Function(bool isHome)? onGoalScored;
  void Function(int minute)? onHalfTime;
  void Function(int minute)? onFullTime;

  void startSimulation() {
    // Tick game clock every 1 second = 1 game minute
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());

    // Random game events (goals) — check every 5 seconds
    _eventTimer = Timer.periodic(const Duration(seconds: 5), (_) => _maybeGameEvent());
  }

  void _tickClock() {
    if (!_state.isLive || _state.isFullTime) return;

    int nextMinute = _state.clockMinute + 1;
    bool enteringHalfTime = false;
    bool enteringFullTime = false;

    // Half-time at 45'
    if (nextMinute == 45 && !_state.isHalfTime) {
      enteringHalfTime = true;
    }

    // Resume after half-time at 46' (auto-resume after 5s real time)
    if (_state.isHalfTime && nextMinute <= 45) {
      return; // Stay paused
    }

    // Full-time at 90'
    if (nextMinute >= 90) {
      enteringFullTime = true;
    }

    _state = _state.copyWith(
      clockMinute: nextMinute,
      clock: enteringHalfTime ? "HT" : "$nextMinute'",
      isHalfTime: enteringHalfTime,
      isLive: !enteringFullTime,
    );
    notifyListeners();

    if (enteringHalfTime) {
      onHalfTime?.call(nextMinute);
      // Auto-resume after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_state.isHalfTime) {
          _state = _state.copyWith(
            isHalfTime: false,
            clockMinute: 46,
            clock: "46'",
          );
          notifyListeners();
        }
      });
    }

    if (enteringFullTime) {
      _state = _state.copyWith(clock: "FT", isLive: false);
      onFullTime?.call(nextMinute);
      notifyListeners();
      stopSimulation();
    }
  }

  void _maybeGameEvent() {
    if (!_state.isLive || _state.isHalfTime) return;

    // ~15% chance of a goal each check (roughly 1-2 goals per half)
    if (_rng.nextDouble() < 0.12) {
      final isHome = _rng.nextBool();
      _state = _state.copyWith(
        homeScore: isHome ? _state.homeScore + 1 : null,
        awayScore: !isHome ? _state.awayScore + 1 : null,
      );
      notifyListeners();
      onGoalScored?.call(isHome);
    }
  }

  void stopSimulation() {
    _clockTimer?.cancel();
    _eventTimer?.cancel();
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
