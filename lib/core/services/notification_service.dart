import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Инициализация часовых поясов
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse payload) {
        // Обработка нажатия на уведомление
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'attendance_channel',
      'Уведомления о посещаемости',
      channelDescription: 'Канал для уведомлений о посещаемости',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Тикер',
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
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
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'attendance_channel',
      'Уведомления о посещаемости',
      channelDescription: 'Канал для уведомлений о посещаемости',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    // Конвертируем DateTime в TZDateTime для корректной работы планировщика
    tz.TZDateTime scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Метод для планирования ежедневных уведомлений о приходе
  Future<void> scheduleDailyArrivalNotification({
    required int id,
    required Time time,
  }) async {
    tz.TZDateTime scheduledTime = _getNextOccurrence(time);

    await scheduleNotification(
      id: id,
      title: 'Напоминание о приходе',
      body: 'Не забудьте отметить ваш приход на работу',
      scheduledDate: scheduledTime.toLocal(),
      payload: 'arrival_reminder',
    );
  }

  // Метод для планирования ежедневных уведомлений об уходе
  Future<void> scheduleDailyDepartureNotification({
    required int id,
    required Time time,
  }) async {
    tz.TZDateTime scheduledTime = _getNextOccurrence(time);

    await scheduleNotification(
      id: id,
      title: 'Напоминание об уходе',
      body: 'Не забудьте отметить ваш уход с работы',
      scheduledDate: scheduledTime.toLocal(),
      payload: 'departure_reminder',
    );
  }

  // Метод для планирования ежедневных уведомлений о посещаемости детей
  Future<void> scheduleDailyAttendanceNotification({
    required int id,
    required Time time,
  }) async {
    tz.TZDateTime scheduledTime = _getNextOccurrence(time);

    await scheduleNotification(
      id: id,
      title: 'Напоминание о посещаемости детей',
      body: 'Не забудьте отметить посещаемость детей',
      scheduledDate: scheduledTime.toLocal(),
      payload: 'attendance_reminder',
    );
  }

  // Вспомогательный метод для получения следующего occurrence времени
  tz.TZDateTime _getNextOccurrence(Time time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      time.second,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}

class Time {
  final int hour;
  final int minute;
  final int second;

  Time({required this.hour, required this.minute, this.second = 0});
}