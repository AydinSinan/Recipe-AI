import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/config.dart';

class SubscriptionService {
  static bool _initialized = false;

  // Entitlement identifier — RevenueCat'teki ile aynı olmalı
  static const String _entitlementKey = 'RecipeAI Pro';

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration config;
    if (Platform.isIOS || Platform.isMacOS) {
      config = PurchasesConfiguration(SubscriptionConfig.revenueCatAppleKey);
    } else {
      config = PurchasesConfiguration(SubscriptionConfig.revenueCatGoogleKey);
    }

    await Purchases.configure(config);
    _initialized = true;

    // Firebase user ile ilişkilendir
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Purchases.logIn(user.uid);
    }
  }

  // ── Login user to RevenueCat ──────────────────────────────────────────────
  static Future<void> loginUser(String uid) async {
    await Purchases.logIn(uid);
  }

  static Future<void> logoutUser() async {
    await Purchases.logOut();
  }

  // ── Check Premium Status ──────────────────────────────────────────────────
  static Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementKey);
    } catch (e) {
      return false;
    }
  }

  // ── Get Offerings ─────────────────────────────────────────────────────────
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      return null;
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────
  static Future<bool> purchase(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      final isPrem = info.entitlements.active.containsKey(_entitlementKey);
      if (isPrem) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isPremium': true});
        }
      }
      return isPrem;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  // ── Manage Subscription (mağaza sayfasını açar) ───────────────────────────
  static Future<void> manageSubscription() async {
    if (kIsWeb) return;

    Uri uri;
    if (Platform.isIOS || Platform.isMacOS) {
      uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      // Android: aktif ürün ID ile Play Store abonelik sayfası
      const packageName = 'com.snnydn.recipeai';
      const productId = SubscriptionConfig.monthlyProductId;
      uri = Uri.parse(
        'https://play.google.com/store/account/subscriptions'
        '?sku=$productId&package=$packageName',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────
  static Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final isPrem = info.entitlements.active.containsKey(_entitlementKey);

      if (isPrem) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isPremium': true});
        }
      }
      return isPrem;
    } catch (e) {
      return false;
    }
  }
}
