import 'dart:convert';
import 'package:flutter/services.dart';

/// A scheduled bus result from the Kerala district JSON files.
class ScheduledBus {
  final String vehicleNumber;
  final String district;
  final List<String> route;
  final String originStation;
  final String destinationStation;
  final String departureTime;
  final String arrivalTime;
  final int stopsBetween;

  const ScheduledBus({
    required this.vehicleNumber,
    required this.district,
    required this.route,
    required this.originStation,
    required this.destinationStation,
    required this.departureTime,
    required this.arrivalTime,
    required this.stopsBetween,
  });
}

/// Loads all 14 Kerala district JSON files and provides:
///  - [allStations]   – de-duped list of every stop name across all files
///  - [findBuses]     – returns upcoming buses between two stops
class KeralaScheduleService {
  static final KeralaScheduleService _instance =
      KeralaScheduleService._internal();
  factory KeralaScheduleService() => _instance;
  KeralaScheduleService._internal();

  bool _loaded = false;

  // Map from station name (upper-case) → display name
  final Map<String, String> _stationMap = {};

  // All parsed buses: list of {vehicleNumber, district, route, schedule}
  final List<Map<String, dynamic>> _allBuses = [];

  static const _districtFiles = [
    'alappuzha',
    'attingal',
    'ernakulam',
    'idukki',
    'kannur',
    'kottayam',
    'kozhikkode',
    'malappuram',
    'muvattupuzha',
    'palakkad-1',
    'palakkad-2',
    'pathanamthitta',
    'vadakara',
    'wayanad',
  ];

  /// Call once at app start (or lazily before first use).
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    for (final district in _districtFiles) {
      try {
        final raw =
            await rootBundle.loadString('assets/data/$district.json');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final buses = data['busSchedules'] as List<dynamic>;

        for (final bus in buses) {
          final route = List<String>.from(bus['route'] as List);
          final vehicleNumber = bus['Vehicle Number'] as String;
          final schedule = bus['schedule'] as List<dynamic>;

          // Register every stop in the station map
          for (final stop in route) {
            _stationMap[stop.toUpperCase()] = stop;
          }

          // Also collect all inline station names from schedule trips
          for (final trip in schedule) {
            final stations = trip['stations'] as List<dynamic>;
            for (final s in stations) {
              final name = s['station'] as String;
              _stationMap[name.toUpperCase()] = name;
            }
          }

          _allBuses.add({
            'vehicleNumber': vehicleNumber,
            'district': district,
            'route': route,
            'schedule': schedule,
          });
        }
      } catch (_) {
        // Skip files that fail to load silently
      }
    }
  }


  /// All unique station names (title-cased from JSON).
  List<String> get allStations => _stationMap.values.toList()
    ..sort();

  /// Find buses whose route includes both [from] and [to] (case-insensitive).
  /// Returns up to [limit] results sorted by proximity to current time.
  List<ScheduledBus> findBuses(String from, String to, {int limit = 20}) {
    if (!_loaded || from.trim().isEmpty || to.trim().isEmpty) return [];

    final fromUpper = from.trim().toUpperCase();
    final toUpper = to.trim().toUpperCase();

    final results = <ScheduledBus>[];
    final now = DateTime.now();

    for (final bus in _allBuses) {
      final route = bus['route'] as List<String>;
      final routeUpper = route.map((s) => s.toUpperCase()).toList();

      // Check if both stops are in this bus route
      final fromIdx = routeUpper.indexWhere((s) => s.contains(fromUpper) || fromUpper.contains(s));
      final toIdx = routeUpper.indexWhere((s) => s.contains(toUpper) || toUpper.contains(s));

      if (fromIdx == -1 || toIdx == -1) continue;

      // Find the next upcoming trip that passes through both stops in order
      final schedule = bus['schedule'] as List<dynamic>;
      for (final trip in schedule) {
        final stations = trip['stations'] as List<dynamic>;
        final stationNames = stations
            .map((s) => (s['station'] as String).toUpperCase())
            .toList();

        final tripFromIdx = stationNames.indexWhere(
            (s) => s.contains(fromUpper) || fromUpper.contains(s));
        final tripToIdx = stationNames.indexWhere(
            (s) => s.contains(toUpper) || toUpper.contains(s));

        // Must both be present AND in the right order
        if (tripFromIdx == -1 || tripToIdx == -1 || tripFromIdx >= tripToIdx) {
          continue;
        }

        final depTimeStr =
            stations[tripFromIdx]['departureTime'] as String? ?? '';
        final arrTimeStr =
            stations[tripToIdx]['arrivalTime'] as String? ?? '';

        // Parse time to check if it's upcoming
        final depTime = _parseTime(depTimeStr, now);
        if (depTime == null) continue;

        results.add(ScheduledBus(
          vehicleNumber: bus['vehicleNumber'] as String,
          district: bus['district'] as String,
          route: route,
          originStation: stations[tripFromIdx]['station'] as String,
          destinationStation: stations[tripToIdx]['station'] as String,
          departureTime: depTimeStr,
          arrivalTime: arrTimeStr,
          stopsBetween: tripToIdx - tripFromIdx - 1,
        ));
      }
    }

    // Sort by departure time proximity to now
    results.sort((a, b) {
      final tA = _parseTime(a.departureTime, now);
      final tB = _parseTime(b.departureTime, now);
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tA.compareTo(tB);
    });

    return results.take(limit).toList();
  }

  /// Parse a time string like "06:20 am" or "01:35 pm" into today's DateTime.
  DateTime? _parseTime(String timeStr, DateTime now) {
    try {
      final parts = timeStr.trim().toLowerCase().split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final bool isPm = parts[1] == 'pm';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      // If time already passed today, consider it for tomorrow
      return dt.isBefore(now) ? dt.add(const Duration(days: 1)) : dt;
    } catch (_) {
      return null;
    }
  }

  /// Estimate price based on number of stops.
  double estimatePrice(int stops) {
    return 10.0 + stops * 5.0;
  }

  /// Duration string between two times.
  String durationBetween(String dep, String arr) {
    final now = DateTime.now();
    final d = _parseTime(dep, now);
    var a = _parseTime(arr, now);
    if (d == null || a == null) return '--';
    if (a.isBefore(d)) a = a.add(const Duration(days: 1));
    final diff = a.difference(d);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
