import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/claude_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../config/config.dart';

enum RecipeState { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  final ClaudeService _claude = ClaudeService();

  // ── Auth State ────────────────────────────────────────────────────────────
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isPremium = false;
  bool _isAuthLoading = true;

  // ── Recipe State ──────────────────────────────────────────────────────────
  RecipeState _recipeState = RecipeState.idle;
  List<Recipe> _recipes = [];
  List<Recipe> _favorites = [];
  List<String> _selectedCuisines = [];
  Map<String, int> _calorieMap = {};
  MealPlan? _mealPlan;
  String? _errorMessage;
  List<String> _lastIngredients = []; // dil değişince yeniden aramak için

  // ── UI State ──────────────────────────────────────────────────────────────
  String _language = 'tr';
  int _selectedTab = 0;
  int _dailySearchCount = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isPremium => _isPremium;
  bool get isAuthLoading => _isAuthLoading;
  bool get isLoggedIn => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  RecipeState get recipeState => _recipeState;
  List<Recipe> get recipes => _recipes;
  List<Recipe> get favorites => _favorites;
  List<String> get selectedCuisines => _selectedCuisines;
  Map<String, int> get calorieMap => _calorieMap;
  MealPlan? get mealPlan => _mealPlan;
  String? get errorMessage => _errorMessage;
  String get language => _language;
  int get selectedTab => _selectedTab;
  int get dailySearchCount => _dailySearchCount;
  int get dailySearchLimit => SubscriptionConfig.freeSearchesPerDay;
  int get favoritesLimit => SubscriptionConfig.freeFavoritesLimit;
  int get cuisinesLimit => SubscriptionConfig.freeCuisinesLimit;
  bool get canAddMoreFavorites =>
      _isPremium || _favorites.length < SubscriptionConfig.freeFavoritesLimit;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _onUserLoggedIn(user);
      } else {
        _userData = null;
        _isPremium = false;
        _favorites = [];
      }
      _isAuthLoading = false;
      notifyListeners();
    });
  }

  Future<void> _onUserLoggedIn(User user) async {
    if (!kIsWeb) {
      _isPremium = await SubscriptionService.isPremium();
      if (!user.isAnonymous) {
        await SubscriptionService.loginUser(user.uid);
      }
    } else {
      _isPremium = false;
    }

    if (!user.isAnonymous) {
      _userData = await _authService.getUserData();
      _language = _userData?['language'] ?? 'tr';
    }

    _favorites = await _storage.getFavorites();
    _mealPlan = await _storage.getMealPlan();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _userData?['dailySearchDate'] ?? '';
    _dailySearchCount =
        lastDate == today ? (_userData?['dailySearchCount'] ?? 0) : 0;

    notifyListeners();
  }

  // ── Auth Actions ──────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    _isAuthLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    _isAuthLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithApple();
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    await _authService.signUpWithEmail(
        email: email, password: password, displayName: name);
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _authService.signInWithEmail(email: email, password: password);
  }

  Future<void> signInAnonymously() async {
    _isAuthLoading = true;
    notifyListeners();
    try {
      await _authService.signInAnonymously();
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    if (!kIsWeb) {
      await SubscriptionService.logoutUser();
    }
    _recipes = [];
    _favorites = [];
    _calorieMap = {};
    _lastIngredients = [];
    _recipeState = RecipeState.idle;
    notifyListeners();
  }

  // ── Language ──────────────────────────────────────────────────────────────
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _storage.setLanguage(lang);

    if (_user != null && !_user!.isAnonymous) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'language': lang});
    }

    notifyListeners();

    // Tarif yüklüyse aynı malzemelerle yeni dilde yeniden çek (sayaç artmaz)
    if (_lastIngredients.isNotEmpty && _recipeState == RecipeState.success) {
      await _searchRecipesInternal(_lastIngredients, incrementCounter: false);
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────
  void setTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  // ── Cuisine ───────────────────────────────────────────────────────────────
  void toggleCuisine(String cuisine) {
    if (_selectedCuisines.contains(cuisine)) {
      _selectedCuisines.remove(cuisine);
    } else {
      if (!_isPremium &&
          _selectedCuisines.length >= SubscriptionConfig.freeCuisinesLimit) {
        _errorMessage = _language == 'tr'
            ? 'Ücretsiz planda en fazla ${SubscriptionConfig.freeCuisinesLimit} mutfak seçebilirsiniz. Premium\'a geçin!'
            : 'Free plan allows ${SubscriptionConfig.freeCuisinesLimit} cuisines. Upgrade to Premium!';
        notifyListeners();
        return;
      }
      _selectedCuisines.add(cuisine);
    }
    _errorMessage = null;
    notifyListeners();
  }

  void clearCuisines() {
    _selectedCuisines = [];
    notifyListeners();
  }

  // ── Search (public — limit kontrolü yapar) ────────────────────────────────
  Future<void> searchRecipes(List<String> ingredients) async {
    if (_user == null) return;

    if (!_isPremium &&
        _dailySearchCount >= SubscriptionConfig.freeSearchesPerDay) {
      _errorMessage = _language == 'tr'
          ? 'Günlük $_dailySearchCount/5 arama hakkınızı kullandınız. Premium\'a geçin!'
          : 'Daily limit reached ($_dailySearchCount/5). Upgrade to Premium!';
      _recipeState = RecipeState.error;
      notifyListeners();
      return;
    }

    await _searchRecipesInternal(ingredients, incrementCounter: true);
  }

  // ── Search Internal (dil değişiminde sayaç artırmadan çağrılır) ──────────
  Future<void> _searchRecipesInternal(
    List<String> ingredients, {
    required bool incrementCounter,
  }) async {
    _lastIngredients = List.from(ingredients);
    _recipeState = RecipeState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _claude.generateRecipes(
          ingredients: ingredients,
          language: _language,
          selectedCuisines: _selectedCuisines,
          isPremium: _isPremium,
        ),
        _claude.getIngredientCalories(
          ingredients: ingredients,
          language: _language,
        ),
      ]);

      _recipes = results[0] as List<Recipe>;
      _calorieMap = results[1] as Map<String, int>;

      final favIds = _favorites.map((f) => f.id).toSet();
      for (var r in _recipes) {
        r.isFavorite = favIds.contains(r.id);
      }

      if (incrementCounter) {
        if (_user != null && !_user!.isAnonymous) {
          await _authService.incrementSearchCount();
        }
        _dailySearchCount++;
        await _storage.addRecentSearch(ingredients);
      }

      _recipeState = RecipeState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _recipeState = RecipeState.error;
    }

    notifyListeners();
  }

  // ── Favorites ─────────────────────────────────────────────────────────────
  Future<bool> toggleFavorite(Recipe recipe) async {
    final isFav = _favorites.any((f) => f.id == recipe.id);

    if (!isFav && !canAddMoreFavorites) {
      _errorMessage = _language == 'tr'
          ? 'Ücretsiz planda en fazla ${SubscriptionConfig.freeFavoritesLimit} favori kaydedebilirsiniz!'
          : 'Free plan allows ${SubscriptionConfig.freeFavoritesLimit} favorites!';
      notifyListeners();
      return false;
    }

    if (isFav) {
      _favorites.removeWhere((f) => f.id == recipe.id);
      await _storage.removeFavorite(recipe.id);
      recipe.isFavorite = false;
      final idx = _recipes.indexWhere((r) => r.id == recipe.id);
      if (idx != -1) _recipes[idx].isFavorite = false;
    } else {
      recipe.isFavorite = true;
      _favorites.insert(0, recipe);
      await _storage.saveFavorite(recipe);
      final idx = _recipes.indexWhere((r) => r.id == recipe.id);
      if (idx != -1) _recipes[idx].isFavorite = true;
    }
    notifyListeners();
    return true;
  }

  // ── Meal Plan ─────────────────────────────────────────────────────────────
  Future<void> addToMealPlan({
    required Recipe recipe,
    required DateTime date,
    required String mealType,
  }) async {
    if (!_isPremium) {
      _errorMessage = _language == 'tr'
          ? 'Haftalık plan sadece Premium kullanıcılar için!'
          : 'Weekly plan is for Premium users only!';
      notifyListeners();
      return;
    }

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final weekStart = date.subtract(Duration(days: date.weekday - 1));

    _mealPlan ??= MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weekStart: weekStart,
      days: {},
    );

    final days = Map<String, DayMeals>.from(_mealPlan!.days);
    final day = days[dateKey] ?? DayMeals();

    switch (mealType) {
      case 'breakfast':
        day.breakfast = recipe;
        break;
      case 'lunch':
        day.lunch = recipe;
        break;
      case 'dinner':
        day.dinner = recipe;
        break;
    }

    days[dateKey] = day;
    _mealPlan = MealPlan(id: _mealPlan!.id, weekStart: weekStart, days: days);
    await _storage.saveMealPlan(_mealPlan!);
    notifyListeners();
  }

  // ── Subscription ──────────────────────────────────────────────────────────
  Future<void> refreshPremiumStatus() async {
    if (!kIsWeb) {
      _isPremium = await SubscriptionService.isPremium();
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
