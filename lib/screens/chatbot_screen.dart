import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
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
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
        });
      },
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    // Send the recognized message
    if (_messageController.text.isNotEmpty) {
      _sendMessage(_messageController.text);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': message,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();

    // Simulate bot response
    Future.delayed(const Duration(milliseconds: 500), () {
      final botResponse = _getBotResponse(message);

      setState(() {
        _messages.add({
          'text': botResponse,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });

      // Speak the bot response
      _speak(botResponse);
    });
  }

  String _getBotResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('bus') &&
        (msg.contains('where') || msg.contains('location'))) {
      return 'I can help you track your bus! Please share your booking ID or route number.';
    } else if (msg.contains('ticket') || msg.contains('status')) {
      return 'To check your ticket status, please provide your ticket ID starting with BW.';
    } else if (msg.contains('delay') || msg.contains('report')) {
      return 'I\'m sorry to hear about the delay. Please share the route number so I can help you file a report.';
    } else if (msg.contains('route') || msg.contains('shortest')) {
      return 'I can help you find the shortest route! Where are you traveling from and to?';
    } else if (msg.contains('hello') || msg.contains('hi')) {
      return 'Hello! I\'m your BusWay Assistant. How can I help you today?';
    } else if (msg.contains('thank')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    } else {
      return 'I\'m here to help! You can ask me about bus locations, ticket status, delays, or routes.';
    }
  }

  void _handleQuickQuestion(String question) {
    _sendMessage(question);
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
                    'BusWay Assistant',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Bot Icon
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 50,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'BusWay Assistant',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Hello! How can I help you today?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Instructions
          Text(
            'TAP THE MIC OR TYPE BELOW',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Questions
          Text(
            'QUICK SUGGESTIONS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickButton(
            icon: Icons.directions_bus,
            label: 'Where is my bus?',
            onTap: () => _handleQuickQuestion('Where is my bus?'),
          ),
          const SizedBox(height: 12),
          _buildQuickButton(
            icon: Icons.confirmation_number,
            label: 'Check ticket status',
            onTap: () => _handleQuickQuestion('Check my ticket status'),
          ),
          const SizedBox(height: 12),
          _buildQuickButton(
            icon: Icons.warning,
            label: 'Report a delay',
            onTap: () => _handleQuickQuestion('I want to report a delay'),
          ),
          const SizedBox(height: 12),
          _buildQuickButton(
            icon: Icons.route,
            label: 'Find shortest route',
            onTap: () => _handleQuickQuestion('Find the shortest route for me'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryYellow,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message['isUser'] as bool;

        return Align(
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
        );
      },
    );
  }
}
