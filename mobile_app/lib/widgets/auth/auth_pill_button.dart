import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_constants.dart';

enum AuthPillButtonVariant { primary, social }

class AuthPillButton extends StatelessWidget {
  const AuthPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AuthPillButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AuthPillButtonVariant variant;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == AuthPillButtonVariant.primary;

    return SizedBox(
      width: double.infinity,
      height: AppConstants.authButtonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppConstants.primaryColor : AppConstants.socialButtonBg,
          foregroundColor: isPrimary ? Colors.white : AppConstants.textPrimary,
          elevation: 0,
          disabledBackgroundColor:
              isPrimary ? AppConstants.primaryColor.withValues(alpha: 0.6) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isPrimary ? Colors.white : AppConstants.primaryColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 10)],
                  Text(
                    label,
                    style: GoogleFonts.syne(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
