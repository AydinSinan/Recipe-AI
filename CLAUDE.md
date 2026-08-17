# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

RecipeAI (`recipe_ai`) is a Flutter app (iOS/Android/Web) that generates AI recipes from a list of ingredients, with multi-cultural cuisine styles, dietary filters, calorie estimates, favorites, a weekly meal plan, and a grocery list. It's freemium: Firebase (Auth, Firestore, Functions, Cloud Messaging) is the backend, RevenueCat handles subscriptions, and Anthropic (Claude) generates the recipes. `functions/` is a separate Node.js Firebase Functions project that proxies AI calls.

## Commands

Flutter app (run from repo root):
```
flutter pub get                 # install deps
flutter run                     # run on connected device/simulator
flutter analyze                 # lint (flutter_lints via analysis_options.yaml)
flutter test                    # run tests (test/widget_test.dart)
flutter test test/widget_test.dart --plain-name "<test name>"   # run a single test
flutter build apk / flutter build ios / flutter build web        # release builds
dart pub global activate flutterfire_cli && flutterfire configure --project=recipeai-7429a  # regenerate lib/firebase_options.dart
```

Firebase Functions (run from `functions/`):
```
npm install
npm run serve      # local emulator (functions only)
npm run shell       # interactive functions shell
npm run deploy      # firebase deploy --only functions
npm run logs        # firebase functions:log
firebase functions:secrets:set ANTHROPIC_KEY   # set the Anthropic key used by defineSecret("ANTHROPIC_KEY") in index.js
```

## Architecture

**State management is a single `ChangeNotifier`.** `lib/providers/app_provider.dart` (`AppProvider`) holds essentially all app state — auth/user, recipe search results, favorites, grocery list, meal plan, selected cuisines/dietary filters, language, daily search count, and paywall/upgrade-prompt flags. Screens read it via `context.watch<AppProvider>()`; there's no other provider/bloc. `main.dart` wraps the app in a single `ChangeNotifierProvider(create: (_) => AppProvider()..initialize())`.

**Navigation shell.** `main.dart`: `AppSplash` → `AuthGate` (routes to `LoginScreen` or `MainShell` based on `AppProvider.isLoggedIn`) → `MainShell`, which is an `IndexedStack` over 4 tabs (Home/search, Favorites, Meal Plan, Profile) keyed by `AppProvider.selectedTab`. The meal-plan tab is locked client-side for non-premium users (`_navItem(lockForFree: ...)`).

**Recipe generation flow.** `AppProvider.searchRecipes()` first enforces the free-tier daily search limit (`SubscriptionConfig` in `lib/config/config.dart`), then calls `ClaudeService.generateRecipes()` (`lib/services/claude_service.dart`), which builds a prompt that strictly demands a JSON response in a fixed schema and a fixed output language (`tr`/`en`). Requests go through `ClaudeService._callApi`, which routes to either:
- `_callDirect` — dev only, calls Anthropic directly from the client (needs a local API key that should never be committed), or
- `_callProxy` — production, calls the Firebase Functions endpoint with the user's Firebase Auth ID token.

`ApiConfig.devMode` in `config.dart` switches between the two and **must be `false`** for any non-local build.

**Backend (`functions/index.js`).** Firebase Functions v2 (Express apps), region `europe-west1`. `generateRecipes` and `getCalories` both verify the Firebase ID token, then proxy the given prompt to Anthropic (`claude-haiku-4-5-20251001`) using the `ANTHROPIC_KEY` secret (`defineSecret`) — the Anthropic key never reaches the client in production. Three scheduled functions (`onSchedule`) send push notifications via FCM topics: a daily recipe nudge (09:00 Europe/Istanbul), a weekly meal-plan reminder (Sunday 18:00), and a re-engagement ping to premium users inactive 3+ days.

**Data model & parsing.** Models live in `lib/models/models.dart`. `ClaudeService` parses the AI's JSON response into `Recipe`/`Ingredient` objects — the prompt's JSON schema and `Recipe.fromJson` must be changed together if the response shape changes.

**Freemium gating.** All limits (daily searches, favorites cap, cuisine selection cap, recipes per search for free vs. premium) live in `SubscriptionConfig` (`lib/config/config.dart`). Premium status comes from RevenueCat via `SubscriptionService` (`lib/services/subscription_service.dart`) and is cached on `AppProvider.isPremium`.

**Services (`lib/services/`).** `auth_service.dart` — Firebase Auth (Google/Apple/Email/Anonymous) plus the Firestore `users/{uid}` doc; `subscription_service.dart` — RevenueCat; `storage_service.dart` — `SharedPreferences`-backed local persistence for favorites, meal plan, grocery list, dietary filters; `notification_service.dart` — FCM topic subscribe/unsubscribe (per-language and premium topics).

**Firestore.** Only two collection paths are allowed (`firestore.rules`): `users/{userId}` and `users/{userId}/searches/{searchId}`, both readable/writable only by the owning `request.auth.uid`. Everything else is denied.

**Localization.** No `gen-l10n`/ARB files — translations are a manual lookup table in `lib/l10n/strings.dart` (`AppStrings.get(key, lang)`). Language is `'tr'` or `'en'`, persisted to the Firestore user doc and `SharedPreferences`. Changing language while recipes are loaded triggers `AppProvider.setLanguage` to silently re-run the last search in the new language without consuming a search-count credit.

## Notes

- The Anthropic API key belongs only in the Functions secret `ANTHROPIC_KEY` (`firebase functions:secrets:set ANTHROPIC_KEY`) — never in `config.dart` or the `devApiKey` placeholder in `claude_service.dart`.
- `README.md` describes setting the key via `firebase functions:config:set anthropic.key=...`; that's stale — the code (`functions/index.js`) uses `defineSecret("ANTHROPIC_KEY")`, i.e. Secret Manager via `firebase functions:secrets:set`.
