import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
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
      print('🔴 Error getting access token: $e');
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
        print('🔴 No access token — cannot send push notification');
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
            'notification': {
              'title': title,
              'body': body,
            }, // ✅ FIXED: was 'notifications' (plural)
            'data': {
              'eventId': eventId,
              'type': 'rsvp',
            }, // ✅ FIXED: was hardcoded string 'eventId'
            'android': {
              'priority':
                  'high', // ✅ FIXED: was bare identifier `Priority:` — invalid key
              'notification': {
                'channel_id': 'rsvp_channel',
                'priority': 'high',
              },
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
        print('🟢 Notification sent successfully.');
      } else {
        print('🔴 FCM error: ${response.body}');
      }
    } catch (e) {
      print('🔴 Error sending push notification: $e');
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
      print('🔵 Current user: ${FirebaseAuth.instance.currentUser?.uid}');
      print('🔵 Fetching user doc for creatorId: $creatorId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      print('🔵 Fetched user doc: ${userDoc.exists}');
      print('🔵 User doc data: ${userDoc.data()}');

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        print('🔴 No FCM token for Creator: $creatorId');
        return;
      }
      await sendPushNotication(
        fcmToken: fcmToken,
        title: "New RSVP",
        body: '$rsvpUserName is attending $eventTitle',
        eventId: eventId,
      );
    } catch (e, stack) {
      print('🔴 Error sending RSVP Notification: $e');
      print('🔴 Stack trace: $stack');
    }
  }

  Future<void> init() async {
    // Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

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
        print('Notification tapped: ${response.payload}');
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
    print('🟡 saveTokenToFirestore called for user: ${user?.uid}');

    if (user == null) {
      print('🔴 No current user — token NOT saved');
      return;
    }

    final token = await _messaging.getToken();
    print('🟡 FCM token retrieved: $token');

    if (token != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('🟢 Token saved successfully for ${user.uid}');
      } catch (e) {
        print('🔴 FAILED to save token: $e');
      }
    } else {
      print(
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
