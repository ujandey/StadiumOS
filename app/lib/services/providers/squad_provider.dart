import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';

class SquadProvider extends ChangeNotifier {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SquadMember> _members = [];
  SquadProposal? _activeProposal;
  final String _joinCode = 'XK3A7M'; // In real app, this is dynamic

  StreamSubscription? _membersSub;
  StreamSubscription? _proposalSub;

  List<SquadMember> get members => List.unmodifiable(_members);
  SquadProposal? get activeProposal => _activeProposal;
  String get joinCode => _joinCode;

  SquadMember? get me {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    try { return _members.firstWhere((m) => m.id == uid); }
    catch (_) { return null; }
  }

  void initialize() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Join the squad node in RTDB
    final myRef = _rtdb.ref('squads/$_joinCode/members/$uid');
    myRef.set({
      'name': 'You', // Would come from profile
      'initials': 'U',
      'location': 'Sec 114, Row C',
      'status': IntentStatus.atSeat.name,
      'targetZoneId': '2',
      'lastUpdate': ServerValue.timestamp,
    });

    // Handle disconnects to remove self or mark offline
    myRef.child('status').onDisconnect().set('offline');

    _listenToMembers();
    _listenToProposals();
  }

  void _listenToMembers() {
    _membersSub?.cancel();
    _membersSub = _rtdb.ref('squads/$_joinCode/members').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final uid = _auth.currentUser?.uid;
      final newMembers = <SquadMember>[];

      data.forEach((key, value) {
        final id = key.toString();
        final map = value as Map<dynamic, dynamic>;
        
        IntentStatus status;
        try {
          status = IntentStatus.values.byName(map['status'] ?? 'atSeat');
        } catch (_) {
          status = IntentStatus.atSeat;
        }

        newMembers.add(SquadMember(
          id: id,
          name: map['name'] ?? 'Unknown',
          initials: map['initials'] ?? '?',
          location: map['location'] ?? 'Unknown',
          status: status,
          targetZoneId: map['targetZoneId'] ?? '2',
          isMe: id == uid,
        ));
      });

      _members = newMembers;
      notifyListeners();
    });
  }

  void _listenToProposals() {
    _proposalSub?.cancel();
    _proposalSub = _rtdb.ref('squads/$_joinCode/activeProposal').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        _activeProposal = null;
      } else {
        final agreed = (data['agreedMemberIds'] as Map<dynamic, dynamic>?)?.keys.map((e) => e.toString()).toSet() ?? {};
        _activeProposal = SquadProposal(
          id: event.snapshot.key ?? 'p1',
          proposer: data['proposer'] ?? 'Unknown',
          destination: data['destination'] ?? 'Unknown',
          agreeCount: agreed.length,
          totalCount: _members.length,
          agreedMemberIds: agreed,
          isResolved: data['isResolved'] ?? false,
        );
      }
      notifyListeners();
    });
  }

  void startSimulation() { 
    // In Phase 2, we no longer simulate! The RTDB handles real sync.
  }

  void setMyStatus(IntentStatus status) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    String loc;
    switch (status) {
      case IntentStatus.atSeat: loc = 'Sec 114, Row C'; break;
      case IntentStatus.headingFood: loc = 'Heading to food'; break;
      case IntentStatus.bathroom: loc = 'Heading to bathroom'; break;
      case IntentStatus.leavingEarly: loc = 'Heading to exit'; break;
      case IntentStatus.onRoute: loc = 'On route'; break;
    }

    _rtdb.ref('squads/$_joinCode/members/$uid').update({
      'status': status.name,
      'location': loc,
      'lastUpdate': ServerValue.timestamp,
    });
  }

  void voteOnProposal(bool agree) {
    if (_activeProposal == null || _activeProposal!.isResolved) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final proposalRef = _rtdb.ref('squads/$_joinCode/activeProposal');
    
    if (agree) {
      proposalRef.child('agreedMemberIds/$uid').set(true);
    } else {
      proposalRef.child('agreedMemberIds/$uid').remove();
    }

    // Check resolution logic in a Cloud Function ideally, but for now we do it client-side
    final newAgreeCount = agree ? _activeProposal!.agreeCount + 1 : _activeProposal!.agreeCount - 1;
    if (newAgreeCount > _activeProposal!.totalCount / 2) {
      proposalRef.update({'isResolved': true});
    }
  }

  void dismissProposal() {
    final proposalRef = _rtdb.ref('squads/$_joinCode/activeProposal');
    proposalRef.update({'isResolved': true});
  }

  void stopSimulation() {}

  @override
  void dispose() {
    _membersSub?.cancel();
    _proposalSub?.cancel();
    super.dispose();
  }
}
