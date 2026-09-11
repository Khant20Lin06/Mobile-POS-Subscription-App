import 'dart:io';
import 'package:flutter/material.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final BoxFit fit;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackIcon = Icons.inventory_2_outlined,
    this.fallbackColor,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return _buildFallback(radius);
    }

    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: isNetwork
            ? Image.network(
                url,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF38BDF8),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
              )
            : Image.file(
                File(url),
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
              ),
      ),
    );
  }

  Widget _buildFallback(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFF334155)),
      ),
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: fallbackColor ?? const Color(0xFF60A5FA),
        size: (width != null && height != null) ? (width! * 0.45).clamp(16.0, 32.0) : 22,
      ),
    );
  }
}
