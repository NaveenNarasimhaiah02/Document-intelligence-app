import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AnimatedScanningLogo extends StatefulWidget {
  final double size;
  const AnimatedScanningLogo({super.key, this.size = 120});

  @override
  State<AnimatedScanningLogo> createState() => _AnimatedScanningLogoState();
}

class _AnimatedScanningLogoState extends State<AnimatedScanningLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // The Base Logo (with the white folded edge)
          SvgPicture.asset(
            'assets/smartscan_logo.svg',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
          // Animated Scanning Line Overlay
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: widget.size * 0.2 + (widget.size * 0.6 * _controller.value),
                left: widget.size * 0.2,
                right: widget.size * 0.2,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE), // Flashy bluish-white
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withAlpha(150),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
