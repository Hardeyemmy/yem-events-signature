import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app/app.dart';

// ✅ Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Register background handler before anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Init local notifications + FCM permissions
  await NotificationService().init();

  // ✅ Save FCM token to Firestore so creators can receive notifications
  await NotificationService().saveTokenToFirestore();

  // ✅ Handle notification tap when app was terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print(
      'App opened from terminated state via notification: ${initialMessage.data}',
    );
    // You can navigate to the event page here using initialMessage.data['eventId']
  }

  // ✅ Handle notification tap when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from background via notification: ${message.data}');
    // You can navigate to the event page here using message.data['eventId']
  });

  runApp(const ProviderScope(child: MyApp()));
}
