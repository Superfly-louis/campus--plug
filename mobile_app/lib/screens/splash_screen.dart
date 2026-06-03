import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_router.dart';
import '../services/auth_service.dart';
import '../widgets/campus_plug_logo.dart';
import 'onboarding_screen.dart';
import '../core/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 10), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.reloadProfile();

    if (authService.currentUserProfile == null) {
      await authService.ensureUserProfile(
        uid: authUser.uid,
        email: authUser.email ?? '',
      );
    }

    if (!mounted) return;
    AppRouter.go(context, authService.currentUserProfile);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashGlow(
            alignment: Alignment.topRight,
            colors: [
              AppConstants.splashGlowOrange,
              AppConstants.primaryColor,
              Colors.transparent,
            ],
            offset: Offset(0.32, -0.22),
            sizeFactor: 1.35,
            intensity: 1.0,
          ),
          const _SplashGlow(
            alignment: Alignment.bottomLeft,
            colors: [
              AppConstants.splashGlowGreen,
              AppConstants.secondaryColor,
              AppConstants.splashGlowOrange,
              Colors.transparent,
            ],
            offset: Offset(-0.28, 0.32),
            sizeFactor: 1.45,
            intensity: 1.0,
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: CampusPlugLogo(
                width: logoWidth.clamp(220.0, 320.0),
                heroTag: 'app_logo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashGlow extends StatelessWidget {
  const _SplashGlow({
    required this.alignment,
    required this.colors,
    required this.offset,
    this.sizeFactor = 1.0,
    this.intensity = 1.0,
  });

  final Alignment alignment;
  final List<Color> colors;
  final Offset offset;
  final double sizeFactor;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final glowSize = size.shortestSide * 0.95 * sizeFactor;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          offset.dx * size.width,
          offset.dy * size.height,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _glowBlob(
              diameter: glowSize * 1.15,
              blur: 72,
              alpha: 0.38 * intensity,
            ),
            _glowBlob(
              diameter: glowSize * 0.72,
              blur: 42,
              alpha: 0.62 * intensity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob({
    required double diameter,
    required double blur,
    required double alpha,
  }) {
    return Center(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                for (final c in colors)
                  c == Colors.transparent
                      ? Colors.transparent
                      : c.withValues(alpha: alpha),
              ],
              stops: List.generate(
                colors.length,
                (i) => i / (colors.length - 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
