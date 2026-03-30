import 'package:flutter/material.dart';
import '../../models/menu_model.dart';
import '../../core/services/kitchen_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import 'package:intl/intl.dart';

class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({super.key});

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen> {
  final KitchenService _kitchenService = KitchenService();
  DailyMenu? _menu;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menu = await _kitchenService.getTodayMenu();
      setState(() {
        _menu = menu;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки меню: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кухня: Меню на сегодня'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMenu,
          ),
        ],
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _menu == null
                    ? _buildEmptyView()
                    : _buildMenuView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchMenu, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Меню на сегодня еще не сформировано', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchMenu, child: const Text('Обновить')),
        ],
      ),
    );
  }

  Widget _buildMenuView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(),
        const SizedBox(height: 16),
        _buildMealCard('breakfast', 'Завтрак', Icons.wb_sunny_outlined),
        const SizedBox(height: 12),
        _buildMealCard('lunch', 'Обед', Icons.light_mode_outlined),
        const SizedBox(height: 12),
        _buildMealCard('snack', 'Полдник', Icons.cookie_outlined),
        const SizedBox(height: 12),
        _buildMealCard('dinner', 'Ужин', Icons.nightlight_outlined),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'ru_RU').format(_menu!.date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Всего детей: ${_menu!.totalChildCount}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String type, String title, IconData icon) {
    final meal = _menu!.meals[type] ?? Meal(dishes: []);
    bool isServed = meal.isServed;

    return Container(
      decoration: AppDecorations.cardDecoration,
      child: ExpansionTile(
        key: PageStorageKey(type),
        leading: Icon(icon, color: isServed ? AppColors.success : AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: isServed 
          ? Text('Выдано в ${DateFormat('HH:mm').format(meal.servedAt!)} (${meal.childCount} дет.)', 
                 style: const TextStyle(color: AppColors.success, fontSize: 12))
          : const Text('Не выдано', style: TextStyle(color: Colors.grey, fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                ...meal.dishes.map((dish) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(dish.name)),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isServed ? Colors.grey[200] : AppColors.primary,
                      foregroundColor: isServed ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(isServed ? Icons.undo : Icons.check_circle_outline),
                    label: Text(isServed ? 'Отменить выдачу' : 'Отметить выдачу'),
                    onPressed: () => isServed ? _cancelMeal(type) : _showServeDialog(type),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServeDialog(String type) {
    final TextEditingController countController = TextEditingController(
      text: _menu!.totalChildCount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выдача питания'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите количество детей для списания продуктов:'),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество детей'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final int count = int.tryParse(countController.text) ?? _menu!.totalChildCount;
              Navigator.pop(context);
              _serveMeal(type, count);
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  Future<void> _serveMeal(String type, int count) async {
    try {
      final updatedMenu = await _kitchenService.serveMeal(_menu!.id, type, count);
      if (updatedMenu != null) {
        if (!mounted) return;
        setState(() => _menu = updatedMenu);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Питание выдано, продукты списаны')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _cancelMeal(String type) async {
    try {
      final updatedMenu = await _kitchenService.cancelMeal(_menu!.id, type);
      if (updatedMenu != null) {
        if (!mounted) return;
        setState(() => _menu = updatedMenu);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выдача отменена')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
