import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/animated_press.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Восстановление доступа', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 130, AppSpacing.xl, AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildIcon(),
                const SizedBox(height: AppSpacing.xxl),
                Text('Забыли пароль?', style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Введите адрес электронной почты, связанный с вашей учетной записью, и мы отправим вам инструкции.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppDecorations.inputDecoration(
                    labelText: 'Электронная почта',
                    prefixIcon: const Icon(Symbols.mail_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Некорректный email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedPress(
                    onTap: _isLoading ? null : _resetPassword,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                        boxShadow: [AppColors.shadowLevel2],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Отправить инструкции', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: AppColors.primary10, shape: BoxShape.circle),
      child: const Icon(Symbols.lock_reset_rounded, size: 64, color: AppColors.primary),
    ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut);
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Инструкции отправлены на вашу почту'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
