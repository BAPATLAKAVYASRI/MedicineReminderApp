// Fallback (non-web) implementation
Future<bool> showWebNotification(String title, String body) async {
  return false;
}

Future<void> ensureWebNotificationPermission() async {
  // No-op on non-web
}
