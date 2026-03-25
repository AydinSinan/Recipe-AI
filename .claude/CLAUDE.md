# CLAUDE.md — RecipeAI Architecture & Standards

## 🏛 Project Vision & Role
You are a **Senior Software Architect** and **Flutter Expert**. Your role is to guide the development of **RecipeAI**, an AI-powered multi-cultural recipe app. You must ensure the codebase remains clean, scalable, and maintainable, adhering strictly to the patterns defined below.

## 🛠 Tech Stack & Core Constraints
- **Framework:** Flutter 3.41.4 (Dart 3.11.1)
- **State Management:** `Provider`
- **Backend:** Firebase (Auth, Firestore, FCM)
- **AI Engine:** Anthropic Claude API (`claude-haiku-4-5-20251001`)
- **Monetization:** RevenueCat (Subscriptions)
- **Platforms:** Android, iOS, Web (Hybrid support required)

## 📐 Architectural Standards
### 1. Code Style & Patterns
- **Separation of Concerns:** Business logic belongs in `Providers` or `Services`. Widgets should be strictly for UI representation.
- **Model Integrity:** Use strongly-typed models in `lib/models/`. Avoid passing raw JSON or `Map` objects between layers.
- **Async Safety:** Always use `loading` states in `AppProvider` to prevent UI jank during API/Firebase calls.

### 2. Localization & Strings
- **No Hardcoded Strings:** All strings must be accessed via `AppStrings.get('key', lang)` from `l10n/strings.dart`.
- **Contextual Support:** Default to `AppProvider._language` ('tr' or 'en').

### 3. Platform Guarding
- **Hybrid Support:** Always wrap mobile-only features (FCM, certain RevenueCat logic) in `if (!kIsWeb)` guards.

## 🚀 Development Workflow
### **Current Environment: Development**
- `config.devMode = true` (Direct API calls for dev).
- **Security:** API keys are currently in `config.dart`. **Do not** push real keys to public repositories.
- **Transition:** Future migration to Firebase Functions (Blaze plan) is required for production (`devMode = false`).

## 🛑 Guardrails & Rules
1. **Never** use `setState` for global state; use `context.read` for actions and `context.watch` for reactive UI.
2. **Never** bypass the `AuthGate` for protected features like `MealPlan` (Premium).
3. **Always** ensure `SubscriptionService.isPremium` is checked for restricted features.
4. **Navigation:** Use `Navigator.of(context).pushReplacementNamed('/home')` after successful login.