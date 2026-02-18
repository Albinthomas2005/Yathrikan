import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import 'shortest_route_screen.dart';

import '../services/bus_location_service.dart';
import '../models/live_bus_model.dart';
import 'dart:math';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  // Voice assistance
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isTyping = false;
  bool _voiceSent = false; // Prevent double-send from both _stopListening and _onSpeechStatus

  // Location Context
  String? _currentCity;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _getUserLocation();
  }

  // ... (init methods are fine, skipping to build method parts)

  // (Inside _buildMessageList)
  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                ],
              ),
            ),
          );
        }

        final message = _messages[index];
        final isUser = message['isUser'] as bool;

        final action = message['action'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primaryYellow : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message['text'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isUser ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            
            // Action Button
            if (action != null && action.startsWith('navigate_shortest_route') && !isUser) 
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map, size: 16),
                    label: Text(
                      "Check Shortest Route",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                       String? city;
                       if (action.contains(':')) {
                          city = action.split(':')[1];
                       }
                       Navigator.push(context, MaterialPageRoute(builder: (context) => ShortestRouteScreen(initialDestination: city)));
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5 + (0.5 * (value))),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        // Simple loop animation trigger could be added here if needed, 
        // but for now static pulsing is simulated or just simple dots.
        // For a true typing animation, we'd need a StatefulWidget or repetitive controller.
        // Keeping it simple static dots for this iteration to avoid state complexity complexity.
      },
    );
  }

  void _onSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (mounted && !_voiceSent) {
        final text = _messageController.text.trim();
        setState(() => _isListening = false);
        if (text.isNotEmpty) {
          _voiceSent = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _sendMessage(text);
          });
        }
      }
    }
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: _onSpeechStatus,
      debugLogging: true,
    );
    setState(() {});
  }

  void _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }



  void _startListening() async {
    // 1. Check Permission
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice commands')),
        );
      }
      return;
    }

    // 2. Initialize if needed
    if (!_speechEnabled) {
      bool available = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: _onSpeechStatus,
      );
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available on this device')),
          );
        }
        return;
      }
      _speechEnabled = true;
    }

    // 3. Clear previous text and start
    _messageController.clear();
    _voiceSent = false;
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _messageController.text = result.recognizedWords;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _stopListening() async {
    final text = _messageController.text.trim();
    await _speech.stop();
    setState(() => _isListening = false);
    // Auto-send whatever was recognized
    if (text.isNotEmpty && !_voiceSent) {
      _voiceSent = true;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _sendMessage(text);
      });
    }
  }



  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _isTyping = true; // Start typing indicator
    });

    _messageController.clear();

    // Simulate delay + processing
    Future.delayed(const Duration(milliseconds: 1000), () async {
      try {
        // Run smart response generation with a safety timeout
        final botResponse = await _generateSmartResponse(message).timeout(
          const Duration(seconds: 4), 
          onTimeout: () => "I took too long to think! Please try finding a route in the main menu.",
        );

        // Check if response warrants a navigation button
        String? action;
        String? city = _findCityInMessage(message);
        if (botResponse.contains('Here are the buses') ||
            botResponse.contains('next bus is') ||
            botResponse.contains('ETA:') ||
            botResponse.contains('currently running') ||
            botResponse.contains('arriving in')) {
          action = city != null
              ? 'navigate_shortest_route:$city'
              : 'navigate_shortest_route';
        }

        if (mounted) {
          setState(() {
            _messages.add({
              'text': botResponse,
              'isUser': false,
              'timestamp': DateTime.now(),
              'action': action,
            });
          });
          // Speak the bot response
          //_speak(botResponse);
        }
      } catch (e) {
        debugPrint("Chatbot Error: $e");
        if (mounted) {
          setState(() {
            _messages.add({
              'text': "Oops! My brain froze. Ask me about bus timings!",
              'isUser': false,
              'timestamp': DateTime.now(),
            });
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      }
    });
  }

  // Context Memory
  // String? _currentContext; // Removed for stateless style interactions mostly

  /// The "Brain" of the chatbot
  Future<String> _generateSmartResponse(String input) async {
    final msg = input.toLowerCase().trim();

    // 0. RESET
    if (_matches(msg, ['clear', 'reset', 'restart'])) {
      setState(() {
        _messages.clear();
      });
      return "Conversation cleared! I'm ready to help you finding your bus.";
    }

    // 1. GREETINGS
    if (_matches(msg, ['hello', 'hi', 'hey', 'morning', 'evening', 'yo']) && msg.length < 15) {
       final greetings = [
         "Hello there! Where are you planning to go today?",
         "Hi! I'm ready to find the best bus for you. Just name the city!",
         "Hey! Need to catch a bus? Tell me your destination.",
         "Greetings! I can track any bus in Kerala for you."
       ];
       return greetings[Random().nextInt(greetings.length)];
    }
    
    if (_matches(msg, ['thank', 'thanks', 'thx'])) {
      return "You're very welcome! Safe travels! 🚌";
    }

    // 2. BUS SPECIFIC QUERY (By Bus ID)
    final busIdRegex = RegExp(r'(kl[-\s]?eru|eru)[-\s]?(\d+)', caseSensitive: false);
    final busIdMatch = busIdRegex.firstMatch(msg);
    if (busIdMatch != null) {
      final num = busIdMatch.group(2)!.padLeft(3, '0');
      final searchId = 'KL-ERU-$num';
      final allBuses = BusLocationService().buses;
      try {
        final bus = allBuses.firstWhere((b) => b.busId == searchId);
        return _formatBusStatus(bus);
      } catch (e) {
        return "I couldn't find bus '$searchId'. We have KL-ERU-001 to KL-ERU-030. Try asking about one of those!";
      }
    }

    // 3. HOW MANY / COUNT
    if (_matches(msg, ['how many', 'count', 'total'])) {
      final svc = BusLocationService();
      final running = svc.buses.where((b) => b.status == 'RUNNING').length;
      return "There are $running buses currently running on the Erumely → Kottayam route. ${svc.buses.length} total including scheduled.";
    }

    // 4. NEAREST / NEXT BUS
    if (_matches(msg, ['nearest', 'next bus', 'coming soon', 'next one', 'soonest'])) {
      final svc = BusLocationService();
      final incoming = svc.buses.where((b) => svc.isIncoming(b) && b.status == 'RUNNING').toList();
      incoming.sort((a, b) => svc.etaMinutes(a).compareTo(svc.etaMinutes(b)));
      if (incoming.isNotEmpty) {
        final b = incoming.first;
        final eta = svc.etaMinutes(b);
        return "The next bus is ${b.busName} (${b.busId}), arriving in approximately $eta minutes!";
      }
      return "No buses are currently approaching your location.";
    }

    // 5. ROUTE QUERY — detect city anywhere in the message
    String? city = _findCityInMessage(msg);
    if (city != null) {
       String? origin = _findCityInMessage(msg.replaceAll(city.toLowerCase(), ''));
       String startLocation = origin ?? _currentCity ?? "Koovappally";
       
       final svc = BusLocationService();
       final incoming = svc.buses.where((b) => svc.isIncoming(b) && b.status == 'RUNNING').toList();
       incoming.sort((a, b) => svc.etaMinutes(a).compareTo(svc.etaMinutes(b)));
       
       if (incoming.isEmpty) {
         return "No buses are currently approaching $startLocation. They run on the Erumely → Kottayam route via $city.";
       }
       
       final top = incoming.take(5).toList();
       final buf = StringBuffer();
       buf.writeln('Here are the buses heading through $city:');
       buf.writeln();
       for (final b in top) {
         final eta = svc.etaMinutes(b);
         buf.writeln('🚌 ${b.busName} (${b.busId})');
         buf.writeln('   ETA: $eta min');
         buf.writeln();
       }
       buf.writeln('Tap "View Route" to track them on the map!');
       return buf.toString();
    }

    // 6. SHOW ALL BUSES (no city detected, but bus-related keywords)
    if (_matches(msg, ['bus', 'buses', 'show', 'list', 'all', 'running', 'available', 'route', 'schedule', 'going', 'travel', 'trip'])) {
      final svc = BusLocationService();
      final incoming = svc.buses.where((b) => svc.isIncoming(b) && b.status == 'RUNNING').toList();
      incoming.sort((a, b) => svc.etaMinutes(a).compareTo(svc.etaMinutes(b)));
      
      if (incoming.isEmpty) {
        return "No buses are currently approaching your location on the Erumely → Kottayam route.";
      }
      
      final top = incoming.take(5).toList();
      final buf = StringBuffer();
      buf.writeln('Here are the buses currently approaching:');
      buf.writeln();
      for (final b in top) {
        final eta = svc.etaMinutes(b);
        buf.writeln('🚌 ${b.busName} (${b.busId})');
        buf.writeln('   ETA: $eta min');
        buf.writeln();
      }
      buf.writeln('You can also try: "Bus to Kottayam" or "KL-ERU-005"');
      return buf.toString();
    }

    // 7. TICKET / BOOKING
    if (_matches(msg, ['ticket', 'book', 'fare', 'price'])) {
      return "You can book tickets in the 'Shortest Route' section. I'm just here to track them!";
    }
    
    // 8. DELAY
    if (_matches(msg, ['delay', 'late', 'slow'])) {
      return "Delays happen! If you tell me your bus number (e.g., KL-ERU-005), I can tell you exactly where it is.";
    }

    // 9. FALLBACK
    return "I can help you find buses! Try:\n\n"
           "• Type a city name: \"Kottayam\"\n"
           "• Ask for a bus: \"Bus to Pala\"\n"
           "• Track by ID: \"KL-ERU-005\"\n"
           "• Ask: \"Next bus\" or \"Show buses\"";
  }

  // --- LOGIC HELPERS ---

  /// Get user's current city
  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium)
      );

      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Prioritize locality (City)
        if (mounted) {
           setState(() {
             _currentCity = place.locality; 
           });
           debugPrint("Chatbot Location: $_currentCity");
        }
      }
    } catch (e) {
      debugPrint("Error getting location for chatbot: $e");
    }
  }

  String _formatBusStatus(LiveBus bus) {
    final status = bus.speedKmph > 0 ? "Moving at ${bus.speedKmph} km/h" : "Stopped";
    return "Found it! 🚌\n\n"
           "**${bus.busId}** (${bus.routeName})\n"
           "📍 Status: $status\n"
           "⏳ ETA: ${bus.etaMin} mins\n"
           "🕒 Last Updated: Just now\n"; 
           // In a real app we'd decode lat/lng to a place name here
  }





  /// List of supported cities for fuzzy matching
  final List<String> _supportedCities = BusLocationService.allPlaces;

  /// Detects if any supported city is present in the message
  String? _findCityInMessage(String message) {
    final words = message.split(' ');
    for (var word in words) {
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s]+'), '');
      if (cleanWord.length < 3) continue; 

      for (var city in _supportedCities) {
        // Direct match or close enough
        if (cleanWord.toLowerCase() == city.toLowerCase() || 
            _calculateLevenshtein(cleanWord.toLowerCase(), city.toLowerCase()) <= 2) {
          return city;
        }
      }
    }
    return null;
  }

  /// Levenshtein distance algorithm for fuzzy matching
  int _calculateLevenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  bool _matches(String message, List<String> keywords) {
    for (var word in keywords) {
      if (message.contains(word)) return true;
    }
    return false;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'Yathrikan Assistant',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Voice status indicator
            if (_isListening)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: AppColors.primaryYellow.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mic,
                      color: AppColors.primaryYellow,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Listening...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),

            // Messages or Welcome Screen
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildMessageList(),
            ),

            // Input Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening...'
                              : 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            color: _isListening
                                ? AppColors.primaryYellow
                                : Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: AppColors.primaryYellow,
                            ),
                            onPressed: () {
                              _sendMessage(_messageController.text);
                            },
                          ),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Voice button with active state
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color:
                            _isListening ? Colors.red : AppColors.primaryYellow,
                        shape: BoxShape.circle,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bot Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryYellow, width: 2),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 60,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Yathrikan AI',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'I can help you find buses, track trips, and check schedules instantly.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white60,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
