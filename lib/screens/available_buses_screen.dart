import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class AvailableBusesScreen extends StatelessWidget {
  const AvailableBusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlack,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlack,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Available Buses',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', true),
                _buildFilterChip('Favorites', false),
                _buildFilterChip('Express', false),
                _buildFilterChip('Local', false),
              ].animate(interval: 50.ms).fadeIn().slideX(),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NEARBY ROUTES',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Bus List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildBusCard(
                  busNumber: '102',
                  type: 'BUS',
                  from: 'Downtown',
                  to: 'Central Park',
                  timeLeft: '2 min',
                  status: 'On time',
                  statusColor: Colors.green,
                  imagePath:
                      'assets/images/bus_yellow.png', // Placeholder or use Icon
                ),
                _buildBusCard(
                  busNumber: '55B',
                  type: 'RAPID',
                  from: 'Airport',
                  to: 'City Center',
                  timeLeft: '12 min',
                  status: '+4 min delay',
                  statusColor: Colors.orange,
                  imagePath: 'assets/images/bus_circle.png',
                ),
                _buildBusCard(
                  busNumber: '12',
                  type: 'BUS',
                  from: 'West Side',
                  to: 'Union Station',
                  timeLeft: '18 min',
                  status: 'On time',
                  statusColor: Colors.green,
                  imagePath: 'assets/images/bus_icon.png',
                ),
                _buildBusCard(
                  busNumber: '8',
                  type: 'BUS',
                  from: 'North Hills',
                  to: 'Market St',
                  timeLeft: '24 min',
                  status: 'On time',
                  statusColor: Colors.green,
                  imagePath: 'assets/images/bus_icon.png',
                ),
              ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Chip(
        label: Text(label),
        backgroundColor:
            isSelected ? AppColors.primaryYellow : const Color(0xFF1E1E1E),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side:
            isSelected ? BorderSide.none : const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildBusCard({
    required String busNumber,
    required String type,
    required String from,
    required String to,
    required String timeLeft,
    required String status,
    required Color statusColor,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515), // Slightly lighter than bg
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Bus Image/Icon
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            // Placeholder for actual image
            child: const Icon(Icons.directions_bus, color: Colors.black),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      busNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      from,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    Icon(Icons.arrow_right_alt,
                        color: Colors.grey[600], size: 16),
                    Text(
                      to,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeLeft,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
