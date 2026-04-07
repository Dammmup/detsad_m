import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/animated_press.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background with Animated Blobs for Mesh Effect
          Positioned.fill(
            child: Container(color: AppColors.background),
          ),
          ..._buildBackgroundBlobs(),
          
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildLoginForm(authProvider),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        '© 2026 Antigravity Systems', 
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
                      ).animate().fadeIn(delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundBlobs() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: _Blob(color: AppColors.primary.withValues(alpha: 0.15), size: 300),
      ),
      Positioned(
        bottom: -50,
        left: -50,
        child: _Blob(color: AppColors.secondary.withValues(alpha: 0.1), size: 250),
      ),
      Positioned(
        top: 200,
        left: -100,
        child: _Blob(color: AppColors.tertiary.withValues(alpha: 0.05), size: 200),
      ),
    ];
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Center(
            child: Icon(Symbols.child_care_rounded, color: Colors.white, size: 48)
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white24)
        .moveY(begin: -4, end: 4, duration: 2.seconds, curve: Curves.easeInOut),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'ДЕТСАД', 
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w900, 
            color: AppColors.primary90, 
            letterSpacing: 4
          )
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildLoginForm(AuthProvider authProvider) {
    return Container(
      decoration: AppDecorations.cardElevated3.copyWith(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Вход в систему', 
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary
                ), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 8),
              Text(
                'Введите ваши данные для доступа', 
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTypography.bodyLarge,
                decoration: AppDecorations.inputDecoration(
                  hintText: '7XXXXXXXXXX',
                  labelText: 'Номер телефона',
                  prefixIcon: const Icon(Symbols.phone_iphone_rounded, color: AppColors.primary),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Введите номер телефона' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.bodyLarge,
                decoration: AppDecorations.inputDecoration(
                  hintText: '••••••••',
                  labelText: 'Пароль',
                  prefixIcon: const Icon(Symbols.lock_rounded, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Symbols.visibility_rounded : Symbols.visibility_off_rounded, 
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Введите пароль' : null,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _buildLoginButton(authProvider),
              if (authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    authProvider.errorMessage!, 
                    style: AppTypography.bodySmall.copyWith(color: AppColors.error), 
                    textAlign: TextAlign.center
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoginButton(AuthProvider authProvider) {
    return AnimatedPress(
      onTap: authProvider.isLoading ? null : _handleLogin,
      child: Container(
        height: 56,
        decoration: AppDecorations.pillButtonDecoration,
        child: Center(
          child: authProvider.isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                'Авторизоваться', 
                style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
              ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.login(_phoneController.text.trim(), _passwordController.text);
      if (!mounted || !success) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen())
      );
    }
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveX(begin: -20, end: 20, duration: 5.seconds, curve: Curves.easeInOut)
     .moveY(begin: -20, end: 20, duration: 7.seconds, curve: Curves.easeInOut);
  }
}
