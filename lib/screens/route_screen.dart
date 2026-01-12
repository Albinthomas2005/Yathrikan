import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../utils/app_localizations.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                loc.translate('routes'),
                style: AppTextStyles.heading1.copyWith(
                    fontSize: 32,
                    color: theme.textTheme.displayLarge?.color ??
                        theme.textTheme.titleLarge?.color),
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
                        loc.translate('route_planning'),
                        style: AppTextStyles.heading2.copyWith(
                            fontSize: 24,
                            color: theme.textTheme.titleLarge?.color),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      Text(
                        loc.translate('coming_soon_desc'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyRegular.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[400]
                              : AppColors.greyText,
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
