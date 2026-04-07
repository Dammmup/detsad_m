import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_decorations.dart';
import '../core/widgets/animated_press.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _email = '', _password = '';
  final GlobalKey<FormState> _key = GlobalKey();
  bool _showPassword = false, _load = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.pageBackground,
        height: double.infinity,
        width: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.xxxl),
                _logo().animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
                const SizedBox(height: AppSpacing.xxl),
                _welcomeText().animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: AppSpacing.xl),
                _loginCard().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.lg),
                _forgetPassText().animate().fadeIn(delay: 800.ms),
                const SizedBox(height: AppSpacing.xxxl),
                _button().animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      height: 100.0,
      width: 100.0,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [AppColors.shadowLevel2],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Image.asset(
        'assets/images/logo.png',
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.school_rounded,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _welcomeText() {
    return Column(
      children: [
        Text(
          "Welcome back",
          style: AppTypography.displaySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Sign in to your account to continue",
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      decoration: AppDecorations.cardElevated3,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Form(
        key: _key,
        child: Column(
          children: <Widget>[
            TextFormField(
              style: AppTypography.bodyLarge,
              decoration: AppDecorations.inputDecoration(
                labelText: "Email address",
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              onSaved: (input) => _email = input!.trim(),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              style: AppTypography.bodyLarge,
              obscureText: !_showPassword,
              decoration: AppDecorations.inputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              onSaved: (input) => _password = input!.trim(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _forgetPassText() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.of(context).pushNamed('forgotpassword'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        child: Text(
          "Forgot your password?",
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _button() {
    if (_load) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return AnimatedPress(
      onTap: _onLoginPressed,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 56,
        decoration: AppDecorations.filledButtonDecoration,
        child: Text(
          'SIGN IN',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  void _onLoginPressed() {
    RegExp regExp = RegExp(
        r'^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$');
    final formstate = _key.currentState;
    formstate!.save();
    
    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email cannot be empty')));
    } else if (_password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password needs to be at least 6 characters')));
    } else if (!regExp.hasMatch(_email)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email')));
    } else {
      setState(() => _load = true);
      _signIn();
    }
  }

  Future<void> _signIn() async {
    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      User? user = result.user;

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', user.email!);
      await prefs.setString(
          'role', (snapshot.data() as Map<String, dynamic>)['role']);
      await prefs.setString('userid', user.uid);
      
      if (!mounted) return;
      setState(() => _load = false);
      Navigator.of(context).pushReplacementNamed('home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _load = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}