import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';
import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';

// ── Number-plate auto-formatter ───────────────────────────────────────────────
// Strips non-alphanumeric chars, uppercases, and inserts hyphens:
//  "KLERU2005" → "KL-ERU-2005"
class _PlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw =
        newValue.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final buf = StringBuffer();
    for (int i = 0; i < raw.length && i < 9; i++) {
      if (i == 2 || i == 5) buf.write('-');
      buf.write(raw[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Map stop-picker dialog ────────────────────────────────────────────────────
/// Full-screen map where the admin taps to place a stop pin.
/// Returns BusStop? (null = cancelled).
class _MapStopPickerDialog extends StatefulWidget {
  final LatLng initialCenter;
  const _MapStopPickerDialog({required this.initialCenter});

  @override
  State<_MapStopPickerDialog> createState() => _MapStopPickerDialogState();
}

class _MapStopPickerDialogState extends State<_MapStopPickerDialog> {
  LatLng? _picked;
  final MapController _mc = MapController();

  String _nearestName(LatLng pt) {
    const dist = Distance();
    double min = double.infinity;
    String name = '${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}';
    BusLocationService.keyPlaces.forEach((k, v) {
      final d = dist.as(LengthUnit.Meter, v, pt);
      if (d < min) {
        min = d;
        // Use place name if within 800 m, else fall back to coordinates
        name = d < 800 ? k : '${pt.latitude.toStringAsFixed(4)}, ${pt.longitude.toStringAsFixed(4)}';
      }
    });
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: Text('Pick Stop on Map',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          if (_picked != null)
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  BusStop(name: _nearestName(_picked!), position: _picked!),
                );
              },
              child: Text('Confirm',
                  style: GoogleFonts.inter(
                      color: AppColors.primaryYellow,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mc,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 14,
              onTap: (tapPos, latlng) {
                setState(() => _picked = latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yathrikan.app',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 56,
                      height: 56,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _nearestName(_picked!),
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.location_pin,
                              color: AppColors.primaryYellow, size: 28),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Instruction banner
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app,
                      color: AppColors.primaryYellow, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _picked == null
                          ? 'Tap anywhere on the map to place this stop'
                          : 'Stop: ${_nearestName(_picked!)}  •  Tap Confirm ↗',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final TextEditingController _searchController     = TextEditingController();
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _busNameController     = TextEditingController();
  final TextEditingController _deviceIdController    = TextEditingController();

  String  _searchQuery        = '';
  String? _selectedOrigin;
  String? _selectedDestination;
  final BusLocationService _busService = BusLocationService();

  @override
  void dispose() {
    _searchController.dispose();
    _numberPlateController.dispose();
    _busNameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  List<LiveBus> _filterBuses(List<LiveBus> buses) {
    if (_searchQuery.isEmpty) return buses;
    return buses.where((bus) {
      final q = _searchQuery.toLowerCase();
      return bus.busId.toLowerCase().contains(q) ||
             bus.busName.toLowerCase().contains(q) ||
             bus.routeName.toLowerCase().contains(q) ||
             bus.numberPlate.toLowerCase().contains(q);
    }).toList();
  }

  // ── Open map picker and return a BusStop ──────────────────────────────────
  Future<BusStop?> _pickStopFromMap(BuildContext context) async {
    // Use origin city coords if available, else fall back to Koovappally
    LatLng center = const LatLng(9.5361, 76.8254);
    if (_selectedOrigin != null) {
      final entry = BusLocationService.keyPlaces.entries.firstWhere(
        (e) => e.key.toLowerCase() == _selectedOrigin!.toLowerCase(),
        orElse: () => const MapEntry('', LatLng(9.5361, 76.8254)),
      );
      if (entry.key.isNotEmpty) center = entry.value;
    }
    return await Navigator.push<BusStop>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _MapStopPickerDialog(initialCenter: center),
      ),
    );
  }

  // ── Stops editor (shared between Add and Edit dialogs) ────────────────────
  Widget _buildStopsEditor(
      List<BusStop> stops, StateSetter setDialogState, BuildContext dlgCtx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.route, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text('Bus Stops (in order)',
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            // "Add Stop" — opens the map picker
            TextButton.icon(
              onPressed: () async {
                final stop = await _pickStopFromMap(dlgCtx);
                if (stop != null) setDialogState(() => stops.add(stop));
              },
              icon: const Icon(Icons.add_location_alt, size: 16, color: AppColors.primaryYellow),
              label: Text('Add Stop',
                  style: GoogleFonts.inter(
                      color: AppColors.primaryYellow, fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: Size.zero),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap "Add Stop" to select each stop directly on the map.',
          style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
        ),
        const SizedBox(height: 8),
        if (stops.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.white24, size: 18),
                const SizedBox(width: 10),
                Text('No stops added yet.',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
        ...List.generate(stops.length, (i) {
          final stop = stops[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                // Index badge
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: GoogleFonts.inter(
                          color: AppColors.primaryYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                // Stop name + coordinates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.name,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${stop.position.latitude.toStringAsFixed(5)}, ${stop.position.longitude.toStringAsFixed(5)}',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // Re-pick on map
                IconButton(
                  icon: const Icon(Icons.edit_location_alt,
                      color: Colors.blueAccent, size: 18),
                  tooltip: 'Re-pick on map',
                  onPressed: () async {
                    final newStop = await _pickStopFromMap(dlgCtx);
                    if (newStop != null) setDialogState(() => stops[i] = newStop);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Move up
                if (i > 0)
                  GestureDetector(
                    onTap: () => setDialogState(() {
                      final tmp = stops[i];
                      stops[i] = stops[i - 1];
                      stops[i - 1] = tmp;
                    }),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_upward,
                          color: Colors.white38, size: 16),
                    ),
                  ),
                // Remove
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.redAccent, size: 18),
                  onPressed: () => setDialogState(() => stops.removeAt(i)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Add Bus dialog ─────────────────────────────────────────────────────────
  void _showAddBusDialog(BuildContext context) {
    _selectedOrigin      = null;
    _selectedDestination = null;
    _numberPlateController.clear();
    _busNameController.clear();
    _deviceIdController.clear();

    bool    _useFirebaseIot = false;
    bool    _isConnected    = false;
    bool    _isTesting      = false;
    String? _testResult;
    final   List<BusStop> _stops = [];
    final   cities = _busService.availableCities;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Add New Bus',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number Plate (mandatory, auto-formatted)
                TextField(
                  controller: _numberPlateController,
                  inputFormatters: [_PlateFormatter()],
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: 'Number Plate *',
                    hintText: 'KL-ERU-2005',
                    hintStyle: GoogleFonts.inter(
                        color: Colors.white24, letterSpacing: 2),
                    labelStyle: const TextStyle(color: Colors.grey),
                    helperText: 'Format: KL-ERU-2005  (hyphens auto-filled)',
                    helperStyle:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                    prefixIcon: const Icon(Icons.credit_card_rounded,
                        color: AppColors.primaryYellow, size: 20),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                // Bus Name (mandatory)
                TextField(
                  controller: _busNameController,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Bus Name *',
                    hintText: 'e.g. Kottayam Express',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.directions_bus,
                        color: AppColors.primaryYellow, size: 20),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                // IoT Device ID
                TextField(
                  controller: _deviceIdController,
                  onChanged: (v) => setDS(() {
                    _isConnected = false;
                    _testResult = null;
                  }),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'IoT Device ID (e.g. ESP32_01)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                // Origin
                DropdownButtonFormField<String>(
                  value: _selectedOrigin,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Origin',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDS(() => _selectedOrigin = v),
                ),
                const SizedBox(height: 16),
                // Destination
                DropdownButtonFormField<String>(
                  value: _selectedDestination,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDS(() => _selectedDestination = v),
                ),
                // Map-based stops editor
                _buildStopsEditor(_stops, setDS, dlgCtx),
                const SizedBox(height: 16),
                // Firebase IoT toggle
                Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.grey),
                  child: SwitchListTile(
                    title: Text('Use Firebase IoT Tracker',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 14)),
                    subtitle: Text('Tracks actual location via /gps',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12)),
                    value: _useFirebaseIot,
                    activeColor: AppColors.primaryYellow,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDS(() {
                      _useFirebaseIot = v;
                      _isConnected = false;
                      _testResult = null;
                    }),
                  ),
                ),
                if (_useFirebaseIot) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting
                          ? null
                          : () async {
                              setDS(() => _isTesting = true);
                              final ok = await _busService
                                  .testConnection(_deviceIdController.text.trim());
                              setDS(() {
                                _isTesting = false;
                                _isConnected = ok;
                                _testResult = ok
                                    ? 'Connection Successful! ✅'
                                    : 'Connection Failed! ❌';
                              });
                            },
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.satellite_alt, size: 18),
                      label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _testResult!,
                      style: GoogleFonts.inter(
                        color: _testResult!.contains('✅')
                            ? Colors.green
                            : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (_useFirebaseIot && !_isConnected)
                  ? null
                  : () async {
                final plate = _numberPlateController.text.trim();
                if (plate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Number plate is required')));
                  return;
                }
                if (_selectedOrigin == null || _selectedDestination == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Please select origin and destination')));
                  return;
                }
                if (_selectedOrigin == _selectedDestination) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Origin and Destination cannot be the same')));
                  return;
                }
                final busId = plate.replaceAll('-', '_');
                final name  = _busNameController.text.trim();
                final newBus = LiveBus(
                  busId: busId,
                  busName: name.isNotEmpty ? name : 'Bus $plate',
                  routeName: '$_selectedOrigin - $_selectedDestination',
                  from: _selectedOrigin!,
                  to: _selectedDestination!,
                  speedMps: 11.0,
                  headingDeg: 0,
                  status: 'RUNNING',
                  isFirebaseIot: _useFirebaseIot,
                  deviceId: _deviceIdController.text.trim(),
                  numberPlate: plate,
                  stops: _stops,
                );
                Navigator.pop(dlgCtx);
                await _busService.addBus(newBus);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bus $plate added & started')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black),
              child: const Text('Add Bus'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Bus dialog ────────────────────────────────────────────────────────
  void _showEditBusDialog(BuildContext context, LiveBus bus) {
    final plateCtrl  = TextEditingController(
        text: bus.numberPlate.isNotEmpty ? bus.numberPlate : bus.busId);
    final nameCtrl   = TextEditingController(text: bus.busName);
    final deviceCtrl = TextEditingController(text: bus.deviceId);
    String? origin      = bus.from;
    String? destination = bus.to;
    final List<BusStop> stops = List<BusStop>.from(bus.stops);
    bool   useIot = bus.isFirebaseIot;
    bool   isConnected = false;
    bool   isTesting = false;
    String? testResult;
    final  cities = _busService.availableCities;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
              'Edit  ${bus.numberPlate.isNotEmpty ? bus.numberPlate : bus.busId}',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: plateCtrl,
                  inputFormatters: [_PlateFormatter()],
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: 'Number Plate *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    helperText: 'Hyphens auto-filled',
                    helperStyle:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                    prefixIcon: const Icon(Icons.credit_card_rounded,
                        color: AppColors.primaryYellow, size: 20),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Bus Name *',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.directions_bus,
                        color: AppColors.primaryYellow, size: 20),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: deviceCtrl,
                  onChanged: (v) => setDS(() {
                    isConnected = false;
                    testResult = null;
                  }),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'IoT Device ID',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: origin,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Origin',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDS(() => origin = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: destination,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primaryYellow)),
                  ),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDS(() => destination = v),
                ),
                _buildStopsEditor(stops, setDS, dlgCtx),
                const SizedBox(height: 16),
                Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.grey),
                  child: SwitchListTile(
                    title: Text('Use Firebase IoT Tracker',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 14)),
                    subtitle: Text('Tracks actual location via /gps',
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12)),
                    value: useIot,
                    activeColor: AppColors.primaryYellow,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDS(() {
                      useIot = v;
                      isConnected = false;
                      testResult = null;
                    }),
                  ),
                ),
                if (useIot) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              setDS(() => isTesting = true);
                              final ok = await _busService
                                  .testConnection(deviceCtrl.text.trim());
                              setDS(() {
                                isTesting = false;
                                isConnected = ok;
                                testResult = ok
                                    ? 'Connection Successful! ✅'
                                    : 'Connection Failed! ❌';
                              });
                            },
                      icon: isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.satellite_alt, size: 18),
                      label: Text(isTesting ? 'Testing...' : 'Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      testResult!,
                      style: GoogleFonts.inter(
                        color: testResult!.contains('✅')
                            ? Colors.green
                            : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (useIot && !isConnected)
                  ? null
                  : () {
                final plate = plateCtrl.text.trim();
                if (plate.isEmpty || origin == null || destination == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Please fill in all required fields')));
                  return;
                }
                bus.numberPlate = plate;
                bus.busName     = nameCtrl.text.trim();
                bus.deviceId    = deviceCtrl.text.trim();
                bus.isFirebaseIot = useIot;
                bus.stops = stops;
                // Force stream refresh
                _busService.updateBusStatus(bus.busId, bus.status);
                Navigator.pop(dlgCtx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bus $plate updated')));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDeleteBus(BuildContext context, String busId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            Text('Delete Bus?', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Are you sure you want to delete bus $busId?',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _busService.removeBus(busId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bus $busId deleted')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text('Manage Fleet',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by plate, ID or route...',
                  hintStyle:
                      GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Bus list
          Expanded(
            child: StreamBuilder<List<LiveBus>>(
              stream: _busService.busStream,
              initialData: _busService.buses,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No buses online',
                          style:
                              GoogleFonts.inter(color: Colors.white54)));
                }
                final buses = _filterBuses(snapshot.data!);
                
                // Sort: IoT buses first
                buses.sort((a, b) {
                  if (a.isFirebaseIot && !b.isFirebaseIot) return -1;
                  if (!a.isFirebaseIot && b.isFirebaseIot) return 1;
                  return 0;
                });
                if (buses.isEmpty) {
                  return Center(
                      child: Text(
                          'No buses found for "$_searchQuery"',
                          style:
                              GoogleFonts.inter(color: Colors.white54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: buses.length,
                  itemBuilder: (context, i) {
                    final bus = buses[i];
                    return _BusCard(
                      bus: bus,
                      onDelete: () =>
                          _confirmDeleteBus(context, bus.busId),
                      onEdit: () =>
                          _showEditBusDialog(context, bus),
                      onStatusToggle: (isRunning) {
                        _busService.updateBusStatus(
                            bus.busId, isRunning ? 'RUNNING' : 'IDLE');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBusDialog(context),
        backgroundColor: AppColors.primaryYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// ── Bus card ──────────────────────────────────────────────────────────────────
class _BusCard extends StatelessWidget {
  final LiveBus bus;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onStatusToggle;

  const _BusCard({
    required this.bus,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRunning = bus.status == 'RUNNING';
    final Color statusColor = isRunning ? Colors.green : Colors.orange;
    final String displayId =
        bus.numberPlate.isNotEmpty ? bus.numberPlate : bus.busId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              // Number-plate and IoT badge
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primaryYellow.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bus.isFirebaseIot) ...[
                              const Icon(Icons.sensors,
                                  size: 14, color: AppColors.primaryYellow),
                              const SizedBox(width: 6),
                            ],
                            const Icon(Icons.credit_card_rounded,
                                size: 14, color: AppColors.primaryYellow),
                            const SizedBox(width: 5),
                            Text(displayId,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryYellow,
                                    fontSize: 13,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                      if (bus.isFirebaseIot) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: BusLocationService().isDeviceOnline(bus.deviceId)
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: BusLocationService()
                                          .isDeviceOnline(bus.deviceId)
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                BusLocationService().isDeviceOnline(bus.deviceId)
                                    ? 'ONLINE'
                                    : 'OFFLINE',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: BusLocationService()
                                          .isDeviceOnline(bus.deviceId)
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Running/Idle switch and text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isRunning ? 'RUNNING' : 'IDLE',
                      style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                  const SizedBox(width: 2),
                  Transform.scale(
                    scale: 0.7,
                    child: SizedBox(
                      width: 40,
                      child: Switch(
                        value: isRunning,
                        activeThumbColor: Colors.green,
                        inactiveThumbColor: Colors.orange,
                        inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                        onChanged: onStatusToggle,
                      ),
                    ),
                  ),
                ],
              ),

              // Edit/Delete
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.blueAccent, size: 16),
                onPressed: onEdit,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 16),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bus Name
          Text(bus.busName,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),

          // Route name
          Text(bus.routeName,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),

          // Stops preview
          if (bus.stops.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < bus.stops.length; i++) ...[
                    if (i > 0)
                      const Icon(Icons.chevron_right,
                          size: 14, color: Colors.white38),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(bus.stops[i].name,
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          // Speed
          Row(
            children: [
              const Icon(Icons.speed, size: 16, color: Colors.white54),
              const SizedBox(width: 4),
              Text('${bus.speedKmph.toStringAsFixed(0)} km/h',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
