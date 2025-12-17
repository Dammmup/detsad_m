import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payroll_provider.dart';
import '../../models/payroll_model.dart';
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
                  _buildMonthSelector(context, provider),
                  const SizedBox(height: 20),
                  if (provider.currentPayroll == null)
                    const Center(child: Text('Нет данных за выбранный период'))
                  else ...[
                    _buildTotalCard(context, provider.currentPayroll!.total),
                    const SizedBox(height: 20),
                    _buildDetailsGrid(context, provider),
                    const SizedBox(height: 20),
                    if (provider.currentPayroll!.fines.isNotEmpty)
                      _buildFinesSection(
                          context, provider.currentPayroll!.fines),
                    const SizedBox(height: 20),
                    if (provider.currentPayroll!.shiftDetails.isNotEmpty)
                      _buildShiftDetailsSection(
                          context, provider.currentPayroll!.shiftDetails),
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
          DateFormat('LLLL yyyy', 'ru')
              .format(provider.currentDate)
              .toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(total),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
            Expanded(child: _buildInfoCard('Оклад', p.baseSalary, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Бонусы', p.bonuses, Colors.orange)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Аванс', p.advance, Colors.purple)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Вычеты', p.penalties, Colors.red)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildInfoCard('Смен', p.workedShifts, Colors.teal)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Дней', p.workedDays, Colors.teal)),
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
          Text(title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
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
                Text('Детализация Вычетов',
                    style: Theme.of(context).textTheme.titleMedium),
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
                    title: Text(fine.reason.isNotEmpty ? fine.reason : 'Вычет'),
                    subtitle: Text(DateFormat('dd.MM.yyyy HH:mm')
                        .format(fine.date.add(const Duration(hours: 5)))),
                    trailing: Text(
                      '-${currencyFormat.format(fine.amount)}',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftDetailsSection(
      BuildContext context, List<ShiftDetail> details) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Детализация смен',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd.MM.yyyy').format(detail.date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'Начислено: ${currencyFormat.format(detail.earnings)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (detail.fines > 0)
                              Text(
                                  'Вычет: -${currencyFormat.format(detail.fines)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.red)),
                            Text(currencyFormat.format(detail.net),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: detail.net > 0
                                        ? Colors.green
                                        : Colors.red)),
                          ],
                        ),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
