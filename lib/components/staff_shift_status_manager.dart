import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shifts_provider.dart';

class StaffShiftStatusManager extends StatefulWidget {
  final Widget child;

  const StaffShiftStatusManager({super.key, required this.child});

  @override
  State<StaffShiftStatusManager> createState() =>
      _StaffShiftStatusManagerState();
}

class _StaffShiftStatusManagerState extends State<StaffShiftStatusManager> {
  String? _previousUserId;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final shiftsProvider = Provider.of<ShiftsProvider>(context);
    final user = authProvider.user;

    if (user != null && user.id != _previousUserId) {
      _previousUserId = user.id;
      // Откладываем вызов до после завершения build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          shiftsProvider.fetchShiftStatus(user.id);
        }
      });
    }

    return widget.child;
  }
}
