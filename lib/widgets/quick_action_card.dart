import 'package:flutter/material.dart';
import '../utils/constants.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBlack,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow
                    .withValues(alpha: 0.2), // Or just a dark placeholder
                shape: BoxShape.circle,
              ),
              // In design, icon is yellow on dark bg, maybe no circle bg?
              // Design shows small yellow icon.
              child: Icon(icon, color: AppColors.primaryYellow, size: 24),
            ),
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
