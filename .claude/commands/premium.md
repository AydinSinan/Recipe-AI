# /premium — Premium Feature Ekle

Mevcut bir özelliği premium'a taşı veya yeni bir premium özellik ekle.

## Adımlar

1. `lib/config/config.dart`'taki limit değerlerini kontrol et
2. `AppProvider`'da `isPremium` kontrolü ekle — limit aşılırsa anlamlı hata mesajı set et
3. UI'da kilitleme göster (paywall tetiklemesi için `_errorMessage` yeterli — `main.dart`'taki `AuthGate` zaten dinliyor)
4. Localization: hata mesajını TR + EN ekle

## Paywall Tetikleme Akışı

```
AppProvider._errorMessage set edilir
→ main.dart'taki listener yakalar
→ PaywallScreen modal olarak açılır
```

`PaywallScreen`'i doğrudan açma — her zaman `_errorMessage` üzerinden tetikle.

## Özellik: $ARGUMENTS
