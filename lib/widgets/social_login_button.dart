import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData? iconData;
  final String? assetPath;
  final bool isAsset;

  const SocialLoginButton({
    super.key,
    this.onTap,
    this.iconData,
    this.assetPath,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: isAsset && assetPath != null
            ? Image.asset(assetPath!, width: 24, height: 24)
            : Icon(iconData, size: 24, color: Colors.black),
      ),
    );
  }
}
