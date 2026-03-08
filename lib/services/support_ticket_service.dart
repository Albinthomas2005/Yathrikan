import 'dart:async';
import 'dart:math';

class SupportTicketService {
  static final SupportTicketService _instance = SupportTicketService._internal();
  factory SupportTicketService() => _instance;
  SupportTicketService._internal();

  // State
  final List<Map<String, dynamic>> _pendingTickets = [
    {
      'id': '#BW-10294',
      'title': 'Route Delay',
      'description':
          'Bus 402 on the Downtown route is consistently 20 minutes late every morning. I\'ve been late ...',
      'priority': 'HIGH',
      'userName': null,
      'upvotes': 1,
      'category': 'Timing Issue',
      'busId': 'KL-00-AA-0000',
      'evidence': [], // List of file paths
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': '#BW-10311',
      'title': 'Driver Conduct',
      'description':
          'The driver was extremely rude when I asked for a stop. He drove past the designated station...',
      'priority': 'MEDIUM',
      'userName': 'Sarah M.',
      'category': 'Staff Behavior',
      'busId': 'KL-35-A-5566',
      'evidence': [],
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '#BW-10325',
      'title': 'App Error',
      'description':
          'Unable to recharge my wallet using Apple Pay. It keeps saying \'Transaction Failed\' but the...',
      'priority': 'LOW',
      'userName': 'Anonymous',
      'category': 'Other',
      'busId': null,
      'evidence': [],
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  final List<Map<String, dynamic>> _inProgressTickets = [];
  final List<Map<String, dynamic>> _resolvedTickets = [];

  // Streams for UI
  final _pendingController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _inProgressController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _resolvedController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get pendingStream => _pendingController.stream;
  Stream<List<Map<String, dynamic>>> get inProgressStream => _inProgressController.stream;
  Stream<List<Map<String, dynamic>>> get resolvedStream => _resolvedController.stream;

  List<Map<String, dynamic>> get pendingTickets => List.unmodifiable(_pendingTickets);
  List<Map<String, dynamic>> get inProgressTickets => List.unmodifiable(_inProgressTickets);
  List<Map<String, dynamic>> get resolvedTickets => List.unmodifiable(_resolvedTickets);

  void _broadcastUpdates() {
    _pendingController.add(pendingTickets);
    _inProgressController.add(inProgressTickets);
    _resolvedController.add(resolvedTickets);
  }

  /// Adds a new ticket from the user side.
  void addTicket({
    required String title,
    required String description,
    required String category,
    String? busId,
    List<Map<String, dynamic>>? evidenceFiles,
  }) {
    final randomStr = (10000 + Random().nextInt(90000)).toString();
    final newTicket = {
      'id': '#YW-$randomStr', // Yathrikan Web/App
      'title': title,
      'description': description,
      'priority': _determinePriority(category),
      'userName': 'User (App)',
      'category': category,
      'busId': busId,
      'evidence': evidenceFiles ?? [],
      'timestamp': DateTime.now(),
    };

    _pendingTickets.insert(0, newTicket); // Add to top
    _broadcastUpdates();
  }

  /// Resolves an existing ticket.
  void resolveTicket(String id) {
    int pendingIndex = _pendingTickets.indexWhere((t) => t['id'] == id);
    if (pendingIndex != -1) {
      final ticket = _pendingTickets.removeAt(pendingIndex);
      _resolvedTickets.insert(0, ticket);
      _broadcastUpdates();
      return;
    }

    int inProgressIndex = _inProgressTickets.indexWhere((t) => t['id'] == id);
    if (inProgressIndex != -1) {
      final ticket = _inProgressTickets.removeAt(inProgressIndex);
      _resolvedTickets.insert(0, ticket);
      _broadcastUpdates();
    }
  }

  void moveToInProgress(String id) {
     int pendingIndex = _pendingTickets.indexWhere((t) => t['id'] == id);
    if (pendingIndex != -1) {
      final ticket = _pendingTickets.removeAt(pendingIndex);
      _inProgressTickets.insert(0, ticket);
      _broadcastUpdates();
    }
  }

  String _determinePriority(String category) {
    if (category == 'Reckless Driving') return 'HIGH';
    if (category == 'Bus Condition') return 'MEDIUM';
    if (category == 'Staff Behavior') return 'MEDIUM';
    return 'LOW';
  }

  void dispose() {
    _pendingController.close();
    _inProgressController.close();
    _resolvedController.close();
  }
}
