import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/child_model.dart';
import '../../../models/user_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childrenService = ChildrenService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _iinController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  String? _selectedGroupId;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGroups();
      }
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? currentUser = authProvider.user;

    bool isTeacherOrSubstitute = currentUser != null &&
        (currentUser.role == 'teacher' || currentUser.role == 'substitute');

    if (isTeacherOrSubstitute) {
      await groupsProvider.loadGroupsByTeacherId(currentUser.id);
    } else {
      await groupsProvider.loadGroups();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;

      final child = Child(
        id: '',
        fullName: _fullNameController.text.trim(),
        iin: _iinController.text.trim().isEmpty
            ? null
            : _iinController.text.trim(),
        birthday:
            _birthdayController.text.isEmpty ? null : _birthdayController.text,
        parentName: _parentNameController.text.trim().isEmpty
            ? null
            : _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isEmpty
            ? null
            : _parentPhoneController.text.trim(),
        groupId: _selectedGroupId,
        staffId: currentUser?.id,
        gender: _selectedGender,
        active: true,
      );

      await _childrenService.createChild(child);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ребенок успешно добавлен')),
        );

        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage.contains('Нет прав для добавления') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        errorMessage = 'Нет прав для добавления ребенка';
      } else if (errorMessage.contains('Некорректные данные') ||
          errorMessage.contains('invalid data') ||
          errorMessage.contains('400')) {
        errorMessage =
            'Некорректные данные. Проверьте правильность введенной информации';
      } else if (errorMessage.contains('Ребенок уже существует') ||
          errorMessage.contains('child already exists') ||
          errorMessage.contains('duplicate')) {
        errorMessage = 'Ребенок с такими данными уже существует';
      } else {
        errorMessage =
            'Ошибка при добавлении ребенка. Проверьте подключение к интернету';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage =
          'Ошибка при добавлении ребенка. Проверьте подключение к интернету';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
        title: const Text('Добавить ребенка'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'ФИО ребенка',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите ФИО';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iinController,
                  decoration: InputDecoration(
                    labelText: 'ИИН',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdayController,
                  decoration: InputDecoration(
                    labelText: 'Дата рождения',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, выберите дату рождения';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Адрес',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parentNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя родителя',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parentPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Телефон родителя',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<GroupsProvider>(
                  builder: (context, groupsProvider, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Пол',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ['Мужской', 'Женский'].map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<GroupsProvider>(
                  builder: (context, groupsProvider, child) {
                    if (groupsProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (groupsProvider.groups.isEmpty) {
                      return const Text('Нет доступных групп');
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedGroupId,
                      decoration: InputDecoration(
                        labelText: 'Группа',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: groupsProvider.groups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group.id,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroupId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Добавить ребенка',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _iinController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();

    super.dispose();
  }
}
