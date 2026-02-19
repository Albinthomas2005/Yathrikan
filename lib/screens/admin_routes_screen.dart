import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../utils/constants.dart';
import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';

class AdminRoutesScreen extends StatefulWidget {
  const AdminRoutesScreen({super.key});

  @override
  State<AdminRoutesScreen> createState() => _AdminRoutesScreenState();
}

class _AdminRoutesScreenState extends State<AdminRoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newBusIdController = TextEditingController();
  
  String _searchQuery = '';
  String? _selectedOrigin;
  String? _selectedDestination;
  final BusLocationService _busService = BusLocationService();

  @override
  void dispose() {
    _searchController.dispose();
    _newBusIdController.dispose();
    super.dispose();
  }

  List<LiveBus> _filterBuses(List<LiveBus> buses) {
    if (_searchQuery.isEmpty) return buses;
    return buses.where((bus) {
      final query = _searchQuery.toLowerCase();
      return bus.busId.toLowerCase().contains(query) ||
             bus.busName.toLowerCase().contains(query) ||
             bus.routeName.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddBusDialog(BuildContext context) {
    _selectedOrigin = null;
    _selectedDestination = null;
    _newBusIdController.clear();

    final cities = _busService.availableCities;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Add New Bus', style: GoogleFonts.inter(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _newBusIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Bus ID (e.g. KTM-101)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedOrigin,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedOrigin = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDestination,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => _selectedDestination = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_newBusIdController.text.isNotEmpty &&
                        _selectedOrigin != null &&
                        _selectedDestination != null &&
                        _selectedOrigin != _selectedDestination) {
                      
                      // Construct route name
                      final routeName = '$_selectedOrigin - $_selectedDestination';
                      
                      // Create a new bus 
                      // Note: Lat/Lon will be auto-corrected by BusLocationService based on Origin
                      final newBus = LiveBus(
                        busId: _newBusIdController.text.toUpperCase(),
                        busName: "Bus ${_newBusIdController.text}", // Default name
                        routeName: routeName,
                        lat: 9.5916, // Temporary, will snap to Origin
                        lon: 76.5222,
                        speedKmph: 40, // Set meaningful speed so it moves
                        headingDeg: 0,
                        lastUpdated: DateTime.now(),
                        status: 'RUNNING', // Start as RUNNING
                      );
                      
                      _busService.addBus(newBus);
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bus Added & Started Successfully')),
                      );
                    } else if (_selectedOrigin == _selectedDestination) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Origin and Destination cannot be same')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: Colors.black
                  ),
                  child: const Text('Add Bus'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDeleteBus(BuildContext context, String busId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Bus?', style: GoogleFonts.inter(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete bus $busId?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _busService.removeBus(busId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bus $busId deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Fleet',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Bus ID or Route...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Bus List
          Expanded(
            child: StreamBuilder<List<LiveBus>>(
              stream: _busService.busStream,
              initialData: _busService.buses,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No buses online',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  );
                }

                final buses = _filterBuses(snapshot.data!);

                if (buses.isEmpty) {
                  return Center(
                    child: Text(
                      'No buses found matching "$_searchQuery"',
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
                    return _BusCard(
                      bus: bus,
                      onDelete: () => _confirmDeleteBus(context, bus.busId),
                      onStatusToggle: (bool isRunning) {
                        final newStatus = isRunning ? "RUNNING" : "IDLE";
                        _busService.updateBusStatus(bus.busId, newStatus);
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

class _BusCard extends StatelessWidget {
  final LiveBus bus;
  final VoidCallback onDelete;
  final Function(bool) onStatusToggle;

  const _BusCard({
    required this.bus,
    required this.onDelete,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRunning = bus.status == "RUNNING";
    final Color statusColor = isRunning ? Colors.green : Colors.orange;

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
          // Header: Bus ID, Status Switch, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bus ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bus.busId,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const Spacer(),

              // Status Switch
              Row(
                children: [
                  Text(
                    isRunning ? "RUNNING" : "IDLE",
                     style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  Switch(
                    value: isRunning,
                    activeThumbColor: Colors.green,
                    inactiveThumbColor: Colors.orange,
                    inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                    onChanged: onStatusToggle,
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Name
          Text(
            bus.routeName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Metadata Row: Speed
          Row(
            children: [
              const Icon(Icons.speed, size: 16, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                '${bus.speedKmph.toStringAsFixed(0)} km/h',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
