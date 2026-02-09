import 'dart:math';
import '../data/bus_stops.dart';

class BusSchedule {
  final String id;
  final String name; // e.g., "Super Fast", "Limited Stop"
  final String type; // "KSRTC", "Private"
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String price;
  final String seatAvailability;

  BusSchedule({
    required this.id,
    required this.name,
    required this.type,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.seatAvailability,
  });
}

class BusScheduleService {
  static final BusScheduleService _instance = BusScheduleService._internal();
  factory BusScheduleService() => _instance;
  BusScheduleService._internal();

  // Get all available stops for autocomplete
  List<String> getStops() {
    return kBusStops;
  }

  // Generate realistic schedules between two points
  List<BusSchedule> getSchedules(String from, String to) {
    if (!kBusStops.contains(from) || !kBusStops.contains(to)) {
      return [];
    }
    
    // Seed random with route string to ensure consistent results for same query
    final seed = (from + to).hashCode;
    final random = Random(seed);
    
    // Generate 3 to 8 buses
    final count = 3 + random.nextInt(6);
    final List<BusSchedule> schedules = [];

    // Base duration between 30 mins and 4 hours
    final baseDurationMinutes = 30 + random.nextInt(210);

    // Start time from "now"
    DateTime currentTime = DateTime.now();

    for (int i = 0; i < count; i++) {
      // Each bus departs 15-60 mins after the previous one
      final gapMinutes = 15 + random.nextInt(45);
      currentTime = currentTime.add(Duration(minutes: gapMinutes));
      
      // Variation in duration for different buses (faster/slower)
      final durationVariation = -10 + random.nextInt(20);
      final durationMinutes = baseDurationMinutes + durationVariation;
      
      final arrivalTime = currentTime.add(Duration(minutes: durationMinutes));
      
      final type = random.nextBool() ? "KSRTC" : "Private";
      final category = _getBusCategory(type, random);
      
      final price = (durationMinutes * (type == "KSRTC" ? 1.5 : 1.2)).round();

      schedules.add(BusSchedule(
        id: "${from.substring(0, 2)}${to.substring(0, 2)}$i".toUpperCase(),
        name: category,
        type: type,
        departureTime: _formatTime(currentTime),
        arrivalTime: _formatTime(arrivalTime),
        duration: _formatDuration(durationMinutes),
        price: "₹$price",
        seatAvailability: "${random.nextInt(20) + 1} seats",
      ));
    }

    return schedules;
  }

  String _getBusCategory(String type, Random random) {
    if (type == "KSRTC") {
      final categories = ["Super Fast", "Fast Passenger", "Super Express", "Minnal", "Low Floor AC"];
      return categories[random.nextInt(categories.length)];
    } else {
      final categories = ["Limited Stop", "Ordinary", "Executive"];
      return categories[random.nextInt(categories.length)];
    }
  }

  String _formatTime(DateTime time) {
    String period = "AM";
    int hour = time.hour;
    if (hour >= 12) {
      period = "PM";
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  String _formatDuration(int minutes) {
    final hrs = minutes ~/ 60;
    final mins = minutes % 60;
    if (hrs > 0) {
      return "${hrs}h ${mins}m";
    }
    return "${mins}m";
  }
}
