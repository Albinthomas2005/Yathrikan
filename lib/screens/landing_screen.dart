import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryYellow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primaryYellow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.1,
                          child: Image.asset(
                            'assets/images/logo_circle.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),
                    Text(
                      'YATHRIKAN',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 40,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: -0.3, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Public Transport Assistant',
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Your Smart Transport Companion',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2,
                          )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 500.ms)
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: 16),
                          Text(
                            'Track buses in real-time, buy tickets digitally, and travel hassle-free.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyRegular.copyWith(
                              color: AppColors.greyText,
                              height: 1.5,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 700.ms, duration: 500.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlack,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 900.ms, duration: 500.ms)
                          .slideY(begin: 0.3, end: 0)
                          .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
