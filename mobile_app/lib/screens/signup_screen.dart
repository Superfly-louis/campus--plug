import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/app_constants.dart';
import 'login_screen.dart';
import 'shop_welcome_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isVendor;
  const SignupScreen({super.key, this.isVendor = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedCampusId = AppConstants.campuses[0]['id']!;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: AppConstants.primaryColor,
                  size: 70,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isVendor ? 'Sign Up as Vendor' : 'Sign Up',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 32),
              _buildField(
                _fullNameController,
                'Full Name',
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildField(
                _emailController,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Campus Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCampusId,
                decoration: _inputDecoration('Campus', Icons.school_outlined),
                items: AppConstants.campuses.map((campus) {
                  return DropdownMenuItem(
                    value: campus['id'],
                    child: Text(campus['name']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCampusId = val!),
              ),
              const SizedBox(height: 16),
              _buildField(
                _passwordController,
                'Password',
                Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                toggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),
              _buildField(
                _confirmPasswordController,
                'Confirm Password',
                Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirm,
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleSignup(authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignup(AuthService authService) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        campusId: _selectedCampusId,
        isVendor: widget.isVendor,
      );
      if (mounted) {
        if (widget.isVendor) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ShopWelcomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: AppConstants.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppConstants.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword ? obscure : false,
      decoration: _inputDecoration(label, icon).copyWith(
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }
}
