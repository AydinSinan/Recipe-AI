import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../config/config.dart';

class ClaudeService {
  // ── Generate Recipes (streaming) ────────────────────────────────────────
  // Tarifler tek tek (NDJSON — satır başına bir tarif) üretilip geldikçe
  // yield edilir; kullanıcı hepsinin bitmesini beklemeden ilk tarifi görür.
  Stream<Recipe> generateRecipesStream({
    required List<String> ingredients,
    required String language,
    required List<String> selectedCuisines,
    required List<String> selectedDietaryFilters,
    required bool isPremium,
  }) async* {
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

Generate exactly $count recipes.

CRITICAL OUTPUT FORMAT: Respond with exactly $count lines. Each line is one complete,
self-contained JSON object for a single recipe — NOT a JSON array, NOT wrapped in an
outer object, no markdown, no explanation, no blank lines between recipes.

Each line must look like this:
{"id": "uid1", "name": "Recipe name in $lang", "culture": "Culture/cuisine name in $lang", "cultureFlag": "🇹🇷", "description": "2-3 sentence description in $lang", "ingredients": [{"name": "ingredient name in $lang", "amount": "2", "unit": "cup", "calories": 150}], "steps": ["Step 1 in $lang", "Step 2 in $lang"], "cookTimeMinutes": 30, "servings": 4, "difficulty": "easy", "totalCalories": 450, "nutrition": {"calories": 450, "protein": 25.5, "carbs": 45.0, "fat": 12.3, "fiber": 5.2}, "tags": ["tag1_in_$lang", "tag2_in_$lang"]}

Rules:
- difficulty must be exactly "easy", "medium", or "hard" (always in English, never translate)
- calories are per serving
- ALL other text fields must be in $lang — no exceptions
- If dietary restrictions are specified, every recipe MUST comply with ALL of them — no exceptions
- Each recipe must be valid, complete JSON on its own single line
''';

    var recipeCount = 0;
    await for (final jsonObj in _callApiJsonObjects(
      endpoint: 'generateRecipes',
      prompt: prompt,
    )) {
      try {
        final data = jsonDecode(jsonObj) as Map<String, dynamic>;
        recipeCount++;
        yield Recipe.fromJson(data);
      } catch (_) {
        // Tek bir tarifin ayrıştırılamaması diğerlerini etkilemesin
      }
    }

    if (recipeCount == 0) {
      throw Exception('Tarif alınamadı, lütfen tekrar deneyin');
    }
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

  // ── Call API (tek seferlik, tam yanıt) ────────────────────────────────────
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

  // ── Call API (üst seviye JSON objelerini akış halinde çıkarır) ────────────
  // Modelin her tarifi ayrı bir satıra koyacağına güvenmiyoruz — bunun yerine
  // süslü parantez derinliğini takip edip tamamlanan her üst seviye {...}
  // objesini, gelen metinde newline olsun olmasın anında yakalıyoruz.
  Stream<String> _callApiJsonObjects({
    required String endpoint,
    required String prompt,
  }) async* {
    if (ApiConfig.devMode) {
      // Dev modunda streaming yok: tek seferde çekip objelere böl.
      final raw = await _callDirect(prompt);
      final extractor = _JsonObjectExtractor();
      for (final obj in extractor.feed(raw)) {
        yield obj;
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Giriş yapılmamış');
    final token = await user.getIdToken();

    final request = http.Request(
      'POST',
      Uri.parse('${ApiConfig.functionsBaseUrl}/$endpoint'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.body = jsonEncode({'prompt': prompt});

    final client = http.Client();
    try {
      final streamed =
          await client.send(request).timeout(const Duration(seconds: 60));

      if (streamed.statusCode == 401) {
        throw Exception('Yetkilendirme hatası');
      }
      if (streamed.statusCode == 429) {
        throw Exception('Günlük arama limitine ulaştınız');
      }
      if (streamed.statusCode != 200) {
        final body = await streamed.stream.bytesToString();
        throw Exception('Sunucu hatası: ${streamed.statusCode} $body');
      }

      final extractor = _JsonObjectExtractor();
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        for (final obj in extractor.feed(chunk)) {
          yield obj;
        }
      }
    } finally {
      client.close();
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
        'max_tokens': 8192,
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

    if (res.statusCode == 401) throw Exception('Yetkilendirme hatası: ${res.body}');
    if (res.statusCode == 429) throw Exception('Günlük arama limitine ulaştınız');
    if (res.statusCode != 200) throw Exception('Sunucu hatası: ${res.statusCode}');

    final data = jsonDecode(res.body);
    return data['text'] as String;
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

// ── JSON Object Extractor ─────────────────────────────────────────────────
// Akış halinde gelen metinden, süslü parantez derinliğini takip ederek
// tamamlanmış üst seviye {...} objelerini çıkarır. Objeler arasında newline
// olsun olmasın, string içindeki kaçışlı tırnak/parantez karakterlerini de
// doğru şekilde göz ardı ederek çalışır.
class _JsonObjectExtractor {
  final StringBuffer _buffer = StringBuffer();
  int _depth = 0;
  bool _inString = false;
  bool _escaped = false;
  int _objStart = -1;
  int _length = 0;

  List<String> feed(String chunk) {
    final completed = <String>[];
    _buffer.write(chunk);
    final full = _buffer.toString();

    for (var i = _length; i < full.length; i++) {
      final ch = full[i];

      if (_escaped) {
        _escaped = false;
        continue;
      }
      if (_inString) {
        if (ch == '\\') {
          _escaped = true;
        } else if (ch == '"') {
          _inString = false;
        }
        continue;
      }
      if (ch == '"') {
        _inString = true;
        continue;
      }
      if (ch == '{') {
        if (_depth == 0) _objStart = i;
        _depth++;
      } else if (ch == '}') {
        if (_depth > 0) {
          _depth--;
          if (_depth == 0 && _objStart != -1) {
            completed.add(full.substring(_objStart, i + 1));
            _objStart = -1;
          }
        }
      }
    }

    _length = full.length;
    return completed;
  }
}
