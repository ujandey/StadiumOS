import '../models/models.dart';

/// Seed data for initializing providers. Not used directly by screens.
class MockData {
  static const List<VenueZone> venueZones = [
    VenueZone(id: 'A', name: 'Gate A', density: DensityLevel.high, estimatedCount: 820, capacity: 1200),
    VenueZone(id: 'B', name: 'Gate B', density: DensityLevel.low, estimatedCount: 210, capacity: 1200),
    VenueZone(id: 'C', name: 'North Stand', density: DensityLevel.moderate, estimatedCount: 480, capacity: 1200),
    VenueZone(id: 'D', name: 'South Stand', density: DensityLevel.low, estimatedCount: 190, capacity: 1200),
    VenueZone(id: 'E', name: 'East End', density: DensityLevel.critical, estimatedCount: 1100, capacity: 1200),
    VenueZone(id: 'F', name: 'West End', density: DensityLevel.moderate, estimatedCount: 560, capacity: 1200),
    VenueZone(id: 'G', name: 'Concourse N', density: DensityLevel.empty, estimatedCount: 80, capacity: 800),
    VenueZone(id: 'H', name: 'Concourse S', density: DensityLevel.high, estimatedCount: 740, capacity: 1000),
    VenueZone(id: '1', name: 'Sec 112', density: DensityLevel.low, estimatedCount: 155, capacity: 800),
    VenueZone(id: '2', name: 'Sec 114', density: DensityLevel.moderate, estimatedCount: 410, capacity: 800),
    VenueZone(id: '3', name: 'Sec 116', density: DensityLevel.high, estimatedCount: 710, capacity: 1000),
    VenueZone(id: '4', name: 'Sec 118', density: DensityLevel.critical, estimatedCount: 980, capacity: 1200),
    VenueZone(id: '5', name: 'Food Court A', density: DensityLevel.low, estimatedCount: 120, capacity: 600),
    VenueZone(id: '6', name: 'Food Court B', density: DensityLevel.moderate, estimatedCount: 430, capacity: 600),
    VenueZone(id: 'I', name: 'Sec 120', density: DensityLevel.moderate, estimatedCount: 520, capacity: 1000),
    VenueZone(id: 'J', name: 'Sec 122', density: DensityLevel.low, estimatedCount: 280, capacity: 800),
    VenueZone(id: 'K', name: 'Gate C', density: DensityLevel.moderate, estimatedCount: 450, capacity: 1200),
    VenueZone(id: 'L', name: 'Gate D', density: DensityLevel.empty, estimatedCount: 90, capacity: 1200),
  ];
}
