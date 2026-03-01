import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _busController;
  late AnimationController _progressController;
  late AnimationController _cloudController;
  late AnimationController _fadeController;

  late Animation<double> _progressAnimation;
  late Animation<double> _cloudAnimation;
  late Animation<double> _fadeAnimation;

  bool _navigated = false;
  User? _cachedUser;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Fade in controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Cloud drift controller — loops forever
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _cloudAnimation = CurvedAnimation(
      parent: _cloudController,
      curve: Curves.linear,
    );

    // Bus drive controller - just for wheel bounce effect
    _busController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Progress bar / bus movement — exactly 3 seconds, no repeat
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    );

    // Pre-fetch auth state in parallel so it's ready when bar finishes
    _prefetchAuth();

    // Navigate the instant the progress animation hits 100%
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _doNavigate();
      }
    });

    // Safety fallback: use Timer in case the status listener misfires
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!_navigated && mounted) {
        _doNavigate();
      }
    });

    _progressController.forward();
  }

  Future<void> _prefetchAuth() async {
    _cachedUser = FirebaseAuth.instance.currentUser;
    if (_cachedUser != null) {
      _isAdmin = await AdminService().isAdmin(_cachedUser!.email ?? '');
    }
  }

  void _doNavigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    if (_cachedUser != null) {
      if (_isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }


  @override
  void dispose() {
    _busController.dispose();
    _progressController.dispose();
    _cloudController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppColors.primaryYellow,
        body: Stack(
          children: [
            // ── Clouds top ───────────────────────────────────────────────
            AnimatedBuilder(
              animation: _cloudAnimation,
              builder: (context, _) {
                final offset = _cloudAnimation.value * 30 - 15;
                return Stack(
                  children: [
                    Positioned(
                      top: 30 + offset,
                      left: -20,
                      child: const _Cloud(width: 110, height: 55),
                    ),
                    Positioned(
                      top: 20 - offset * 0.6,
                      right: -10,
                      child: const _Cloud(width: 90, height: 45),
                    ),
                    Positioned(
                      top: 80 + offset * 0.4,
                      left: size.width * 0.35,
                      child: const _Cloud(width: 70, height: 36),
                    ),
                    Positioned(
                      top: 45 - offset * 0.8,
                      left: size.width * 0.7,
                      child: const _Cloud(width: 80, height: 40),
                    ),
                    Positioned(
                      top: 10 + offset * 1.2,
                      left: size.width * 0.15,
                      child: const _Cloud(width: 60, height: 30),
                    ),
                  ],
                );
              },
            ),

            // ── Title ───────────────────────────────────────────────────
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  Text(
                    'YATHRIKAN',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading your journey...',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Trees bottom-left ────────────────────────────────────────
            const Positioned(
              bottom: 80,
              left: -10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Tree(height: 120),
                  SizedBox(width: 6),
                  _Tree(height: 95),
                  SizedBox(width: 6),
                  _Tree(height: 110),
                ],
              ),
            ),

            // ── Trees bottom-right ───────────────────────────────────────
            const Positioned(
              bottom: 80,
              right: -10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Tree(height: 100),
                  SizedBox(width: 6),
                  _Tree(height: 125),
                  SizedBox(width: 6),
                  _Tree(height: 90),
                ],
              ),
            ),

            // ── Road + Bus ───────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bus driving across (synced with progress)
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      // Bus starts at left, ends at far right of the progress bar
                      // Using progress bar value which goes 0.0 -> 1.0 continuously over 4s
                      final busX =
                          24.0 + _progressAnimation.value * (size.width - 48.0 - 80.0);
                      return SizedBox(
                        width: size.width,
                        height: 50,
                        child: Stack(
                          children: [
                            Positioned(
                              left: busX,
                              bottom: 0,
                              child: const _BusWidget(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Road / progress bar track
                  Container(
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF222222),
                                    Color(0xFF000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cloud widget ──────────────────────────────────────────────────────────────
class _Cloud extends StatelessWidget {
  final double width;
  final double height;
  const _Cloud({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CloudPainter()),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final cx = size.width * 0.5;
    final cy = size.height * 0.6;
    final r = size.height * 0.38;

    // Shadow
    canvas.drawCircle(Offset(cx, cy + 4), r * 1.1, shadow);

    // Body
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..addOval(
          Rect.fromCircle(center: Offset(cx - r * 0.7, cy), radius: r * 0.7))
      ..addOval(
          Rect.fromCircle(center: Offset(cx + r * 0.7, cy), radius: r * 0.7))
      ..addOval(
          Rect.fromCircle(center: Offset(cx - r * 0.3, cy - r * 0.5), radius: r * 0.65))
      ..addOval(
          Rect.fromCircle(center: Offset(cx + r * 0.3, cy - r * 0.5), radius: r * 0.55));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Tree widget ───────────────────────────────────────────────────────────────
class _Tree extends StatelessWidget {
  final double height;
  const _Tree({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.55,
      height: height,
      child: CustomPaint(painter: _TreePainter()),
    );
  }
}

class _TreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dark = Color(0xFF1A2340);
    const darker = Color(0xFF111827);
    final trunkPaint = Paint()..color = darker;
    final leafPaint = Paint()..color = dark;

    final cx = size.width / 2;
    final trunkW = size.width * 0.18;
    final trunkH = size.height * 0.22;

    // Trunk
    canvas.drawRect(
      Rect.fromLTWH(
          cx - trunkW / 2, size.height - trunkH, trunkW, trunkH),
      trunkPaint,
    );

    // Three layered triangles
    _drawTriangle(
        canvas,
        leafPaint,
        Offset(cx, 0),
        Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.55));
    _drawTriangle(
        canvas,
        leafPaint,
        Offset(cx, size.height * 0.2),
        Offset(size.width * 0.06, size.height * 0.7),
        Offset(size.width * 0.94, size.height * 0.7));
    _drawTriangle(
        canvas,
        leafPaint,
        Offset(cx, size.height * 0.42),
        Offset(size.width * 0.12, size.height * 0.82),
        Offset(size.width * 0.88, size.height * 0.82));
  }

  void _drawTriangle(
      Canvas canvas, Paint paint, Offset top, Offset bl, Offset br) {
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(bl.dx, bl.dy)
      ..lineTo(br.dx, br.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bus widget ────────────────────────────────────────────────────────────────
class _BusWidget extends StatelessWidget {
  const _BusWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 44,
      child: CustomPaint(painter: _BusPainter()),
    );
  }
}

class _BusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF1A2340);
    final yellowPaint = Paint()..color = AppColors.primaryYellow;
    final windowPaint = Paint()..color = const Color(0xFFD0E8F5);

    final w = size.width;
    final h = size.height;

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.1, w, h * 0.75),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Front bumper highlight
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.5, w * 0.06, h * 0.25),
        yellowPaint);

    // Windows
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.2, h * 0.3),
            const Radius.circular(3)),
        windowPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.35, h * 0.18, w * 0.2, h * 0.3),
            const Radius.circular(3)),
        windowPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.2, h * 0.3),
            const Radius.circular(3)),
        windowPaint);

    // Stripe
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.52, w, h * 0.06), darkPaint);

    // Wheels
    canvas.drawCircle(Offset(w * 0.22, h * 0.87), h * 0.13, darkPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.87), h * 0.13, darkPaint);
    canvas.drawCircle(
        Offset(w * 0.22, h * 0.87), h * 0.07, Paint()..color = Colors.grey.shade400);
    canvas.drawCircle(
        Offset(w * 0.75, h * 0.87), h * 0.07, Paint()..color = Colors.grey.shade400);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
