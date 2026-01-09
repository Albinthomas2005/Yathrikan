import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../utils/constants.dart';

class BusFormDialog extends StatefulWidget {
  final Bus? bus;
  final Function(Bus) onSave;

  const BusFormDialog({
    super.key,
    this.bus,
    required this.onSave,
  });

  @override
  State<BusFormDialog> createState() => _BusFormDialogState();
}

class _BusFormDialogState extends State<BusFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNumberController;
  late TextEditingController _routeNameController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late TextEditingController _frequencyController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _busNumberController =
        TextEditingController(text: widget.bus?.busNumber ?? '');
    _routeNameController =
        TextEditingController(text: widget.bus?.routeName ?? '');
    _startTimeController =
        TextEditingController(text: widget.bus?.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.bus?.endTime ?? '');
    _frequencyController =
        TextEditingController(text: widget.bus?.frequency ?? '');
    _isActive = widget.bus?.isActive ?? true;
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _routeNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkBlack,
              onPrimary: AppColors.primaryYellow,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      final formattedTime = picked.format(context);
      controller.text = formattedTime;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final bus = Bus(
        id: widget.bus?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        busNumber: _busNumberController.text.trim(),
        routeName: _routeNameController.text.trim(),
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        frequency: _frequencyController.text.trim(),
        isActive: _isActive,
        createdAt: widget.bus?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(bus);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bus != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Bus' : 'Add New Bus',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bus Number
                _buildTextField(
                  controller: _busNumberController,
                  label: 'Bus Number',
                  hint: 'e.g., KL-07-1234',
                  icon: Icons.confirmation_number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bus number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Route Name
                _buildTextField(
                  controller: _routeNameController,
                  label: 'Route Name',
                  hint: 'e.g., Kochi - Thrissur',
                  icon: Icons.route,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter route name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Time & End Time
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _startTimeController,
                        label: 'Start Time',
                        hint: '6:00 AM',
                        icon: Icons.access_time,
                        readOnly: true,
                        onTap: () => _selectTime(_startTimeController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _endTimeController,
                        label: 'End Time',
                        hint: '10:00 PM',
                        icon: Icons.access_time,
                        readOnly: true,
                        onTap: () => _selectTime(_endTimeController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Frequency
                _buildTextField(
                  controller: _frequencyController,
                  label: 'Frequency',
                  hint: 'e.g., Every 15 minutes',
                  icon: Icons.repeat,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter frequency';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Active Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.toggle_on_outlined),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Active Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeThumbColor: AppColors.darkBlack,
                        activeTrackColor: AppColors.primaryYellow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlack,
                          foregroundColor: AppColors.primaryYellow,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEditing ? 'Update' : 'Add Bus'),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.darkBlack,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
