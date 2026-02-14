import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedAvatar;
  bool _isLoading = false;
  bool _isEditing = false;
  String _tokenStatus = 'Проверка...';
  String? _tokenPreview;

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
      setState(() {
        if (token == null || token.isEmpty) {
          _tokenStatus = 'Токен не найден';
          _tokenPreview = null;
        } else {
          _tokenStatus = 'Токен найден (${token.length} символов)';
          _tokenPreview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
        }
      });
    } catch (e) {
      setState(() {
        _tokenStatus = 'Ошибка: $e';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phone;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        bool profileUpdated = await _authService.updateProfile(
          userId: user.id,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          avatar: _selectedAvatar,
        );

        bool passwordUpdated = true;

        if (_passwordController.text.isNotEmpty) {
          passwordUpdated = await _authService.changePassword(
            userId: user.id,
            newPassword: _passwordController.text,
          );
        }

        if (profileUpdated || passwordUpdated) {
          await authProvider.refreshUser();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Профиль успешно обновлен')),
            );
            setState(() {
              _isEditing = false;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось обновить профиль')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль сотрудника'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isEditing ? _saveProfile : null,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            if (user == null) {
              return const Center(child: Text('Пользователь не авторизован'));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              image: user.avatar != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.avatar!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user.avatar == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileField(
                      label: 'Имя',
                      controller: _firstNameController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Введите имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Фамилия',
                      controller: _lastNameController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Введите фамилию';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Телефон',
                      controller: _phoneController,
                      enabled: _isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Введите телефон';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildProfileField(
                      label: 'Роль',
                      controller: TextEditingController(text: user.role),
                      enabled: false,
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Изменение пароля',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        label: 'Новый пароль',
                        controller: _passwordController,
                        enabled: true,
                        isPassword: true,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Пароль должен содержать не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        label: 'Подтвердите пароль',
                        controller: _confirmPasswordController,
                        enabled: true,
                        isPassword: true,
                        validator: (value) {
                          if (value != null &&
                              _passwordController.text.isNotEmpty &&
                              value != _passwordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Секция диагностики токена
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Text(
                                'Диагностика токена',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Статус: $_tokenStatus'),
                          if (_tokenPreview != null)
                            Text('Превью: $_tokenPreview', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _checkTokenStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade100,
                              foregroundColor: Colors.amber.shade900,
                            ),
                            child: const Text('Обновить статус'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing) ...[
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Сохранить изменения'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadUserProfile();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Отмена'),
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

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              enabled: enabled,
              obscureText: isPassword,
              validator: validator,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: enabled ? 'Введите $label'.toLowerCase() : '',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
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
