// Browser Notification API — the web analogue of NotificationService in the
// mobile app (lib/services/notification_service.dart). Unlike the mobile
// version, these only fire while this tab is open: there's no OS-level
// scheduler here, so "reminders" are plain setTimeout calls that don't
// survive a page reload or the tab being closed. Real persistent web push
// would need a service worker + the Push API, which is out of scope here.

export async function requestNotificationPermission(): Promise<boolean> {
  if (!('Notification' in window)) return false;
  if (Notification.permission === 'granted') return true;
  if (Notification.permission === 'denied') return false;
  const result = await Notification.requestPermission();
  return result === 'granted';
}

export function notificationsGranted(): boolean {
  return 'Notification' in window && Notification.permission === 'granted';
}

export function showNotification(title: string, body: string): void {
  if (!notificationsGranted()) return;
  try {
    new Notification(title, { body, icon: '/escape-icon.svg' });
  } catch {
    // Some browsers (notably iOS Safari) don't support the constructor form
    // outside a service worker — fail silently rather than crash the app.
  }
}
