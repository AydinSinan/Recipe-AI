import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _mealPlanKey = 'meal_plan';
  static const String _langKey = 'language';
  static const String _apiKeyKey = 'api_key';
  static const String _recentSearchesKey = 'recent_searches';

  // ── Favorites ────────────────────────────────────────────────────────────
  Future<List<Recipe>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesKey) ?? [];
    return raw
        .map((s) => Recipe.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
  }

  Future<void> saveFavorite(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_favoritesKey) ?? [];
    // Avoid duplicates
    current.removeWhere((s) {
      final r = jsonDecode(s);
      return r['id'] == recipe.id;
    });
    final updated = Recipe(
      id: recipe.id,
      name: recipe.name,
      culture: recipe.culture,
      cultureFlag: recipe.cultureFlag,
      description: recipe.description,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      cookTimeMinutes: recipe.cookTimeMinutes,
      servings: recipe.servings,
      difficulty: recipe.difficulty,
      totalCalories: recipe.totalCalories,
      nutrition: recipe.nutrition,
      tags: recipe.tags,
      isFavorite: true,
      createdAt: DateTime.now(),
    );
    current.add(jsonEncode(updated.toJson()));
    await prefs.setStringList(_favoritesKey, current);
  }

  Future<void> removeFavorite(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_favoritesKey) ?? [];
    current.removeWhere((s) {
      final r = jsonDecode(s);
      return r['id'] == recipeId;
    });
    await prefs.setStringList(_favoritesKey, current);
  }

  Future<bool> isFavorite(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_favoritesKey) ?? [];
    return current.any((s) {
      final r = jsonDecode(s);
      return r['id'] == recipeId;
    });
  }

  // ── Meal Plan ─────────────────────────────────────────────────────────────
  Future<MealPlan?> getMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealPlanKey);
    if (raw == null) return null;
    return MealPlan.fromJson(jsonDecode(raw));
  }

  Future<void> saveMealPlan(MealPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealPlanKey, jsonEncode(plan.toJson()));
  }

  // ── Language ──────────────────────────────────────────────────────────────
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'tr';
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  // ── API Key ───────────────────────────────────────────────────────────────
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  // ── Recent Searches ────────────────────────────────────────────────────
  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(List<String> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_recentSearchesKey) ?? [];
    final entry = ingredients.join(', ');
    current.remove(entry);
    current.insert(0, entry);
    await prefs.setStringList(
      _recentSearchesKey,
      current.take(10).toList(),
    );
  }
}
