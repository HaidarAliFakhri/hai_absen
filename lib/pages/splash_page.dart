import 'dart:async';

import 'package:flutter/material.dart';

import '../core/shared_prefs.dart';
import 'auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  late AnimationController _circleController;

  @override
  void initState() {
    super.initState();

    // ===== LOGO ANIMATION =====
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoController.forward();

    // ===== BACKGROUND CIRCLES ANIMATION =====
    _circleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    Future.microtask(() => _redirect());
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));

    final token = await LocalStorage.getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 2, 55, 107),
      body: Stack(
        children: [
          // ==========================
          //   ANIMATED BACKGROUND
          // ==========================
          AnimatedBuilder(
            animation: _circleController,
            builder: (_, child) {
              return CustomPaint(
                size: size,
                painter: _BubblePainter(_circleController.value),
              );
            },
          ),

          // ==========================
          //        LOGO + TEXT
          // ==========================
          Center(
            child: ScaleTransition(
              scale: _logoScale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
                  Container(
                    height: 125,
                    width: 125,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/haiabsen.png", // ← pakai logo.png
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    "Absensi Modern & Otomatis",
                    style: TextStyle(color: Colors.white70, fontSize: 21),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "Create by: Haidar Ali Fakhri",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
//         CUSTOM PAINTER UNTUK CIRCLE ANIMATION
// =====================================================
class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.fill;

    // animasi radius naik turun
    double radius1 = 60 + progress * 20;
    double radius2 = 40 + (1 - progress) * 20;
    double radius3 = 80 + progress * 30;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      radius1,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      radius2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.75),
      radius3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
