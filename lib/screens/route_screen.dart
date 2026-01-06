import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Routes',
                style: AppTextStyles.heading1.copyWith(fontSize: 32),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 30),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.map,
                          size: 80,
                          color: AppColors.primaryYellow,
                        ),
                      )
                          .animate()
                          .scale(
                            delay: 200.ms,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 24),
                      Text(
                        'Route Planning',
                        style: AppTextStyles.heading2.copyWith(fontSize: 24),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        'Find the best routes for your journey.\nComing soon!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: AppColors.greyText,
                          height: 1.5,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
