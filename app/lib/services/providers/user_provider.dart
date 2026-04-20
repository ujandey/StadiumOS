import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isOnboarded = false;
  bool _accessibilityMode = false;
  bool _alertsFood = true;
  bool _alertsTiming = true;
  bool _alertsExit = true;
  bool _alertsView = true;

  SeatInfo _seatInfo = const SeatInfo(
    section: '114', row: 'C', seat: '18', gate: 'A', stand: 'East Stand',
  );

  bool get isOnboarded => _isOnboarded;
  bool get accessibilityMode => _accessibilityMode;
  bool get alertsFood => _alertsFood;
  bool get alertsTiming => _alertsTiming;
  bool get alertsExit => _alertsExit;
  bool get alertsView => _alertsView;
  SeatInfo get seatInfo => _seatInfo;
  String? get uid => _auth.currentUser?.uid;

  Future<void> loadPreferences() async {
    // We still use SharedPreferences for the initial "has seen onboarding" flag 
    // so we don't flash the onboarding screen if they've already logged in.
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('isOnboarded') ?? false;

    if (_isOnboarded && _auth.currentUser != null) {
      // Load their cloud preferences
      await _fetchProfileFromCloud();
    }
    notifyListeners();
  }

  Future<void> _fetchProfileFromCloud() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('fans').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _accessibilityMode = data['accessibilityMode'] ?? false;
        
        final alerts = data['alerts'] as Map<String, dynamic>? ?? {};
        _alertsFood = alerts['food'] ?? true;
        _alertsTiming = alerts['timing'] ?? true;
        _alertsExit = alerts['exit'] ?? true;
        _alertsView = alerts['view'] ?? true;
        
        // In a real app we'd load seat data here too
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> completeOnboarding() async {
    try {
      // 1. Sign in anonymously
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }

      // 2. Create the default fan profile in Firestore
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('fans').doc(uid).set({
        'createdAt': FieldValue.serverTimestamp(),
        'accessibilityMode': _accessibilityMode,
        'alerts': {
          'food': _alertsFood,
          'timing': _alertsTiming,
          'exit': _alertsExit,
          'view': _alertsView,
        },
        'seat': {
          'section': _seatInfo.section,
          'row': _seatInfo.row,
          'seat': _seatInfo.seat,
          'gate': _seatInfo.gate,
          'stand': _seatInfo.stand,
        }
      });

      // 3. Mark as onboarded locally
      _isOnboarded = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnboarded', true);
      
      // 4. Subscribe to Push Notification topic for this user
      try {
        await FirebaseMessaging.instance.subscribeToTopic('user_$uid');
      } catch (e) {
        debugPrint('Error subscribing to FCM topic: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  Future<void> setAccessibilityMode(bool value) async {
    _accessibilityMode = value;
    notifyListeners();
    
    if (uid != null) {
      await _firestore.collection('fans').doc(uid).update({
        'accessibilityMode': value,
      });
    }
  }

  Future<void> setAlertPref(String key, bool value) async {
    switch (key) {
      case 'food': _alertsFood = value;
      case 'timing': _alertsTiming = value;
      case 'exit': _alertsExit = value;
      case 'view': _alertsView = value;
    }
    notifyListeners();

    if (uid != null) {
      await _firestore.collection('fans').doc(uid).update({
        'alerts.$key': value,
      });
    }
  }

  void updateSeat(SeatInfo info) {
    _seatInfo = info;
    notifyListeners();
    
    if (uid != null) {
      _firestore.collection('fans').doc(uid).update({
        'seat.section': info.section,
        'seat.row': info.row,
        'seat.seat': info.seat,
        'seat.gate': info.gate,
        'seat.stand': info.stand,
      });
    }
  }
}
