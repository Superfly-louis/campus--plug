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
  final _formKey = GlobalKey<FormState>();
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
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'E-mail',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'E-mail is required';
                        if (!value.contains('@') || !value.contains('.')) return 'Invalid e-mail format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (value) {
                        if (value == null || value.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.syne(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon — use email login for now')),
                  );
                },
              ),
              const SizedBox(height: 12),
              AuthPillButton(
                label: 'Log In with Apple',
                variant: AuthPillButtonVariant.social,
                icon: const Icon(Icons.apple, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon — use email login for now')),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;
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

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset Password', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) return;
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyAuthError(e))),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}
