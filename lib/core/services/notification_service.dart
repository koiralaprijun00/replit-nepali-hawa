import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../constants/aqi_constants.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await NotificationService.instance._initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();
    // Consider setting a default local location if your app targets a specific timezone primarily.
    // For example: tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    // If not set, tz.local (used later) will use the device's current timezone.

    // Android initialization
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Air Quality Alerts Channel
    const AndroidNotificationChannel airQualityChannel = AndroidNotificationChannel(
      AppConstants.airQualityChannelId,
      AppConstants.airQualityChannelName,
      description: AppConstants.airQualityChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(airQualityChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
    // Navigate to appropriate screen based on payload
  }

  Future<bool> requestPermissions() async {
    // Request notification permissions
    final permission = await Permission.notification.request();
    return permission.isGranted;
  }

  Future<bool> hasPermissions() async {
    final permission = await Permission.notification.status;
    return permission.isGranted;
  }

  Future<void> showAirQualityAlert({
    required String cityName,
    required int aqi,
    required String message,
    String? payload,
  }) async {
    final aqiLevel = AQIConstants.getAQILevel(aqi);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.airQualityChannelId,
      AppConstants.airQualityChannelName,
      channelDescription: AppConstants.airQualityChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      'Air Quality Alert - $cityName',
      '$message (AQI: $aqi - ${aqiLevel.label})',
      notificationDetails,
      payload: payload ?? cityName,
    );
  }

  Future<void> showLocationAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.airQualityChannelId,
      AppConstants.airQualityChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1, // Unique ID
      title,
      message,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleAirQualityReminder({
    required int id,
    required String cityName,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.airQualityChannelId,
      AppConstants.airQualityChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Ensure the scheduledTime is in the future relative to now to prevent immediate scheduling of past events.
    final now = DateTime.now();
    if (scheduledTime.isBefore(now) || scheduledTime.isAtSameMomentAs(now)) {
      print('Scheduled time $scheduledTime is in the past or now. Notification not scheduled.');
      return;
    }
    
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      'Air Quality Check',
      'Check the current air quality in $cityName',
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload ?? cityName,
      // To repeat daily at the same time, uncomment and use:
      // matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<List<ActiveNotification>> getActiveNotifications() async {
    return await _notifications.getActiveNotifications();
  }

  bool shouldNotifyForAQI(int aqi, int? previousAqi) {
    final currentLevel = AQIConstants.getAQILevel(aqi);
    
    if (aqi >= 151) return true;
    
    if (previousAqi != null) {
      final previousLevel = AQIConstants.getAQILevel(previousAqi);
      if (currentLevel.min > previousLevel.min) return true;
      if (aqi - previousAqi > 25) return true;
    }
    
    return false;
  }

  String getNotificationMessage(int aqi) {
    final level = AQIConstants.getAQILevel(aqi);
    // final activity = AQIConstants.getActivityAlert(aqi); // activity is not used
    
    switch (level.label) {
      case 'Good':
        return 'Great air quality! Perfect for outdoor activities.';
      case 'Moderate':
        return 'Air quality is acceptable. Sensitive individuals should be cautious.';
      case 'Unhealthy for Sensitive Groups':
        return 'Sensitive groups should limit outdoor activities.';
      case 'Unhealthy':
        return 'Avoid outdoor activities. Air quality is unhealthy.';
      case 'Very Unhealthy':
        return 'Stay indoors. Air quality is very unhealthy.';
      case 'Hazardous':
        return 'EMERGENCY: Remain indoors. Air quality is hazardous.';
      default:
        return 'Check current air quality conditions.';
    }
  }
}