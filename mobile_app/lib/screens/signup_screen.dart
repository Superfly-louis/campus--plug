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
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedCampusId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
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
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthTextField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Full name is required';
                        if (value.trim().length < 2) return 'Minimum 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Phone Number',
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Phone number is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Campus',
                            style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.labelGreen,
                            ),
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedCampusId,
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
                              borderSide: const BorderSide(color: AppConstants.inputBorderOrange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
                              borderSide: const BorderSide(color: AppConstants.inputBorderOrange),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
                              borderSide: const BorderSide(
                                color: AppConstants.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: AppConstants.campuses.map((campus) {
                            return DropdownMenuItem<String>(
                              value: campus['id'],
                              child: Text(campus['name']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCampusId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please select a campus';
                            return null;
                          },
                        ),
                      ],
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
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (value) {
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final fullName = _fullNameController.text.trim();
      final phoneNumber = _phoneNumberController.text.trim();

      await authService.signUp(
        email: email,
        password: _passwordController.text.trim(),
        fullName: fullName,
        phoneNumber: phoneNumber,
        campusId: _selectedCampusId!,
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
