import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/animated_press.dart';
import '../models/child_model.dart';
import '../core/services/children_service.dart';
import '../screens/birthdays/birthdays_screen.dart';

import '../core/widgets/shimmer_loading.dart';

class BirthdaysWidget extends StatefulWidget {
  const BirthdaysWidget({super.key});

  @override
  State<BirthdaysWidget> createState() => _BirthdaysWidgetState();
}

class _BirthdaysWidgetState extends State<BirthdaysWidget> {
  Child? _nextBirthdayChild;
  String? _nextBirthdayGroupName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      final childrenService = ChildrenService();
      List<Child> allChildren = await childrenService.getAllChildren();
      if (mounted) {
        Child? nextChild = _getNextBirthdayChild(allChildren);
        setState(() {
          _nextBirthdayChild = nextChild;
          _nextBirthdayGroupName = nextChild?.groupName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Ошибка загрузки'; _isLoading = false; });
    }
  }

  Child? _getNextBirthdayChild(List<Child> children) {
    final now = DateTime.now();
    List<Child> childrenWithBirthdays = children.where((child) => child.birthday != null).toList();
    if (childrenWithBirthdays.isEmpty) return null;
    childrenWithBirthdays.sort((a, b) {
      DateTime? d1 = _getNextBirthdayDate(a.birthday, now);
      DateTime? d2 = _getNextBirthdayDate(b.birthday, now);
      if (d1 == null) return 1;
      if (d2 == null) return -1;
      return d1.compareTo(d2);
    });
    return childrenWithBirthdays.first;
  }

  DateTime? _getNextBirthdayDate(String? bday, DateTime now) {
    if (bday == null) return null;
    try {
      DateTime b = DateTime.parse(bday);
      DateTime thisYear = DateTime(now.year, b.month, b.day);
      return thisYear.isBefore(now) || (thisYear.month == now.month && thisYear.day == now.day) 
        ? (thisYear.month == now.month && thisYear.day == now.day ? thisYear : DateTime(now.year + 1, b.month, b.day)) 
        : thisYear;
    } catch (_) { return null; }
  }

  String _formatDateShort(DateTime date) {
    const months = ['янв', 'февр', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сент', 'окт', 'нояб', 'дек'];
    return '${date.day}\n${months[date.month - 1]}';
  }

  int _calculateAge(String? bday, DateTime now) {
    if (bday == null) return 0;
    try {
      DateTime b = DateTime.parse(bday);
      return now.year - b.year;
    } catch (_) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _nextBirthdayChild == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final nextBday = _nextBirthdayChild != null ? _getNextBirthdayDate(_nextBirthdayChild!.birthday, now) : null;
    final isToday = nextBday != null && nextBday.month == now.month && nextBday.day == now.day;

    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        color: isToday ? Colors.pink.withValues(alpha: 0.05) : AppColors.surface,
        border: isToday ? Border.all(color: Colors.pink.withValues(alpha: 0.2), width: 1.5) : null,
      ),
      child: AnimatedPress(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BirthdaysScreen())),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink.withValues(alpha: 0.1) : AppColors.primaryContainer, 
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      Symbols.cake_rounded, 
                      color: isToday ? Colors.pink : AppColors.primary, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Дни рождения', 
                    style: AppTypography.titleSmall.copyWith(
                      color: isToday ? Colors.pink.shade900 : AppColors.primary90,
                      fontWeight: FontWeight.w800,
                    )
                  ),
                  const Spacer(),
                  const Icon(Symbols.chevron_right_rounded, color: AppColors.outline, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                 const Row(
                   children: [
                     SkeletonLoader(width: 54, height: 54, borderRadius: AppRadius.md),
                     SizedBox(width: AppSpacing.md),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           SkeletonLoader(width: 140, height: 16),
                           SizedBox(height: 8),
                           SkeletonLoader(width: 80, height: 12),
                         ],
                       ),
                     ),
                   ],
                 )
              else if (_errorMessage != null)
                Text(_errorMessage!, style: AppTypography.bodySmall.copyWith(color: AppColors.error))
              else
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: isToday 
                          ? const LinearGradient(colors: [Colors.pinkAccent, Colors.orangeAccent]) 
                          : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          if (isToday) 
                            BoxShadow(
                              color: Colors.pinkAccent.withValues(alpha: 0.3), 
                              blurRadius: 10, 
                              offset: const Offset(0, 4)
                            ) 
                          else 
                            AppColors.shadowLevel1
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _formatDateShort(nextBday!),
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nextBirthdayChild!.fullName, 
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                          Row(
                            children: [
                              Text(
                                isToday ? 'СЕГОДНЯ! ' : 'Будет ', 
                                style: AppTypography.bodySmall.copyWith(
                                  color: isToday ? Colors.pink : AppColors.textSecondary, 
                                  fontWeight: isToday ? FontWeight.w900 : null
                                )
                              ),
                              Text(
                                '${_calculateAge(_nextBirthdayChild!.birthday, now) + 1} лет', 
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_nextBirthdayGroupName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer, 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          _nextBirthdayGroupName!, 
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10, 
                            color: AppColors.primary, 
                            fontWeight: FontWeight.w800
                          )
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
