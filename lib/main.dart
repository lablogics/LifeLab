import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_ui/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app/router.dart';
import 'app/theme_provider.dart';
import 'package:app_links/app_links.dart';

final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

@pragma('vm:entry-point')
void _notificationTapHandler(NotificationResponse response) {
  // Handle notification tap — navigate to relevant screen
  final payload = response.payload;
  if (payload != null) {
    // Payload contains route path e.g. "/notes/abc123"
    debugPrint('Notification tapped: $payload');
  }
}

final _appLinks = AppLinks();

Future<void> _initDeepLinks() async {
  // Handle initial deep link
  try {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('Initial deep link: $initialUri');
    }
  } catch (_) {}

  // Handle subsequent deep links
  _appLinks.uriLinkStream.listen((uri) {
    debugPrint('Deep link received: $uri');
    // Navigation handled by GoRouter
  });
}
Future<void> _initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _notificationTapHandler,
  );
  const channel = AndroidNotificationChannel(
    'liflab_default', 'LifeLab Notifications',
    importance: Importance.high,
  );
  await localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Deep link handling
    _initDeepLinks();
    await _initLocalNotifications();
  } catch (_) {
    // Firebase not configured — app works without push
    debugPrint('Firebase not configured, push notifications disabled');
  }
  // Load theme before launching app
  final container = ProviderContainer();
  await container.read(themeProvider.notifier).load();
  runApp(ProviderScope(parent: container, child: const LifeLabApp()));
}

class LifeLabApp extends ConsumerWidget {
  const LifeLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeModeStr = ref.watch(themeProvider);
    final themeMode = themeModeStr == 'light' ? ThemeMode.light
        : themeModeStr == 'dark' ? ThemeMode.dark
        : ThemeMode.system;
    return MaterialApp.router(
      title: 'LifeLab',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
