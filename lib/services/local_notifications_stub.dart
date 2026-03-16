import 'local_notifications.dart';

// Web / unsupported platforms: no-op implementation
class _NoopLocalNotifications implements LocalNotifications {
  @override
  Future<void> init() async {}

  @override
  Future<void> show({required int id, required String title, String? body}) async {}
}

LocalNotifications createLocalNotificationsImpl() => _NoopLocalNotifications();

