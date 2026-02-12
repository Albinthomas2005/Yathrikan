
class RouteHistoryItem {
  final String origin;
  final String destination;
  final DateTime lastViewed;

  RouteHistoryItem({
    required this.origin,
    required this.destination,
    required this.lastViewed,
  });

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'destination': destination,
        'lastViewed': lastViewed.toIso8601String(),
      };

  factory RouteHistoryItem.fromJson(Map<String, dynamic> json) {
    return RouteHistoryItem(
      origin: json['origin'],
      destination: json['destination'],
      lastViewed: DateTime.parse(json['lastViewed']),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
