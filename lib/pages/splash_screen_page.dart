import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Minimum 2 seconds splash
    await Future.wait([
      authProvider.initialize(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('home');
    } else {
      Navigator.of(context).pushReplacementNamed('login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                boxShadow: const [AppColors.shadowHero],
              ),
              child: const Center(child: Icon(Symbols.child_care_rounded, color: Colors.white, size: 64)),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).rotate(begin: -0.2, end: 0),
            const SizedBox(height: AppSpacing.xl),
            Text('ДЕТСАД', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary90, letterSpacing: 4))
                .animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
            const SizedBox(height: AppSpacing.sm),
            Text('Система управления обучением', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500))
                .animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
