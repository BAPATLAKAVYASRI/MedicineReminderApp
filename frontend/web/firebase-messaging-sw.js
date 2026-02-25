/* Firebase Messaging SW for Web Push (Flutter) */
/* Paste your Firebase config values below; same as in main.dart */
self.__FIREBASE_CONFIG__ = {
  apiKey: 'AIzaSyCL0RbvaCB1Gv1Y-2TjDoe3L6Qt4TdMcJ0',
  authDomain: 'mediremind-8036e.firebaseapp.com',
  projectId: 'mediremind-8036e',
  storageBucket: 'mediremind-8036e.firebasestorage.app',
  messagingSenderId: '210662564156',
  appId: '1:210662564156:web:8c1864f8903e2477ff7e39',
  measurementId: 'G-928NSXEP2M'
};

// Import Firebase scripts (compat to support SW)
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-messaging-compat.js');

(function init() {
  const cfg = self.__FIREBASE_CONFIG__ || {};
  if (!cfg.apiKey || !cfg.projectId || !cfg.messagingSenderId || !cfg.appId) {
    // Config not set; background messages will be disabled
    console.warn('[firebase-messaging-sw] Firebase config missing. Background messages disabled.');
    return;
  }
  firebase.initializeApp(cfg);
  const messaging = firebase.messaging();

  // Optional: handle background messages
  messaging.onBackgroundMessage(function(payload) {
    console.log('[firebase-messaging-sw] Background message received:', payload);
    const notificationTitle = (payload.notification && payload.notification.title) || 'MediRemind';
    const notificationOptions = {
      body: (payload.notification && payload.notification.body) || 'You have a reminder.',
      icon: '/icons/Icon-192.png'
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
  });
})();
