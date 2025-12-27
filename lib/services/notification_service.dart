import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test_app/models/medication.dart';
import 'package:test_app/models/medication_intake.dart';
import 'package:test_app/services/database_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  // Singleton instance
  static final NotificationService instance = NotificationService._init();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    // Initialise les fuseaux horaires
    tz.initializeTimeZones();

    // Paramètres Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Paramètres iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Demande de permissions iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Demande de permissions Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');

      if (response.actionId == 'taken_action') {
        await _markMedicationAsTaken(payload);
      } else if (response.actionId == 'ignore_action') {
        await _markMedicationAsMissed(payload);
      }
    }
  }

  Future<void> _markMedicationAsTaken(String payload) async {
    try {
      final parts = payload.split('_');
      final medicationId = int.parse(parts[0]);
      final scheduledTime = DateTime.parse(parts[1]);

      final existingIntake = await DatabaseService.instance.getMedicationIntake(
        medicationId,
        scheduledTime,
      );

      if (existingIntake != null) {
        final updatedIntake = MedicationIntake(
          id: existingIntake.id,
          medicationId: medicationId,
          scheduledTime: scheduledTime,
          actualTime: DateTime.now(),
          status: 'taken',
          date: existingIntake.date,
          createdAt: existingIntake.createdAt,
        );

        await DatabaseService.instance.updateMedicationIntake(updatedIntake);
      }
    } catch (e) {
      debugPrint('Error marking medication as taken: $e');
    }
  }

  Future<void> _markMedicationAsMissed(String payload) async {
    try {
      final parts = payload.split('_');
      final medicationId = int.parse(parts[0]);
      final scheduledTime = DateTime.parse(parts[1]);

      final existingIntake = await DatabaseService.instance.getMedicationIntake(
        medicationId,
        scheduledTime,
      );

      if (existingIntake != null) {
        final updatedIntake = MedicationIntake(
          id: existingIntake.id,
          medicationId: medicationId,
          scheduledTime: scheduledTime,
          actualTime: null,
          status: 'missed',
          date: existingIntake.date,
          createdAt: existingIntake.createdAt,
        );

        await DatabaseService.instance.updateMedicationIntake(updatedIntake);
      }
    } catch (e) {
      debugPrint('Error marking medication as missed: $e');
    }
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation(DateTime.now().timeZoneName);
    return tz.TZDateTime.from(dateTime, location);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meditrack_channel',
      'MediTrack Notifications',
      channelDescription: 'Notifications pour les rappels de médicaments',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      actions: [
        AndroidNotificationAction(
          'taken_action',
          'Pris',
          titleColor: Color.fromARGB(255, 92, 184, 92),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'ignore_action',
          'Ignorer',
          titleColor: Color.fromARGB(255, 217, 83, 79),
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate),
      platformDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Déplace _parseTimes AVANT scheduleMedicationReminders
  List<TimeOfDay> _parseTimes(String timesJson) {
    final times = <TimeOfDay>[];

    try {
      final cleanJson = timesJson.replaceAll("'", '"');
      final timeStrings = cleanJson.replaceAll('[', '').replaceAll(']', '').split(',');

      for (final timeStr in timeStrings) {
        final trimmed = timeStr.trim();
        if (trimmed.isNotEmpty) {
          final parts = trimmed.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            times.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing times: $e');
      times.add(const TimeOfDay(hour: 8, minute: 0)); // fallback
    }

    return times;
  }

  Future<void> scheduleMedicationReminders(Medication medication) async {
    if (!medication.remindersEnabled) return;

    final now = DateTime.now();
    final endDate = medication.endDate ?? now.add(const Duration(days: 30));

    final times = _parseTimes(medication.times);

    var currentDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(endDate.year, endDate.month, endDate.day);

    int notificationId = 0;

    while (currentDate.isBefore(lastDate) || currentDate.isAtSameMomentAs(lastDate)) {
      for (final time in times) {
        final scheduledDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          time.hour,
          time.minute,
        );

        if (scheduledDate.isAfter(now)) {
          final payload = '${medication.id}_${scheduledDate.toIso8601String()}';

          final intake = MedicationIntake(
            medicationId: medication.id!,
            scheduledTime: scheduledDate,
            status: 'pending',
            date: currentDate,
            createdAt: DateTime.now(),
          );

          await DatabaseService.instance.insertMedicationIntake(intake);

          await scheduleNotification(
            id: notificationId,
            title: 'Rappel médicament',
            body: 'Temps de prendre : ${medication.name} ${medication.dosage}',
            scheduledDate: scheduledDate,
            payload: payload,
          );

          notificationId++;
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<void> cancelMedicationReminders(int medicationId) async {
    // Ici on annule toutes les notifications, mais tu peux améliorer pour annuler
    // uniquement celles liées à ce médicament en gardant les IDs en base.
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
