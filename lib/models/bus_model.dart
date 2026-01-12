class Bus {
  final String id;
  final String busNumber;
  final String routeName;
  final String startTime;
  final String endTime;
  final String frequency; // e.g., "Every 15 minutes"
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bus({
    required this.id,
    required this.busNumber,
    required this.routeName,
    required this.startTime,
    required this.endTime,
    required this.frequency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Bus to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'routeName': routeName,
      'startTime': startTime,
      'endTime': endTime,
      'frequency': frequency,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Bus from Firestore JSON
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] ?? '',
      busNumber: json['busNumber'] ?? '',
      routeName: json['routeName'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      frequency: json['frequency'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Create a copy with updated fields
  Bus copyWith({
    String? id,
    String? busNumber,
    String? routeName,
    String? startTime,
    String? endTime,
    String? frequency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      routeName: routeName ?? this.routeName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
