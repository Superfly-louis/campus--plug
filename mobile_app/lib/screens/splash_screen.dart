import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon — replace with your actual asset later
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: AppConstants.primaryColor,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Campus',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Plug',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your campus marketplace',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
