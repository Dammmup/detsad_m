import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aldamiram/providers/groups_provider.dart';
import 'package:aldamiram/core/constants/api_constants.dart';
import 'package:aldamiram/core/services/api_service.dart';
import 'package:aldamiram/models/child_payment_model.dart';
import 'package:aldamiram/core/theme/app_colors.dart';
import 'package:aldamiram/core/theme/app_typography.dart';
import 'package:aldamiram/core/theme/app_decorations.dart';
import 'package:aldamiram/core/widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  DateTime _selectedMonth = DateTime.now();
  List<ChildPaymentModel> _payments = [];
  bool _isLoading = true;
  String? _error;
  
  // Filtering
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGroupId;
  String? _selectedStatus; // 'paid', 'active', 'overdue', null (all)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final monthPeriod = DateFormat('yyyy-MM').format(_selectedMonth);
      
      final response = await ApiService().get(
        ApiConstants.childPayments,
        queryParameters: {'monthPeriod': monthPeriod},
      );

      if (response.data != null && response.data is List) {
        setState(() {
          _payments = (response.data as List)
              .map((e) => ChildPaymentModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Неверный формат данных');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ChildPaymentModel> get _filteredPayments {
    return _payments.where((p) {
      final name = (p.child?.fullName ?? p.user?.fullName ?? '').toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      
      final matchesGroup = _selectedGroupId == null || p.child?.groupId == _selectedGroupId;
      
      final matchesStatus = _selectedStatus == null || p.status == _selectedStatus;
      
      return matchesSearch && matchesGroup && matchesStatus;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadData();
  }

  Future<void> _onMarkPaid(ChildPaymentModel payment) async {
    try {
      await ApiService().patch(
        '${ApiConstants.childPayments}/${payment.id}',
        data: {'status': 'paid', 'paidAmount': payment.total},
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _onEditPayment(ChildPaymentModel payment) async {
    final controller = TextEditingController(text: payment.paidAmount?.toString() ?? '0');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать оплату'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Оплаченная сумма (₸)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final amount = num.tryParse(controller.text) ?? 0;
        final status = amount >= payment.total ? 'paid' : 'active';
        
        await ApiService().put(
          '${ApiConstants.childPayments}/${payment.id}',
          data: {'paidAmount': amount, 'status': status},
        );
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _onDeletePayment(ChildPaymentModel payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление записи'),
        content: const Text('Вы уверены, что хотите удалить эту запись об оплате?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().delete('${ApiConstants.childPayments}/${payment.id}');
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Оплаты за посещение'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              _MonthSelector(
                currentMonth: _selectedMonth,
                onPrevious: _previousMonth,
                onNext: _nextMonth,
              ),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusFilter(),
          const SizedBox(width: 8),
          _buildGroupFilter(),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<String?>(
      icon: Icon(
        Icons.filter_list, 
        color: _selectedStatus != null ? AppColors.primary : AppColors.textTertiary,
      ),
      onSelected: (val) => setState(() => _selectedStatus = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: null, child: Text('Все статусы')),
        const PopupMenuItem(value: 'paid', child: Text('Оплачено')),
        const PopupMenuItem(value: 'active', child: Text('Ожидает')),
        const PopupMenuItem(value: 'overdue', child: Text('Просрочено')),
      ],
    );
  }

  Widget _buildGroupFilter() {
    return Consumer<GroupsProvider>(
      builder: (context, provider, _) {
        return PopupMenuButton<String?>(
          icon: Icon(
            Icons.groups_outlined,
            color: _selectedGroupId != null ? AppColors.primary : AppColors.textTertiary,
          ),
          onSelected: (val) => setState(() => _selectedGroupId = val),
          itemBuilder: (context) => [
            const PopupMenuItem(value: null, child: Text('Все группы')),
            ...provider.groups.map((g) => PopupMenuItem(
              value: g.id,
              child: Text(g.name),
            )),
          ],
        );
      },
    );
  }
  Widget _buildBody() {
    final filteredPayments = _filteredPayments;
    
    if (_isLoading && _payments.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 120, width: double.infinity),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)),
      );
    }

    if (_error != null && _payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Ошибка загрузки данных', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(_error ?? '', 
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSummaryCard(filteredPayments),
        ),
        if (filteredPayments.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PaymentCard(
                  payment: filteredPayments[index],
                  delay: Duration(milliseconds: 50 * index),
                  onMarkPaid: () => _onMarkPaid(filteredPayments[index]),
                  onEdit: () => _onEditPayment(filteredPayments[index]),
                  onDelete: () => _onDeletePayment(filteredPayments[index]),
                ),
                childCount: filteredPayments.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(List<ChildPaymentModel> payments) {
    num totalPlanned = 0;
    num totalPaid = 0;
    num totalDebt = 0;

    for (var p in payments) {
      totalPlanned += p.total;
      if (p.status == 'paid' || (p.paidAmount ?? 0) >= p.total) {
        totalPaid += p.paidAmount ?? p.total;
      } else {
        totalPaid += p.paidAmount ?? 0;
        totalDebt += (p.total - (p.paidAmount ?? 0));
      }
    }

    final formatCurrency = NumberFormat.currency(locale: 'ru_RU', symbol: '₸', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppDecorations.cardElevated1.copyWith(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Сводка за месяц',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency.format(totalPaid),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Фактически оплачено',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    title: 'Начислено',
                    value: formatCurrency.format(totalPlanned),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    title: 'Долг',
                    value: formatCurrency.format(totalDebt),
                    color: const Color(0xFFFCA5A5), // Light red
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Нет оплат за этот месяц', style: AppTypography.headlineSmall),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final ChildPaymentModel payment;
  final Duration delay;
  final VoidCallback onMarkPaid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentCard({
    required this.payment,
    required this.delay,
    required this.onMarkPaid,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'ru_RU', symbol: '₸', decimalDigits: 0);
    
    // Status color logic
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    // UI Override: If paid in full, show as Paid
    bool isActuallyPaid = payment.status == 'paid' || (payment.paidAmount != null && payment.paidAmount! >= payment.total);

    if (isActuallyPaid) {
      statusColor = AppColors.success;
      statusText = 'Оплачено';
      statusIcon = Icons.check_circle_outline;
    } else {
      switch (payment.status) {
        case 'paid': // Fallback if isActuallyPaid somehow missed it
          statusColor = AppColors.success;
          statusText = 'Оплачено';
          statusIcon = Icons.check_circle_outline;
          break;
        case 'active':
          statusColor = AppColors.warning;
          statusText = 'Ожидает оплаты';
          statusIcon = Icons.access_time;
          break;
        case 'overdue':
          statusColor = AppColors.error;
          statusText = 'Просрочено';
          statusIcon = Icons.warning_amber;
          break;
        default:
          statusColor = AppColors.textSecondary;
          statusText = payment.status;
          statusIcon = Icons.info_outline;
      }
    }

    final name = payment.child?.fullName ?? payment.user?.fullName ?? 'Неизвестно';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardElevated1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'paid') onMarkPaid();
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!isActuallyPaid)
                    const PopupMenuItem(
                      value: 'paid',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Отметить оплаченным'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Сумма', style: AppTypography.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency.format(payment.total),
                    style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              if (payment.paidAmount != null && payment.paidAmount! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Оплачено', style: AppTypography.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency.format(payment.paidAmount),
                      style: AppTypography.headlineSmall.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
            ],
          ),
          if (!isActuallyPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMarkPaid,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('ОПЛАТИТЬ ПОЛНОСТЬЮ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: delay).slideY(begin: 0.1, delay: delay);
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('LLLL yyyy', 'ru').format(currentMonth);
    // Capitalize first letter
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
            color: AppColors.textPrimary,
          ),
          Text(
            formattedMonth,
            style: AppTypography.headlineSmall,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
