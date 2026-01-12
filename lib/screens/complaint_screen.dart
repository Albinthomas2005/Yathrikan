import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../utils/constants.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E201E), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "File a Complaint",
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
                                color: Colors.grey.withOpacity(0.2))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.2))),
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
                      color: AppColors.primaryYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.2),
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
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text("Select a category",
                      style: TextStyle(color: Colors.grey.shade500)),
                  dropdownColor: const Color(0xFF111418),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.yellow),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: _categories.map((String value) {
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
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Tell us more details about what happened...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),

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
                          color: Colors.grey.withOpacity(0.3),
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
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
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
                    if (mounted) Navigator.pop(context);
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Submit Complaint',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
