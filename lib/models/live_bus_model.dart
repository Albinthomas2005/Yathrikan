import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'route_path_model.dart';

class LiveBus {
  final String busId;
  final String routeName;
  double lat;
  double lon;
  final double speedKmph;
  double headingDeg;
  final DateTime lastUpdated;
  final String status;
  final int etaMin; // Newly added field

  // New fields for waypoint-based movement
  RoutePath? routePath;
  int currentWaypointIndex;
  double progressInSegment; // 0.0 to 1.0

  LiveBus({
    required this.busId,
    required this.routeName,
    required this.lat,
    required this.lon,
    required this.speedKmph,
    required this.headingDeg,
    required this.lastUpdated,
    required this.status,
    this.etaMin = 0, // Default to 0 if not provided
    this.routePath,
    this.currentWaypointIndex = 0,
    this.progressInSegment = 0.0,
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
      etaMin: json['etaMin'] != null ? (json['etaMin'] as num).toInt() : 0,
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
      'etaMin': etaMin,
    };
  }

  /// Simulates bus movement along predefined route waypoints
  /// Returns a new LiveBus object with updated position
  LiveBus simulateMovement(int secondsElapsed) {
    // If status is IDLE, do not move
    if (status == 'IDLE') {
      return this;
    }

    // If no route path is defined, fall back to simple movement
    if (routePath == null || routePath!.waypoints.length < 2) {
      return _simulateSimpleMovement(secondsElapsed);
    }

    // Convert speed from km/h to m/s
    final speedMs = speedKmph * 1000 / 3600;

    // Distance to travel in meters
    final distanceToTravel = speedMs * secondsElapsed;

    // Add slight random variation (±10%) for realism
    final random = Random();
    final variation = 0.9 + random.nextDouble() * 0.2; // 0.9 to 1.1
    final actualDistance = distanceToTravel * variation;

    return _moveAlongPath(actualDistance);
  }

  /// Move bus along its route path by the specified distance
  LiveBus _moveAlongPath(double distanceMeters) {
    if (routePath == null || routePath!.waypoints.isEmpty) {
      return this;
    }

    int newWaypointIndex = currentWaypointIndex;
    double newProgress = progressInSegment;
    double remainingDistance = distanceMeters;

    // Keep moving until we've covered the required distance
    while (remainingDistance > 0 &&
        newWaypointIndex < routePath!.waypoints.length - 1) {
      final fromPoint = routePath!.waypoints[newWaypointIndex];
      final toPoint = routePath!.waypoints[newWaypointIndex + 1];

      // Calculate segment distance
      final segmentDistance = _calculateDistance(fromPoint, toPoint);

      // How far are we already in this segment?
      final alreadyTraveled = segmentDistance * newProgress;

      // How much of this segment is left?
      final segmentRemaining = segmentDistance - alreadyTraveled;

      if (remainingDistance >= segmentRemaining) {
        // We'll complete this segment and move to the next
        remainingDistance -= segmentRemaining;
        newWaypointIndex++;
        newProgress = 0.0;

        // Check if we've completed the route
        if (newWaypointIndex >= routePath!.waypoints.length - 1) {
          // If circular, loop back to start
          if (routePath!.isCircular) {
            newWaypointIndex = 0;
            newProgress = 0.0;
          } else {
            // Stay at the end
            newWaypointIndex = routePath!.waypoints.length - 2;
            newProgress = 1.0;
          }
          break;
        }
      } else {
        // We'll stop somewhere in this segment
        newProgress += (remainingDistance / segmentDistance);
        remainingDistance = 0;
      }
    }

    // Calculate new position by interpolating between waypoints
    final newPosition = routePath!.interpolate(
      newWaypointIndex,
      min(newWaypointIndex + 1, routePath!.waypoints.length - 1),
      newProgress,
    );

    // Calculate heading to next waypoint
    double newHeading = headingDeg;
    if (newWaypointIndex < routePath!.waypoints.length - 1) {
      final fromPoint = routePath!.waypoints[newWaypointIndex];
      final toPoint = routePath!.waypoints[newWaypointIndex + 1];
      newHeading = routePath!.getBearing(fromPoint, toPoint);
    }

    // Create new bus with updated position
    return LiveBus(
      busId: busId,
      routeName: routeName,
      lat: newPosition.latitude,
      lon: newPosition.longitude,
      speedKmph: speedKmph,
      headingDeg: newHeading,
      lastUpdated: DateTime.now(),
      status: status,
      etaMin: etaMin, // Persist ETA
      routePath: routePath,
      currentWaypointIndex: newWaypointIndex,
      progressInSegment: newProgress,
    );
  }

  /// Fallback: Simulates bus movement based on speed and heading (old method)
  LiveBus _simulateSimpleMovement(int secondsElapsed) {
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
      etaMin: etaMin, // Persist ETA
      routePath: routePath,
      currentWaypointIndex: currentWaypointIndex,
      progressInSegment: progressInSegment,
    );
  }

  /// Calculate distance between two points in meters using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
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
    int? etaMin,
    RoutePath? routePath,
    int? currentWaypointIndex,
    double? progressInSegment,
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
      etaMin: etaMin ?? this.etaMin,
      routePath: routePath ?? this.routePath,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      progressInSegment: progressInSegment ?? this.progressInSegment,
    );
  }
}
