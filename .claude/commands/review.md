# /review — Kod İnceleme

Son yapılan değişiklikleri RecipeAI standartlarına göre incele ve sorunları raporla.

## İnceleme Kriterleri

### Mimari
- [ ] Business logic widget'ta mı? → `AppProvider`'a taşı
- [ ] `setState` global state için kullanılmış mı? → `notifyListeners` olmalı
- [ ] Raw `Map` katmanlar arası geçiyor mu? → Strongly-typed model olmalı

### Localization
- [ ] Hardcoded string var mı? → `AppStrings.get('key', lang)` olmalı
- [ ] Yeni string eklendiyse TR + EN her ikisi de var mı?

### Platform
- [ ] Mobile-only kod `kIsWeb` guard'ı olmadan kullanılmış mı?
- [ ] FCM / RevenueCat web'de çalıştırılmaya mı çalışılıyor?

### Premium
- [ ] Kısıtlı feature `isPremium` kontrolü yapıyor mu?

### Async
- [ ] Loading state eksik mi? UI'da spinner/shimmer var mı?
- [ ] `context.mounted` (veya `mounted`) kontrolü async gap'lerde yapılmış mı?

## Kapsam
$ARGUMENTS
