import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/models.dart';

class AlertProvider extends ChangeNotifier {
  final List<PulseAlert> _alerts = [];
  final Set<String> _mutedCategories = {};
  final Map<String, DateTime> _lastAlertByCategory = {};
  int _nextId = 100;

  AlertProvider() {
    _listenForCloudMessages();
  }

  void _listenForCloudMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final body = message.notification!.body ?? 'New alert received';
        final data = message.data;
        
        AlertType type = AlertType.food;
        if (data['triggerType'] != null) {
          final t = data['triggerType'].toString().toLowerCase();
          if (t.contains('time')) type = AlertType.timing;
          if (t.contains('exit')) type = AlertType.exit;
          if (t.contains('goal')) type = AlertType.goal;
        }

        _addAlert(type, body);
      }
    });
  }

  List<PulseAlert> get alerts => _alerts
      .where((a) => !a.isDismissed)
      .where((a) => !_mutedCategories.contains(a.type.name))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<PulseAlert> get allAlerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts
      .where((a) => !a.isDismissed)
      .where((a) => !_mutedCategories.contains(a.type.name))
      .length;

  int get totalReceived => _alerts.length;

  Set<String> get mutedCategories => Set.unmodifiable(_mutedCategories);

  bool isMuted(AlertType type) => _mutedCategories.contains(type.name);

  void toggleMute(AlertType type) {
    if (_mutedCategories.contains(type.name)) {
      _mutedCategories.remove(type.name);
    } else {
      _mutedCategories.add(type.name);
    }
    notifyListeners();
  }

  void setMuted(AlertType type, bool muted) {
    if (muted) {
      _mutedCategories.add(type.name);
    } else {
      _mutedCategories.remove(type.name);
    }
    notifyListeners();
  }

  void dismiss(String alertId) {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      _alerts[idx] = _alerts[idx].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  /// Generate a food queue alert when a concession zone drops in density
  void generateFoodAlert(String standName, int waitMinutes) {
    _addAlert(
      AlertType.food,
      '$standName: ${waitMinutes}min wait. Go now.',
    );
  }

  /// Generate a timing window alert
  void generateTimingAlert(int targetMinute, int minutesAway) {
    _addAlert(
      AlertType.timing,
      'Best window: ${targetMinute}th min. $minutesAway min away.',
    );
  }

  /// Generate an exit pre-alert
  void generateExitAlert(String gateName) {
    _addAlert(
      AlertType.exit,
      'Leave now for $gateName head start.',
    );
  }

  /// Generate a goal alert
  void generateGoalAlert(String team) {
    _addAlert(
      AlertType.goal,
      'GOAL! $team scores!',
    );
  }

  /// Generate a squad group alert
  void generateSquadAlert(String message) {
    _addAlert(AlertType.group, message);
  }

  void _addAlert(AlertType type, String message) {
    // Throttle: max 1 alert per category per 15 seconds (scaled from 15min real-world)
    final catKey = type.name;
    final lastTime = _lastAlertByCategory[catKey];
    if (lastTime != null && DateTime.now().difference(lastTime).inSeconds < 15) {
      return;
    }

    // Max 3 alerts per 30 seconds total (scaled from 3/hour)
    final recentCount = _alerts
        .where((a) => DateTime.now().difference(a.timestamp).inSeconds < 30)
        .length;
    if (recentCount >= 3) return;

    final alert = PulseAlert(
      id: 'alert_${_nextId++}',
      type: type,
      message: message,
      timeAgo: 'now',
      timestamp: DateTime.now(),
    );

    _alerts.insert(0, alert);
    _lastAlertByCategory[catKey] = DateTime.now();

    // Cap at 50 alerts in history
    if (_alerts.length > 50) {
      _alerts.removeRange(50, _alerts.length);
    }

    notifyListeners();
  }

  /// Seed initial alerts for a fresh session
  void seedAlerts() {
    final now = DateTime.now();
    _alerts.addAll([
      PulseAlert(
        id: 'seed_1', type: AlertType.food,
        message: 'Sec 112 stand: 3 min wait. Go now.',
        timeAgo: '2m', timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      PulseAlert(
        id: 'seed_2', type: AlertType.timing,
        message: 'Halftime window: 44-46min. Best time to move.',
        timeAgo: '1m', timestamp: now.subtract(const Duration(minutes: 1)),
      ),
      PulseAlert(
        id: 'seed_3', type: AlertType.exit,
        message: 'Leave at 88min for Gate A head start.',
        timeAgo: 'pred', timestamp: now.subtract(const Duration(seconds: 30)),
      ),
      PulseAlert(
        id: 'seed_4', type: AlertType.view,
        message: 'Row G: replay screen blocked. Try D-F.',
        timeAgo: '5m', timestamp: now.subtract(const Duration(minutes: 5)),
      ),
    ]);
    notifyListeners();
  }
}
