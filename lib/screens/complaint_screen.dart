import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'tripId': 'TRIP-8294', // Mock Trip ID
        'busNumber': '402',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Complaint submitted successfully! We will review it.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11131E), // Dark theme to match design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'File a Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What went wrong?',
              style: AppTextStyles.heading2
                  .copyWith(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              "We're sorry you had a bad experience. Please share the details so we can improve.",
              style: TextStyle(color: Colors.grey[400], height: 1.5),
            ),
            const SizedBox(height: 24),

            // Trip Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C29),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'TRIP #8294',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bus 402 - Downtown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                color: Colors.grey[500], size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Today, 08:30 AM',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // Placeholder for map snippet
                    child: const Icon(Icons.map, color: Colors.grey),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(),

            const SizedBox(height: 24),

            // Issue Category
            const Text(
              'Issue Category',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C29),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text('Select a category',
                      style: TextStyle(color: Colors.grey[400])),
                  dropdownColor: const Color(0xFF1A1C29),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.yellow),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: [
                    'Late Arrival',
                    'Rude Behavior',
                    'Cleanliness',
                    'Safety Issue'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A1C29),
                hintText: 'Tell us more details about what happened...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.yellow),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Evidence
            Row(
              children: [
                const Text(
                  'Add Evidence',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Optional)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Add Photo Button
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C29),
                    borderRadius: BorderRadius.circular(20), // Squircle
                    border: Border.all(
                      color: Colors.grey[700]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.grey[400]),
                      const SizedBox(height: 4),
                      Text(
                        'ADD PHOTO',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Existing Photo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C29),
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage(
                          'assets/images/bus_interior.jpg'), // Placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Submit Complaint',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send_rounded),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
