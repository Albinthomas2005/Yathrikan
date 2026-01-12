import 'dart:async';
import '../models/live_bus_model.dart';

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

  void initialize() {
    if (_buses.isNotEmpty) return; // Already initialized

    // Add all 100 buses from the provided data
    _buses.addAll(_get100BusesData());

    // Start simulating movement every 4 seconds
    _startMovementSimulation();
  }

  void _startMovementSimulation() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _updateBusPositions();
    });
  }

  void _updateBusPositions() {
    for (int i = 0; i < _buses.length; i++) {
      _buses[i] = _buses[i].simulateMovement(4); // 4 seconds elapsed
    }
    _busStreamController.add(List.from(_buses));
  }

  void dispose() {
    _updateTimer?.cancel();
    _busStreamController.close();
  }

  List<LiveBus> _get100BusesData() {
    final busesJson = [
      {
        "busId": "KTM-001",
        "routeName": "Kottayam - Changanassery",
        "lat": 9.5951,
        "lon": 76.5223,
        "speedKmph": 34,
        "headingDeg": 145,
        "lastUpdated": "2026-01-08T12:00:01Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-002",
        "routeName": "Kottayam - Ettumanoor",
        "lat": 9.6524,
        "lon": 76.5559,
        "speedKmph": 41,
        "headingDeg": 12,
        "lastUpdated": "2026-01-08T12:00:02Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-003",
        "routeName": "Kottayam - Vaikom",
        "lat": 9.7263,
        "lon": 76.4102,
        "speedKmph": 29,
        "headingDeg": 310,
        "lastUpdated": "2026-01-08T12:00:03Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-004",
        "routeName": "Kottayam - Pala",
        "lat": 9.7145,
        "lon": 76.6841,
        "speedKmph": 36,
        "headingDeg": 85,
        "lastUpdated": "2026-01-08T12:00:04Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-005",
        "routeName": "Kottayam - Kanjirappally",
        "lat": 9.5244,
        "lon": 76.8012,
        "speedKmph": 52,
        "headingDeg": 130,
        "lastUpdated": "2026-01-08T12:00:05Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-006",
        "routeName": "Changanassery - Pala",
        "lat": 9.5713,
        "lon": 76.6305,
        "speedKmph": 47,
        "headingDeg": 40,
        "lastUpdated": "2026-01-08T12:00:06Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-007",
        "routeName": "Changanassery - Vaikom",
        "lat": 9.6235,
        "lon": 76.4588,
        "speedKmph": 33,
        "headingDeg": 325,
        "lastUpdated": "2026-01-08T12:00:07Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-008",
        "routeName": "Kottayam - Kumarakom",
        "lat": 9.6211,
        "lon": 76.4299,
        "speedKmph": 26,
        "headingDeg": 265,
        "lastUpdated": "2026-01-08T12:00:08Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-009",
        "routeName": "Vaikom - Ettumanoor",
        "lat": 9.7112,
        "lon": 76.5247,
        "speedKmph": 39,
        "headingDeg": 52,
        "lastUpdated": "2026-01-08T12:00:09Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-010",
        "routeName": "Pala - Kanjirappally",
        "lat": 9.6103,
        "lon": 76.7584,
        "speedKmph": 43,
        "headingDeg": 140,
        "lastUpdated": "2026-01-08T12:00:10Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-011",
        "routeName": "Kottayam Circular 1",
        "lat": 9.6044,
        "lon": 76.5231,
        "speedKmph": 21,
        "headingDeg": 210,
        "lastUpdated": "2026-01-08T12:00:11Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-012",
        "routeName": "Kottayam Circular 2",
        "lat": 9.6019,
        "lon": 76.5287,
        "speedKmph": 19,
        "headingDeg": 55,
        "lastUpdated": "2026-01-08T12:00:12Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-013",
        "routeName": "Kottayam - Pampady",
        "lat": 9.5863,
        "lon": 76.5855,
        "speedKmph": 38,
        "headingDeg": 110,
        "lastUpdated": "2026-01-08T12:00:13Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-014",
        "routeName": "Pampady - Pala",
        "lat": 9.6342,
        "lon": 76.6610,
        "speedKmph": 42,
        "headingDeg": 60,
        "lastUpdated": "2026-01-08T12:00:14Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-015",
        "routeName": "Pala - Erattupetta",
        "lat": 9.7004,
        "lon": 76.7803,
        "speedKmph": 37,
        "headingDeg": 98,
        "lastUpdated": "2026-01-08T12:00:15Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-016",
        "routeName": "Erattupetta - Mundakayam",
        "lat": 9.6213,
        "lon": 76.8566,
        "speedKmph": 49,
        "headingDeg": 135,
        "lastUpdated": "2026-01-08T12:00:16Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-017",
        "routeName": "Vaikom - Kumarakom",
        "lat": 9.6731,
        "lon": 76.4136,
        "speedKmph": 31,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:00:17Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-018",
        "routeName": "Kumarakom - Changanassery",
        "lat": 9.5668,
        "lon": 76.4712,
        "speedKmph": 35,
        "headingDeg": 170,
        "lastUpdated": "2026-01-08T12:00:18Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-019",
        "routeName": "Kottayam - Vaikom (Express)",
        "lat": 9.6555,
        "lon": 76.4412,
        "speedKmph": 55,
        "headingDeg": 290,
        "lastUpdated": "2026-01-08T12:00:19Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-020",
        "routeName": "Kottayam - Thalayolaparambu",
        "lat": 9.7481,
        "lon": 76.4855,
        "speedKmph": 44,
        "headingDeg": 15,
        "lastUpdated": "2026-01-08T12:00:20Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-021",
        "routeName": "Thalayolaparambu - Vaikom",
        "lat": 9.7633,
        "lon": 76.4324,
        "speedKmph": 32,
        "headingDeg": 260,
        "lastUpdated": "2026-01-08T12:00:21Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-022",
        "routeName": "Changanassery - Tiruvalla",
        "lat": 9.4612,
        "lon": 76.5675,
        "speedKmph": 40,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:00:22Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-023",
        "routeName": "Kanjirappally - Erumely",
        "lat": 9.4621,
        "lon": 76.8541,
        "speedKmph": 39,
        "headingDeg": 140,
        "lastUpdated": "2026-01-08T12:00:23Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-024",
        "routeName": "Erumely - Mundakayam",
        "lat": 9.4888,
        "lon": 76.8903,
        "speedKmph": 35,
        "headingDeg": 210,
        "lastUpdated": "2026-01-08T12:00:24Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-025",
        "routeName": "Pala Town Shuttle 1",
        "lat": 9.7167,
        "lon": 76.6853,
        "speedKmph": 18,
        "headingDeg": 320,
        "lastUpdated": "2026-01-08T12:00:25Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-026",
        "routeName": "Pala Town Shuttle 2",
        "lat": 9.7179,
        "lon": 76.6722,
        "speedKmph": 16,
        "headingDeg": 45,
        "lastUpdated": "2026-01-08T12:00:26Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-027",
        "routeName": "Kottayam - Neendoor",
        "lat": 9.6802,
        "lon": 76.5421,
        "speedKmph": 30,
        "headingDeg": 25,
        "lastUpdated": "2026-01-08T12:00:27Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-028",
        "routeName": "Neendoor - Vaikom",
        "lat": 9.7221,
        "lon": 76.4704,
        "speedKmph": 34,
        "headingDeg": 280,
        "lastUpdated": "2026-01-08T12:00:28Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-029",
        "routeName": "Kottayam - Kidangoor",
        "lat": 9.6642,
        "lon": 76.6383,
        "speedKmph": 37,
        "headingDeg": 70,
        "lastUpdated": "2026-01-08T12:00:29Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-030",
        "routeName": "Kidangoor - Pala",
        "lat": 9.6903,
        "lon": 76.6877,
        "speedKmph": 32,
        "headingDeg": 90,
        "lastUpdated": "2026-01-08T12:00:30Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-031",
        "routeName": "Kottayam - Bharananganam",
        "lat": 9.6505,
        "lon": 76.6552,
        "speedKmph": 45,
        "headingDeg": 75,
        "lastUpdated": "2026-01-08T12:00:31Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-032",
        "routeName": "Bharananganam - Pala",
        "lat": 9.7008,
        "lon": 76.6961,
        "speedKmph": 28,
        "headingDeg": 100,
        "lastUpdated": "2026-01-08T12:00:32Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-033",
        "routeName": "Kottayam - Manarcadu",
        "lat": 9.5693,
        "lon": 76.5788,
        "speedKmph": 27,
        "headingDeg": 145,
        "lastUpdated": "2026-01-08T12:00:33Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-034",
        "routeName": "Manarcadu - Ponkunnam",
        "lat": 9.5431,
        "lon": 76.7003,
        "speedKmph": 40,
        "headingDeg": 125,
        "lastUpdated": "2026-01-08T12:00:34Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-035",
        "routeName": "Ponkunnam - Kanjirappally",
        "lat": 9.5404,
        "lon": 76.7811,
        "speedKmph": 32,
        "headingDeg": 115,
        "lastUpdated": "2026-01-08T12:00:35Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-036",
        "routeName": "Kottayam - Kaduthuruthy",
        "lat": 9.7053,
        "lon": 76.5233,
        "speedKmph": 44,
        "headingDeg": 15,
        "lastUpdated": "2026-01-08T12:00:36Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-037",
        "routeName": "Kaduthuruthy - Vaikom",
        "lat": 9.7362,
        "lon": 76.4494,
        "speedKmph": 31,
        "headingDeg": 260,
        "lastUpdated": "2026-01-08T12:00:37Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-038",
        "routeName": "Changanassery Town Shuttle 1",
        "lat": 9.4421,
        "lon": 76.5488,
        "speedKmph": 14,
        "headingDeg": 20,
        "lastUpdated": "2026-01-08T12:00:38Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-039",
        "routeName": "Changanassery Town Shuttle 2",
        "lat": 9.4444,
        "lon": 76.5481,
        "speedKmph": 17,
        "headingDeg": 200,
        "lastUpdated": "2026-01-08T12:00:39Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-040",
        "routeName": "Kottayam - Kuravilangad",
        "lat": 9.7132,
        "lon": 76.6005,
        "speedKmph": 39,
        "headingDeg": 30,
        "lastUpdated": "2026-01-08T12:00:40Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-041",
        "routeName": "Kuravilangad - Pala",
        "lat": 9.7250,
        "lon": 76.6484,
        "speedKmph": 33,
        "headingDeg": 80,
        "lastUpdated": "2026-01-08T12:00:41Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-042",
        "routeName": "Kottayam - Parippu",
        "lat": 9.6402,
        "lon": 76.5045,
        "speedKmph": 21,
        "headingDeg": 295,
        "lastUpdated": "2026-01-08T12:00:42Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-043",
        "routeName": "Parippu - Vaikom",
        "lat": 9.6888,
        "lon": 76.4377,
        "speedKmph": 27,
        "headingDeg": 260,
        "lastUpdated": "2026-01-08T12:00:43Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-044",
        "routeName": "Kottayam - Ayarkunnam",
        "lat": 9.6191,
        "lon": 76.5860,
        "speedKmph": 36,
        "headingDeg": 95,
        "lastUpdated": "2026-01-08T12:00:44Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-045",
        "routeName": "Ayarkunnam - Pala",
        "lat": 9.6612,
        "lon": 76.6506,
        "speedKmph": 37,
        "headingDeg": 65,
        "lastUpdated": "2026-01-08T12:00:45Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-046",
        "routeName": "Ettumanoor Town Shuttle 1",
        "lat": 9.6691,
        "lon": 76.5665,
        "speedKmph": 13,
        "headingDeg": 140,
        "lastUpdated": "2026-01-08T12:00:46Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-047",
        "routeName": "Ettumanoor Town Shuttle 2",
        "lat": 9.6705,
        "lon": 76.5612,
        "speedKmph": 11,
        "headingDeg": 310,
        "lastUpdated": "2026-01-08T12:00:47Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-048",
        "routeName": "Kottayam - Uzhavoor",
        "lat": 9.7311,
        "lon": 76.6122,
        "speedKmph": 42,
        "headingDeg": 40,
        "lastUpdated": "2026-01-08T12:00:48Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-049",
        "routeName": "Uzhavoor - Pala",
        "lat": 9.7442,
        "lon": 76.6588,
        "speedKmph": 34,
        "headingDeg": 95,
        "lastUpdated": "2026-01-08T12:00:49Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-050",
        "routeName": "Kottayam - Vakathanam",
        "lat": 9.5677,
        "lon": 76.5522,
        "speedKmph": 28,
        "headingDeg": 150,
        "lastUpdated": "2026-01-08T12:00:50Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-051",
        "routeName": "Vakathanam - Changanassery",
        "lat": 9.5144,
        "lon": 76.5721,
        "speedKmph": 32,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:00:51Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-052",
        "routeName": "Kottayam - Karukachal",
        "lat": 9.5202,
        "lon": 76.6302,
        "speedKmph": 37,
        "headingDeg": 120,
        "lastUpdated": "2026-01-08T12:00:52Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-053",
        "routeName": "Karukachal - Ponkunnam",
        "lat": 9.5166,
        "lon": 76.6928,
        "speedKmph": 34,
        "headingDeg": 120,
        "lastUpdated": "2026-01-08T12:00:53Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-054",
        "routeName": "Kottayam - Mallappally (via Changanassery)",
        "lat": 9.4833,
        "lon": 76.6172,
        "speedKmph": 46,
        "headingDeg": 205,
        "lastUpdated": "2026-01-08T12:00:54Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-055",
        "routeName": "Kottayam - Kodungoor",
        "lat": 9.5561,
        "lon": 76.6082,
        "speedKmph": 39,
        "headingDeg": 130,
        "lastUpdated": "2026-01-08T12:00:55Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-056",
        "routeName": "Kodungoor - Ponkunnam",
        "lat": 9.5423,
        "lon": 76.6681,
        "speedKmph": 31,
        "headingDeg": 115,
        "lastUpdated": "2026-01-08T12:00:56Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-057",
        "routeName": "Kottayam Night Service 1",
        "lat": 9.5999,
        "lon": 76.5342,
        "speedKmph": 22,
        "headingDeg": 180,
        "lastUpdated": "2026-01-08T12:00:57Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-058",
        "routeName": "Kottayam Night Service 2",
        "lat": 9.6061,
        "lon": 76.5177,
        "speedKmph": 20,
        "headingDeg": 350,
        "lastUpdated": "2026-01-08T12:00:58Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-059",
        "routeName": "Kottayam - Chethipuzha",
        "lat": 9.4918,
        "lon": 76.5444,
        "speedKmph": 30,
        "headingDeg": 180,
        "lastUpdated": "2026-01-08T12:00:59Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-060",
        "routeName": "Chethipuzha - Changanassery",
        "lat": 9.4638,
        "lon": 76.5482,
        "speedKmph": 23,
        "headingDeg": 200,
        "lastUpdated": "2026-01-08T12:01:00Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-061",
        "routeName": "Kumarakom Tourist Shuttle 1",
        "lat": 9.6133,
        "lon": 76.4291,
        "speedKmph": 17,
        "headingDeg": 260,
        "lastUpdated": "2026-01-08T12:01:01Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-062",
        "routeName": "Kumarakom Tourist Shuttle 2",
        "lat": 9.6177,
        "lon": 76.4370,
        "speedKmph": 15,
        "headingDeg": 80,
        "lastUpdated": "2026-01-08T12:01:02Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-063",
        "routeName": "Kottayam - Neerattupuram (via Kumarakom)",
        "lat": 9.5801,
        "lon": 76.4653,
        "speedKmph": 39,
        "headingDeg": 220,
        "lastUpdated": "2026-01-08T12:01:03Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-064",
        "routeName": "Kottayam - Muttuchira",
        "lat": 9.7388,
        "lon": 76.5572,
        "speedKmph": 40,
        "headingDeg": 30,
        "lastUpdated": "2026-01-08T12:01:04Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-065",
        "routeName": "Muttuchira - Kuravilangad",
        "lat": 9.7344,
        "lon": 76.5884,
        "speedKmph": 27,
        "headingDeg": 80,
        "lastUpdated": "2026-01-08T12:01:05Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-066",
        "routeName": "Kottayam - Pallickathodu",
        "lat": 9.5640,
        "lon": 76.6130,
        "speedKmph": 35,
        "headingDeg": 130,
        "lastUpdated": "2026-01-08T12:01:06Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-067",
        "routeName": "Pallickathodu - Ponkunnam",
        "lat": 9.5389,
        "lon": 76.6745,
        "speedKmph": 30,
        "headingDeg": 115,
        "lastUpdated": "2026-01-08T12:01:07Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-068",
        "routeName": "Kottayam - Puthuppally",
        "lat": 9.5717,
        "lon": 76.5801,
        "speedKmph": 31,
        "headingDeg": 120,
        "lastUpdated": "2026-01-08T12:01:08Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-069",
        "routeName": "Puthuppally - Manarcadu",
        "lat": 9.5633,
        "lon": 76.5950,
        "speedKmph": 24,
        "headingDeg": 150,
        "lastUpdated": "2026-01-08T12:01:09Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-070",
        "routeName": "Kottayam - Kooroppada",
        "lat": 9.5550,
        "lon": 76.6094,
        "speedKmph": 33,
        "headingDeg": 135,
        "lastUpdated": "2026-01-08T12:01:10Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-071",
        "routeName": "Kooroppada - Karukachal",
        "lat": 9.5312,
        "lon": 76.6401,
        "speedKmph": 26,
        "headingDeg": 145,
        "lastUpdated": "2026-01-08T12:01:11Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-072",
        "routeName": "Kottayam - Elikulam",
        "lat": 9.6299,
        "lon": 76.6322,
        "speedKmph": 29,
        "headingDeg": 80,
        "lastUpdated": "2026-01-08T12:01:12Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-073",
        "routeName": "Elikulam - Pala",
        "lat": 9.6802,
        "lon": 76.6921,
        "speedKmph": 31,
        "headingDeg": 90,
        "lastUpdated": "2026-01-08T12:01:13Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-074",
        "routeName": "Kottayam - Thiruvalla (via Changanassery)",
        "lat": 9.4790,
        "lon": 76.6012,
        "speedKmph": 48,
        "headingDeg": 205,
        "lastUpdated": "2026-01-08T12:01:14Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-075",
        "routeName": "Kottayam - Kattachira",
        "lat": 9.6270,
        "lon": 76.5033,
        "speedKmph": 23,
        "headingDeg": 310,
        "lastUpdated": "2026-01-08T12:01:15Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-076",
        "routeName": "Kattachira - Ettumanoor",
        "lat": 9.6542,
        "lon": 76.5490,
        "speedKmph": 27,
        "headingDeg": 45,
        "lastUpdated": "2026-01-08T12:01:16Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-077",
        "routeName": "Kottayam - Athirampuzha",
        "lat": 9.6522,
        "lon": 76.5461,
        "speedKmph": 19,
        "headingDeg": 15,
        "lastUpdated": "2026-01-08T12:01:17Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-078",
        "routeName": "Athirampuzha - Ettumanoor",
        "lat": 9.6690,
        "lon": 76.5621,
        "speedKmph": 21,
        "headingDeg": 40,
        "lastUpdated": "2026-01-08T12:01:18Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-079",
        "routeName": "Kottayam - Aymanam",
        "lat": 9.5930,
        "lon": 76.5004,
        "speedKmph": 24,
        "headingDeg": 260,
        "lastUpdated": "2026-01-08T12:01:19Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-080",
        "routeName": "Aymanam - Kumarakom",
        "lat": 9.6091,
        "lon": 76.4469,
        "speedKmph": 30,
        "headingDeg": 250,
        "lastUpdated": "2026-01-08T12:01:20Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-081",
        "routeName": "Kottayam - Cherpunkal",
        "lat": 9.6644,
        "lon": 76.6204,
        "speedKmph": 33,
        "headingDeg": 70,
        "lastUpdated": "2026-01-08T12:01:21Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-082",
        "routeName": "Cherpunkal - Pala",
        "lat": 9.7042,
        "lon": 76.6760,
        "speedKmph": 29,
        "headingDeg": 95,
        "lastUpdated": "2026-01-08T12:01:22Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-083",
        "routeName": "Kottayam - Edathuva (via Changanassery)",
        "lat": 9.4532,
        "lon": 76.5611,
        "speedKmph": 44,
        "headingDeg": 210,
        "lastUpdated": "2026-01-08T12:01:23Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-084",
        "routeName": "Kottayam - Vazhappally",
        "lat": 9.4688,
        "lon": 76.5644,
        "speedKmph": 27,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:01:24Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-085",
        "routeName": "Vazhappally - Changanassery",
        "lat": 9.4499,
        "lon": 76.5518,
        "speedKmph": 18,
        "headingDeg": 200,
        "lastUpdated": "2026-01-08T12:01:25Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-086",
        "routeName": "Kottayam - Melukavu",
        "lat": 9.7082,
        "lon": 76.7592,
        "speedKmph": 36,
        "headingDeg": 95,
        "lastUpdated": "2026-01-08T12:01:26Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-087",
        "routeName": "Melukavu - Erattupetta",
        "lat": 9.6938,
        "lon": 76.7912,
        "speedKmph": 28,
        "headingDeg": 105,
        "lastUpdated": "2026-01-08T12:01:27Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-088",
        "routeName": "Kottayam - Naduvathom",
        "lat": 9.5844,
        "lon": 76.5401,
        "speedKmph": 22,
        "headingDeg": 200,
        "lastUpdated": "2026-01-08T12:01:28Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-089",
        "routeName": "Naduvathom - Changanassery",
        "lat": 9.5308,
        "lon": 76.5572,
        "speedKmph": 26,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:01:29Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-090",
        "routeName": "Kottayam - Chengalam",
        "lat": 9.6201,
        "lon": 76.6061,
        "speedKmph": 29,
        "headingDeg": 110,
        "lastUpdated": "2026-01-08T12:01:30Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-091",
        "routeName": "Chengalam - Pala",
        "lat": 9.6644,
        "lon": 76.6741,
        "speedKmph": 28,
        "headingDeg": 95,
        "lastUpdated": "2026-01-08T12:01:31Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-092",
        "routeName": "Kottayam - Kidangoor (Fast Passenger)",
        "lat": 9.6801,
        "lon": 76.6331,
        "speedKmph": 52,
        "headingDeg": 60,
        "lastUpdated": "2026-01-08T12:01:32Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-093",
        "routeName": "Kottayam - Chingavanam",
        "lat": 9.5711,
        "lon": 76.5142,
        "speedKmph": 25,
        "headingDeg": 210,
        "lastUpdated": "2026-01-08T12:01:33Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-094",
        "routeName": "Chingavanam - Changanassery",
        "lat": 9.5204,
        "lon": 76.5262,
        "speedKmph": 31,
        "headingDeg": 200,
        "lastUpdated": "2026-01-08T12:01:34Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-095",
        "routeName": "Kottayam - Poovanthuruthu",
        "lat": 9.6310,
        "lon": 76.4940,
        "speedKmph": 24,
        "headingDeg": 280,
        "lastUpdated": "2026-01-08T12:01:35Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-096",
        "routeName": "Poovanthuruthu - Vaikom",
        "lat": 9.6777,
        "lon": 76.4301,
        "speedKmph": 33,
        "headingDeg": 270,
        "lastUpdated": "2026-01-08T12:01:36Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-097",
        "routeName": "Kottayam - Pampady (Circular)",
        "lat": 9.5755,
        "lon": 76.5688,
        "speedKmph": 20,
        "headingDeg": 130,
        "lastUpdated": "2026-01-08T12:01:37Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-098",
        "routeName": "Ettumanoor - Caritas Hospital Shuttle",
        "lat": 9.6730,
        "lon": 76.5690,
        "speedKmph": 12,
        "headingDeg": 190,
        "lastUpdated": "2026-01-08T12:01:38Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-099",
        "routeName": "Kottayam - Collectorate Shuttle",
        "lat": 9.6151,
        "lon": 76.5283,
        "speedKmph": 10,
        "headingDeg": 40,
        "lastUpdated": "2026-01-08T12:01:39Z",
        "status": "RUNNING"
      },
      {
        "busId": "KTM-100",
        "routeName": "Kottayam - MG University Shuttle",
        "lat": 9.6663,
        "lon": 76.5695,
        "speedKmph": 18,
        "headingDeg": 10,
        "lastUpdated": "2026-01-08T12:01:40Z",
        "status": "RUNNING"
      },
    ];

    return busesJson.map((json) => LiveBus.fromJson(json)).toList();
  }
}
