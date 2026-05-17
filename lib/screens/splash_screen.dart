import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import '../data/storage_service.dart';
import '../theme.dart';
import 'onboarding_screen.dart';
import 'app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    // Inisialisasi storage lalu tentukan ke mana navigasi
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Tunggu animasi selesai minimal 1.8 detik
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      _loadStorage(),
    ]);

    if (!mounted) return;

    final storage = StorageService.instance;
    Widget nextScreen;

    if (storage.isFirstLaunch) {
      // Pertama kali buka → onboarding
      nextScreen = const OnboardingScreen();
    } else {
      // Sudah pernah pakai → langsung ke app
      nextScreen = const AppShell();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _loadStorage() async {
    await StorageService.instance.init();
    if (mounted) {
      await context.read<AppState>().loadFromStorage();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: const Text(
              'MEIN\nGELD',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: AppColors.orange,
                letterSpacing: 3,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
