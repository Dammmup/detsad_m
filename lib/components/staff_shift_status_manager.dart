import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shifts_provider.dart';

class StaffShiftStatusManager extends StatefulWidget {
  final Widget child;

  const StaffShiftStatusManager({Key? key, required this.child}) : super(key: key);

  @override
  State<StaffShiftStatusManager> createState() => _StaffShiftStatusManagerState();
}

class _StaffShiftStatusManagerState extends State<StaffShiftStatusManager> {
  String? _previousUserId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final shiftsProvider = Provider.of<ShiftsProvider>(context);
    final user = authProvider.user;

    // Проверяем, изменился ли пользователь, и если да, загружаем статус смены
    if (user != null && user.id != _previousUserId) {
      _previousUserId = user.id;
      shiftsProvider.fetchShiftStatus(user.id);
    }

    return widget.child;
  }
}