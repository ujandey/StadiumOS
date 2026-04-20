// Data models for StadiumOS

enum AlertType { food, timing, exit, view, goal, group }
enum DensityLevel { empty, low, moderate, high, critical }
enum IntentStatus { atSeat, headingFood, bathroom, leavingEarly, onRoute }

class PulseAlert {
  final String id;
  final AlertType type;
  final String message;
  final String timeAgo;
  final bool isDismissed;
  final DateTime timestamp;

  const PulseAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.timeAgo,
    this.isDismissed = false,
    required this.timestamp,
  });

  PulseAlert copyWith({
    String? id,
    AlertType? type,
    String? message,
    String? timeAgo,
    bool? isDismissed,
    DateTime? timestamp,
  }) {
    return PulseAlert(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      isDismissed: isDismissed ?? this.isDismissed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Compute a human-readable time-ago string from timestamp
  String get computedTimeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 30) return 'now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}

class SquadMember {
  final String id;
  final String name;
  final String initials;
  final String location;
  final IntentStatus status;
  final bool isMe;
  final String? targetZoneId;

  const SquadMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.location,
    required this.status,
    this.isMe = false,
    this.targetZoneId,
  });

  SquadMember copyWith({
    String? id,
    String? name,
    String? initials,
    String? location,
    IntentStatus? status,
    bool? isMe,
    String? targetZoneId,
  }) {
    return SquadMember(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      location: location ?? this.location,
      status: status ?? this.status,
      isMe: isMe ?? this.isMe,
      targetZoneId: targetZoneId ?? this.targetZoneId,
    );
  }
}

class VenueZone {
  final String id;
  final String name;
  final DensityLevel density;
  final int estimatedCount;
  final int capacity;
  final double percentile;

  const VenueZone({
    required this.id,
    required this.name,
    required this.density,
    required this.estimatedCount,
    this.capacity = 1200,
    this.percentile = 0.0,
  });

  VenueZone copyWith({
    String? id,
    String? name,
    DensityLevel? density,
    int? estimatedCount,
    int? capacity,
    double? percentile,
  }) {
    return VenueZone(
      id: id ?? this.id,
      name: name ?? this.name,
      density: density ?? this.density,
      estimatedCount: estimatedCount ?? this.estimatedCount,
      capacity: capacity ?? this.capacity,
      percentile: percentile ?? this.percentile,
    );
  }

  double get occupancyRatio => estimatedCount / capacity;
}

class GameState {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String clock;
  final bool isLive;
  final int clockMinute;
  final bool isHalfTime;

  const GameState({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.clock,
    required this.isLive,
    this.clockMinute = 0,
    this.isHalfTime = false,
  });

  GameState copyWith({
    String? homeTeam,
    String? awayTeam,
    int? homeScore,
    int? awayScore,
    String? clock,
    bool? isLive,
    int? clockMinute,
    bool? isHalfTime,
  }) {
    return GameState(
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      clock: clock ?? this.clock,
      isLive: isLive ?? this.isLive,
      clockMinute: clockMinute ?? this.clockMinute,
      isHalfTime: isHalfTime ?? this.isHalfTime,
    );
  }

  bool get isFullTime => clockMinute >= 90;
}

class SquadProposal {
  final String id;
  final String proposer;
  final String destination;
  final int agreeCount;
  final int totalCount;
  final Set<String> agreedMemberIds;
  final bool isResolved;

  const SquadProposal({
    required this.id,
    required this.proposer,
    required this.destination,
    required this.agreeCount,
    required this.totalCount,
    this.agreedMemberIds = const {},
    this.isResolved = false,
  });

  SquadProposal copyWith({
    String? id,
    String? proposer,
    String? destination,
    int? agreeCount,
    int? totalCount,
    Set<String>? agreedMemberIds,
    bool? isResolved,
  }) {
    return SquadProposal(
      id: id ?? this.id,
      proposer: proposer ?? this.proposer,
      destination: destination ?? this.destination,
      agreeCount: agreeCount ?? this.agreeCount,
      totalCount: totalCount ?? this.totalCount,
      agreedMemberIds: agreedMemberIds ?? this.agreedMemberIds,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  bool get hasMajority => agreeCount > totalCount / 2;
}

class RouteSegment {
  final String fromZoneId;
  final String toZoneId;
  final double estimatedMinutes;
  final bool isAccessible;

  const RouteSegment({
    required this.fromZoneId,
    required this.toZoneId,
    required this.estimatedMinutes,
    this.isAccessible = true,
  });
}

class SeatInfo {
  final String section;
  final String row;
  final String seat;
  final String gate;
  final String stand;

  const SeatInfo({
    required this.section,
    required this.row,
    required this.seat,
    required this.gate,
    required this.stand,
  });

  String get display => 'Section $section, Row $row, Seat $seat';
  String get gateDisplay => 'Gate $gate — $stand';
}
