import 'package:flutter/material.dart';
import '../core/app_constants.dart';

/// Main Campus Plug brand logo (icon + wordmark).
class CampusPlugLogo extends StatelessWidget {
  const CampusPlugLogo({
    super.key,
    this.width = 280,
    this.heroTag,
  });

  final double width;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppConstants.logoAsset,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: image);
    }
    return image;
  }
}
