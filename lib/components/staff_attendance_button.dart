import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/animated_press.dart';
import '../providers/auth_provider.dart';
import '../providers/shifts_provider.dart';
import '../providers/geolocation_provider.dart';

import 'package:flutter_animate/flutter_animate.dart';

class StaffAttendanceButton extends StatefulWidget {
  final VoidCallback? onStatusChange;

  const StaffAttendanceButton({super.key, this.onStatusChange});

  @override
  State<StaffAttendanceButton> createState() => _StaffAttendanceButtonState();
}

class _StaffAttendanceButtonState extends State<StaffAttendanceButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
        final geoProvider = Provider.of<GeolocationProvider>(context, listen: false);

        geoProvider.loadSettings();

        if (authProvider.user != null) {
          shiftsProvider.fetchShiftStatus(authProvider.user!.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shiftsProvider = Provider.of<ShiftsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final geolocationProvider = Provider.of<GeolocationProvider>(context);
    final user = authProvider.user;

    String buttonText = '';
    IconData buttonIcon = Symbols.login_rounded;
    VoidCallback? buttonAction;
    bool buttonDisabled = shiftsProvider.loading || user == null || user.id.isEmpty;
    List<Color> gradientColors = [AppColors.primary, AppColors.secondary];

    if (shiftsProvider.status == 'scheduled' || shiftsProvider.status == 'no_record') {
      buttonText = 'Отметить приход';
      buttonIcon = Symbols.login_rounded;
      buttonAction = user != null ? () => _handleCheckIn(context, user.id) : null;
      gradientColors = [AppColors.primary, AppColors.secondary];

      if (geolocationProvider.enabled && geolocationProvider.isPositionLoaded && !geolocationProvider.isWithinGeofence) {
        buttonDisabled = true;
      }
    } else if (shiftsProvider.status == 'in_progress') {
      buttonText = 'Отметить уход';
      buttonIcon = Symbols.logout_rounded;
      buttonAction = user != null ? () => _handleCheckOut(context, user.id) : null;
      gradientColors = [AppColors.error, const Color(0xFFD32F2F)];

      if (geolocationProvider.enabled && geolocationProvider.isPositionLoaded && !geolocationProvider.isWithinGeofence) {
        buttonDisabled = true;
      }
    } else if (shiftsProvider.status == 'completed') {
      buttonText = 'Смена завершена';
      buttonIcon = Symbols.check_circle_rounded;
      buttonAction = null;
      buttonDisabled = true;
      gradientColors = [AppColors.success, const Color(0xFF2E7D32)];
    } else if (shiftsProvider.status == 'error') {
      buttonText = 'Ошибка';
      buttonIcon = Symbols.error_rounded;
      buttonAction = null;
      buttonDisabled = true;
      gradientColors = [AppColors.grey400, AppColors.grey500];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (geolocationProvider.enabled) 
          _buildGeolocationStatus(geolocationProvider)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: AppSpacing.sm),
        AnimatedPress(
          onTap: buttonDisabled ? null : buttonAction,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: buttonDisabled 
                ? AppColors.disabledGradient 
                : LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: buttonDisabled ? [] : [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Center(
              child: shiftsProvider.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, 
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(buttonIcon, color: Colors.white, size: 22),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          buttonText,
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.white, 
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (shiftsProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              shiftsProvider.errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildGeolocationStatus(GeolocationProvider provider) {
    bool isError = provider.errorMessage != null || (provider.enabled && !provider.isServiceEnabled);
    bool isWaiting = provider.isLocationTemporarilyUnavailable;
    bool isInZone = provider.isWithinGeofence;

    Color statusColor = AppColors.success;
    IconData statusIcon = Symbols.location_on_rounded;
    String statusText = provider.getStatusText(provider.currentPosition?.latitude ?? 0, provider.currentPosition?.longitude ?? 0);

    if (isError) {
      statusColor = AppColors.error;
      statusIcon = Symbols.location_off_rounded;
    } else if (isWaiting) {
      statusColor = AppColors.primary;
      statusIcon = Symbols.location_searching_rounded;
      statusText = 'Определяем местоположение...';
    } else if (!isInZone) {
      statusColor = AppColors.error;
      statusIcon = Symbols.wrong_location_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              statusText,
              style: AppTypography.bodySmall.copyWith(
                color: statusColor.withValues(alpha: 0.9), 
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context, String userId) async {
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    await shiftsProvider.checkIn(userId);
    if (mounted && shiftsProvider.errorMessage == null) {
      widget.onStatusChange?.call();
      if (mounted) _showSnackbar(this.context, 'Приход успешно отмечен! Удачной смены 🌟', AppColors.success);
    }
  }

  Future<void> _handleCheckOut(BuildContext context, String userId) async {
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    await shiftsProvider.checkOut(userId);
    if (mounted && shiftsProvider.errorMessage == null) {
      widget.onStatusChange?.call();
      if (mounted) _showSnackbar(this.context, 'Уход отмечен. Хорошего отдыха! 👋', AppColors.success);
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}
