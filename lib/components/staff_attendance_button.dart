import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/shifts_provider.dart';
import '../providers/geolocation_provider.dart';

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
        final shiftsProvider =
            Provider.of<ShiftsProvider>(context, listen: false);
        final geoProvider =
            Provider.of<GeolocationProvider>(context, listen: false);

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
    VoidCallback? buttonAction;
    bool buttonDisabled =
        shiftsProvider.loading || user == null || user.id.isEmpty;

    if (shiftsProvider.status == 'scheduled' ||
        shiftsProvider.status == 'no_record') {
      buttonText = 'Отметить приход';
      buttonAction =
          user != null ? () => _handleCheckIn(context, user.id) : null;

      if (geolocationProvider.enabled &&
          geolocationProvider.isPositionLoaded &&
          !geolocationProvider.isWithinGeofence) {
        buttonDisabled = true;
      }
    } else if (shiftsProvider.status == 'in_progress') {
      buttonText = 'Отметить уход';
      buttonAction =
          user != null ? () => _handleCheckOut(context, user.id) : null;

      if (geolocationProvider.enabled &&
          geolocationProvider.isPositionLoaded &&
          !geolocationProvider.isWithinGeofence) {
        buttonDisabled = true;
      }
    } else if (shiftsProvider.status == 'completed') {
      buttonText = 'Посещение отмечено';
      buttonAction = null;
      buttonDisabled = true;
    } else if (shiftsProvider.status == 'error') {
      buttonText = 'Ошибка';
      buttonAction = null;
      buttonDisabled = true;
    }

    final gradient = _getButtonGradient(shiftsProvider.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (geolocationProvider.enabled &&
            (geolocationProvider.isPositionLoaded ||
                geolocationProvider.isLocationTemporarilyUnavailable))
          _buildGeolocationStatus(geolocationProvider),
        SizedBox(
          width: 200,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              gradient: buttonDisabled ? AppColors.disabledGradient : gradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: buttonDisabled
                  ? []
                  : const [AppColors.shadowButton],
            ),
            child: ElevatedButton(
              onPressed: buttonDisabled ? null : buttonAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.white70,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: shiftsProvider.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),
          ),
        ),
        if (shiftsProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              shiftsProvider.errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeolocationStatus(GeolocationProvider provider) {
    if (provider.isLocationTemporarilyUnavailable) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.info.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.info,
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching,
              color: AppColors.info,
              size: 16,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'GPS сигнал недоступен, ожидание позиции...',
                style: TextStyle(
                  color: AppColors.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final isInZone = provider.isWithinGeofence;
    final statusText = provider.getStatusText(
      provider.currentPosition!.latitude,
      provider.currentPosition!.longitude,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isInZone
            ? AppColors.success.withAlpha((0.1 * 255).round())
            : AppColors.error.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInZone ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInZone ? Icons.check_circle : Icons.error,
            color: isInZone ? AppColors.success : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                color: isInZone ? AppColors.success : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getButtonGradient(String status) {
    switch (status) {
      case 'completed':
        return AppColors.successGradient;
      case 'in_progress':
        return AppColors.dangerGradient;
      case 'error':
        return AppColors.disabledGradient;
      default:
        return AppColors.primaryGradient;
    }
  }

  Future<void> _handleCheckIn(BuildContext context, String userId) async {
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    final ctx = context;
    await shiftsProvider.checkIn(userId);

    if (!ctx.mounted) return;

    if (shiftsProvider.errorMessage == null) {
      widget.onStatusChange?.call();
      _showSnackbar(ctx, 'Отметка о приходе успешно сохранена', AppColors.success);
    } else {
      _showSnackbar(ctx, shiftsProvider.errorMessage!, AppColors.error);
    }
  }

  Future<void> _handleCheckOut(BuildContext context, String userId) async {
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    final ctx = context;

    await shiftsProvider.checkOut(userId);

    if (!ctx.mounted) return;

    if (shiftsProvider.errorMessage == null) {
      widget.onStatusChange?.call();
      _showSnackbar(ctx, 'Отметка об уходе успешно сохранена', AppColors.success);
    } else {
      _showSnackbar(ctx, shiftsProvider.errorMessage!, AppColors.error);
    }
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
