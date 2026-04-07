import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/animated_press.dart';
import '../../models/user_model.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _base64Image;
  bool _isLoading = false;
  bool _isEditing = false;
  String _tokenStatus = 'Проверка...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkTokenStatus();
  }

  Future<void> _checkTokenStatus() async {
    try {
      await StorageService.ensureInitialized();
      final token = await StorageService().getToken();
      if (mounted) {
        setState(() {
          if (token != null && token.isNotEmpty) {
            _tokenStatus = 'Активен';
          } else {
            _tokenStatus = 'Токен не найден';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _tokenStatus = 'Ошибка');
    }
  }

  void _loadUserProfile() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _base64Image = null;
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка выбора фото: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Если меняется пароль, проверяем совпадение
    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Пароли не совпадают'),
              backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Обновляем профиль
      final profileSuccess = await authProvider.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        avatar: _base64Image, // Передаем base64 строку
      );

      // Обновляем пароль, если он введен
      bool passwordSuccess = true;
      if (_passwordController.text.isNotEmpty) {
        passwordSuccess =
            await authProvider.changePassword(_passwordController.text);
      }

      if (mounted) {
        if (profileSuccess && passwordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Профиль успешно обновлен'),
                backgroundColor: AppColors.success),
          );
          setState(() {
            _isEditing = false;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        } else {
          final error = authProvider.errorMessage ?? 'Ошибка при обновлении';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Произошла ошибка: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Мой профиль',
            style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
        actions: [
          IconButton(
            icon: Icon(
                _isEditing ? Symbols.close_rounded : Symbols.edit_rounded,
                color: Colors.white),
            onPressed: () => setState(() {
              _isEditing = !_isEditing;
              if (!_isEditing) _loadUserProfile();
            }),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            if (user == null)
              // ignore: curly_braces_in_flow_control_structures
              return const Center(child: Text('Авторизуйтесь заново'));

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.xxxl),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildHeader(user),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInfoCard(user),
                    if (_isEditing) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildPasswordCard(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildDiagnosticsCard(),
                    if (_isEditing) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: AnimatedPress(
                          onTap: _isLoading ? null : _saveProfile,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: const [AppColors.shadowLevel2],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Сохранить изменения',
                                      style: AppTypography.labelLarge
                                          .copyWith(color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(
                avatar: _base64Image ?? user.avatar,
                fullName: user.fullName,
                size: 120,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: AnimatedPress(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Symbols.photo_camera_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('${user.firstName} ${user.lastName}',
              style: AppTypography.titleLarge),
          Text(user.role.toUpperCase(),
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.primary, letterSpacing: 1.2)),
        ],
      )
          .animate()
          .fadeIn()
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _buildInfoCard(User user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardElevated1,
      child: Column(
        children: [
          _buildField(Symbols.person_rounded, 'Имя', _firstNameController,
              enabled: _isEditing),
          const Divider(height: 32),
          _buildField(Symbols.badge_rounded, 'Фамилия', _lastNameController,
              enabled: _isEditing),
          const Divider(height: 32),
          _buildField(Symbols.phone_rounded, 'Телефон', _phoneController,
              enabled: _isEditing, keyboardType: TextInputType.phone),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardElevated1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Безопасность',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          _buildField(Symbols.lock_rounded, 'Новый пароль', _passwordController,
              isPassword: true, enabled: true),
          const SizedBox(height: AppSpacing.md),
          _buildField(Symbols.lock_reset_rounded, 'Подтверждение',
              _confirmPasswordController,
              isPassword: true, enabled: true),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildDiagnosticsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.neutral10,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary10)),
      child: Row(
        children: [
          const Icon(Symbols.security_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Статус сессии: $_tokenStatus',
                  style: AppTypography.bodySmall)),
          AnimatedPress(
              onTap: _checkTokenStatus,
              child: const Icon(Symbols.refresh_rounded,
                  size: 20, color: AppColors.primary)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildField(
      IconData icon, String label, TextEditingController controller,
      {bool enabled = false,
      bool isPassword = false,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: AppTypography.bodyLarge.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.textSecondary),
      decoration: AppDecorations.inputDecoration(
              labelText: label, prefixIcon: Icon(icon))
          .copyWith(fillColor: enabled ? null : Colors.transparent),
      validator: (v) =>
          enabled && (v == null || v.isEmpty) ? 'Обязательное поле' : null,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
