import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/shop_welcome_screen.dart';

/// Central routing after splash, login, and signup.
class AppRouter {
  static Widget destinationFor(UserModel? profile) {
    if (profile == null) {
      return const LoginScreen();
    }
    if (!profile.hasSelectedRole) {
      return const RoleSelectionScreen();
    }
    if (profile.isVendor &&
        (profile.vendorId == null || profile.vendorId!.isEmpty)) {
      return const ShopWelcomeScreen();
    }
    return const HomeScreen();
  }

  static void go(
    BuildContext context,
    UserModel? profile, {
    int homeTab = 0,
  }) {
    final destination = destinationFor(profile);
    final Widget screen;
    if (destination is HomeScreen) {
      screen = HomeScreen(initialTab: homeTab);
    } else {
      screen = destination;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }
}
