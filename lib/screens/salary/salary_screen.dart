
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payroll_provider.dart';
import '../../models/fine_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({Key? key}) : super(key: key);

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: 'тг');

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru', null);
    // Load payroll data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayrollProvider>().loadMyPayroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя зарплата'),
        centerTitle: true,
      ),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${provider.errorMessage}'),
                  ElevatedButton(
                    onPressed: () => provider.loadMyPayroll(),
                    child: const Text('Повторить'),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMyPayroll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   // Month Selector
                  _buildMonthSelector(context, provider),
                  const SizedBox(height: 20),

                  if (provider.currentPayroll == null)
                    const Center(child: Text('Нет данных за выбранный период'))
                  else ...[
                    // Total Card
                    _buildTotalCard(context, provider.currentPayroll!.total),
                    const SizedBox(height: 20),
                    // Details Grid
                    _buildDetailsGrid(context, provider),
                    const SizedBox(height: 20),
                    // Fines Section if any
                    if (provider.currentPayroll!.penalties > 0)
                       _buildFinesSection(context, provider.currentPayroll!.fines),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, PayrollProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: provider.prevMonth,
        ),
        Text(
          DateFormat('LLLL yyyy', 'ru').format(provider.currentDate).toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: provider.nextMonth,
        ),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context, double total) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade600,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Итого к выплате',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(total),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context, PayrollProvider provider) {
    final p = provider.currentPayroll!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('Оклад', p.accruals, Colors.blue)), // Using accruals as calculated salary
            const SizedBox(width: 16),
             Expanded(child: _buildInfoCard('Бонусы', p.bonuses, Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Аванс', p.advance, Colors.purple)),
             const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Штрафы', p.penalties, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinesSection(BuildContext context, List<Fine> fines) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 const Icon(Icons.warning_amber_rounded, color: Colors.red),
                 const SizedBox(width: 8),
                 Text('Детализация штрафов', style: Theme.of(context).textTheme.titleMedium),
               ],
             ),
             const Divider(),
             if (fines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Нет детальной информации'),
                )
             else
               ...fines.map((fine) => ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text(fine.reason.isNotEmpty ? fine.reason : 'Штраф'),
                 subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(fine.date)),
                 trailing: Text(
                   '-${currencyFormat.format(fine.amount)}',
                   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                 ),
               )),
          ],
        ),
      ),
    );
  }
}
