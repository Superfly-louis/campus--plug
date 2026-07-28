import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_constants.dart';

class LiquidGlassNavItem {
  const LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
}

/// Floating pill bottom nav with cross-platform “liquid glass” blur.
/// Uses [BackdropFilter] so Android / Web / Windows get the same frosted look as iOS.
class LiquidGlassBottomNav extends StatelessWidget {
  const LiquidGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavTab(
                          item: items[i],
                          selected: currentIndex == i,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final LiquidGlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = selected ? item.activeIcon : item.icon;
    final showBadge = item.badgeCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppConstants.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      iconData,
                      size: 22,
                      color: AppConstants.textPrimary,
                    ),
                    if (showBadge)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            item.badgeCount > 99
                                ? '99+'
                                : '${item.badgeCount}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? AppConstants.primaryColor
                                  : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
