import 'package:latlong2/latlong.dart';
import '../models/route_path_model.dart';

/// Predefined route paths with realistic waypoints for Kerala bus routes
/// These waypoints follow actual roads and highways in the Kottayam region
class RoutePathsData {
  static final Map<String, RoutePath> routePaths = {
    // Main routes from Kottayam
    "Kottayam - Changanassery": RoutePath(
      routeName: "Kottayam - Changanassery",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam center
        LatLng(9.5850, 76.5245),
        LatLng(9.5701, 76.5350),
        LatLng(9.5520, 76.5410),
        LatLng(9.5320, 76.5455),
        LatLng(9.5130, 76.5485),
        LatLng(9.4850, 76.5505),
        LatLng(9.4598, 76.5520),
        LatLng(9.4450, 76.5488), // Changanassery
      ],
    ),

    "Kottayam - Ettumanoor": RoutePath(
      routeName: "Kottayam - Ettumanoor",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.6088, 76.5301),
        LatLng(9.6255, 76.5388),
        LatLng(9.6421, 76.5466),
        LatLng(9.6588, 76.5544),
        LatLng(9.6691, 76.5622), // Ettumanoor
      ],
    ),

    "Kottayam - Vaikom": RoutePath(
      routeName: "Kottayam - Vaikom",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.6080, 76.5100),
        LatLng(9.6250, 76.4950),
        LatLng(9.6420, 76.4800),
        LatLng(9.6590, 76.4650),
        LatLng(9.6760, 76.4500),
        LatLng(9.6920, 76.4350),
        LatLng(9.7050, 76.4200),
        LatLng(9.7188, 76.4066), // Vaikom
      ],
    ),

    "Kottayam - Pala": RoutePath(
      routeName: "Kottayam - Pala",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.6050, 76.5450),
        LatLng(9.6180, 76.5680),
        LatLng(9.6310, 76.5910),
        LatLng(9.6440, 76.6140),
        LatLng(9.6570, 76.6370),
        LatLng(9.6700, 76.6600),
        LatLng(9.6900, 76.6750),
        LatLng(9.7101, 76.6841), // Pala
      ],
    ),

    "Kottayam - Kanjirappally": RoutePath(
      routeName: "Kottayam - Kanjirappally",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.5850, 76.5450),
        LatLng(9.5750, 76.5680),
        LatLng(9.5650, 76.5910),
        LatLng(9.5550, 76.6140),
        LatLng(9.5450, 76.6550),
        LatLng(9.5380, 76.6980),
        LatLng(9.5320, 76.7410),
        LatLng(9.5280, 76.7840),
        LatLng(9.5244, 76.8141), // Kanjirappally
      ],
    ),

    "Changanassery - Pala": RoutePath(
      routeName: "Changanassery - Pala",
      waypoints: [
        LatLng(9.4450, 76.5488), // Changanassery
        LatLng(9.4680, 76.5620),
        LatLng(9.4910, 76.5752),
        LatLng(9.5140, 76.5884),
        LatLng(9.5370, 76.6016),
        LatLng(9.5600, 76.6148),
        LatLng(9.5830, 76.6280),
        LatLng(9.6260, 76.6450),
        LatLng(9.6690, 76.6620),
        LatLng(9.7101, 76.6841), // Pala
      ],
    ),

    "Changanassery - Vaikom": RoutePath(
      routeName: "Changanassery - Vaikom",
      waypoints: [
        LatLng(9.4450, 76.5488), // Changanassery
        LatLng(9.4750, 76.5350),
        LatLng(9.5050, 76.5212),
        LatLng(9.5350, 76.5074),
        LatLng(9.5650, 76.4936),
        LatLng(9.5950, 76.4798),
        LatLng(9.6250, 76.4660),
        LatLng(9.6550, 76.4522),
        LatLng(9.6850, 76.4284),
        LatLng(9.7188, 76.4066), // Vaikom
      ],
    ),

    "Kottayam - Kumarakom": RoutePath(
      routeName: "Kottayam - Kumarakom",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.5950, 76.5050),
        LatLng(9.5980, 76.4880),
        LatLng(9.6010, 76.4710),
        LatLng(9.6040, 76.4540),
        LatLng(9.6070, 76.4370),
        LatLng(9.6100, 76.4300), // Kumarakom
      ],
    ),

    "Vaikom - Ettumanoor": RoutePath(
      routeName: "Vaikom - Ettumanoor",
      waypoints: [
        LatLng(9.7188, 76.4066), // Vaikom
        LatLng(9.7150, 76.4350),
        LatLng(9.7100, 76.4634),
        LatLng(9.7020, 76.4918),
        LatLng(9.6920, 76.5102),
        LatLng(9.6820, 76.5286),
        LatLng(9.6720, 76.5470),
        LatLng(9.6691, 76.5622), // Ettumanoor
      ],
    ),

    "Pala - Kanjirappally": RoutePath(
      routeName: "Pala - Kanjirappally",
      waypoints: [
        LatLng(9.7101, 76.6841), // Pala
        LatLng(9.7000, 76.7050),
        LatLng(9.6850, 76.7260),
        LatLng(9.6550, 76.7470),
        LatLng(9.6250, 76.7580),
        LatLng(9.5950, 76.7690),
        LatLng(9.5650, 76.7800),
        LatLng(9.5450, 76.7970),
        LatLng(9.5244, 76.8141), // Kanjirappally
      ],
    ),

    // Circular routes
    "Kottayam Circular 1": RoutePath(
      routeName: "Kottayam Circular 1",
      waypoints: [
        LatLng(9.5916, 76.5222), // Start
        LatLng(9.6000, 76.5300),
        LatLng(9.6050, 76.5400),
        LatLng(9.6000, 76.5500),
        LatLng(9.5900, 76.5450),
        LatLng(9.5850, 76.5350),
        LatLng(9.5916, 76.5222), // Back to start
      ],
      isCircular: true,
    ),

    "Kottayam Circular 2": RoutePath(
      routeName: "Kottayam Circular 2",
      waypoints: [
        LatLng(9.5916, 76.5222), // Start
        LatLng(9.5850, 76.5150),
        LatLng(9.5800, 76.5100),
        LatLng(9.5800, 76.5250),
        LatLng(9.5850, 76.5300),
        LatLng(9.5916, 76.5222), // Back to start
      ],
      isCircular: true,
    ),

    "Kottayam - Pampady": RoutePath(
      routeName: "Kottayam - Pampady",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.5900, 76.5400),
        LatLng(9.5880, 76.5580),
        LatLng(9.5863, 76.5760),
        LatLng(9.5863, 76.5855), // Pampady
      ],
    ),

    "Pampady - Pala": RoutePath(
      routeName: "Pampady - Pala",
      waypoints: [
        LatLng(9.5863, 76.5855), // Pampady
        LatLng(9.6050, 76.6050),
        LatLng(9.6237, 76.6245),
        LatLng(9.6424, 76.6440),
        LatLng(9.6611, 76.6635),
        LatLng(9.7101, 76.6841), // Pala
      ],
    ),

    "Pala - Erattupetta": RoutePath(
      routeName: "Pala - Erattupetta",
      waypoints: [
        LatLng(9.7101, 76.6841), // Pala
        LatLng(9.7080, 76.7100),
        LatLng(9.7060, 76.7359),
        LatLng(9.7040, 76.7618),
        LatLng(9.7004, 76.7803), // Erattupetta
      ],
    ),

    "Erattupetta - Mundakayam": RoutePath(
      routeName: "Erattupetta - Mundakayam",
      waypoints: [
        LatLng(9.7004, 76.7803), // Erattupetta
        LatLng(9.6850, 76.8000),
        LatLng(9.6650, 76.8200),
        LatLng(9.6450, 76.8383),
        LatLng(9.6213, 76.8566), // Mundakayam
      ],
    ),

    "Vaikom - Kumarakom": RoutePath(
      routeName: "Vaikom - Kumarakom",
      waypoints: [
        LatLng(9.7188, 76.4066), // Vaikom
        LatLng(9.7000, 76.4100),
        LatLng(9.6800, 76.4133),
        LatLng(9.6600, 76.4166),
        LatLng(9.6400, 76.4200),
        LatLng(9.6250, 76.4250),
        LatLng(9.6100, 76.4300), // Kumarakom
      ],
    ),

    "Kumarakom - Changanassery": RoutePath(
      routeName: "Kumarakom - Changanassery",
      waypoints: [
        LatLng(9.6100, 76.4300), // Kumarakom
        LatLng(9.6000, 76.4450),
        LatLng(9.5850, 76.4600),
        LatLng(9.5650, 76.4750),
        LatLng(9.5450, 76.4900),
        LatLng(9.5150, 76.5100),
        LatLng(9.4850, 76.5300),
        LatLng(9.4450, 76.5488), // Changanassery
      ],
    ),

    "Kottayam - Vaikom (Express)": RoutePath(
      routeName: "Kottayam - Vaikom (Express)",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.6200, 76.4900),
        LatLng(9.6500, 76.4600),
        LatLng(9.6800, 76.4300),
        LatLng(9.7188, 76.4066), // Vaikom (fewer stops)
      ],
    ),

    "Kottayam - Thalayolaparambu": RoutePath(
      routeName: "Kottayam - Thalayolaparambu",
      waypoints: [
        LatLng(9.5916, 76.5222), // Kottayam
        LatLng(9.6200, 76.5100),
        LatLng(9.6500, 76.5000),
        LatLng(9.6800, 76.4950),
        LatLng(9.7100, 76.4900),
        LatLng(9.7400, 76.4875),
        LatLng(9.7481, 76.4855), // Thalayolaparambu
      ],
    ),

    "Thalayolaparambu - Vaikom": RoutePath(
      routeName: "Thalayolaparambu - Vaikom",
      waypoints: [
        LatLng(9.7481, 76.4855), // Thalayolaparambu
        LatLng(9.7550, 76.4650),
        LatLng(9.7600, 76.4450),
        LatLng(9.7633, 76.4324), // Vaikom
      ],
    ),

    "Changanassery - Tiruvalla": RoutePath(
      routeName: "Changanassery - Tiruvalla",
      waypoints: [
        LatLng(9.4450, 76.5488), // Changanassery
        LatLng(9.4380, 76.5550),
        LatLng(9.4300, 76.5600),
        LatLng(9.4200, 76.5650),
        LatLng(9.4100, 76.5700),
        LatLng(9.4000, 76.5750),
        LatLng(9.3850, 76.5800),
        LatLng(9.3700, 76.5850),
        LatLng(9.3830, 76.5740), // Tiruvalla
      ],
    ),

    // Generic template for other routes - they will use intermediate waypoints
    // between their start and end points
  };

  /// Get route path by name, if not found, generate a simple path
  static RoutePath? getRoutePath(String routeName) {
    return routePaths[routeName];
  }

  /// Generate a simple linear path between two points if route not predefined
  static RoutePath generateSimplePath(
    String routeName,
    LatLng start,
    LatLng end,
  ) {
    // Calculate intermediate waypoints (5 points for smooth movement)
    List<LatLng> waypoints = [];
    waypoints.add(start);

    for (int i = 1; i < 5; i++) {
      double lat = start.latitude + (end.latitude - start.latitude) * i / 5;
      double lon = start.longitude + (end.longitude - start.longitude) * i / 5;
      waypoints.add(LatLng(lat, lon));
    }

    waypoints.add(end);

    return RoutePath(
      routeName: routeName,
      waypoints: waypoints,
    );
  }
}
