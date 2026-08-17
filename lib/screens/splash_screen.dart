import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.45, 0.85, curve: Curves.easeOut)),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // En kısa kenara göre boyutlandır ki geniş/kısa (masaüstü tarayıcı gibi)
    // pencerelerde logo mevcut yüksekliği taşırıp overflow'a yol açmasın.
    final logoSize = (math.min(screenSize.width, screenSize.height) * 0.6)
        .clamp(120.0, 320.0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── İçerik ──────────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: screenSize.height * 0.08),
                // Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/icons/icon.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Metin
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'RecipeAI',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 1.5,
                                color: AppTheme.primary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'AI destekli tarif asistanın',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 28,
                                height: 1.5,
                                color: AppTheme.primary.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),

          // ── Alt versiyon yazısı ──────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'v1.1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textHint,
                    letterSpacing: 1.2,
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
