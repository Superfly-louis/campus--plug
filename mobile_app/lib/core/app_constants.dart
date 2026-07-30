import 'package:flutter/material.dart';

class AppConstants {
  static const String logoAsset = 'assets/images/campus_plug_logo.png';

  // Brand Colors
  static const Color primaryColor = Color(0xFFFF8200);
  static const Color secondaryColor = Color(0xFF8CC63F);
  static const Color splashGlowOrange = Color(0xFFFFB347);
  static const Color splashGlowGreen = Color(0xFFB8E986);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color labelGreen = Color(0xFF9BC53D);
  static const Color inputBorderOrange = Color(0xFFFFC9A3);
  static const Color socialButtonBg = Color(0xFFF0F0F0);
  static const Color linkBlue = Color(0xFF2F80ED);

  static const String authIllustrationAsset =
      'assets/images/auth_hero.png';
  static const double authFieldHeight = 52;
  static const double authPillRadius = 30;
  static const double authButtonHeight = 54;
  static const int minPasswordLength = 6;
  static const Duration splashDuration = Duration(seconds: 10);

  /// Web OAuth client ID from Firebase (needed so Android returns an ID token).
  static const String googleWebClientId =
      '1020489811715-4uhb5p23i1ch62rsvcggij3a2st6uguj.apps.googleusercontent.com';

  /// ISO 4217 currency for Ghana (Campus Plug is GHS-only).
  static const String currencyCode = 'GHS';

  /// Typed confirmation required before deleting an account.
  static const String deleteAccountConfirmPhrase = 'DELETE';

  /// Local flag: marketing onboarding slides completed (device-scoped).
  static const String onboardingCompletedKey = 'has_completed_onboarding';

  /// Home product price filter bands (GHS). null min/max = unbounded.
  static const List<Map<String, dynamic>> productPriceBands = [
    {'id': 'all', 'label': 'Any price', 'min': null, 'max': null},
    {'id': 'under_50', 'label': 'Under 50', 'min': 0.0, 'max': 50.0},
    {'id': '50_100', 'label': '50–100', 'min': 50.0, 'max': 100.0},
    {'id': '100_200', 'label': '100–200', 'min': 100.0, 'max': 200.0},
    {'id': '200_plus', 'label': '200+', 'min': 200.0, 'max': null},
  ];

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String vendorsCollection = 'vendors';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String reviewsCollection = 'reviews';

  // Central University Ghana Campuses
  static const List<Map<String, String>> campuses = [
    {'id': 'cu_miotso', 'name': 'Miotso Campus'},
    {'id': 'cu_accra', 'name': 'Accra Campus'},
    {'id': 'cu_tema', 'name': 'Tema Campus'},
  ];

  static const String defaultCampusId = 'cu_miotso';
  static const String defaultCampusName = 'Central University - Miotso';

  // Product Categories
  static const List<Map<String, dynamic>> categories = [
    {'id': 'food', 'name': 'Food', 'icon': '🍔'},
    {'id': 'services', 'name': 'Services', 'icon': '🛠️'},
    {'id': 'electronics', 'name': 'Electronics', 'icon': '💻'},
    {'id': 'stationery', 'name': 'Stationery', 'icon': '📝'},
    {'id': 'tutoring', 'name': 'Tutoring', 'icon': '📖'},
    {'id': 'other', 'name': 'Other', 'icon': '📦'},
  ];
}