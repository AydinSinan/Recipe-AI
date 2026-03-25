import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../config/config.dart';

class ClaudeService {
  // ── Generate Recipes ──────────────────────────────────────────────────────
  Future<List<Recipe>> generateRecipes({
    required List<String> ingredients,
    required String language,
    required List<String> selectedCuisines,
    required List<String> selectedDietaryFilters,
    required bool isPremium,
  }) async {
    final count = isPremium
        ? SubscriptionConfig.premiumRecipesPerSearch
        : SubscriptionConfig.freeRecipesPerSearch;

    final isTurkish = language == 'tr';
    final lang = isTurkish ? 'Turkish' : 'English';
    final langStrict = isTurkish
        ? 'TÜRKÇE (tüm metin, adımlar, malzemeler ve açıklamalar kesinlikle Türkçe olmalı)'
        : 'ENGLISH (all text, steps, ingredients and descriptions must be in English)';

    final ingList = ingredients.join(', ');
    final cuisineList = selectedCuisines.isEmpty
        ? 'any world cuisine'
        : selectedCuisines.join(', ');
    final dietaryList = selectedDietaryFilters.isEmpty
        ? 'none'
        : selectedDietaryFilters.join(', ');

    final prompt = '''
You are an expert international chef and nutritionist.

CRITICAL LANGUAGE REQUIREMENT: You MUST respond entirely in $langStrict.
Every single word in name, culture, description, ingredient names, steps, tags — ALL must be in $lang.
Do NOT use any other language. This is mandatory.

Ingredients available: $ingList
Requested cuisine styles: $cuisineList
Dietary restrictions (MUST be strictly followed): $dietaryList

Generate exactly $count recipes. Respond ONLY with valid JSON, no markdown, no explanation.

{
  "recipes": [
    {
      "id": "uid1",
      "name": "Recipe name in $lang",
      "culture": "Culture/cuisine name in $lang",
      "cultureFlag": "🇹🇷",
      "description": "2-3 sentence description in $lang",
      "ingredients": [
        {"name": "ingredient name in $lang", "amount": "2", "unit": "cup", "calories": 150}
      ],
      "steps": ["Step 1 in $lang", "Step 2 in $lang"],
      "cookTimeMinutes": 30,
      "servings": 4,
      "difficulty": "easy",
      "totalCalories": 450,
      "nutrition": {"calories": 450, "protein": 25.5, "carbs": 45.0, "fat": 12.3, "fiber": 5.2},
      "tags": ["tag1_in_$lang", "tag2_in_$lang"]
    }
  ]
}

Rules:
- difficulty must be exactly "easy", "medium", or "hard" (always in English, never translate)
- calories are per serving
- ALL other text fields must be in $lang — no exceptions
- If dietary restrictions are specified, every recipe MUST comply with ALL of them — no exceptions
''';

    final response = await _callApi(
      endpoint: 'generateRecipes',
      prompt: prompt,
    );
    return _parseRecipes(response);
  }

  // ── Get Ingredient Calories ───────────────────────────────────────────────
  Future<Map<String, int>> getIngredientCalories({
    required List<String> ingredients,
    required String language,
  }) async {
    final isTurkish = language == 'tr';
    final lang = isTurkish ? 'Turkish' : 'English';
    final langStrict = isTurkish
        ? 'TÜRKÇE (malzeme isimleri Türkçe olmalı)'
        : 'ENGLISH (ingredient names in English)';

    final prompt = '''
CRITICAL: Respond in $langStrict. Ingredient names in the JSON keys must be in $lang.

Provide calories per 100g for each ingredient. Respond ONLY with valid JSON, no markdown.
Ingredients: ${ingredients.join(', ')}

Expected format:
{"calories": {"ingredient name in $lang": 123, "another ingredient in $lang": 456}}
''';

    final response = await _callApi(endpoint: 'getCalories', prompt: prompt);
    try {
      final data = jsonDecode(_cleanJson(response)) as Map<String, dynamic>;
      final cals = data['calories'] as Map<String, dynamic>;
      return cals.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  // ── Call API ──────────────────────────────────────────────────────────────
  Future<String> _callApi({
    required String endpoint,
    required String prompt,
  }) async {
    if (ApiConfig.devMode) {
      return await _callDirect(prompt);
    } else {
      return await _callProxy(endpoint, prompt);
    }
  }

  // Dev: Direkt Anthropic (Chrome'da çalışır, production'da kullanma)
  // API key'i buraya yazmak yerine .env dosyasından veya lokal config'den al.
  // devMode sadece local geliştirme için — config.dart'ta devMode=false bırak.
  Future<String> _callDirect(String prompt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Giriş yapılmamış');

    const devApiKey = '';

    final res = await http.post(
      Uri.parse(ApiConfig.claudeDirectUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': devApiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': ApiConfig.claudeModel,
        'max_tokens': 4096,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('API Hatası ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['content'][0]['text'] as String;
  }

  // Production: Firebase Functions proxy
  Future<String> _callProxy(String endpoint, String prompt) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Giriş yapılmamış');

    final token = await user.getIdToken();

    final res = await http.post(
      Uri.parse('${ApiConfig.functionsBaseUrl}/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'prompt': prompt}),
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode == 401) throw Exception('Yetkilendirme hatası');
    if (res.statusCode == 429) throw Exception('Günlük arama limitine ulaştınız');
    if (res.statusCode != 200) throw Exception('Sunucu hatası: ${res.statusCode}');

    final data = jsonDecode(res.body);
    return data['text'] as String;
  }

  List<Recipe> _parseRecipes(String raw) {
    try {
      final data = jsonDecode(_cleanJson(raw)) as Map<String, dynamic>;
      return (data['recipes'] as List)
          .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Tarif ayrıştırma hatası: $e');
    }
  }

  String _cleanJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      s = s.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return s.trim();
  }
}