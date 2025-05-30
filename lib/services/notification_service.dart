import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

const String _windowsAppName = 'RecurSafe';
const String _windowsAppUserModelId =
    'com.example.recursafe'; // Replace with your actual AppUserModelId

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize native plugin settings for Android.
    // Replace '@mipmap/ic_launcher' with your app's icon name if different.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize native plugin settings for iOS.
    const DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true, // Show alert when app is in foreground
      defaultPresentBadge: true, // Update badge when app is in foreground
      defaultPresentSound: true, // Play sound when app is in foreground
      // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Optional: for older iOS versions
    );

    // Initialize native plugin settings for Windows.
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: _windowsAppName,
          appUserModelId: _windowsAppUserModelId,
          guid: "58784f9c-331a-4be0-a1ec-86d17c957ac5",
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          windows: initializationSettingsWindows, // Add Windows settings
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveNotificationResponse: onDidReceiveNotificationResponse, // Optional: handle notification tap
    );
    debugPrint("[INFO] NotificationService: Initialized.");
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    int id = 0, // Unique ID for the notification
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'recursafe_reset_channel_id', // Channel ID
          'App Notifications', // Channel Name
          channelDescription: 'General notifications for RecurSafe app.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker', // Ticker text for older Android versions
        );

    // Define Windows notification details
    const WindowsNotificationDetails
    windowsNotificationDetails = WindowsNotificationDetails(
      // The AppUserModelId is crucial for Windows notifications to work correctly.
    );

    // Define iOS notification details to ensure foreground presentation
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true, // Ensure alert is shown in foreground
          presentBadge: true, // Ensure badge is updated in foreground
          presentSound: true, // Ensure sound is played in foreground
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      windows: windowsNotificationDetails,
      iOS: darwinNotificationDetails, // Add iOS specific details
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
    debugPrint(
      "[INFO] NotificationService: Notification shown - Title: $title",
    );
  }

  // Optional: Callback for when a notification is tapped.
  // static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async { ... }
}
