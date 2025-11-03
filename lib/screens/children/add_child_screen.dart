import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/child_model.dart';
import '../../../models/user_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({Key? key}) : super(key: key);

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
  final TextEditingController _clinicController = TextEditingController();
 final TextEditingController _bloodGroupController = TextEditingController();
 final TextEditingController _rhesusController = TextEditingController();
  final TextEditingController _disabilityController = TextEditingController();
 final TextEditingController _dispensaryController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();
 final TextEditingController _infectionsController = TextEditingController();
  final TextEditingController _hospitalizationsController = TextEditingController();
 final TextEditingController _incapacityController = TextEditingController();
  final TextEditingController _checkupsController = TextEditingController();
 final TextEditingController _notesController = TextEditingController();
  
  String? _selectedGroupId;
  String? _selectedGender;
  bool _isLoading = false;
  
  @override
 void initState() {
    super.initState();
    // Загружаем группы при инициализации экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }
  
  Future<void> _loadGroups() async {
    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final User? currentUser = authProvider.user;
    
    if (currentUser != null && currentUser.role == 'teacher') {
      // Если пользователь - воспитатель, загружаем только его группы
      await groupsProvider.loadGroupsByTeacherId(currentUser.id);
    } else {
      // Для других ролей загружаем все группы
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
        id: '', // будет сгенерирован на сервере
        fullName: _fullNameController.text.trim(),
        iin: _iinController.text.trim().isEmpty ? null : _iinController.text.trim(),
        birthday: _birthdayController.text.isEmpty ? null : _birthdayController.text,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        parentName: _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
        groupId: _selectedGroupId,
        staffId: currentUser?.id, // Привязываем к текущему пользователю
        gender: _selectedGender,
        clinic: _clinicController.text.trim().isEmpty ? null : _clinicController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim().isEmpty ? null : _bloodGroupController.text.trim(),
        rhesus: _rhesusController.text.trim().isEmpty ? null : _rhesusController.text.trim(),
        disability: _disabilityController.text.trim().isEmpty ? null : _disabilityController.text.trim(),
        dispensary: _dispensaryController.text.trim().isEmpty ? null : _dispensaryController.text.trim(),
        diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
        allergy: _allergyController.text.trim().isEmpty ? null : _allergyController.text.trim(),
        infections: _infectionsController.text.trim().isEmpty ? null : _infectionsController.text.trim(),
        hospitalizations: _hospitalizationsController.text.trim().isEmpty ? null : _hospitalizationsController.text.trim(),
        incapacity: _incapacityController.text.trim().isEmpty ? null : _incapacityController.text.trim(),
        checkups: _checkupsController.text.trim().isEmpty ? null : _checkupsController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        active: true,
      );
      
      await _childrenService.createChild(child);
      
      // Показываем сообщение об успешном добавлении
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ребенок успешно добавлен')),
        );
        
        // Возвращаемся назад к списку детей
        Navigator.pop(context, true); // Передаем true как индикатор успешного добавления
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при добавлении ребенка: $e')),
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
        title: Text('Добавить ребенка'),
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
                // Поле ФИО
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
                
                // Поле ИИН
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
                
                // Поле Дата рождения
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
                      icon: Icon(Icons.calendar_today),
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
                
                // Поле Адрес
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
                
                // Поле Имя родителя
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
                
                // Поле Телефон родителя
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
                
                // Выбор пола
                Consumer<GroupsProvider>(
                  builder: (context, groupsProvider, child) {
                    return DropdownButtonFormField<String>(
                      value: _selectedGender,
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
                
                // Выбор группы
                Consumer<GroupsProvider>(
                  builder: (context, groupsProvider, child) {
                    if (groupsProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (groupsProvider.groups.isEmpty) {
                      return const Text('Нет доступных групп');
                    }
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedGroupId,
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
                          value: (group['_id'] ?? group['id']).toString(),
                          child: Text(group['name'] ?? 'Без названия'),
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
                // Поле Клиника
                TextFormField(
                  controller: _clinicController,
                  decoration: InputDecoration(
                    labelText: 'Клиника',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Группа крови
                TextFormField(
                  controller: _bloodGroupController,
                  decoration: InputDecoration(
                    labelText: 'Группа крови',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Резус-фактор
                TextFormField(
                  controller: _rhesusController,
                  decoration: InputDecoration(
                    labelText: 'Резус-фактор',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Инвалидность
                TextFormField(
                  controller: _disabilityController,
                  decoration: InputDecoration(
                    labelText: 'Инвалидность',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Диспансер
                TextFormField(
                  controller: _dispensaryController,
                  decoration: InputDecoration(
                    labelText: 'Диспансер',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Диагноз
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Диагноз',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Аллергии
                TextFormField(
                  controller: _allergyController,
                  decoration: InputDecoration(
                    labelText: 'Аллергии',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Перенесенные инфекции
                TextFormField(
                  controller: _infectionsController,
                  decoration: InputDecoration(
                    labelText: 'Перенесенные инфекции',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Госпитализации
                TextFormField(
                  controller: _hospitalizationsController,
                  decoration: InputDecoration(
                    labelText: 'Госпитализации',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Периоды нетрудоспособности
                TextFormField(
                  controller: _incapacityController,
                  decoration: InputDecoration(
                    labelText: 'Периоды нетрудоспособности',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Обследования
                TextFormField(
                  controller: _checkupsController,
                  decoration: InputDecoration(
                    labelText: 'Обследования',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Поле Примечания
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Примечания',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Кнопка добавить
                ElevatedButton(
                  onPressed: _isLoading ? null : _addChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Добавить ребенка', style: TextStyle(fontSize: 16)),
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
    _clinicController.dispose();
    _bloodGroupController.dispose();
    _rhesusController.dispose();
    _disabilityController.dispose();
    _dispensaryController.dispose();
    _diagnosisController.dispose();
    _allergyController.dispose();
    _infectionsController.dispose();
    _hospitalizationsController.dispose();
    _incapacityController.dispose();
    _checkupsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}