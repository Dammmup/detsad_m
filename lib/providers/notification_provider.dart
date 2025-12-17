import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  Future<void> scheduleDailyArrivalNotification({
    required int id,
    required Time time,
  }) async {
    await _notificationService.scheduleDailyArrivalNotification(
      id: id,
      time: time,
    );
  }

  Future<void> scheduleDailyDepartureNotification({
    required int id,
    required Time time,
  }) async {
    await _notificationService.scheduleDailyDepartureNotification(
      id: id,
      time: time,
    );
  }

  Future<void> scheduleDailyAttendanceNotification({
    required int id,
    required Time time,
  }) async {
    await _notificationService.scheduleDailyAttendanceNotification(
      id: id,
      time: time,
    );
  }
}
