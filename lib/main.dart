import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app/app.dart';

// ✅ Background message handler must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Register background handler before anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Init local notifications + FCM permissions
  await NotificationService().init();

  // ✅ Save FCM token immediately if user is already logged in at startup
  await NotificationService().saveTokenToFirestore();

  // ✅ NEW — Listen for auth state changes (login/logout) and save token
  // This ensures the token is saved every time someone logs in,
  // not just once at app startup
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      //debugPrint('🟢 Auth state changed — user logged in: ${user.uid}');
      await NotificationService().saveTokenToFirestore();
    } else {}
  });

  // ✅ Handle notification tap when app was terminated
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // You can navigate to the event page here using initialMessage.data['eventId']
  }

  // ✅ Handle notification tap when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  // In main.dart
  FlutterError.onError = (details) {
    // Log to a service like Sentry or Firebase Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  runApp(const ProviderScope(child: MyApp()));
}
