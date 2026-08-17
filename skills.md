---
name: recipeai-dev
description: Use when making changes to the Recipe-AI Flutter app or its Firebase Functions backend — adding/changing a recipe field, editing the AI prompt schema, adding translations, adjusting freemium limits, or deploying functions. Encodes the places that must stay in sync so nothing breaks silently.
---

# Recipe-AI development skill

Recipe-AI is a Flutter app + Firebase Functions backend that generates recipes via Anthropic's Claude API. See `CLAUDE.md` at the repo root for the full architecture. This skill covers the recurring, easy-to-get-wrong workflows.

## Task: add or change a recipe field

The recipe JSON shape is duplicated in three places. Changing one without the others causes silent parse failures or blank UI fields.

1. `lib/services/claude_service.dart` — the prompt's JSON schema (in `generateRecipes()`) that tells Claude what to return.
2. `lib/models/models.dart` — `Recipe`/`Ingredient` classes and their `fromJson`.
3. Any screen that displays the field (`lib/screens/recipe_detail_screen.dart`, `home_screen.dart`, etc.).

Steps:
- Update the prompt's JSON example and any `Rules:` bullet that constrains the field (e.g. "difficulty must be exactly...").
- Update `fromJson`/the model class to read the new/changed field, with a safe default for older cached data (favorites/meal plan are persisted locally via `storage_service.dart` and may contain the old shape).
- Update the UI.
- Manually re-run a search after the change (`flutter run`) — parse errors from `ClaudeService._parseRecipes` fail silently into `_errorMessage`, not a crash, so check the error banner.

## Task: add or update a translation string

Localization is a manual table, not `gen-l10n`.

1. Add the key to `lib/l10n/strings.dart` with both `tr` and `en` values.
2. Reference it via `AppStrings.get('your_key', lang)`; `lang` comes from `AppProvider.language` (`context.watch<AppProvider>().language` in a widget).
3. Don't hardcode new user-facing strings — every existing string goes through this table.

## Task: adjust freemium limits or pricing

All limits live in one place: `SubscriptionConfig` in `lib/config/config.dart` (`freeSearchesPerDay`, `freeFavoritesLimit`, `freeCuisinesLimit`, `freeRecipesPerSearch`, `premiumRecipesPerSearch`, prices, product IDs). Change values there — don't hardcode limits elsewhere. If you change `monthlyProductId`/`yearlyProductId`, the product must also exist under that exact ID in App Store Connect / Play Console and RevenueCat.

## Task: deploy the Firebase Functions backend

```
cd functions
npm install
firebase functions:secrets:set ANTHROPIC_KEY   # only needed if the key changed
npm run deploy                                  # firebase deploy --only functions
npm run logs                                    # tail logs to verify
```

Both HTTP endpoints (`generateRecipes`, `getCalories`) verify a Firebase Auth ID token before calling Anthropic — don't remove `verifyAuth()`. The three scheduled notification functions (`dailyRecipeNotification`, `weeklyMealPlanReminder`, `reEngagementNotification`) deploy along with everything else; check `npm run logs` after deploying to confirm no cold-start errors.

Before deploying, confirm `lib/config/config.dart`'s `ApiConfig.devMode` is `false` and `functionsBaseUrl` matches the deployed project (`europe-west1-recipeai-7429a.cloudfunctions.net`) — a client built with `devMode: true` will try to call Anthropic directly from the device and fail (no API key ships client-side).

## Task: add a new screen or nav tab

Screens are plain widgets under `lib/screens/`, wired into `AppProvider` for state (no per-screen provider). To add one:

1. Create the screen widget; read/write state through `context.watch<AppProvider>()` / `context.read<AppProvider>()` — don't introduce a second state container.
2. If it's a main tab, add it to `MainShell._screens` and add a `_navItem` in `main.dart`; use `lockForFree: !provider.isPremium` if it should be a premium-only tab (see the existing Meal Plan tab for the pattern).
3. If it needs persistence, add methods to `storage_service.dart` (SharedPreferences) rather than reading `SharedPreferences` directly from the widget.
