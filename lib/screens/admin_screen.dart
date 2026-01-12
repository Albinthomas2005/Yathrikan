import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../models/bus_model.dart';
import '../services/bus_service.dart';
import '../widgets/animated_notification.dart';
import '../widgets/bus_form_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final BusService _busService = BusService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddBusDialog() {
    showDialog(
      context: context,
      builder: (_) => BusFormDialog(
        onSave: (bus) async {
          try {
            await _busService.addBus(bus);
            if (mounted) {
              AnimatedNotification.showSuccess(
                context,
                title: 'Success',
                message: 'Bus added successfully!',
                duration: const Duration(seconds: 2),
              );
            }
          } catch (e) {
            if (mounted) {
              AnimatedNotification.showError(
                context,
                title: 'Error',
                message: e.toString(),
                duration: const Duration(seconds: 3),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditBusDialog(Bus bus) {
    showDialog(
      context: context,
      builder: (_) => BusFormDialog(
        bus: bus,
        onSave: (updatedBus) async {
          try {
            await _busService.updateBus(updatedBus);
            if (mounted) {
              AnimatedNotification.showSuccess(
                context,
                title: 'Success',
                message: 'Bus updated successfully!',
                duration: const Duration(seconds: 2),
              );
            }
          } catch (e) {
            if (mounted) {
              AnimatedNotification.showError(
                context,
                title: 'Error',
                message: e.toString(),
                duration: const Duration(seconds: 3),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteBus(Bus bus) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bus'),
        content: Text('Are you sure you want to delete bus ${bus.busNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _busService.deleteBus(bus.id);
                if (mounted) {
                  AnimatedNotification.showSuccess(
                    context,
                    title: 'Success',
                    message: 'Bus deleted successfully!',
                    duration: const Duration(seconds: 2),
                  );
                }
              } catch (e) {
                if (mounted) {
                  AnimatedNotification.showError(
                    context,
                    title: 'Error',
                    message: e.toString(),
                    duration: const Duration(seconds: 3),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleBusStatus(Bus bus) async {
    try {
      await _busService.toggleBusStatus(bus.id, !bus.isActive);
      if (mounted) {
        AnimatedNotification.showSuccess(
          context,
          title: 'Success',
          message: 'Bus status updated!',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        AnimatedNotification.showError(
          context,
          title: 'Error',
          message: e.toString(),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBlack,
              foregroundColor: AppColors.primaryYellow,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo_circle.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 24,
                                ),
                              ),
                              const Text(
                                'Bus Management System',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by bus number or route...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

            // Bus List
            Expanded(
              child: StreamBuilder<List<Bus>>(
                stream: _busService.getBusesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkBlack,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  final buses = snapshot.data ?? [];
                  final filteredBuses = _searchQuery.isEmpty
                      ? buses
                      : buses
                          .where((bus) =>
                              bus.busNumber
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              bus.routeName
                                  .toLowerCase()
                                  .contains(_searchQuery))
                          .toList();

                  if (filteredBuses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.directions_bus_outlined
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No buses added yet'
                                : 'No buses found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              'Tap the + button to add a bus',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = filteredBuses[index];
                      return _BusListItem(
                        bus: bus,
                        onEdit: () => _showEditBusDialog(bus),
                        onDelete: () => _deleteBus(bus),
                        onToggleStatus: () => _toggleBusStatus(bus),
                      )
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                          .slideX(begin: 0.2, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBusDialog,
        backgroundColor: AppColors.darkBlack,
        foregroundColor: AppColors.primaryYellow,
        icon: const Icon(Icons.add),
        label: const Text('Add Bus'),
      )
          .animate()
          .fadeIn(delay: 600.ms, duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

class _BusListItem extends StatelessWidget {
  final Bus bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _BusListItem({
    required this.bus,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bus.busNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bus.routeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bus.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: bus.isActive ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bus.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: bus.isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.access_time,
                      label: '${bus.startTime} - ${bus.endTime}',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.repeat,
                      label: bus.frequency,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        bus.isActive
                            ? Icons.toggle_on
                            : Icons.toggle_off_outlined,
                      ),
                      color: bus.isActive ? Colors.green : Colors.grey,
                      tooltip: bus.isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.blue,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
