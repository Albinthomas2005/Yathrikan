import 'package:flutter/material.dart';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/live_bus_model.dart';
// import '../data/simulation_data.dart'; // Removed as we use user provided data

class BusLocationService {
  static final BusLocationService _instance = BusLocationService._internal();
  factory BusLocationService() => _instance;
  BusLocationService._internal();

  final List<LiveBus> _buses = [];
  final StreamController<List<LiveBus>> _busStreamController =
      StreamController<List<LiveBus>>.broadcast();
  Timer? _updateTimer;

  Stream<List<LiveBus>> get busStream => _busStreamController.stream;
  List<LiveBus> get buses => List.unmodifiable(_buses);

  // ---------------------------------------------------------
  // 1. ROUTE (Erumely -> Kottayam) - USER PROVIDED (13 points)
  // ---------------------------------------------------------
  static final List<LatLng> erumelyToKottayamRoute = [
    const LatLng(9.4821, 76.8443), // Erumely (Index 0)
    const LatLng(9.4905, 76.8390), // Koratty (Index 1)
    const LatLng(9.4980, 76.8335), // Kuruvamoozhi (Index 2)
    const LatLng(9.5070, 76.8280), // Erumely North (Index 3)
    const LatLng(9.5400, 76.7800), // Koovappally (Index 4)
    const LatLng(9.5580, 76.7916), // Kanjirappally (Index 5)
    const LatLng(9.5550, 76.7500), // Ponkunnam (Index 6)
    const LatLng(9.5665, 76.7200), // Vazhoor (Index 7)
    const LatLng(9.5750, 76.6950), // 14th Mile (Index 8)
    const LatLng(9.5830, 76.6700), // Mannathipara (Index 9)
    const LatLng(9.5900, 76.6450), // Chennampally (Index 10)
    const LatLng(9.5960, 76.6100), // Pampady (Index 11)
    const LatLng(9.5916, 76.5222), // Kottayam (Index 12)
  ];
  
  // Dense route for smooth animation (Interpolated)
  late List<LatLng> _interpolatedRoute;
  // Map to store which interpolated index corresponds to the original route index
  final Map<int, int> _originalIndexToInterpolatedMap = {};

  // ---------------------------------------------------------
  // 2. USER LOCATION LOGIC
  // ---------------------------------------------------------
  final LatLng userLocation = const LatLng(9.5361, 76.8254); // Koovappally (Approx between index 3 & 4)

  void initialize() {
    if (_buses.isNotEmpty) return;
    
    // Interpolate heavily to allow smooth 1-second updates
    // Total distance is ~40km. 
    // If we want smooth movement at ~10m/s (36km/h), we need points every ~10m if we update index+=1 every second?
    // User said: "updateBuses() { ... bus.index += 1; }"
    // So `index` refers to the points in the route list.
    // If the list is the 13 points, jumping 1 point is 3km. That's too fast.
    // So the list MUST be the interpolated high-res list.
    
    // We'll interpolate such that there are, say, 100 steps between each major waypoint.
    // This gives 12 * 100 = 1200 points.
    // 40km / 1200 points = ~33 meters per point.
    // This is perfect for 1-second updates at ~30m/s (High speed) or index+=1 every second.
    // Typical bus speed 10m/s -> we might need to increment index slower or have denser points.
    // Let's do 50 meters per point approximately.
    
    _interpolatedRoute = _generateDenseRoute(erumelyToKottayamRoute, 50.0); // 50 meters per step

    // ---------------------------------------------------------
    // 3. BUS DATA - 50 BUSES (USER PROVIDED)
    // ---------------------------------------------------------
    
    final List<Map<String, dynamic>> busesData = [
      {"busId":"KL-01","busName":"KSRTC Fast Passenger","from":"Erumely","to":"Kottayam","routeIndex":0,"speedMps":8.0},
      {"busId":"KL-02","busName":"KSRTC Super Fast","from":"Erumely","to":"Kottayam","routeIndex":1,"speedMps":9.2},
      {"busId":"KL-03","busName":"KSRTC Limited Stop","from":"Erumely","to":"Kottayam","routeIndex":2,"speedMps":7.5},
      {"busId":"KL-04","busName":"A1 Travels","from":"Erumely","to":"Kottayam","routeIndex":3,"speedMps":8.8},
      {"busId":"KL-05","busName":"Highrange Express","from":"Erumely","to":"Kottayam","routeIndex":4,"speedMps":9.5},

      {"busId":"KL-06","busName":"Malabar Express","from":"Koovappally","to":"Kottayam","routeIndex":4,"speedMps":8.0},
      {"busId":"KL-07","busName":"Green Line","from":"Koovappally","to":"Kottayam","routeIndex":5,"speedMps":7.9},
      {"busId":"KL-08","busName":"Royal Express","from":"Koovappally","to":"Kottayam","routeIndex":6,"speedMps":8.6},
      {"busId":"KL-09","busName":"Unity Travels","from":"Koovappally","to":"Kottayam","routeIndex":7,"speedMps":9.1},
      {"busId":"KL-10","busName":"City Express","from":"Koovappally","to":"Kottayam","routeIndex":8,"speedMps":8.3},

      {"busId":"KL-11","busName":"Venad Express","from":"Kanjirappally","to":"Kottayam","routeIndex":5,"speedMps":9.0},
      {"busId":"KL-12","busName":"Popular Travels","from":"Kanjirappally","to":"Kottayam","routeIndex":6,"speedMps":8.4},
      {"busId":"KL-13","busName":"Southern Express","from":"Kanjirappally","to":"Kottayam","routeIndex":7,"speedMps":7.8},
      {"busId":"KL-14","busName":"Travancore Express","from":"Kanjirappally","to":"Kottayam","routeIndex":8,"speedMps":8.9},
      {"busId":"KL-15","busName":"Hill View Express","from":"Kanjirappally","to":"Kottayam","routeIndex":9,"speedMps":9.4},

      {"busId":"KL-16","busName":"KSRTC Minnal","from":"Ponkunnam","to":"Kottayam","routeIndex":6,"speedMps":9.8},
      {"busId":"KL-17","busName":"KSRTC Swift","from":"Ponkunnam","to":"Kottayam","routeIndex":7,"speedMps":8.7},
      {"busId":"KL-18","busName":"KSRTC Garuda","from":"Ponkunnam","to":"Kottayam","routeIndex":8,"speedMps":9.3},
      {"busId":"KL-19","busName":"Fast Track","from":"Ponkunnam","to":"Kottayam","routeIndex":9,"speedMps":8.2},
      {"busId":"KL-20","busName":"Metro Express","from":"Ponkunnam","to":"Kottayam","routeIndex":10,"speedMps":7.9},

      {"busId":"KL-21","busName":"Golden Line","from":"Vazhoor","to":"Kottayam","routeIndex":7,"speedMps":8.1},
      {"busId":"KL-22","busName":"Silver Star","from":"Vazhoor","to":"Kottayam","routeIndex":8,"speedMps":9.0},
      {"busId":"KL-23","busName":"Blue Bird","from":"Vazhoor","to":"Kottayam","routeIndex":9,"speedMps":8.6},
      {"busId":"KL-24","busName":"Sunrise Express","from":"Vazhoor","to":"Kottayam","routeIndex":10,"speedMps":9.2},
      {"busId":"KL-25","busName":"Evening Rider","from":"Vazhoor","to":"Kottayam","routeIndex":11,"speedMps":8.0},

      {"busId":"KL-26","busName":"Morning Star","from":"14th Mile","to":"Kottayam","routeIndex":8,"speedMps":7.8},
      {"busId":"KL-27","busName":"Highway King","from":"14th Mile","to":"Kottayam","routeIndex":9,"speedMps":9.1},
      {"busId":"KL-28","busName":"Fast Lane","from":"14th Mile","to":"Kottayam","routeIndex":10,"speedMps":8.7},
      {"busId":"KL-29","busName":"Red Line","from":"14th Mile","to":"Kottayam","routeIndex":11,"speedMps":9.4},
      {"busId":"KL-30","busName":"White Pearl","from":"14th Mile","to":"Kottayam","routeIndex":12,"speedMps":8.3},

      {"busId":"KL-31","busName":"Kerala Express","from":"Pampady","to":"Kottayam","routeIndex":11,"speedMps":7.5},
      {"busId":"KL-32","busName":"Town Rider","from":"Pampady","to":"Kottayam","routeIndex":12,"speedMps":6.8},
      {"busId":"KL-33","busName":"City Link","from":"Pampady","to":"Kottayam","routeIndex":10,"speedMps":7.2},
      {"busId":"KL-34","busName":"Rapid Line","from":"Pampady","to":"Kottayam","routeIndex":9,"speedMps":8.0},
      {"busId":"KL-35","busName":"KSRTC Ordinary","from":"Pampady","to":"Kottayam","routeIndex":8,"speedMps":6.5},

      {"busId":"KL-36","busName":"Night Rider","from":"Erumely","to":"Kottayam","routeIndex":1,"speedMps":7.0},
      {"busId":"KL-37","busName":"Moonlight Express","from":"Erumely","to":"Kottayam","routeIndex":2,"speedMps":7.8},
      {"busId":"KL-38","busName":"Galaxy Travels","from":"Erumely","to":"Kottayam","routeIndex":3,"speedMps":8.4},
      {"busId":"KL-39","busName":"Highway Queen","from":"Erumely","to":"Kottayam","routeIndex":4,"speedMps":9.0},
      {"busId":"KL-40","busName":"Swift Arrow","from":"Erumely","to":"Kottayam","routeIndex":5,"speedMps":9.6},

      {"busId":"KL-41","busName":"Kerala Deluxe","from":"Koovappally","to":"Kottayam","routeIndex":6,"speedMps":8.9},
      {"busId":"KL-42","busName":"Fast Way","from":"Koovappally","to":"Kottayam","routeIndex":7,"speedMps":9.1},
      {"busId":"KL-43","busName":"Green Arrow","from":"Koovappally","to":"Kottayam","routeIndex":8,"speedMps":8.2},
      {"busId":"KL-44","busName":"Golden Ride","from":"Koovappally","to":"Kottayam","routeIndex":9,"speedMps":7.9},
      {"busId":"KL-45","busName":"Express Way","from":"Koovappally","to":"Kottayam","routeIndex":10,"speedMps":9.3},

      {"busId":"KL-46","busName":"KSRTC Super Deluxe","from":"Kanjirappally","to":"Kottayam","routeIndex":6,"speedMps":8.5},
      {"busId":"KL-47","busName":"Hill Express","from":"Kanjirappally","to":"Kottayam","routeIndex":7,"speedMps":8.1},
      {"busId":"KL-48","busName":"Road Star","from":"Kanjirappally","to":"Kottayam","routeIndex":8,"speedMps":9.0},
      {"busId":"KL-49","busName":"Turbo Line","from":"Kanjirappally","to":"Kottayam","routeIndex":9,"speedMps":9.7},
      {"busId":"KL-50","busName":"Prime Express","from":"Kanjirappally","to":"Kottayam","routeIndex":10,"speedMps":8.6},
    ];

    for (var bData in busesData) {
        // Map the coarse 'routeIndex' (0-12) to our fine interpolated index
        final int coarseIndex = bData['routeIndex'];
        final int fineIndex = _originalIndexToInterpolatedMap[coarseIndex] ?? 0;
        
        _buses.add(LiveBus(
          busId: bData['busId'],
          busName: bData['busName'],
          routeName: "Erumely - Kottayam",
          from: bData['from'],
          to: bData['to'], // "Kottayam" normally
          route: _interpolatedRoute,
          index: fineIndex,
          speedMps: (bData['speedMps'] as num).toDouble(),
        ));
    }
    
    _busStreamController.add(List.from(_buses));
    _startSimulation();
  }

  // ---------------------------------------------------------
  // 4. MOVEMENT LOGIC (USER logic adapted)
  // ---------------------------------------------------------
  void _startSimulation() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateBuses();
      _busStreamController.add(List.from(_buses));
    });
  }

  void _updateBuses() {
    for (final bus in _buses) {
      if (bus.index < bus.route.length - 1) {
         // Logic: bus.index += 1;
         // But since we interpolated to ~50m segments, and bus speed is ~8m/s..
         // we should only increment every ~6 seconds?
         // OR, we can just say 1 index = 1 second of travel roughly if we spaced points by speed?
         // But speed varies per bus.
         
         // Better logic: Calculate how many indices to jump based on speed
         // Distance = Speed * 1 sec.
         // Indices = Distance / MetersPerIndex (~50m)
         
// double indicesToMove = bus.speedMps / 50.0;
         // Since index is int, we accumulate fraction? Or just randomize/round.
         // Let's just always move at least 1 index to show movement, 
         // unless speed is very low. 8m/s / 50m = 0.16 index per sec.
         // This means it takes ~6 seconds to move one dot.
         // That might look "laggy" or stationary.
         
         // Alternative: Make points closer. 10 meters apart.
         // 8m/s -> 0.8 index per sec. Still < 1.
         
         // Let's just increment by 1 for visual satisfaction as per user request "animate in map".
         // The user said "updateBuses() { ... bus.index += 1; }"
         // So I will honor that. The speedMps will influence ETA, not visual speed per se,
         // unless I change the route density.
         
         bus.index += 1;
      } else {
         bus.index = 0; // Loop
      }
    }
  }
  
  // ---------------------------------------------------------
  // 5. ETA & HELPERS
  // ---------------------------------------------------------
  
  int _userIndex(List<LatLng> route) {
     double minDst = double.infinity;
     int uIdx = 0;
     const Distance dist = Distance();
     
     // Only search near likely index of Koovappally (Original index 4)
     // which corresponds to ~30-40% of the interpolated route
     
     for(int i=0; i<route.length; i++) {
        final d = dist.as(LengthUnit.Meter, route[i], userLocation);
        if (d < minDst) {
           minDst = d;
           uIdx = i;
        }
     }
     return uIdx;
  }
  
  int etaMinutes(LiveBus bus) {
    final uIdx = _userIndex(bus.route);
    final remainingPoints = uIdx - bus.index;

    if (remainingPoints <= 0) return 0; // Already passed

    // Distance = Remaining Points * MetersPerPoint
    // User snippet: "final metersPerPoint = 30;"
    // We used 50m spacing in generator. Let's align.
    const metersPerPoint = 50; 
    
    final seconds = (remainingPoints * metersPerPoint) / bus.speedMps;

    return (seconds / 60).ceil();
  }
  
  bool isIncoming(LiveBus bus) {
     return bus.index < _userIndex(bus.route);
  }

  // ---------------------------------------------------------
  // 6. LEGACY / ADMIN / CHATBOT SUPPORT
  // ---------------------------------------------------------
  
  List<String> get availableCities => [
    'Koovappally', 'Kanjirappally', 'Ponkunnam', 'Erumely', 'Kottayam', 'Pala', 'Mundakayam', 'Vazhoor', 'Pampady'
  ];

  void addBus(LiveBus bus) {
     // If bus has no route (added from Admin), assign the default route
     if (bus.route.isEmpty) {
        bus.route = _interpolatedRoute;
        bus.index = 0;
     }
     _buses.add(bus);
     _busStreamController.add(List.from(_buses));
  }
  
  void removeBus(String busId) {
     _buses.removeWhere((b) => b.busId == busId);
     _busStreamController.add(List.from(_buses));
  }
  
  void updateBusStatus(String busId, String status) {
     try {
       final bus = _buses.firstWhere((b) => b.busId == busId);
       bus.status = status;
       _busStreamController.add(List.from(_buses));
     } catch (e) {
       debugPrint("Bus not found: $busId");
     }
  }

  /// Helper for chatbot to find buses
  List<Map<String, dynamic>> findBusesForUser({
    required String startLocation,
    required String endLocation,
    required TimeOfDay userCurrentTime,
  }) {
    // Return formatted list of buses that match roughly
    final matches = _buses.where((b) {
       // Simple fuzzy check or direct check
       return (b.from.toLowerCase().contains(startLocation.toLowerCase()) && 
               b.to.toLowerCase().contains(endLocation.toLowerCase())) ||
               (b.routeName.toLowerCase().contains(startLocation.toLowerCase()) && 
                b.routeName.toLowerCase().contains(endLocation.toLowerCase()));
    }).toList();
    
    // Sort by ETA
    matches.sort((a, b) => etaMinutes(a).compareTo(etaMinutes(b)));

    return matches.map((b) {
       final eta = etaMinutes(b);
       final now = DateTime.now();
       final reach = now.add(Duration(minutes: eta + 45)); // Mock duration
       
       return {
          'busName': b.busName,
          'arrivalTime': "$eta min", // Simplify for chat
          'reachTime': "${reach.hour}:${reach.minute.toString().padLeft(2,'0')}",
          'duration': "45 min"
       };
    }).toList();
  }
  
  // ---------------------------------------------------------
  // UTILS
  // ---------------------------------------------------------
  List<LatLng> _generateDenseRoute(List<LatLng> waypoints, double stepMeters) {
    List<LatLng> dense = [];
    const Distance dist = Distance();
    
    for (int i = 0; i < waypoints.length - 1; i++) {
       // Save the mapping for the start of this segment
       _originalIndexToInterpolatedMap[i] = dense.length;
       
       final start = waypoints[i];
       final end = waypoints[i+1];
       final segmentDist = dist.as(LengthUnit.Meter, start, end);
       final steps = (segmentDist / stepMeters).ceil();
       
       dense.add(start);
       
       for(int j=1; j<steps; j++) {
          final t = j / steps;
          dense.add(LatLng(
             start.latitude + (end.latitude - start.latitude) * t,
             start.longitude + (end.longitude - start.longitude) * t,
          ));
       }
    }
    // Add last point and map it
    _originalIndexToInterpolatedMap[waypoints.length - 1] = dense.length;
    dense.add(waypoints.last);
    
    return dense;
  }
  
  void dispose() {
    _updateTimer?.cancel();
    _busStreamController.close();
  }
}
