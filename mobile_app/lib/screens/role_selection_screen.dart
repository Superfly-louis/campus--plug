import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../core/app_constants.dart';
import '../core/auth_errors.dart';
import '../core/app_router.dart';
import '../widgets/campus_plug_logo.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Required post-signup step — block system back from skipping role choice.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CampusPlugLogo(width: 200, heroTag: 'app_logo'),
                const SizedBox(height: 48),
                const Text(
                  'Are you a...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                _buildRoleButton(
                  title: 'Vendor',
                  subtitle: 'I want to sell products/services',
                  icon: Icons.storefront,
                  isVendor: true,
                ),
                const SizedBox(height: 20),
                _buildRoleButton(
                  title: 'Buyer',
                  subtitle: 'I want to shop for items',
                  icon: Icons.shopping_bag_outlined,
                  isVendor: false,
                ),
                const SizedBox(height: 60),
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVendor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleRoleSelection(isVendor),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRoleSelection(bool isVendor) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final currentUser = authService.currentUserProfile;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile not loaded. Please log in again.'),
          ),
        );
        return;
      }

      // Write only role fields — do not rewrite createdAt / full profile via toJson.
      await firestoreService.updateUserFields(currentUser.id, {
        'isVendor': isVendor,
        'hasSelectedRole': true,
      });
      authService.updateLocalProfile(
        currentUser.copyWith(
          isVendor: isVendor,
          hasSelectedRole: true,
        ),
      );

      if (!mounted) return;
      AppRouter.go(context, authService.currentUserProfile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthError(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
