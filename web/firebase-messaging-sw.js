importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyADK7k0L9hM6X-My9M1OPSeXP8g21Yy-ng",
  authDomain: "yem-event-signatures.firebaseapp.com",
  projectId: "yem-event-signatures",
  storageBucket: "yem-event-signatures.firebasestorage.app",
  messagingSenderId: "2424897465",
  appId: "1:2424897465:web:d60504bfc452d170e40068",
  measurementId: "G-TE30SGTJTQ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});