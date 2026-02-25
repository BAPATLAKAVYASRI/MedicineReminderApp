// Web implementation using browser Notification API
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> ensureWebNotificationPermission() async {
  if (html.Notification.supported) {
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  }
}

Future<bool> showWebNotification(String title, String body) async {
  if (!html.Notification.supported) return false;
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
  if (html.Notification.permission != 'granted') return false;
  html.Notification(title, body: body);
  return true;
}
