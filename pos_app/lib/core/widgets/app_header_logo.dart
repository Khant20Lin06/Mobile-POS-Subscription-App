import 'package:flutter/material.dart';

/// Clean branded App Logo widget for screen headers, AppBars and dialog headers.
/// Automatically hides on desktop/tablet where the logo is already prominently in the sidebar.
/// On mobile, maintains a strictly consistent size across all screens.
class AppHeaderLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showOnDesktop;

  const AppHeaderLogo({
    super.key,
    this.size = 28,
    this.borderRadius = 7,
    this.showOnDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 700;
    if (isDesktopOrTablet && !showOnDesktop) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/icons/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.point_of_sale_rounded,
            color: Color(0xFF38BDF8),
            size: 18,
          ),
        ),
      ),
    );
  }
}
