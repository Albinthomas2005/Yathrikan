import 'dart:math';

class LiveBus {
  final String busId;
  final String routeName;
  double lat;
  double lon;
  final double speedKmph;
  final double headingDeg;
  final DateTime lastUpdated;
  final String status;

  LiveBus({
    required this.busId,
    required this.routeName,
    required this.lat,
    required this.lon,
    required this.speedKmph,
    required this.headingDeg,
    required this.lastUpdated,
    required this.status,
  });

  factory LiveBus.fromJson(Map<String, dynamic> json) {
    return LiveBus(
      busId: json['busId'] as String,
      routeName: json['routeName'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      speedKmph: (json['speedKmph'] as num).toDouble(),
      headingDeg: (json['headingDeg'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'routeName': routeName,
      'lat': lat,
      'lon': lon,
      'speedKmph': speedKmph,
      'headingDeg': headingDeg,
      'lastUpdated': lastUpdated.toIso8601String(),
      'status': status,
    };
  }

  /// Simulates bus movement based on speed and heading
  /// Returns a new LiveBus object with updated position
  LiveBus simulateMovement(int secondsElapsed) {
    // Convert speed from km/h to m/s
    final speedMs = speedKmph * 1000 / 3600;

    // Distance traveled in meters
    final distanceM = speedMs * secondsElapsed;

    // Add slight random variation (±10%) for realism
    final random = Random();
    final variation = 0.9 + random.nextDouble() * 0.2; // 0.9 to 1.1
    final actualDistance = distanceM * variation;

    // Convert heading to radians
    final headingRad = headingDeg * pi / 180;

    // Calculate change in latitude and longitude
    // 1 degree latitude ≈ 111,000 meters
    // 1 degree longitude ≈ 111,000 * cos(latitude) meters
    final deltaLat = (actualDistance * cos(headingRad)) / 111000;
    final deltaLon =
        (actualDistance * sin(headingRad)) / (111000 * cos(lat * pi / 180));

    // Calculate new position
    final newLat = lat + deltaLat;
    final newLon = lon + deltaLon;

    // Create new bus with updated position
    return LiveBus(
      busId: busId,
      routeName: routeName,
      lat: newLat,
      lon: newLon,
      speedKmph: speedKmph,
      headingDeg: headingDeg,
      lastUpdated: DateTime.now(),
      status: status,
    );
  }

  LiveBus copyWith({
    String? busId,
    String? routeName,
    double? lat,
    double? lon,
    double? speedKmph,
    double? headingDeg,
    DateTime? lastUpdated,
    String? status,
  }) {
    return LiveBus(
      busId: busId ?? this.busId,
      routeName: routeName ?? this.routeName,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      speedKmph: speedKmph ?? this.speedKmph,
      headingDeg: headingDeg ?? this.headingDeg,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }
}
