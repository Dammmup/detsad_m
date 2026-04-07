import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/animated_press.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

import '../core/widgets/shimmer_loading.dart';

class TasksWidget extends StatefulWidget {
  const TasksWidget({super.key});

  @override
  State<TasksWidget> createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (authProvider.user != null) {
      await taskProvider.loadAllTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    List<Task> pendingTasks = taskProvider.tasks
        .where((task) => task.status != 'completed')
        .take(3)
        .toList();

    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        color: AppColors.surface,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer, 
                  shape: BoxShape.circle
                ),
                child: const Icon(Symbols.task_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Ближайшие задачи', 
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary90,
                  fontWeight: FontWeight.w800,
                )
              ),
              const Spacer(),
              if (pendingTasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary, 
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  child: Text(
                    '${pendingTasks.length}', 
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white, 
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    )
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (taskProvider.isLoading)
            Column(
              children: List.generate(3, (index) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: SkeletonLoader(width: double.infinity, height: 64, borderRadius: AppRadius.md),
              )),
            )
          else if (taskProvider.errorMessage != null)
            Text(taskProvider.errorMessage!, style: AppTypography.bodySmall.copyWith(color: AppColors.error))
          else if (pendingTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Все задачи выполнены ✨', 
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary)
                )
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingTasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _buildTaskItem(pendingTasks[index], taskProvider)
                  .animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, TaskProvider taskProvider) {
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.error.withValues(alpha: 0.05) : AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isOverdue ? AppColors.error.withValues(alpha: 0.2) : AppColors.primaryContainer,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title, 
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: task.status == 'completed' ? TextDecoration.lineThrough : null
                  ), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                if (task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.schedule_rounded, 
                          size: 14, 
                          color: _getDueDateColor(task.dueDate!)
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}',
                          style: AppTypography.bodySmall.copyWith(
                            color: _getDueDateColor(task.dueDate!), 
                            fontWeight: isOverdue ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedPress(
            onTap: () => _toggleTaskStatus(task.id, taskProvider),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.status == 'completed' ? AppColors.success : Colors.white.withValues(alpha: 0.5),
                border: Border.all(
                  color: task.status == 'completed' ? AppColors.success : AppColors.primary30,
                  width: 2,
                ),
              ),
              child: Icon(
                task.status == 'completed' ? Symbols.check_rounded : Symbols.circle_rounded,
                color: task.status == 'completed' ? Colors.white : AppColors.primary30,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;
    if (diff < 0) return AppColors.error;
    if (diff <= 1) return AppColors.warning;
    return AppColors.textTertiary;
  }

  Future<void> _toggleTaskStatus(String taskId, TaskProvider taskProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      await taskProvider.toggleTaskStatus(taskId, authProvider.user!.id);
    }
  }
}
