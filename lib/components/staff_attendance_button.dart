import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shifts_provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class StaffAttendanceButton extends StatefulWidget {
  final VoidCallback? onStatusChange;

  const StaffAttendanceButton({Key? key, this.onStatusChange}) : super(key: key);

  @override
  State<StaffAttendanceButton> createState() => _StaffAttendanceButtonState();
}

class _StaffAttendanceButtonState extends State<StaffAttendanceButton> {
  bool _isCheckInActive = false;
  Timer? _timer;

  @override
 void initState() {
    super.initState();
    _checkTime();
    // Проверяем время каждую минуту
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTime();
    });
 }

  void _checkTime() {
    final now = DateTime.now();
    final hours = now.hour;
    final minutes = now.minute;

    // Активно с 6:30 до 9:30 (изменил временные рамки для примера)
    final isActive = (hours == 6 && minutes >= 30) || (hours > 6 && hours < 22) || (hours == 9 && minutes <= 30);
    
    if (_isCheckInActive != isActive) {
      setState(() {
        _isCheckInActive = isActive;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsProvider = Provider.of<ShiftsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Загружаем статус смены при инициализации или изменении пользователя - это должно происходить вне build метода
    // Логика проверки и загрузки перенесена в отдельный метод или родительский виджет

    // Определяем текст и обработчик кнопки в зависимости от статуса
    String buttonText = '';
    VoidCallback? buttonAction;
    bool buttonDisabled = shiftsProvider.loading || !user!.id.isNotEmpty;

    if (shiftsProvider.status == 'scheduled' || shiftsProvider.status == 'no_record') {
      buttonText = 'Отметить приход';
      buttonAction = user != null ? () => _handleCheckIn(context, user.id) : null;
      buttonDisabled = shiftsProvider.loading || !user!.id.isNotEmpty || !_isCheckInActive;
    } else if (shiftsProvider.status == 'in_progress') {
      buttonText = 'Отметить уход';
      buttonAction = user != null ? () => _handleCheckOut(context, user.id) : null;
      buttonDisabled = shiftsProvider.loading || !user!.id.isNotEmpty;
    } else if (shiftsProvider.status == 'completed') {
      buttonText = 'Посещение отмечено';
      buttonAction = null;
      buttonDisabled = true;
    } else if (shiftsProvider.status == 'error') {
      buttonText = 'Ошибка';
      buttonAction = null;
      buttonDisabled = true;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 50,
          child: ElevatedButton(
            onPressed: buttonDisabled ? null : buttonAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(shiftsProvider.status),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              shadowColor: Colors.black.withOpacity(0.1),
              elevation: 4,
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
        if (shiftsProvider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              shiftsProvider.errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
 }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.purple;
      case 'error':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

 // Get current location
 Future<Map<String, double>?> _getCurrentLocation() async {
   try {
     // Check if location services are enabled
     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
     if (!serviceEnabled) {
       _showSnackbar(context, 'Службы геолокации отключены. Пожалуйста, включите их.', Colors.red);
       return null;
     }

     // Check location permissions
     LocationPermission permission = await Geolocator.checkPermission();
     if (permission == LocationPermission.denied) {
       permission = await Geolocator.requestPermission();
       if (permission == LocationPermission.denied) {
         _showSnackbar(context, 'Разрешение на доступ к местоположению отклонено', Colors.red);
         return null;
       }
     }
     
     if (permission == LocationPermission.deniedForever) {
       _showSnackbar(context, 'Разрешение на доступ к местоположению отклонено навсегда. Пожалуйста, разрешите в настройках.', Colors.red);
       return null;
     }

     // Get current position
     Position position = await Geolocator.getCurrentPosition(
       desiredAccuracy: LocationAccuracy.high
     );
     
     return {
       'latitude': position.latitude,
       'longitude': position.longitude
     };
   } catch (e) {
     _showSnackbar(context, 'Ошибка получения геолокации: $e', Colors.red);
     return null;
   }
 }

Future<void> _handleCheckIn(BuildContext context, String userId) async {
    // Get current location
    Map<String, double>? location = await _getCurrentLocation();
    if (location == null) {
      _showSnackbar(context, 'Не удалось получить геолокацию. Отметка не будет сохранена.', Colors.red);
      return;
    }
    
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    await shiftsProvider.checkIn(
      userId,
      latitude: location['latitude'],
      longitude: location['longitude']
    );
    
    if (shiftsProvider.errorMessage == null) {
      if (widget.onStatusChange != null) {
        widget.onStatusChange!();
      }
      _showSnackbar(context, 'Отметка о приходе успешно сохранена', Colors.green);
    } else {
      _showSnackbar(context, shiftsProvider.errorMessage!, Colors.red);
    }
  }

  Future<void> _handleCheckOut(BuildContext context, String userId) async {
    // Get current location
    Map<String, double>? location = await _getCurrentLocation();
    if (location == null) {
      _showSnackbar(context, 'Не удалось получить геолокацию. Отметка не будет сохранена.', Colors.red);
      return;
    }
    
    final shiftsProvider = Provider.of<ShiftsProvider>(context, listen: false);
    await shiftsProvider.checkOut(
      userId,
      latitude: location['latitude'],
      longitude: location['longitude']
    );
    
    if (shiftsProvider.errorMessage == null) {
      if (widget.onStatusChange != null) {
        widget.onStatusChange!();
      }
      _showSnackbar(context, 'Отметка об уходе успешно сохранена', Colors.green);
    } else {
      _showSnackbar(context, shiftsProvider.errorMessage!, Colors.red);
    }
  }

 void _showSnackbar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}