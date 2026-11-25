import 'package:flutter/material.dart';
import 'views/auth/login_screen.dart';

void main() {
  runApp(const ReyesCompanyApp());
}

class ReyesCompanyApp extends StatelessWidget {
  const ReyesCompanyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReyesCompany',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A5276)),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {'/login': (_) => const LoginScreen()},
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _irAlLogin();
  }

  Future<void> _irAlLogin() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A5276), Color(0xFF2E86C1), Color(0xFF1ABC9C)],
        ),
      ),
      child: Center(child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 110, height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.storefront_rounded, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('ReyesCompany', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('Sistema de Inventario y Ventas',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 48),
          SizedBox(width: 28, height: 28, child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
              strokeWidth: 2.5)),
        ]),
      ))),
    ),
  );
}
