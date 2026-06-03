import 'package:firebase_auth/firebase_auth.dart';
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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                'Log In',
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
              const SizedBox(height: 14),
              AuthSwitchLink(
                prompt: "Don't have an account?",
                actionLabel: 'Sign Up',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),
              AuthPillButton(
                label: 'Log In',
                isLoading: _isLoading,
                onPressed: () => _handleLogin(authService),
              ),
              const SizedBox(height: 14),
              AuthPillButton(
                label: 'Log In with Google',
                variant: AuthPillButtonVariant.social,
                icon: Text(
                  'G',
                  style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              AuthPillButton(
                label: 'Log In with Apple',
                variant: AuthPillButtonVariant.social,
                icon: const Icon(Icons.apple, size: 22),
                onPressed: () {},
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(AuthService authService) async {
    setState(() => _isLoading = true);
    try {
      await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (authService.currentUserProfile == null) {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          await authService.ensureUserProfile(
            uid: current.uid,
            email: current.email ?? _emailController.text.trim(),
          );
        }
      }
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
