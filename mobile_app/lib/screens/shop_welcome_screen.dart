import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import 'shop_create_screen.dart';

class ShopWelcomeScreen extends StatelessWidget {
  const ShopWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  size: 120,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Let's get you\nstarted",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create your shop and start selling to students on campus.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstants.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ShopCreateScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Create Shop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
