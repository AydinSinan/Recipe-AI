# 🍳 RecipeAI v2 — Kurulum Rehberi

## 📁 Proje Yapısı
```
lib/
├── main.dart                    # Giriş + AuthGate + MainShell
├── theme.dart                   # Renkler ve tema
├── config/
│   └── config.dart              # API URLs, subscription config
├── models/models.dart           # Veri modelleri
├── services/
│   ├── auth_service.dart        # Firebase Auth (Google/Apple/Email/Anonim)
│   ├── claude_service.dart      # AI API (dev: direkt, prod: Functions proxy)
│   ├── subscription_service.dart# RevenueCat entegrasyonu
│   └── storage_service.dart     # SharedPreferences
├── providers/app_provider.dart  # Tüm state yönetimi
├── screens/
│   ├── login_screen.dart        # Giriş ekranı
│   ├── paywall_screen.dart      # Premium satın alma
│   ├── home_screen.dart         # Ana ekran (arama)
│   ├── recipe_detail_screen.dart# Tarif detayı
│   ├── favorites_screen.dart    # Favoriler
│   ├── meal_plan_screen.dart    # Haftalık plan (Premium)
│   └── profile_screen.dart      # Profil + ayarlar
└── widgets/widgets.dart         # Ortak bileşenler

functions/
├── index.js                     # Firebase Functions (API proxy)
└── package.json
```

---

## 🚀 Kurulum Adımları

### 1. Firebase Projesi Oluştur
1. https://console.firebase.google.com → Yeni Proje → `recipeai`
2. **Authentication** → Sign-in methods aktif et:
   - ✅ Google
   - ✅ Apple
   - ✅ Email/Password
   - ✅ Anonymous
3. **Firestore** → Create Database → Production mode → `europe-west1`
4. **Functions** → Blaze planına geç (ücretsiz tier geniş)

### 2. Flutter'a Firebase Ekle
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=recipeai
```
Bu komut `firebase_options.dart` dosyasını otomatik oluşturur.

### 3. main.dart'ı Güncelle
`Firebase.initializeApp()` satırına `options` ekle:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 4. API Key'i Functions'a Ekle
```bash
cd functions
npm install
firebase functions:config:set anthropic.key="sk-ant-XXXXXXXX"
firebase deploy --only functions
```

### 5. config.dart'ı Güncelle
```dart
// DEV modunu kapat, Functions URL'ini gir:
static const bool devMode = false;
static const String functionsBaseUrl =
    'https://europe-west1-recipeai.cloudfunctions.net';
```

### 6. RevenueCat Kurulumu
1. https://app.revenuecat.com → Yeni Proje
2. iOS App + Android App ekle
3. App Store Connect / Play Console'da ürünleri oluştur:
   - `recipeai_premium_monthly` — Aylık ₺99
   - `recipeai_premium_yearly` — Yıllık ₺599
4. config.dart'taki API key'leri gir
5. RevenueCat Dashboard → Webhooks → Firebase Functions URL ekle:
   `https://europe-west1-recipeai.cloudfunctions.net/revenueCatWebhook`

---

## 💰 Freemium Model
| Özellik | Ücretsiz | Premium |
|---------|----------|---------|
| Günlük arama | 5 | Sınırsız |
| Tarif/arama | 4 | 8 |
| Kültür seçimi | 2 | Tümü |
| Favoriler | 5 | Sınırsız |
| Haftalık plan | ❌ | ✅ |
| Fiyat | Ücretsiz | ₺99/ay veya ₺599/yıl |

---

## 🔒 Güvenlik
- API key sadece Firebase Functions'ta, kullanıcı **asla** göremez
- Her istek Firebase Auth token ile doğrulanır
- Rate limiting hem Flutter'da hem Functions'ta uygulanır
- RevenueCat webhook ile premium durum otomatik güncellenir
