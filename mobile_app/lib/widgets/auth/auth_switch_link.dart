import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_constants.dart';

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.textPrimary,
            ),
            children: [
              TextSpan(text: '$prompt '),
              TextSpan(
                text: actionLabel,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.linkBlue,
                  decoration: TextDecoration.underline,
                  decorationColor: AppConstants.linkBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
