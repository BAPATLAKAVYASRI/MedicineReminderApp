import 'package:flutter/material.dart';
import 'dart:math';

// 🎨 Import your other screens here
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _floatController;
  late Animation<double> _fadeIcon;
  late Animation<double> _scaleIcon;
  late Animation<double> _fadeQuote;

  @override
  void initState() {
    super.initState();

    // 🎞️ Icon + Quote animations
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeIcon = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleIcon = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeQuote = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _iconController.forward();

    // 🌊 Floating animation for icons
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  double _float(double base, double range) {
    return base + sin(_floatController.value * 2 * pi) * range;
  }

  // 🎬 Custom page transition (fade + slide)
  Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const beginOffset = Offset(0.0, 0.2);
        const endOffset = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3E5F5),
          body: Stack(
            children: [
              // 🌸 Floating background icons
              Positioned(
                top: _float(80, 10),
                left: 30,
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.pinkAccent.withOpacity(0.1),
                  size: 100,
                ),
              ),
              Positioned(
                bottom: _float(120, 15),
                right: 40,
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.deepPurple.withOpacity(0.08),
                  size: 120,
                ),
              ),
              Positioned(
                bottom: _float(40, 8),
                left: 60,
                child: Icon(
                  Icons.medication_rounded,
                  color: Colors.teal.withOpacity(0.1),
                  size: 80,
                ),
              ),

              // 🌟 Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🩺 App Icon Animation
                    FadeTransition(
                      opacity: _fadeIcon,
                      child: ScaleTransition(
                        scale: _scaleIcon,
                        child: const Icon(
                          Icons.medical_services_rounded,
                          size: 100,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🏷️ Title
                    const Text(
                      "Welcome to MediRemind",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 💬 Quote (fade-in)
                    FadeTransition(
                      opacity: _fadeQuote,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        child: Text(
                          '"Your health is your greatest investment — never forget a dose again."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF5E35B1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 💜 LOGIN Button (light lavender)
                    Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD1C4E9), Color(0xFF9575CD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(_createRoute(const LoginScreen()));
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 💧 REGISTER Button (teal gradient)
                    Container(
                      width: 200,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF80DEEA), Color(0xFF26A69A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(_createRoute(const RegisterScreen()));
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
