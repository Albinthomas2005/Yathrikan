import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_path_model.dart';

/// Service to fetch actual road routes from OpenStreetMap using OSRM API
class OSRMRoutingService {
  // Using the public OSRM demo server
  // For production, consider hosting your own OSRM instance
  static const String _baseUrl = 'https://router.project-osrm.org';

  // Cache to store fetched routes and avoid redundant API calls
  static final Map<String, RoutePath> _routeCache = {};

  /// Fetch a route between two points that follows actual roads
  /// Returns null if the API call fails
  static Future<RoutePath?> fetchRoute({
    required LatLng start,
    required LatLng end,
    required String routeName,
    bool useCache = true,
  }) async {
    // Create cache key
    final cacheKey =
        '${start.latitude},${start.longitude}-${end.latitude},${end.longitude}';

    // Check cache first
    if (useCache && _routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }

    try {
      // Build OSRM API URL
      // Format: /route/v1/{profile}/{coordinates}?overview=full&geometries=geojson
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );

      // Make API request
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('OSRM API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract waypoints from the route geometry
        final waypoints = _parseOSRMResponse(data);

        if (waypoints.isEmpty) {
          return null;
        }

        // Create RoutePath from waypoints
        final routePath = RoutePath(
          routeName: routeName,
          waypoints: waypoints,
        );

        // Cache the route
        _routeCache[cacheKey] = routePath;

        return routePath;
      } else {
        debugPrint('OSRM API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching route from OSRM: $e');
      return null;
    }
  }

  /// Parse OSRM API response and extract waypoints
  static List<LatLng> _parseOSRMResponse(Map<String, dynamic> data) {
    try {
      final routes = data['routes'] as List;
      if (routes.isEmpty) return [];

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;

      // Convert coordinates to LatLng
      // OSRM returns [longitude, latitude] format
      return coordinates.map((coord) {
        return LatLng(
          (coord[1] as num).toDouble(), // latitude
          (coord[0] as num).toDouble(), // longitude
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing OSRM response: $e');
      return [];
    }
  }

  /// Fetch route with multiple waypoints (for complex routes)
  static Future<RoutePath?> fetchRouteWithWaypoints({
    required List<LatLng> waypoints,
    required String routeName,
    bool useCache = true,
  }) async {
    if (waypoints.length < 2) return null;

    // Build coordinates string
    final coords =
        waypoints.map((wp) => '${wp.longitude},${wp.latitude}').join(';');
    final cacheKey = coords;

    // Check cache
    if (useCache && _routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey];
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/$coords'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('OSRM API request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routeWaypoints = _parseOSRMResponse(data);

        if (routeWaypoints.isEmpty) return null;

        final routePath = RoutePath(
          routeName: routeName,
          waypoints: routeWaypoints,
        );

        _routeCache[cacheKey] = routePath;
        return routePath;
      }
    } catch (e) {
      debugPrint('Error fetching multi-waypoint route: $e');
    }

    return null;
  }

  /// Clear the route cache
  static void clearCache() {
    _routeCache.clear();
  }

  /// Get cache size
  static int getCacheSize() {
    return _routeCache.length;
  }

  /// Extract intermediate waypoints from a route for better path control
  /// This simplifies very detailed routes to fewer waypoints
  static List<LatLng> simplifyRoute(List<LatLng> waypoints, int targetCount) {
    if (waypoints.length <= targetCount) return waypoints;

    List<LatLng> simplified = [waypoints.first];
    final step = (waypoints.length - 1) / (targetCount - 1);

    for (int i = 1; i < targetCount - 1; i++) {
      final index = (step * i).round();
      simplified.add(waypoints[index]);
    }

    simplified.add(waypoints.last);
    return simplified;
  }
}
