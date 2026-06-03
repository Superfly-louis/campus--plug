import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/app_constants.dart';
import '../core/auth_errors.dart';
import '../core/app_router.dart';
import '../widgets/auth/auth_illustration.dart';
import '../widgets/auth/auth_pill_button.dart';
import '../widgets/auth/auth_switch_link.dart';
import '../widgets/auth/auth_text_field.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isVendor;
  const SignupScreen({super.key, this.isVendor = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthIllustration(),
              Text(
                widget.isVendor ? 'Sign Up as Vendor' : 'Sign Up',
                style: GoogleFonts.syne(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                label: 'E-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Confirm password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 14),
              AuthSwitchLink(
                prompt: 'Already have an account?',
                actionLabel: 'Log In',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),
              AuthPillButton(
                label: 'Sign Up',
                isLoading: _isLoading,
                onPressed: () => _handleSignup(authService),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup(AuthService authService) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final namePart = email.split('@').first;
      final fullName = namePart.isNotEmpty
          ? namePart[0].toUpperCase() + namePart.substring(1)
          : 'Campus User';

      await authService.signUp(
        email: email,
        password: _passwordController.text.trim(),
        fullName: fullName,
        campusId: AppConstants.defaultCampusId,
        isVendor: widget.isVendor,
      );
      if (mounted) {
        AppRouter.go(context, authService.currentUserProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAuthError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
