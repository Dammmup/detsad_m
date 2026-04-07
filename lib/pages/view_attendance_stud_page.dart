import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/shimmer_loading.dart';

class ViewAttendanceStud extends StatelessWidget {
  final String code;
  final String uid;
  const ViewAttendanceStud({
    super.key,
    required this.code,
    required this.uid,
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
                'Моя посещаемость', 
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
      body: ViewAttendanceStudScreen(code: code, uid: uid),
    );
  }
}

class ViewAttendanceStudScreen extends StatefulWidget {
  final String code;
  final String uid;
  const ViewAttendanceStudScreen({
    super.key,
    required this.code,
    required this.uid,
  });

  @override
  State<ViewAttendanceStudScreen> createState() => _ViewAttendanceStudScreenState();
}

class _ViewAttendanceStudScreenState extends State<ViewAttendanceStudScreen> {
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
    return StreamBuilder(
      stream: db
          .collection('attendance')
          .where(FieldPath.documentId, isEqualTo: widget.uid)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('Данные не найдены');
        }

        final docData = snapshot.data!.docs[0].data() as Map<String, dynamic>;
        if (!docData.containsKey(widget.code)) {
          return _buildEmptyState('Курс "${widget.code}" не найден');
        }

        final attendanceList = (docData[widget.code] as Map<String, dynamic>)['attendance'] as List<dynamic>;
        final reversedList = attendanceList.reversed.toList();
        
        double totalHrs = 0;
        int presentCount = 0;
        for (var item in attendanceList) {
          totalHrs += double.tryParse(item['hrs'].toString()) ?? 0;
          if (item['attendance'] == true) presentCount++;
        }
        double attendanceRate = attendanceList.isEmpty ? 0 : (presentCount / attendanceList.length) * 100;

        return Column(
          children: [
            _buildSummaryHeader(totalHrs, attendanceRate, attendanceList.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                itemCount: reversedList.length,
                itemBuilder: (context, index) => _buildAttendanceCard(reversedList[index], index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader(double hours, double rate, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Часы', 
              '${hours.toStringAsFixed(1)} ч', 
              Symbols.schedule_rounded, 
              AppColors.primary
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Посещаемость', 
              '${rate.toStringAsFixed(0)}%', 
              Symbols.verified_rounded, 
              AppColors.success
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardElevated1.copyWith(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.w900)),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(dynamic data, int index) {
    final bool isPresent = data['attendance'] as bool;
    final String dateStr = data['date'].toString().split('–')[0];
    final String hrs = '${data['hrs']} ч';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: AppDecorations.cardElevated1.copyWith(
        border: isPresent ? Border.all(color: AppColors.success.withValues(alpha: 0.1), width: 1) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPresent ? AppColors.success : AppColors.error).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPresent ? Symbols.check_circle_rounded : Symbols.cancel_rounded,
                color: isPresent ? AppColors.success : AppColors.error.withValues(alpha: 0.5),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  Text(isPresent ? 'Присутствовал(а)' : 'Отсутствовал(а)', 
                    style: AppTypography.bodySmall.copyWith(color: isPresent ? AppColors.success : AppColors.textTertiary)),
                ],
              ),
            ),
            Text(hrs, style: AppTypography.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 20).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 10,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: SkeletonLoader(width: double.infinity, height: 70, borderRadius: AppRadius.md),
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
            const Icon(Symbols.error_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Произошла ошибка', style: AppTypography.titleSmall),
            Text(error, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.inbox_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}