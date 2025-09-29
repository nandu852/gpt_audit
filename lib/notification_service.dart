import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permission for notifications
    await _requestPermission();

    // Note: Background tasks removed for compatibility

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission for notifications');
    } else {
      print('User declined or has not accepted permission for notifications');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rfi_reminders',
      'RFI Reminders',
      channelDescription: 'Notifications for pending RFI items',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'RFI Reminder',
      message.notification?.body ?? 'You have pending RFI items',
      notificationDetails,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific project
  }

  Future<void> scheduleRFIReminder(String projectId) async {
    try {
      // For now, just show an immediate notification
      // In a production app, you would use a proper scheduling mechanism
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rfi_reminders',
        'RFI Reminders',
        channelDescription: 'Notifications for pending RFI items',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        projectId.hashCode,
        'RFI Reminder',
        'You have pending RFI items that need attention',
        notificationDetails,
        payload: projectId,
      );
      
      print('RFI reminder sent for project: $projectId');
    } catch (e) {
      print('Error sending RFI reminder: $e');
    }
  }

  Future<void> cancelRFIReminder(String projectId) async {
    try {
      await _localNotifications.cancel(projectId.hashCode);
      print('RFI reminder cancelled for project: $projectId');
    } catch (e) {
      print('Error cancelling RFI reminder: $e');
    }
  }

  Future<void> sendRFIReminder(String projectId) async {
    try {
      // Get project details
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
      
      if (!projectDoc.exists) return;
      
      final projectData = projectDoc.data() as Map<String, dynamic>;
      final companyName = projectData['company_name'] ?? 'Unknown Company';
      final rfiItems = projectData['rfi_items'] as List<dynamic>? ?? [];
      final pendingItems = rfiItems.where((item) => item['completed'] != true).length;
      
      if (pendingItems == 0) {
        // All RFI items completed, cancel future reminders
        await cancelRFIReminder(projectId);
        return;
      }
      
      // Send notification to all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final fcmToken = userData['fcm_token'];
        
        if (fcmToken != null) {
          await _sendPushNotification(
            fcmToken,
            'RFI Reminder',
            'Project $companyName has $pendingItems pending RFI items. Please update.',
            projectId,
          );
        }
      }
      
      // Log the reminder
      await const AuditLogger().writeLog(
        projectId: projectId,
        action: 'rfi_reminder',
        summary: 'RFI reminder sent: $pendingItems pending items',
      );
      
      // Note: Auto-scheduling removed for compatibility
      
    } catch (e) {
      print('Error sending RFI reminder: $e');
    }
  }

  Future<void> _sendPushNotification(
    String fcmToken,
    String title,
    String body,
    String projectId,
  ) async {
    // This would typically be done through a backend service
    // For now, we'll use local notifications as a fallback
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rfi_reminders',
      'RFI Reminders',
      channelDescription: 'Notifications for pending RFI items',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      projectId.hashCode,
      title,
      body,
      notificationDetails,
      payload: projectId,
    );
  }

  Future<void> saveFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'fcm_token': token,
          'last_updated': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
        
        print('FCM token saved: $token');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
