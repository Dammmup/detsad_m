import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/shimmer_loading.dart';

class ViewAttendanceAll extends StatelessWidget {
  final String code;
  final String uid;
  final List students;
  const ViewAttendanceAll({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

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
                'Общая посещаемость', 
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
              actions: [
                IconButton(
                  icon: const Icon(Symbols.info_rounded, color: AppColors.primary90),
                  onPressed: () => _showLegend(context),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ViewAttendanceAllScreen(
        code: code,
        uid: uid,
        students: students,
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Легенда', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.md),
            _buildLegendItem(Symbols.check_circle_rounded, AppColors.success, 'Присутствовал'),
            const SizedBox(height: AppSpacing.sm),
            _buildLegendItem(Symbols.cancel_rounded, AppColors.error.withValues(alpha: 0.5), 'Отсутствовал'),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppTypography.bodyLarge),
      ],
    );
  }
}

class ViewAttendanceAllScreen extends StatefulWidget {
  final String code;
  final String uid;
  final List students;
  const ViewAttendanceAllScreen({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

  @override
  State<ViewAttendanceAllScreen> createState() => _ViewAttendanceAllScreenState();
}

class _ViewAttendanceAllScreenState extends State<ViewAttendanceAllScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.pageBackground,
      child: Column(
        children: [
          const SizedBox(height: 110),
          Expanded(
            child: _buildStream(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStream(BuildContext context) {
    if (widget.students.isEmpty) {
      return _buildEmptyState('Список студентов пуст');
    }

    return StreamBuilder(
      stream: db
          .collection('attendance')
          .where(FieldPath.documentId, whereIn: widget.students)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Данные о посещаемости отсутствуют');
        }

        final firstDocData = snapshot.data!.docs[0].data() as Map<String, dynamic>;
        if (!firstDocData.containsKey(widget.code)) {
          return _buildEmptyState('Курс "${widget.code}" не найден');
        }

        final attendanceList = (firstDocData[widget.code] as Map<String, dynamic>)['attendance'] as List<dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSummary(snapshot.data!.docs),
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: AppDecorations.cardElevated1,
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowHeight: 64,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 56,
                    headingRowColor: WidgetStateProperty.all(AppColors.primaryContainer.withValues(alpha: 0.3)),
                    horizontalMargin: 20,
                    columns: _generateColumns(attendanceList),
                    rows: snapshot.data!.docs.map((element) {
                      final data = element.data() as Map<String, dynamic>;
                      final studentAttendance = (data[widget.code] as Map<String, dynamic>)['attendance'] as List<dynamic>;
                      return _generateRows(element.id, studentAttendance);
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.05, end: 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSummary(List<QueryDocumentSnapshot> docs) {
    int totalSlots = 0;
    int presentSlots = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey(widget.code)) {
        final attendance = (data[widget.code] as Map<String, dynamic>)['attendance'] as List<dynamic>;
        totalSlots += attendance.length;
        presentSlots += attendance.where((a) => a['attendance'] == true).length;
      }
    }

    double rate = totalSlots == 0 ? 0 : (presentSlots / totalSlots) * 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardElevated1.copyWith(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient.colors.map((c) => c.withValues(alpha: 0.1)).toList(),
          begin: AppColors.primaryGradient.begin,
          end: AppColors.primaryGradient.end,
        ),
      ),
      child: Row(
        children: [
          _buildSummaryStat('Всего записей', totalSlots.toString(), Symbols.analytics_rounded, AppColors.primary),
          const Spacer(),
          _buildSummaryStat('Средняя явка', '${rate.toStringAsFixed(1)}%', Symbols.group_rounded, AppColors.success),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }

  List<DataColumn> _generateColumns(List doc) {
    List<DataColumn> columns = [];
    columns.add(DataColumn(
      label: Text('Студент (ID)', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
    ));

    for (var entry in doc) {
      final dateStr = entry['date'].toString().split('–')[0];
      final hrsStr = entry['hrs'] ?? '0';
      columns.add(DataColumn(
        label: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(dateStr, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$hrsStr ч', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
        ),
      ));
    }
    return columns;
  }

  DataRow _generateRows(String docId, List attendance) {
    List<DataCell> cells = [];
    cells.add(DataCell(
      Text(
        docId.length > 8 ? '${docId.substring(0, 8)}...' : docId, 
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)
      )
    ));

    for (var entry in attendance) {
      final isPresent = entry['attendance'] as bool;
      cells.add(DataCell(
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent ? Symbols.check_circle_rounded : Symbols.cancel_rounded,
              color: isPresent ? AppColors.success : AppColors.error.withValues(alpha: 0.3),
              size: 22,
            ),
          ),
        ),
      ));
    }
    return DataRow(cells: cells);
  }

  Widget _buildSkeletonLoading() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          SkeletonLoader(width: double.infinity, height: 80, borderRadius: AppRadius.md),
          SizedBox(height: AppSpacing.md),
          Expanded(child: SkeletonLoader(width: double.infinity, height: double.infinity, borderRadius: AppRadius.md)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.history_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.warning_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Ошибка загрузки', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}