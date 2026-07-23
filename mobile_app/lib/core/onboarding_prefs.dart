import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';

/// Device-local persistence for the marketing onboarding slides.
///
/// This is intentionally local (not Firestore): the slides run before auth,
/// and should not reappear on every logout. A reinstall clears the flag
/// (expected), so first-launch after install shows onboarding again.
class OnboardingPrefs {
  OnboardingPrefs._();

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  static Future<void> setCompleted({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, value);
  }
}
