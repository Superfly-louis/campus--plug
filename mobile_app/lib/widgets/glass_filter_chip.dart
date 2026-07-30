import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_constants.dart';

/// Frosted glass filter chip used on Home / Explore.
class GlassFilterChip extends StatelessWidget {
  const GlassFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onSelected,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected
                    ? AppConstants.primaryColor.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.45),
                border: Border.all(
                  color: selected
                      ? AppConstants.primaryColor
                      : Colors.white.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppConstants.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
