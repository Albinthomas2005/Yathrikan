import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'dart:async';
import 'dart:convert';
import '../models/route_path_model.dart';
import '../services/notification_service.dart';
import '../utils/app_localizations.dart';
import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';
import '../utils/string_utils.dart';

class BusOption {
  final String id;
  final String name;
  final String type;
  final String time;
  final DateTime departureTime;
  final String duration;
  final double price;
  final int seatsLeft;
  final String origin;
  final String destination;
  final String arrivalTimeAtOrigin;
  final String arrivalTimeAtDestination;
  final LiveBus? liveBusData;
  final int? minutesToUser;
  final String? arrivalAtUserStr;

  BusOption({
    required this.id, required this.name, required this.type,
    required this.time, required this.departureTime, required this.duration,
    required this.price, required this.seatsLeft, required this.origin,
    required this.destination, required this.arrivalTimeAtOrigin,
    required this.arrivalTimeAtDestination, this.liveBusData,
    this.minutesToUser, this.arrivalAtUserStr,
  });
}

class ShortestRouteScreen extends StatefulWidget {
  final String? initialDestination;
  final String? initialOrigin;  // ← NEW: pre-fill the From field
  final bool autoDetectOrigin;
  final String? initialBusId; // For notification navigation

  const ShortestRouteScreen({
    super.key,
    this.initialDestination,
    this.initialOrigin,
    this.autoDetectOrigin = false,
    this.initialBusId,
  });

  @override
  State<ShortestRouteScreen> createState() => _ShortestRouteScreenState();
}

class _ShortestRouteScreenState extends State<ShortestRouteScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<List<LiveBus>>? _busSubscription;

  final MapController _mapController = MapController();
  final NotificationService _notificationService = NotificationService();
  final BusLocationService _busService = BusLocationService();

  RoutePath? _currentRoutePath;
  LatLng? _busLocation;
  String _pickupEtaText = "-- min";

  bool _showBusList = true;
  List<BusOption> _availableBuses = [];
  BusOption? _selectedBus;
  LatLng _currentLocation = const LatLng(9.525651, 76.827199); // Default Koovappally, will update
  bool _isLocationLoaded = false;
  bool _isLocating = false; // true while the GPS button is fetching location

  // Autocomplete state
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  // Transfer route state
  List<FoundRoute> _foundRoutes = [];
  FoundRoute? _selectedTransferRoute;
  List<LatLng> _leg1Path = [];
  List<LatLng> _leg2Path = [];
  bool _loadingTransferMap = false;

  // Animated bus icons on the transfer map
  int _bus1Idx = 0;
  int _bus2Idx = 0;
  LatLng? _bus1Pos;
  LatLng? _bus2Pos;
  Timer? _busAnimTimer;
  Timer? _clockUpdateTimer; // Drives the 1-minute UI countdown refresh

  // Sequential animation phase:
  //  0 = Blue bus travelling leg 1 (red hidden)
  //  1 = Pause at transfer stop (~3 s)
  //  2 = Red bus travelling leg 2 (blue stays at transfer)
  //  3 = Short end pause before loop restart
  int _animPhase = 0;
  int _pauseTickCount = 0;
  static const int _transferPauseTicks = 50;  // ~3 s at 60 ms/tick
  static const int _endPauseTicks = 20;       // ~1.2 s gap before loop

  // Estimated travel times (minutes) computed from actual path distances
  int _leg1EtaMin = 0;
  int _leg2EtaMin = 0;
  DateTime? _routeSelectionTime;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _notificationService.requestPermissions();
    _busService.initialize();

    // We can't use AppLocalizations.of(context) in initState because context isn't fully linked.
    // However, we wait until the first frame to safely translate the incoming destinations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        
        if (widget.initialDestination != null) {
            _toController.text = loc.translate(widget.initialDestination!);
        }

        if (widget.initialOrigin != null && widget.initialOrigin!.isNotEmpty) {
            // Card gave us explicit origin — use it directly, no GPS
            _fromController.text = loc.translate(widget.initialOrigin!);
            
            final originLower = widget.initialOrigin!.toLowerCase();
            for (final entry in BusLocationService.keyPlaces.entries) {
                if (entry.key.toLowerCase() == originLower) {
                    setState(() {
                        _currentLocation = entry.value;
                    });
                    _busService.updateUserLocation(entry.value, entry.key);
                    break;
                }
            }
        } else if (widget.autoDetectOrigin) {
            // User did not provide origin but requested auto-detection (e.g. from chatbot)
            _autoDetectLocation().then((_) {
                 // After auto-detecting, we should also auto-trigger the route search
                 if (widget.initialDestination != null) {
                     _handleFindRoute();
                 }
            });
        } else {
            _fromController.text = '';
        }
        
        // Auto-select bus if ID provided
        if (widget.initialBusId != null) {
            _handleNotificationBus(widget.initialBusId!);
        } else if (widget.initialOrigin != null && widget.initialDestination != null) {
            // If coming from Recent Routes or Popular routes, auto-Trigger the search on load.
            _handleFindRoute();
        }
    });


    _busSubscription = _busService.busStream.listen((buses) {
      if (mounted) {
        setState(() {
          if (_showBusList && _fromController.text.isNotEmpty && _toController.text.isNotEmpty) {
            _updateBusList(buses);
          }
          if (_selectedBus != null) {
            final live = buses.firstWhere((b) => b.busId == _selectedBus!.id, orElse: () => _selectedBus!.liveBusData!);
            _busLocation = live.position;
            // Calculate ETA from user location or From location?
            // Usually ETA is to the user.
            final eta = _busService.etaMinutes(live, relativeTo: _currentLocation);
            _pickupEtaText = eta <= 0 ? "Arriving" : "$eta min";
          }
        });
      }
    });

    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _busSubscription?.cancel();
    _busAnimTimer?.cancel();
    _clockUpdateTimer?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _handleNotificationBus(String busId) {
    // Initial wait to ensure buses are populated?
    // The stream listener above will handle updates.
    // But we need to switch view mode immediately if possible.
    final bus = _busService.buses.where((b) => b.busId == busId).firstOrNull;
    if (bus != null) {
        final opt = BusOption(
            id: bus.busId, name: bus.busName, type: "Live",
            time: "Now", departureTime: DateTime.now(), duration: "",
            price: 20.0, seatsLeft: 0, origin: bus.from, destination: bus.to,
            arrivalTimeAtOrigin: "", arrivalTimeAtDestination: "",
            liveBusData: bus, minutesToUser: 0, arrivalAtUserStr: ""
        );
        _selectBus(opt);
    }
  }

  void _onFromChanged() {
    final q = _fromController.text;
    
    // Sync map location instantly if it matches a known place
    final fromText = q.trim().toLowerCase();
    for (final entry in BusLocationService.keyPlaces.entries) {
      if (entry.key.toLowerCase() == fromText) {
        if (mounted) {
          setState(() {
            _currentLocation = entry.value;
          });
          _busService.updateUserLocation(entry.value, entry.key);
        }
        break;
      }
    }

    if (q.length >= 2 && _fromFocus.hasFocus) {
      if (BusLocationService.allPlaces.any((p) => p.toLowerCase() == q.toLowerCase())) {
        setState(() { _showFromSuggestions = false; });
        return;
      }
      setState(() {
        _fromSuggestions = BusLocationService.allPlaces
            .where((p) => p.toLowerCase().contains(q.toLowerCase()))
            .toList();
        _showFromSuggestions = _fromSuggestions.isNotEmpty;
      });
    } else {
      setState(() { _showFromSuggestions = false; });
    }
  }

  void _onToChanged() {
    final q = _toController.text;
    if (q.length >= 2 && _toFocus.hasFocus) {
      if (BusLocationService.allPlaces.any((p) => p.toLowerCase() == q.toLowerCase())) {
        setState(() { _showToSuggestions = false; });
        return;
      }
      setState(() {
        _toSuggestions = BusLocationService.allPlaces
            .where((p) => p.toLowerCase().contains(q.toLowerCase()))
            .toList();
        _showToSuggestions = _toSuggestions.isNotEmpty;
      });
    } else {
      setState(() { _showToSuggestions = false; });
    }
  }

  void _updateBusList(List<LiveBus> buses) {
    // Resolve "From" location to coordinates
    final rawFromText = _fromController.text.trim();
    final rawToText = _toController.text.trim();

    final fromText = _busService.normalizeLocationName(rawFromText);
    final toText = _busService.normalizeLocationName(rawToText);

    // The user ONLY wants buses to show up if the search endpoints are exclusively:
    // Koovappally, Kanjirappally, Ponkunnam, Kottayam, Erumely
    const allowedPlaces = ['koovappally', 'kanjirappally', 'ponkunnam', 'kottayam', 'erumely', 'erumely north'];
    
    // We check if either the 'from' or 'to' text (if not empty) matches our allowed places
    final bool isFromValid = fromText.isEmpty || rawFromText.toLowerCase() == 'current location' || allowedPlaces.contains(fromText);
    final bool isToValid = toText.isEmpty || allowedPlaces.contains(toText);

    if (!isFromValid || !isToValid) {
        setState(() {
            _availableBuses = [];
        });
        _busService.setTrackedBuses([]); // clear tracking 
        return;
    }

    // Case-insensitive lookup

    // Case-insensitive lookup for "From" coords
// 47db6fe3c (added live location using iot)
    LatLng? fromCoords;
    for (final entry in BusLocationService.keyPlaces.entries) {
        if (_busService.normalizeLocationName(entry.key) == fromText) {
            fromCoords = entry.value;
            break;
        }
    }
    
    // Fallback if user means "Current Location"
    if (fromCoords == null && (rawFromText.toLowerCase() == "current location" || rawFromText.isEmpty)) {
        fromCoords = _currentLocation;
    }

    final incoming = buses.where((b) {
      if (b.status != 'RUNNING') return false;

      // Filter by direction/route if "To" is specified
      bool matchesRoute = true;
      if (toText.isNotEmpty) {
           const routeOrder = ['erumely', 'erumely north', 'koovappally', 'kanjirappally', 'ponkunnam', 'vazhoor', 'kottayam', 'ettumanoor', 'kuravilangad', 'bharananganam', 'pala'];
           final fi = routeOrder.indexOf(fromText);
           final ti = routeOrder.indexOf(toText);
           
           if (fi != -1 && ti != -1 && fi < ti) {
               matchesRoute = b.routeName.toLowerCase().contains('erumely - kottayam') || 
                              b.routeName.toLowerCase().contains('kottayam - pala') ||
                              b.to.toLowerCase() == toText;
           } else if (fi != -1 && ti != -1 && fi > ti) {
               matchesRoute = b.routeName.toLowerCase().contains('kottayam - erumely') ||
                              b.routeName.toLowerCase().contains('pala - kottayam') ||
                              b.to.toLowerCase() == toText;
           } else {
               matchesRoute = b.to.toLowerCase() == toText || b.routeName.toLowerCase().contains(toText);
           }
      }
      
      if (!matchesRoute) return false;

      // Check if incoming relative to the "From" location
      return _busService.isIncoming(b, relativeTo: fromCoords);
    }).toList();

    incoming.sort((a, b) {
        // Sort by ETA relative to Start Point
        final etaA = _busService.etaMinutes(a, relativeTo: fromCoords);
        final etaB = _busService.etaMinutes(b, relativeTo: fromCoords);
        return etaA.compareTo(etaB);
    });

    // Notify the background service to restrict push notifications to only the top 3 buses matching this query!
    final top3BusIds = incoming.take(3).map((b) => b.busId).toList();
    _busService.setTrackedBuses(top3BusIds);

    final loc = AppLocalizations.of(context);
    
    _availableBuses = incoming.map((bus) {
      final eta = _busService.etaMinutes(bus, relativeTo: fromCoords);
      return BusOption(
        id: bus.busId, name: loc.translate(bus.busName), type: loc.translate("Live"),
        time: StringUtils.formatTime(DateTime.now().add(Duration(minutes: eta))),
        departureTime: DateTime.now().add(Duration(minutes: eta)),
        duration: loc.translate("Var"), price: 20.0, seatsLeft: 40,
        origin: loc.translate(bus.from), destination: loc.translate(bus.to),
        arrivalTimeAtOrigin: "", arrivalTimeAtDestination: "",
        liveBusData: bus, minutesToUser: eta, arrivalAtUserStr: "$eta ${loc.translate('min')}",
      );
    }).toList();
  }

  /// Called ONLY when the user presses the GPS button — requests permission and
  /// fetches the current position, then reverse-geocodes to the nearest known place.
  Future<void> _detectLocationOnDemand() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Enable it in Settings.');
        return;
      }

      // Get a single fix — with timeout
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _isLocationLoaded = true;
      });

      await _autoDetectLocation(); // reverse-geocode & update From field
    } catch (e) {
      _showSnack('Could not get location: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _autoDetectLocation() async {
    if (!_isLocationLoaded) {
        // Force get current if stream hasn't fired yet
        try {
            final pos = await Geolocator.getCurrentPosition();
            setState(() {
                _currentLocation = LatLng(pos.latitude, pos.longitude);
                _isLocationLoaded = true;
            });
        } catch (_) {}
    }

    // Find nearest known place
    const Distance dist = Distance();
    double minD = double.infinity;
    String nearest = 'Koovappally';
    
    // Check against all known places for better accuracy
    BusLocationService.keyPlaces.forEach((name, loc) {
        final d = dist.as(LengthUnit.Meter, loc, _currentLocation);
        if (d < minD) { minD = d; nearest = name; }
    });

    setState(() { _fromController.text = nearest; });
    _busService.updateUserLocation(_currentLocation, nearest);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location detected: $nearest'), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _swapLocations() {
    setState(() {
      final temp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = temp;
    });
  }

  Future<void> _handleFindRoute() async {
    final fromText = _fromController.text.trim().toLowerCase();
    LatLng? newLocation;
    for (final entry in BusLocationService.keyPlaces.entries) {
        if (entry.key.toLowerCase() == fromText) {
            newLocation = entry.value;
            break;
        }
    }

    setState(() {
      if (newLocation != null) _currentLocation = newLocation;
      _showBusList = true;
      _selectedTransferRoute = null;
      _leg1Path = [];
      _leg2Path = [];
    });
    _updateBusList(_busService.buses);

    // Compute transfer/direct route suggestions
    final from = _fromController.text.trim();
    final to   = _toController.text.trim();
    final normFrom = _busService.normalizeLocationName(from);
    final normTo = _busService.normalizeLocationName(to);

    if (from.isNotEmpty && to.isNotEmpty && normFrom == 'koovappally' && normTo == 'pala') {
      final routes = _busService.findRoutes(from, to);
      if (mounted) setState(() => _foundRoutes = routes);
    } else {
      if (mounted) setState(() => _foundRoutes = []);
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  Future<void> _selectBus(BusOption bus) async {
    setState(() {
      _selectedBus = bus;
      _selectedTransferRoute = null;
      _showBusList = false;
      _busLocation = bus.liveBusData?.position;
    });
    if (bus.liveBusData != null && bus.liveBusData!.route.isNotEmpty) {
      _currentRoutePath = RoutePath(
        routeName: "Live Route", waypoints: bus.liveBusData!.route,
        totalDistanceMeters: 1000, totalDurationSeconds: 600,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
         // Include user current location in the bounds to ensure it's in view
         final pointsToFit = List<LatLng>.from(bus.liveBusData!.route)..add(_currentLocation);
         _fitBounds(pointsToFit);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_busLocation != null) {
             _fitBounds([_currentLocation, _busLocation!]);
         }
      });
    }
  }

  Future<void> _selectTransferRoute(FoundRoute route) async {
    setState(() {
      _selectedTransferRoute = route;
      _selectedBus = null;
      _showBusList = false;
      _loadingTransferMap = true;
      _leg1Path = [];
      _leg2Path = [];
    });

    // Resolve stop coordinates
    final leg1Points = route.leg1Stops
        .map((s) => _busService.getLatLngForStop(s))
        .whereType<LatLng>()
        .toList();
    final leg2Points = route.leg2Stops
        .map((s) => _busService.getLatLngForStop(s))
        .whereType<LatLng>()
        .toList();

    final results = await Future.wait([
      leg1Points.length >= 2 ? _fetchOSRMPath(leg1Points) : Future.value(leg1Points),
      leg2Points.length >= 2 ? _fetchOSRMPath(leg2Points) : Future.value(leg2Points),
    ]);

    if (!mounted) return;

    // Compute ETA minutes from actual path distances (~30 km/h average)
    int calcEta(List<LatLng> path) {
      if (path.length < 2) return 5;
      double totalM = 0;
      const Distance dist = Distance();
      for (int i = 0; i < path.length - 1; i++) {
        totalM += dist.as(LengthUnit.Meter, path[i], path[i + 1]);
      }
      return (totalM / (30000 / 60)).ceil().clamp(1, 999);
    }

    setState(() {
      _leg1Path = results[0];
      _leg2Path = results[1];
      _loadingTransferMap = false;
      _animPhase = 0;
      _pauseTickCount = 0;
      _bus1Idx = 0;
      _bus2Idx = 0;
      _bus1Pos = results[0].isNotEmpty ? results[0].first : null;
      _bus2Pos = null; // hidden until transfer
      _leg1EtaMin = calcEta(results[0]);
      _leg2EtaMin = calcEta(results[1]);
      _routeSelectionTime = DateTime.now();
    });

    // ── Sequential phase timer ────────────────────────────────────────────────
    // Phase 0: blue bus moves along leg 1 until it reaches the transfer stop.
    // Phase 1: 3-second pause at transfer ("Changing buses...").
    // Phase 2: red bus moves from transfer stop to destination.
    // Phase 3: brief end pause then restart from phase 0.
    _busAnimTimer?.cancel();
    _clockUpdateTimer?.cancel();
    _clockUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
    _busAnimTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        switch (_animPhase) {
          case 0: // ── Blue bus travelling ──
            if (_leg1Path.isNotEmpty && _bus1Idx < _leg1Path.length - 1) {
              _bus1Idx++;
              _bus1Pos = _leg1Path[_bus1Idx];
            } else {
              // Arrived at transfer stop → pause
              _animPhase = 1;
              _pauseTickCount = 0;
            }
            break;

          case 1: // ── Pause at transfer stop ──
            _pauseTickCount++;
            if (_pauseTickCount >= _transferPauseTicks) {
              // Start red bus
              _animPhase = 2;
              _bus2Idx = 0;
              _bus2Pos = _leg2Path.isNotEmpty ? _leg2Path.first : null;
            }
            break;

          case 2: // ── Red bus travelling ──
            if (_leg2Path.isNotEmpty && _bus2Idx < _leg2Path.length - 1) {
              _bus2Idx++;
              _bus2Pos = _leg2Path[_bus2Idx];
            } else {
              // Reached destination → end pause
              _animPhase = 3;
              _pauseTickCount = 0;
            }
            break;

          case 3: // ── Short end pause → loop ──
            _pauseTickCount++;
            if (_pauseTickCount >= _endPauseTicks) {
              _animPhase = 0;
              _pauseTickCount = 0;
              _bus1Idx = 0;
              _bus2Idx = 0;
              _bus1Pos = _leg1Path.isNotEmpty ? _leg1Path.first : null;
              _bus2Pos = null; // hide red during leg 1
            }
            break;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allPoints = [...results[0], ...results[1]];
      if (allPoints.isNotEmpty) _fitBounds(allPoints);
    });
  }

  Future<List<LatLng>> _fetchOSRMPath(List<LatLng> points) async {
    try {
      final coords = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = 'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['code'] == 'Ok') {
          final List<dynamic> c = data['routes'][0]['geometry']['coordinates'];
          return c.map((pt) => LatLng(pt[1].toDouble(), pt[0].toDouble())).toList();
        }
      }
    } catch (_) {}
    return points; // fallback: straight lines
  }

  void _onBackPressed() {
    if (_selectedTransferRoute != null) {
      _busAnimTimer?.cancel();
      _clockUpdateTimer?.cancel();
      setState(() { _selectedTransferRoute = null; _showBusList = true; });
    } else if (_selectedBus != null) {
      setState(() { _selectedBus = null; _showBusList = true; });
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSuggestionList(List<String> suggestions, TextEditingController controller, StateSetter setStateCallback) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (ctx, i) => ListTile(
          dense: true,
          leading: const Icon(Icons.location_on_outlined, size: 18),
          title: Text(suggestions[i], style: const TextStyle(fontSize: 14)),
          onTap: () {
            controller.text = suggestions[i];
            setState(() { _showFromSuggestions = false; _showToSuggestions = false; });
          },
        ),
      ),
    );
  }

  // ── Transfer Route Card ────────────────────────────────────────────────────
  Widget _buildTransferRouteCard(FoundRoute route, int index) {
    final theme = Theme.of(context);
    final isDirect = route.type == 'direct';
    
    // Instead of taking the very first stop of the bus (Erumely), show the user where they are getting on and off based on their search.
    final String fromText = _fromController.text.trim();
    final String toText = _toController.text.trim();
    
    final leg1Start = FoundRoute.displayName(fromText.isNotEmpty ? fromText : route.leg1Stops.first);
    final leg1End   = isDirect ? FoundRoute.displayName(toText.isNotEmpty ? toText : route.leg1Stops.last) : FoundRoute.displayName(route.transferStop ?? '');
    
    final leg2Start = route.leg2Stops.isNotEmpty ? FoundRoute.displayName(route.transferStop ?? '') : '';
    final leg2End   = route.leg2Stops.isNotEmpty ? FoundRoute.displayName(toText.isNotEmpty ? toText : route.leg2Stops.last) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.cardColor,
      child: InkWell(
        onTap: () => _selectTransferRoute(route),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDirect
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDirect ? 'Direct Route' : 'Route Option ${index + 1}',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: isDirect ? Colors.green : Colors.orange.shade800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              _buildLegRow(
                busName: route.bus1Name, from: leg1Start, to: leg1End,
                color: Colors.blueAccent, icon: Icons.directions_bus_filled,
              ),
              if (!isDirect) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(children: [
                    const SizedBox(width: 18),
                    Container(width: 2, height: 24, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade300, width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.transfer_within_a_station, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Change at ${route.transferStopDisplay}',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
                _buildLegRow(
                  busName: route.bus2Name ?? '', from: leg2Start, to: leg2End,
                  color: Colors.redAccent, icon: Icons.directions_bus,
                ),
              ],
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.map_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('View on map', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegRow({
    required String busName, required String from, required String to,
    required Color color, required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(busName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Row(children: [
                Flexible(child: Text(from, style: const TextStyle(fontSize: 12))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade500),
                ),
                Flexible(child: Text(to, style: const TextStyle(fontSize: 12))),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phase-aware timing info card (shown in map overlay) ───────────────────
  Widget _buildPhaseInfoCard(FoundRoute route) {
    final now = DateTime.now();
    final selectionTime = _routeSelectionTime ?? now;
    
    // Fixed times calculated ONCE when route was selected
    final arriveLeg1Time = selectionTime.add(Duration(minutes: _leg1EtaMin));
    final departLeg2Time = selectionTime.add(Duration(minutes: _leg1EtaMin + 5));
    final arriveLeg2Time = departLeg2Time.add(Duration(minutes: _leg2EtaMin));

    // Helper: "HH:MM" string
    String clockFormat(DateTime t) {
      return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
    }

    switch (_animPhase) {
      // ── Phase 0: Blue bus heading to transfer stop ─────────────────────────
      case 0:
        final stepsLeft = _leg1Path.isNotEmpty ? (_leg1Path.length - 1 - _bus1Idx) : 0;
        final stepsTotal = _leg1Path.isNotEmpty ? (_leg1Path.length - 1) : 1;
        final remainMin = (_leg1EtaMin * stepsLeft / stepsTotal).ceil();
        final elapsedLeg1Min = _leg1EtaMin - remainMin;
        
        final remainDepartMin = (_leg1EtaMin + 5) - elapsedLeg1Min;
        final arriveClockStr = clockFormat(arriveLeg1Time);
        final departClockStr = clockFormat(departLeg2Time);
        
        final departText = remainDepartMin <= 0
            ? 'now'
            : 'at $departClockStr (${remainDepartMin}m left)';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bus 1 status
            Row(children: [
              Container(width: 14, height: 4, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(route.bus1Name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
            const SizedBox(height: 2),
            Text(
              '${FoundRoute.displayName(route.leg1Stops.first)} → ${FoundRoute.displayName(route.leg1Stops.last)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.blueAccent),
              const SizedBox(width: 5),
              Text(
                remainMin <= 0
                    ? 'Arriving at ${route.transferStopDisplay} now'
                    : 'Arrives at ${route.transferStopDisplay}: $arriveClockStr (${remainMin}m left)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ]),
            const Divider(height: 14),
            // Bus 2 waiting notice
            Row(children: [
              Container(width: 14, height: 4, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(route.bus2Name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.schedule, size: 13, color: Colors.redAccent),
              const SizedBox(width: 5),
              Text(
                'Departs ${route.transferStopDisplay} $departText',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ]),
          ],
        );

      // ── Phase 1: Pause at transfer — changing buses ────────────────────────
      case 1:
        // Bus 1 arrived, red bus departs in 5 minutes. Simulate countdown during the ~3s pause ticks.
        final remainDepartMin = (5 * (1 - (_pauseTickCount / _transferPauseTicks))).ceil().clamp(0, 5);
        final departClockStr = clockFormat(departLeg2Time);
        final departText = remainDepartMin <= 0
            ? 'now'
            : 'at $departClockStr (${remainDepartMin}m left)';
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.transfer_within_a_station, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Now changing buses at ${route.transferStopDisplay}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              )),
            ]),
            const SizedBox(height: 6),
            Text(
              '${route.bus1Name} has arrived.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 14, height: 4, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${route.bus2Name} $departText',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
              )),
            ]),
          ],
        );

      // ── Phase 2: Red bus travelling to destination ─────────────────────────
      case 2:
        final stepsLeft = _leg2Path.isNotEmpty ? (_leg2Path.length - 1 - _bus2Idx) : 0;
        final stepsTotal = _leg2Path.isNotEmpty ? (_leg2Path.length - 1) : 1;
        final remainMin = (_leg2EtaMin * stepsLeft / stepsTotal).ceil();
        final arriveClockStr = clockFormat(arriveLeg2Time);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 14, height: 4, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(route.bus2Name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
            const SizedBox(height: 2),
            Text(
              '${FoundRoute.displayName(route.leg2Stops.first)} → ${FoundRoute.displayName(route.leg2Stops.last)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.redAccent),
              const SizedBox(width: 5),
              Text(
                remainMin <= 0
                    ? 'Arriving at ${FoundRoute.displayName(route.leg2Stops.last)} now'
                    : 'Arrives at ${FoundRoute.displayName(route.leg2Stops.last)}: $arriveClockStr (${remainMin}m left)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 13, color: Colors.blueAccent),
              const SizedBox(width: 5),
              Text(
                '${route.bus1Name} arrived at ${route.transferStopDisplay}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ]),
          ],
        );

      // ── Phase 3: Journey complete ──────────────────────────────────────────
      default:
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            'Journey complete! Arrived at ${FoundRoute.displayName(route.leg2Stops.last)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
          ),
        ]);
    }
  }

  // ── Dual-Leg Transfer Map View ─────────────────────────────────────────────
  Widget _buildTransferMap(FoundRoute route) {
    final theme = Theme.of(context);
    final transferLatLng = route.transferStop != null
        ? _busService.getLatLngForStop(route.transferStop!)
        : null;
    final leg2EndPt = _leg2Path.isNotEmpty ? _leg2Path.last : null;

    return Column(
      children: [
        // Legend strip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 4, color: Colors.blueAccent),
            const SizedBox(width: 6),
            const Text('Bus 1', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text('Transfer', style: TextStyle(fontSize: 12, color: Colors.amber.shade800)),
            const SizedBox(width: 16),
            Container(width: 20, height: 4, color: Colors.redAccent),
            const SizedBox(width: 6),
            const Text('Bus 2', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              _loadingTransferMap
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: transferLatLng ?? _currentLocation,
                        initialZoom: 11,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.yathrikan',
                        ),
                        if (_leg1Path.isNotEmpty)
                          PolylineLayer(polylines: [
                            Polyline(points: _leg1Path, strokeWidth: 5.0, color: Colors.blueAccent),
                          ]),
                        if (_leg2Path.isNotEmpty)
                          PolylineLayer(polylines: [
                            Polyline(points: _leg2Path, strokeWidth: 5.0, color: Colors.redAccent),
                          ]),
                        MarkerLayer(markers: [
                          // ⭐ Transfer/change point
                          if (transferLatLng != null)
                            Marker(
                              point: transferLatLng, width: 44, height: 44,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber, shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                                ),
                                child: const Icon(Icons.star, color: Colors.white, size: 24),
                              ),
                            ),
                          // 🔵 Destination endpoint
                          if (leg2EndPt != null)
                            Marker(
                              point: leg2EndPt, width: 34, height: 34,
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                              ),
                            ),
                          // 🔵 Animated Bus 1 (blue) moving along leg 1
                          if (_bus1Pos != null)
                            Marker(
                              point: _bus1Pos!, width: 48, height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 3)],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 26),
                              ),
                            ),
                          // 🔴 Animated Bus 2 (red) moving along leg 2
                          if (_bus2Pos != null)
                            Marker(
                              point: _bus2Pos!, width: 48, height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 3)],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 26),
                              ),
                            ),
                        ]),
                      ],
                    ),
              Positioned(
                top: 12, right: 12,
                child: FloatingActionButton.small(
                  backgroundColor: theme.cardColor,
                  onPressed: () {
                    _busAnimTimer?.cancel();
                    _clockUpdateTimer?.cancel();
                    setState(() { _selectedTransferRoute = null; _showBusList = true; });
                  },
                  child: Icon(Icons.close, color: theme.iconTheme.color),
                ),
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: _buildPhaseInfoCard(route),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedBus == null && _selectedTransferRoute == null,
      onPopInvokedWithResult: (didPop, result) { if (didPop) return; _onBackPressed(); },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: theme.iconTheme.color), onPressed: _onBackPressed),
          title: Text(loc.translate('shortest_route'), style: AppTextStyles.heading2.copyWith(color: theme.textTheme.titleLarge?.color)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ROUTE INPUT CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor, borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(children: [
                    // From Input with Location Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.trip_origin, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _fromController, focusNode: _fromFocus,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              hintText: loc.translate('from'), border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                        // Auto-location button
                        IconButton(
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blueAccent,
                                  ),
                                )
                              : const Icon(Icons.gps_fixed, color: Colors.blueAccent, size: 22),
                          tooltip: 'Detect my location',
                          onPressed: _isLocating ? null : _detectLocationOnDemand,
                        ),
                      ]),
                    ),
                    if (_showFromSuggestions) _buildSuggestionList(_fromSuggestions, _fromController, setState),
                    const SizedBox(height: 12),
                    // To Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _toController, focusNode: _toFocus,
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            decoration: InputDecoration(
                              hintText: loc.translate('to'), border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    if (_showToSuggestions) _buildSuggestionList(_toSuggestions, _toController, setState),
                    const SizedBox(height: 12),
                    // Swap + Find row
                    Row(children: [
                      Container(
                        decoration: BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primaryYellow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                        child: IconButton(icon: const Icon(Icons.swap_vert, color: Colors.white), onPressed: _swapLocations),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleFindRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow, foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(loc.translate('find_route'), style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 25),

                // ROUTE SUGGESTIONS (transfer / direct routes from the database)
                if (_showBusList && _foundRoutes.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Route Suggestions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._foundRoutes.asMap().entries.map(
                    (e) => _buildTransferRouteCard(e.value, e.key),
                  ),
                  const SizedBox(height: 8),
                ],

                // LIVE BUS LIST
                if (_showBusList) ...[
                  Text(loc.translate("incoming_buses"), style: AppTextStyles.heading2.copyWith(fontSize: 18, color: theme.textTheme.titleLarge?.color)),
                  const SizedBox(height: 15),
                  if (_availableBuses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(loc.translate("no_incoming_buses")),
                    ),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableBuses.length,
                    itemBuilder: (context, index) {
                      final bus = _availableBuses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12), elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: theme.cardColor,
                        child: InkWell(
                          onTap: () => _selectBus(bus), borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.directions_bus_filled, color: Colors.amber, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(bus.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                                const SizedBox(height: 2),
                                Text(bus.id, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text("${loc.translate('eta')}: ${bus.arrivalAtUserStr}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                              ])),
                              Text("₹${bus.price.toInt()}", style: AppTextStyles.bodyBold.copyWith(fontSize: 18, color: AppColors.primaryYellow)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // TRANSFER ROUTE MAP (when a transfer/direct route card is selected)
                if (!_showBusList && _selectedTransferRoute != null) ...[
                  const SizedBox(height: 10),
                  _buildTransferMap(_selectedTransferRoute!),
                  const SizedBox(height: 20),
                ],

                // SINGLE-BUS MAP (only when a live bus is selected — existing behaviour)
                if (!_showBusList && _selectedBus != null) ...[
                  const SizedBox(height: 25),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(initialCenter: _currentLocation, initialZoom: 14),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.yathrikan'),
                            if (_currentRoutePath != null)
                              PolylineLayer(polylines: [Polyline(points: _currentRoutePath!.waypoints, strokeWidth: 4.0, color: Colors.blueAccent)]),
                            MarkerLayer(markers: [
                              // User location
                              Marker(
                                point: _currentLocation, 
                                width: 50, 
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.person_pin, 
                                      color: Colors.blueAccent, 
                                      size: 38,
                                    ),
                                  ),
                                ),
                              ),
                              // ONLY the selected bus
                              if (_busLocation != null)
                                Marker(point: _busLocation!, width: 48, height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent, shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 24),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                        // Close button
                        Positioned(top: 12, right: 12,
                          child: FloatingActionButton.small(
                            backgroundColor: theme.cardColor,
                            onPressed: () { setState(() { _showBusList = true; _selectedBus = null; }); },
                            child: Icon(Icons.close, color: theme.iconTheme.color),
                          ),
                        ),
                        // ETA overlay
                        Positioned(bottom: 16, left: 16, right: 16,
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(_selectedBus!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(_selectedBus!.id, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ]),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_pickupEtaText, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
