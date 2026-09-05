// ── Subscription Plans ────────────────────────────────────────────────────────
class SubscriptionConfig {
  // RevenueCat Product IDs — bunları App Store Connect / Play Console'da oluştur
  static const String monthlyProductId = 'recipeai_premium_monthly';

  // RevenueCat API Keys — console.revenuecat.com'dan al
  // TODO: iOS yayına alınınca gerçek Apple production key ile değiştir.
  static const String revenueCatAppleKey = 'test_HOwPnWRDfCVqFjMfievjhGZewzF';
  static const String revenueCatGoogleKey = 'goog_NUdMluZwxkvsKHBauKCznsutTQr';

  // Fiyatlar (RevenueCat'ten dinamik gelir ama fallback için)
  static const String monthlyPrice = '₺99';

  // Free tier limits
  static const int freeSearchesPerDay = 2;
  static const int freeFavoritesLimit = 5;
  static const int freeCuisinesLimit = 2;
  static const int freeRecipesPerSearch = 4;

  // Premium tier
  static const int premiumRecipesPerSearch = 8;
}

// ── Firebase Collections ──────────────────────────────────────────────────────
class FirebaseCollections {
  static const String users = 'users';
  static const String searches = 'searches';
}

// ── Backend API ───────────────────────────────────────────────────────────────
class ApiConfig {
  // Firebase Functions URL (europe-west1, proje: recipeai-7429a)
  static const String functionsBaseUrl =
      'https://europe-west1-recipeai-7429a.cloudfunctions.net';

  // Geliştirme sırasında direkt API (chrome'da CORS için)
  static const String claudeDirectUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-haiku-4-5-20251001';

  // DEV: true → direkt Anthropic, false → Firebase Functions proxy
  // Production'da her zaman false olmalı
  static const bool devMode = false;
}
