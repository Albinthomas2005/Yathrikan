import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
=======
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
import '../utils/constants.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
<<<<<<< HEAD
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _busController = TextEditingController();

  String? _selectedCategory;
  // File? _evidenceImage; // Use File if using dart:io, for now using XFile or path

  final List<String> _categories = [
    'Reckless Driving',
    'Bus Condition',
    'Staff Behavior',
    'Timing Issue',
    'Other'
  ];

  // Mock Bus Database
  final Map<String, Map<String, String>> _busDatabase = {
    'KL-07-CD-1234': {'name': 'Lulu Express', 'route': 'Edappally - Vyttila'},
    'KL-35-A-5566': {'name': 'Royal Travels', 'route': 'Pala - Kottayam'},
    'KL-01-BK-9988': {'name': 'KSRTC Minnal', 'route': 'Trivandrum - Kannur'},
    'KL-55-R-7744': {'name': 'City Fast', 'route': 'Calicut - Wayanad'},
  };

  Map<String, String>? _selectedBusDetails;

  // List to store evidence. Each item: {'path': String, 'type': 'image' | 'video'}
  final List<Map<String, dynamic>> _evidenceFiles = [];

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();

    // Check permissions
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }

    if (!mounted) return;

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E201E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('Take Photo',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      setState(() {
                        _evidenceFiles
                            .add({'path': image.path, 'type': 'image'});
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.white),
                  title: const Text('Record Video',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? video =
                        await picker.pickVideo(source: ImageSource.camera);
                    if (video != null) {
                      setState(() {
                        _evidenceFiles
                            .add({'path': video.path, 'type': 'video'});
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Pick Photo from Gallery',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _evidenceFiles
                            .add({'path': image.path, 'type': 'image'});
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.white),
                  title: const Text('Pick Video from Gallery',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final XFile? video =
                        await picker.pickVideo(source: ImageSource.gallery);
                    if (video != null) {
                      setState(() {
                        _evidenceFiles
                            .add({'path': video.path, 'type': 'video'});
                      });
                    }
                  },
                ),
              ],
            ),
          );
        });
  }

  void _removeEvidence(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
    });
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFF1E201E), // Dark background
=======
      backgroundColor: const Color(0xFF11131E), // Dark theme to match design
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
<<<<<<< HEAD
        title: Text(
          "File a Complaint",
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
=======
        title: const Text(
          'File a Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
<<<<<<< HEAD
        padding: const EdgeInsets.all(24.0),
=======
        padding: const EdgeInsets.all(20),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
<<<<<<< HEAD
              "What went wrong?",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We're sorry you had a bad experience. Please share the details so we can improve.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Bus Number Search
            Text(
              "Bus Number",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _busDatabase.keys.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedBusDetails = _busDatabase[selection];
                      _busController.text =
                          selection; // Update external check if needed
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF111418),
                        hintText: "Enter Bus Number (e.g. KL-07...)",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                                color: AppColors.primaryYellow)),
                      ),
                    );
                  },
                );
              },
            ),

            if (_selectedBusDetails != null) ...[
              const SizedBox(height: 20),
              // Bus Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2F33),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_bus,
                          color: AppColors.primaryYellow),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBusDetails!['name'] ?? "Bus Name",
                          style: const TextStyle(
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
<<<<<<< HEAD
                        Text(
                          _selectedBusDetails!['route'] ?? "Route Info",
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            // Category Dropdown
            Text(
              "Issue Category",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF111418),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
<<<<<<< HEAD
                  hint: Text("Select a category",
                      style: TextStyle(color: Colors.grey.shade500)),
                  dropdownColor: const Color(0xFF111418),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.yellow),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _categories.map((String value) {
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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

<<<<<<< HEAD
            const SizedBox(height: 25),

            // Description
            Text(
              "Description",
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111418),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Tell us more details about what happened...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                ),
              ),
            ),

<<<<<<< HEAD
            const SizedBox(height: 25),

            // Add Evidence
            Row(
              children: [
                Text(
                  "Add Evidence",
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text("(Optional)",
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 15),
            // Horizontal Scroll for Media
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Add Photo/Video Button
                  GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111418),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Colors.grey.shade500, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            "ADD MEDIA",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Media Previews
                  ..._evidenceFiles.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> file = entry.value;
                    final bool isVideo = file['type'] == 'video';
                    final String path = file['path'];

                    return Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black,
                                image: isVideo
                                    ? null
                                    : DecorationImage(
                                        image: FileImage(File(path)),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              child: isVideo
                                  ? const Center(
                                      child: Icon(Icons.play_circle_fill,
                                          color: Colors.white, size: 40),
                                    )
                                  : null,
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeEvidence(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
<<<<<<< HEAD
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a category")),
                    );
                    return;
                  }
                  if (_selectedBusDetails == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select a valid bus number")),
                    );
                    return;
                  }

                  // Submit logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Complaint Submitted!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 1), () {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit Complaint',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
=======
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
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          ],
        ),
      ),
    );
  }
}
