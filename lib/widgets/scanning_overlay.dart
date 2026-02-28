import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/ac.dart';
import 'animated_scanning_logo.dart';

class ScanningOverlay extends StatefulWidget {
  final File image;
  const ScanningOverlay({super.key, required this.image});

  @override
  State<ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<ScanningOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedScanningLogo(size: 80),
            const SizedBox(height: 32),
            Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AC.header2.withAlpha(100), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.file(widget.image, width: 280, height: 380, fit: BoxFit.cover),
                    // Scanning Laser
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          top: 380 * _controller.value,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AC.header2,
                                  AC.header2,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AC.header2.withAlpha(200),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Glassmorphism Overlay
                    Container(
                      decoration: BoxDecoration(
                        color: AC.header2.withAlpha(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Analyzing Document...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Identifying patterns & text',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
