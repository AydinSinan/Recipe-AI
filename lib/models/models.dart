// ── Recipe Model ──────────────────────────────────────────────────────────────
class Recipe {
  final String id;
  final String name;
  final String culture;
  final String cultureFlag;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty; // easy / medium / hard
  final int totalCalories;
  final NutritionInfo nutrition;
  final List<String> tags;
  bool isFavorite;
  final DateTime? createdAt;

  Recipe({
    required this.id,
    required this.name,
    required this.culture,
    required this.cultureFlag,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.totalCalories,
    required this.nutrition,
    required this.tags,
    this.isFavorite = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'culture': culture,
    'cultureFlag': cultureFlag,
    'description': description,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps,
    'cookTimeMinutes': cookTimeMinutes,
    'servings': servings,
    'difficulty': difficulty,
    'totalCalories': totalCalories,
    'nutrition': nutrition.toJson(),
    'tags': tags,
    'isFavorite': isFavorite,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    name: json['name'],
    culture: json['culture'],
    cultureFlag: json['cultureFlag'] ?? '🍽️',
    description: json['description'],
    ingredients: (json['ingredients'] as List)
        .map((i) => RecipeIngredient.fromJson(i))
        .toList(),
    steps: List<String>.from(json['steps']),
    cookTimeMinutes: json['cookTimeMinutes'],
    servings: json['servings'],
    difficulty: json['difficulty'],
    totalCalories: json['totalCalories'],
    nutrition: NutritionInfo.fromJson(json['nutrition']),
    tags: List<String>.from(json['tags'] ?? []),
    isFavorite: json['isFavorite'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );
}

// ── RecipeIngredient ──────────────────────────────────────────────────────────
class RecipeIngredient {
  final String name;
  final String amount;
  final int calories;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.calories,
    required this.unit,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'calories': calories,
    'unit': unit,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'],
        amount: json['amount'],
        calories: json['calories'] ?? 0,
        unit: json['unit'] ?? '',
      );
}

// ── NutritionInfo ─────────────────────────────────────────────────────────────
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
  };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
    calories: json['calories'] ?? 0,
    protein: (json['protein'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    fat: (json['fat'] ?? 0).toDouble(),
    fiber: (json['fiber'] ?? 0).toDouble(),
  );
}

// ── MealPlan ──────────────────────────────────────────────────────────────────
class MealPlan {
  final String id;
  final DateTime weekStart;
  final Map<String, DayMeals> days; // key: "2024-01-15"

  MealPlan({
    required this.id,
    required this.weekStart,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekStart': weekStart.toIso8601String(),
    'days': days.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
    id: json['id'],
    weekStart: DateTime.parse(json['weekStart']),
    days: (json['days'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, DayMeals.fromJson(v)),
    ),
  );
}

class DayMeals {
  Recipe? breakfast;
  Recipe? lunch;
  Recipe? dinner;

  DayMeals({this.breakfast, this.lunch, this.dinner});

  int get totalCalories =>
      (breakfast?.totalCalories ?? 0) +
      (lunch?.totalCalories ?? 0) +
      (dinner?.totalCalories ?? 0);

  Map<String, dynamic> toJson() => {
    'breakfast': breakfast?.toJson(),
    'lunch': lunch?.toJson(),
    'dinner': dinner?.toJson(),
  };

  factory DayMeals.fromJson(Map<String, dynamic> json) => DayMeals(
    breakfast: json['breakfast'] != null
        ? Recipe.fromJson(json['breakfast'])
        : null,
    lunch: json['lunch'] != null ? Recipe.fromJson(json['lunch']) : null,
    dinner: json['dinner'] != null ? Recipe.fromJson(json['dinner']) : null,
  );
}

// ── AppUser ────────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> favoriteIds;
  final String preferredLanguage;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.favoriteIds = const [],
    this.preferredLanguage = 'tr',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'favoriteIds': favoriteIds,
    'preferredLanguage': preferredLanguage,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    email: json['email'],
    displayName: json['displayName'],
    photoUrl: json['photoUrl'],
    favoriteIds: List<String>.from(json['favoriteIds'] ?? []),
    preferredLanguage: json['preferredLanguage'] ?? 'tr',
  );
}

// ── GroceryItem ───────────────────────────────────────────────────────────────
class GroceryItem {
  final String id;
  final String name;
  final String amount;
  final String unit;
  final String recipeId;
  final String recipeName;
  bool isChecked;

  GroceryItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.recipeId,
    required this.recipeName,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'unit': unit,
    'recipeId': recipeId,
    'recipeName': recipeName,
    'isChecked': isChecked,
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    id: json['id'],
    name: json['name'],
    amount: json['amount'] ?? '',
    unit: json['unit'] ?? '',
    recipeId: json['recipeId'] ?? '',
    recipeName: json['recipeName'] ?? '',
    isChecked: json['isChecked'] ?? false,
  );
}
