import 'package:latlong2/latlong.dart';
import 'dart:math';

/// Represents a complete route path with waypoints
class RoutePath {
  final String routeName;
  final List<LatLng> waypoints;
  final bool isCircular;

  RoutePath({
    required this.routeName,
    required this.waypoints,
    this.isCircular = false,
  });

  /// Get total distance of the route in meters
  double getTotalDistance() {
    double total = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      total += _calculateDistance(waypoints[i], waypoints[i + 1]);
    }
    return total;
  }

  /// Get distance from start to a specific waypoint index
  double getDistanceToWaypoint(int waypointIndex) {
    double total = 0;
    for (int i = 0; i < min(waypointIndex, waypoints.length - 1); i++) {
      total += _calculateDistance(waypoints[i], waypoints[i + 1]);
    }
    return total;
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

  /// Find the closest waypoint to a given position
  int findClosestWaypoint(LatLng position) {
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < waypoints.length; i++) {
      final distance = _calculateDistance(position, waypoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Get the bearing (heading) from one point to another in degrees
  double getBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;

    // Normalize to 0-360
    return (bearing + 360) % 360;
  }

  /// Interpolate position between two waypoints
  /// [progress] should be between 0.0 and 1.0
  LatLng interpolate(int fromIndex, int toIndex, double progress) {
    if (fromIndex >= waypoints.length || toIndex >= waypoints.length) {
      return waypoints.last;
    }

    final from = waypoints[fromIndex];
    final to = waypoints[toIndex];

    final lat = from.latitude + (to.latitude - from.latitude) * progress;
    final lon = from.longitude + (to.longitude - from.longitude) * progress;

    return LatLng(lat, lon);
  }
}

/// Represents a segment of a route between two waypoints
class RouteSegment {
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final double bearingDegrees;

  RouteSegment({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.bearingDegrees,
  });

  factory RouteSegment.fromWaypoints(LatLng start, LatLng end) {
    final path = RoutePath(
      routeName: 'temp',
      waypoints: [start, end],
    );

    return RouteSegment(
      start: start,
      end: end,
      distanceMeters: path._calculateDistance(start, end),
      bearingDegrees: path.getBearing(start, end),
    );
  }
}
