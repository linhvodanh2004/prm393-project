import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_notifications.dart';

class _IoLocalNotifications implements LocalNotifications {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: initAndroid);

    // Keep this positional to match the plugin API on mobile.
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  @override
  Future<void> show({required int id, required String title, String? body}) async {
    if (!_initialized) {
      await init();
    }

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id_main',
          'Main Channel',
          channelDescription: 'Main notification channel',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

LocalNotifications createLocalNotificationsImpl() => _IoLocalNotifications();

