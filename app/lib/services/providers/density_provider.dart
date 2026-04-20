import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../mock_data.dart';

class DensityProvider extends ChangeNotifier {
  final Random _rng = Random();
  Timer? _refreshTimer;
  List<VenueZone> _zones = [];
  int _currentGameMinute = 0;

  List<VenueZone> get zones => List.unmodifiable(_zones);
  List<VenueZone> get hotZones =>
      _zones.where((z) => z.density == DensityLevel.high || z.density == DensityLevel.critical).toList();
  List<VenueZone> get coldZones =>
      _zones.where((z) => z.density == DensityLevel.empty || z.density == DensityLevel.low).toList();

  VenueZone? zoneById(String id) {
    try {
      return _zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Best timing window — finds the zone with lowest predicted density
  String get bestTimingWindow {
    if (_currentGameMinute < 40) {
      final untilHalf = 45 - _currentGameMinute;
      return '${untilHalf}min to halftime';
    }
    return 'Now — concourses clearing';
  }

  int get bestTimingMinute {
    if (_currentGameMinute < 40) return 45;
    return _currentGameMinute + 2;
  }

  void initialize() {
    _zones = List.from(MockData.venueZones);
    notifyListeners();
  }

  void startSimulation() {
    // Refresh density every 3 seconds (simulating the 8s real-world refresh)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshDensity());
  }

  void updateGameMinute(int minute) {
    _currentGameMinute = minute;
  }

  /// Apply a surge to concession zones (after a goal)
  void applyGoalSurge() {
    _zones = _zones.map((zone) {
      // Food courts and concourses surge after goals
      if (zone.name.contains('Food') || zone.name.contains('Concourse')) {
        final surgeCount = (zone.estimatedCount * 1.4).round().clamp(0, zone.capacity);
        return zone.copyWith(
          estimatedCount: surgeCount,
          density: _densityFromCount(surgeCount, zone.capacity),
          percentile: surgeCount / zone.capacity,
        );
      }
      return zone;
    }).toList();
    notifyListeners();
  }

  /// Apply halftime pattern — massive surge to concessions
  void applyHalfTimeSurge() {
    _zones = _zones.map((zone) {
      if (zone.name.contains('Food') || zone.name.contains('Concourse')) {
        final surgeCount = (zone.capacity * 0.85).round();
        return zone.copyWith(
          estimatedCount: surgeCount,
          density: DensityLevel.critical,
          percentile: surgeCount / zone.capacity,
        );
      }
      // Seating sections drop
      if (zone.name.contains('Sec')) {
        final dropCount = (zone.estimatedCount * 0.6).round();
        return zone.copyWith(
          estimatedCount: dropCount,
          density: _densityFromCount(dropCount, zone.capacity),
          percentile: dropCount / zone.capacity,
        );
      }
      return zone;
    }).toList();
    notifyListeners();
  }

  /// Apply exit surge pattern (85th+ minute)
  void applyExitSurge() {
    _zones = _zones.map((zone) {
      if (zone.name.contains('Gate')) {
        final surgeCount = (zone.capacity * 0.9).round();
        return zone.copyWith(
          estimatedCount: surgeCount,
          density: DensityLevel.critical,
          percentile: 0.95,
        );
      }
      return zone;
    }).toList();
    notifyListeners();
  }

  void _refreshDensity() {
    _zones = _zones.map((zone) {
      // Natural drift: ±5-15% random fluctuation
      final driftFactor = 1.0 + (_rng.nextDouble() * 0.2 - 0.1); // 0.9 to 1.1
      int newCount = (zone.estimatedCount * driftFactor).round();

      // Time-based patterns
      if (_currentGameMinute >= 85 && zone.name.contains('Gate')) {
        // Exit surge
        newCount = (newCount * 1.08).round();
      } else if (_currentGameMinute >= 40 && _currentGameMinute <= 50 &&
          (zone.name.contains('Food') || zone.name.contains('Concourse'))) {
        // Halftime vicinity surge
        newCount = (newCount * 1.05).round();
      }

      newCount = newCount.clamp(20, zone.capacity);
      final newDensity = _densityFromCount(newCount, zone.capacity);
      final newPercentile = newCount / zone.capacity;

      return zone.copyWith(
        estimatedCount: newCount,
        density: newDensity,
        percentile: newPercentile,
      );
    }).toList();

    notifyListeners();
  }

  DensityLevel _densityFromCount(int count, int capacity) {
    final ratio = count / capacity;
    if (ratio < 0.15) return DensityLevel.empty;
    if (ratio < 0.35) return DensityLevel.low;
    if (ratio < 0.55) return DensityLevel.moderate;
    if (ratio < 0.75) return DensityLevel.high;
    return DensityLevel.critical;
  }

  /// Calculate lowest-congestion route from current zone to target
  List<String> calculateRoute(String fromZoneId, String toZoneId) {
    // Simple: find path through zones with lowest density
    final sortedZones = List<VenueZone>.from(_zones)
      ..sort((a, b) => a.estimatedCount.compareTo(b.estimatedCount));
    // Return the 3 least congested zones as waypoints
    return [
      fromZoneId,
      ...sortedZones.take(2).map((z) => z.id),
      toZoneId,
    ];
  }

  double estimateWalkMinutes(String fromZoneId, String toZoneId) {
    final fromZone = zoneById(fromZoneId);
    final toZone = zoneById(toZoneId);
    if (fromZone == null || toZone == null) return 3.0;

    // Base time + congestion penalty
    double baseMinutes = 2.0;
    final avgDensity = (fromZone.estimatedCount + toZone.estimatedCount) / 2;
    final congestionPenalty = (avgDensity / 1200) * 3.0; // up to 3 min extra
    return baseMinutes + congestionPenalty;
  }

  void stopSimulation() {
    _refreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}
