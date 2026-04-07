import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/child_model.dart';
import '../../core/services/children_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/shimmer_loading.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  List<Child> _upcomingBirthdays = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final childrenService = ChildrenService();
      List<Child> allChildren = await childrenService.getAllChildren();

      if (mounted) {
        setState(() {
          _upcomingBirthdays = _filterAndSortBirthdays(allChildren);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Не удалось загрузить календарь дней рождения';
          _isLoading = false;
        });
      }
    }
  }

  List<Child> _filterAndSortBirthdays(List<Child> children) {
    final now = DateTime.now();
    List<Child> childrenWithBirthdays = children.where((child) => child.birthday != null).toList();

    childrenWithBirthdays.sort((child1, child2) {
      DateTime? date1 = _getNextBirthdayDate(child1.birthday, now);
      DateTime? date2 = _getNextBirthdayDate(child2.birthday, now);
      if (date1 == null) return 1;
      if (date2 == null) return -1;
      return date1.compareTo(date2);
    });

    return childrenWithBirthdays;
  }

  DateTime? _getNextBirthdayDate(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;
    try {
      DateTime birthday = DateTime.parse(birthdayString);
      DateTime birthdayThisYear = DateTime(currentDate.year, birthday.month, birthday.day);
      if (birthdayThisYear.isBefore(DateTime(currentDate.year, currentDate.month, currentDate.day))) {
        birthdayThisYear = DateTime(currentDate.year + 1, birthday.month, birthday.day);
      }
      return birthdayThisYear;
    } catch (e) {
      return null;
    }
  }

  int? _calculateAge(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;
    try {
      DateTime birthday = DateTime.parse(birthdayString);
      int age = currentDate.year - birthday.year;
      return age;
    } catch (e) {
      return null;
    }
  }

  String _getAgeSuffix(int age) {
    if (age % 10 == 1 && age % 100 != 11) return 'год';
    if ((age % 10 >= 2 && age % 10 <= 4) && (age % 100 < 10 || age % 100 >= 20)) return 'года';
    return 'лет';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(
                'Дни рождения', 
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary90,
                  fontWeight: FontWeight.w900,
                )
              ),
              centerTitle: true,
              backgroundColor: AppColors.surface.withValues(alpha: 0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back_ios_new_rounded, color: AppColors.primary90, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: _isLoading
            ? _buildSkeletonLoading()
            : _errorMessage != null
                ? _buildErrorState()
                : _upcomingBirthdays.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadUpcomingBirthdays,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.xxxl),
                          itemCount: _upcomingBirthdays.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final child = _upcomingBirthdays[index];
                            final nextBday = _getNextBirthdayDate(child.birthday, DateTime.now());
                            final isToday = nextBday != null && 
                                           nextBday.month == DateTime.now().month && 
                                           nextBday.day == DateTime.now().day;
                            final age = _calculateAge(child.birthday, DateTime.now()) ?? 0;

                            return _buildBirthdayCard(child, nextBday, index, isToday, age);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildBirthdayCard(Child child, DateTime? nextBday, int index, bool isToday, int age) {
    return Container(
      decoration: isToday ? AppDecorations.cardElevated1.copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.2), 
            blurRadius: 16, 
            offset: const Offset(0, 4)
          )
        ],
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
      ) : AppDecorations.cardElevated1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: isToday 
                    ? const LinearGradient(colors: [Colors.pinkAccent, Colors.orangeAccent]) 
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${nextBday?.day}', 
                    style: AppTypography.titleLarge.copyWith(color: Colors.white, height: 1, fontWeight: FontWeight.w900)
                  ),
                  Text(
                    _formatMonthShort(nextBday?.month ?? 1), 
                    style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.fullName, 
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 6),
                  _buildIconInfo(
                    isToday ? Symbols.celebration_rounded : Symbols.groups_rounded, 
                    child.groupName ?? 'Группа не указана',
                    isToday ? Colors.pink : AppColors.primary
                  ),
                  const SizedBox(height: 4),
                  _buildIconInfo(
                    Symbols.cake_rounded, 
                    'Исполнится ${age + 1} ${_getAgeSuffix(age + 1)}',
                    isToday ? Colors.orange : AppColors.primary
                  ),
                ],
              ),
            ),
            if (isToday)
              const Icon(Symbols.celebration_rounded, color: Colors.pinkAccent, size: 32)
                  .animate(onPlay: (c) => c.repeat())
                  .shake(duration: 2.seconds, hz: 4),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildIconInfo(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.xxxl),
      itemCount: 8,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.history_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Нет предстоящих событий', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadUpcomingBirthdays,
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonthShort(int month) {
    const List<String> months = ['ЯНВ', 'ФЕВ', 'МАР', 'АПР', 'МАЙ', 'ИЮН', 'ИЮЛ', 'АВГ', 'СЕН', 'ОКТ', 'НОЯ', 'ДЕК'];
    return months[month - 1];
  }
}
