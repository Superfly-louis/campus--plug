import 'package:flutter/material.dart';
import '../../core/app_constants.dart';

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Image.asset(
        AppConstants.authIllustrationAsset,
        key: const ValueKey('auth_hero_v2'),
        height: 220,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: false,
      ),
    );
  }
}
