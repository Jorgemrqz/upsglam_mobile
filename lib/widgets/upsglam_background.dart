import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';

class UPSGlamBackground extends StatelessWidget {
  const UPSGlamBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    this.reserveAppBar = false,
    this.reserveAppBarSpacing = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool reserveAppBar;
  final double reserveAppBarSpacing;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = EdgeInsets.fromLTRB(
      padding.left,
      padding.top + (reserveAppBar ? kToolbarHeight + reserveAppBarSpacing : 0),
      padding.right,
      padding.bottom,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF05050D), Color(0xFF0C1024), Color(0xFF1E0F3F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: _GlowCircle(
              size: 220,
              colors: [UPSGlamTheme.accent.withValues(alpha: 0.35), Colors.transparent],
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: _GlowCircle(
              size: 260,
              colors: [UPSGlamTheme.primary.withValues(alpha: 0.4), Colors.transparent],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.03), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: effectivePadding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
