// ── Subscription Plans ────────────────────────────────────────────────────────
class SubscriptionConfig {
  // RevenueCat Product IDs — bunları App Store Connect / Play Console'da oluştur
  static const String monthlyProductId = 'recipeai_premium_monthly';
  static const String yearlyProductId  = 'recipeai_premium_yearly';

  // RevenueCat API Keys — console.revenuecat.com'dan al
  static const String revenueCatAppleKey  = 'test_HOwPnWRDfCVqFjMfievjhGZewzF';
  static const String revenueCatGoogleKey = 'test_HOwPnWRDfCVqFjMfievjhGZewzF';

  // Fiyatlar (RevenueCat'ten dinamik gelir ama fallback için)
  static const String monthlyPrice = '₺99';
  static const String yearlyPrice  = '₺599';
  static const String yearlySaving = '%50';

  // Free tier limits
  static const int freeSearchesPerDay = 5;
  static const int freeFavoritesLimit = 5;
  static const int freeCuisinesLimit  = 2;
  static const int freeRecipesPerSearch = 4;

  // Premium tier
  static const int premiumRecipesPerSearch = 8;
}

// ── Firebase Collections ──────────────────────────────────────────────────────
class FirebaseCollections {
  static const String users    = 'users';
  static const String searches = 'searches';
}

// ── Backend API ───────────────────────────────────────────────────────────────
class ApiConfig {
  // Firebase Functions URL — deploy sonrası buraya gelecek
  // Örnek: https://us-central1-recipeai.cloudfunctions.net/generateRecipes
  static const String functionsBaseUrl =
      'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net';

  // Geliştirme sırasında direkt API (chrome'da CORS için)
  static const String claudeDirectUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel     = 'claude-haiku-4-5-20251001';

  // DEV: true → direkt Anthropic, false → Firebase Functions proxy
  static const bool devMode = true;
}
