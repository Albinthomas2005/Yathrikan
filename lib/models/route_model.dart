class RouteModel {
  final String id;
  final String name;
  final String fromLocation;
  final String toLocation;
  final String frequency;
  final String? nextIn;
  final int activeBuses;
  final bool isActive;
  final bool isTrending;
  final bool isFastest;
  final String? viaRoute;

  RouteModel({
    required this.id,
    required this.name,
    required this.fromLocation,
    required this.toLocation,
    required this.frequency,
    this.nextIn,
    required this.activeBuses,
    this.isActive = true,
    this.isTrending = false,
    this.isFastest = false,
    this.viaRoute,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] as String,
      name: json['name'] as String,
      fromLocation: json['fromLocation'] as String,
      toLocation: json['toLocation'] as String,
      frequency: json['frequency'] as String,
      nextIn: json['nextIn'] as String?,
      activeBuses: json['activeBuses'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isTrending: json['isTrending'] as bool? ?? false,
      isFastest: json['isFastest'] as bool? ?? false,
      viaRoute: json['viaRoute'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'frequency': frequency,
      'nextIn': nextIn,
      'activeBuses': activeBuses,
      'isActive': isActive,
      'isTrending': isTrending,
      'isFastest': isFastest,
      'viaRoute': viaRoute,
    };
  }
}

class RecentRoute {
  final RouteModel route;
  final DateTime timestamp;

  RecentRoute({
    required this.route,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

class FavoriteRoute {
  final String id;
  final String code;
  final String name;
  final String icon;

  FavoriteRoute({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
  });
}
