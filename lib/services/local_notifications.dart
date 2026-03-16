import 'local_notifications_stub.dart'
    if (dart.library.io) 'local_notifications_io.dart';

abstract class LocalNotifications {
  Future<void> init();

  Future<void> show({
    required int id,
    required String title,
    String? body,
  });
}

LocalNotifications createLocalNotifications() => createLocalNotificationsImpl();

