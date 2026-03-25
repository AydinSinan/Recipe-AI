# /feature — Yeni Özellik Ekle

Kullanıcının istediği yeni özelliği RecipeAI mimarisine uygun şekilde implemente et.

## Zorunlu Adımlar

1. **Keşfet** — İlgili dosyaları oku. Mevcut pattern'leri anla, tekrar kullanılabilir kod ara.
2. **Planla** — Hangi dosyalar değişecek? Yeni dosya gerekiyor mu?
3. **Sırayla uygula:**
   - Model varsa `lib/models/models.dart`'a ekle
   - Storage varsa `lib/services/storage_service.dart`'a ekle
   - Localization string'lerini `lib/l10n/strings.dart`'a ekle (TR + EN)
   - State/logic `lib/providers/app_provider.dart`'a ekle
   - UI son sıraya al

## Mimari Kurallar (Bunları Çiğneme)

- Business logic → `AppProvider` veya `Services`. Widget'lara logic yazma.
- Global state → `context.read` (action) / `context.watch` (UI). `setState` yok.
- String → `AppStrings.get('key', lang)`. Hardcoded string yok.
- Mobile-only kod → `if (!kIsWeb)` guard'ı.
- Premium feature → `SubscriptionService.isPremium` kontrolü.
- Model → strongly-typed. Raw `Map` geçirme.

## Özellik: $ARGUMENTS
