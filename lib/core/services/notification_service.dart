import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Load Credentials from .env
  Map<String, dynamic> get _serviceAccountCredentials => {
    "type": "service_account",
    "project_id": dotenv.env["FCM_PROJECT_ID"],
    "private_key": dotenv.env["FCM_PRIVATE_KEY"]?.replaceAll('\\n', '\n'),
    "client_email": dotenv.env['FCM_CLIENT_EMAIL'],
    "client_id": dotenv.env['FCM_CLIENT_ID'],
  };

  // Get OAuth2 access token using service account
  Future<String?> _getAccessToken() async {
    try {
      final accountCredentials = ServiceAccountCredentials.fromJson(
        _serviceAccountCredentials,
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendPushNotication({
    required String fcmToken,
    required String title,
    required String body,
    required String eventId,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return;
      }
      final projectId = dotenv.env['FCM_PROJECT_ID'];
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body}, //
            'data': {'eventId': eventId, 'type': 'rsvp'},
            'android': {
              'priority': 'high',
              'notification': {'channel_id': 'rsvp_channel'},
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1},
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('🟢 Notification sent successfully.');
      } else {
        throw Exception('🔴 FCM error: ${response.body}');
      }
    } catch (e) {
      throw Exception('🔴 Error sending push notifications: $e');
    }
  }

  // Send RSVP notification — call this after a successful RSVP
  Future<void> sendRsvpNotification({
    required String creatorId,
    required String eventTitle,
    required String rsvpUserName,
    required String eventId,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        return;
      }
      await sendPushNotication(
        fcmToken: fcmToken,
        title: "New RSVP",
        body: '$rsvpUserName is attending $eventTitle',
        eventId: eventId,
      );
    } catch (e) {
      throw Exception('🔴 Error sending RSVP Notification: $e');
    }
  }

  Future<void> init() async {
    // Request permission

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Init local notifications for foreground
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'rsvp_channel',
              'RSVP Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // ✅ FIXED: saveTokenToFirestore() now has debug logging built in
    await saveTokenToFirestore();

    // Update token on refresh
    _messaging.onTokenRefresh.listen(_updateToken);
  }

  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final token = await _messaging.getToken();

    if (token != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'displayName':
              user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        throw Exception('🔴 FAILED to save token: $e');
      }
    } else {
      debugPrint(
        '🔴 Token was null — nothing saved. If on web, check VAPID key setup.',
      );
    }
  }

  Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }
}
