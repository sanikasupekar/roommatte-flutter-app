import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart'; // AuthWrapper access sathi main.dart cha import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3000), () {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (mounted) {
      // --- FIXED: Vaparla MaterialPageRoute jyamule splash cha background pudhe screen var stretch honar nahi ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- AAPLYA SAMPOORNA APP LA MATCH HONARE ORIGINAL CORAL THEME COLORS ---
    const brandCoral = Color(0xFFFF5A5F);
    const softBackground = Color(0xFFFAFAFA); // Premium minimal light canvas

    return Scaffold(
      backgroundColor: softBackground,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandCoral.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: brandCoral.withOpacity(0.08),
                    blurRadius: 90,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: brandCoral.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brandCoral.withOpacity(0.05),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.holiday_village_rounded,
                        size: 64,
                        color: brandCoral,
                      ),
                    ),
                    const SizedBox(height: 28),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        children: [
                          TextSpan(text: 'Room', style: TextStyle(color: Color(0xFF1E293B))), // Premium Slate Black text
                          TextSpan(text: 'Hive', style: TextStyle(color: brandCoral)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your Space. Your Vibe. Your Tribe.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 3,
                  child: LinearProgressIndicator(
                    backgroundColor: brandCoral.withOpacity(0.15),
                    color: brandCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}