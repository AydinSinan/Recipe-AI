import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

// Background message handler — top-level fonksiyon olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'recipeai_channel',
    'RecipeAI Bildirimleri',
    description: 'RecipeAI uygulama bildirimleri',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    // Background handler kaydet
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // İzin iste
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Bildirim izni verildi');
    } else {
      print('Bildirim izni reddedildi');
      return;
    }

    // Android bildirim kanalı oluştur
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Local notifications init
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Foreground bildirimleri göster
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground mesaj dinle
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // FCM token al
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Token yenilenince güncelle
    _messaging.onTokenRefresh.listen((token) {
      print('FCM Token yenilendi: $token');
      // TODO: token'ı Firestore'a kaydet
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // FCM token'ı al (Firestore'a kaydetmek için)
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await _messaging.getToken();
  }

  // Konuya abone ol
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(topic);
  }

  // Konudan çık
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Varsayılan konulara abone ol
  static Future<void> subscribeToDefaultTopics() async {
    if (kIsWeb) return;
    await subscribeToTopic('daily_recipe');      // Günlük yemek önerisi
    await subscribeToTopic('new_features');      // Yeni özellik duyurusu
    await subscribeToTopic('weekly_meal_plan');  // Haftalık plan hatırlatması
  }

  // Premium teklifi bildirimi (premium olmayanlar için)
  static Future<void> subscribeToPremiumOffers() async {
    if (kIsWeb) return;
    await subscribeToTopic('premium_offers');
  }

  static Future<void> unsubscribeFromPremiumOffers() async {
    if (kIsWeb) return;
    await unsubscribeFromTopic('premium_offers');
  }
}
