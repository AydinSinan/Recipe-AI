import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _ingredientCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _ingredients = [];
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Dietary filter data: {name_tr, name_en, icon, key}
  static const List<Map<String, String>> _dietaryFilters = [
    {'tr': 'Vejeteryan', 'en': 'Vegetarian', 'icon': '🥗', 'key': 'vegetarian'},
    {'tr': 'Vegan', 'en': 'Vegan', 'icon': '🌱', 'key': 'vegan'},
    {'tr': 'Glutensiz', 'en': 'Gluten-Free', 'icon': '🌾', 'key': 'gluten-free'},
    {'tr': 'Sütsüz', 'en': 'Dairy-Free', 'icon': '🥛', 'key': 'dairy-free'},
    {'tr': 'Fındıksız', 'en': 'Nut-Free', 'icon': '🥜', 'key': 'nut-free'},
    {'tr': 'Düşük Karb', 'en': 'Low Carb', 'icon': '📉', 'key': 'low-carb'},
  ];

  // Cuisine data: {name_tr, name_en, flag, key}
  static const List<Map<String, String>> _cuisines = [
    {'tr': 'Akdeniz', 'en': 'Mediterranean', 'flag': '🌊', 'key': 'Mediterranean'},
    {'tr': 'Anadolu', 'en': 'Anatolian', 'flag': '🇹🇷', 'key': 'Turkish/Anatolian'},
    {'tr': 'Meksika', 'en': 'Mexican', 'flag': '🇲🇽', 'key': 'Mexican'},
    {'tr': 'Uzak Doğu', 'en': 'Far East', 'flag': '🥢', 'key': 'Japanese/Chinese/Korean'},
    {'tr': 'Hint', 'en': 'Indian', 'flag': '🇮🇳', 'key': 'Indian'},
    {'tr': 'İtalyan', 'en': 'Italian', 'flag': '🇮🇹', 'key': 'Italian'},
    {'tr': 'Fransız', 'en': 'French', 'flag': '🇫🇷', 'key': 'French'},
    {'tr': 'Orta Doğu', 'en': 'Middle East', 'flag': '🌙', 'key': 'Middle Eastern'},
    {'tr': 'Amerikan', 'en': 'American', 'flag': '🇺🇸', 'key': 'American'},
    {'tr': 'Tayland', 'en': 'Thai', 'flag': '🇹🇭', 'key': 'Thai'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _ingredientCtrl.dispose();
    _focusNode.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientCtrl.text.trim();
    if (text.isEmpty || _ingredients.contains(text.toLowerCase())) return;
    setState(() => _ingredients.add(text.toLowerCase()));
    _ingredientCtrl.clear();
    _focusNode.requestFocus();
  }

  void _removeIngredient(String item) {
    setState(() => _ingredients.remove(item));
  }

  Future<void> _search(AppProvider provider) async {
    if (_ingredients.isEmpty) return;
    _focusNode.unfocus();
    await provider.searchRecipes(_ingredients);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final isLoading = provider.recipeState == RecipeState.loading;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  // ── Header ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.warmGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: Text('🍳',
                                        style: TextStyle(fontSize: 22))),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.get('app_name', lang),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => provider.setLanguage(
                                    lang == 'tr' ? 'en' : 'tr'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: AppTheme.divider),
                                  ),
                                  child: Text(
                                    lang == 'tr' ? '🇹🇷 TR' : '🇬🇧 EN',
                                    style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.get('home_title', lang),
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.get('app_tagline', lang),
                            style: GoogleFonts.lato(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Cuisine Selector ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                lang == 'tr'
                                    ? 'Hangi mutfak tarzı?'
                                    : 'Which cuisine style?',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (provider.selectedCuisines.isNotEmpty)
                                GestureDetector(
                                  onTap: provider.clearCuisines,
                                  child: Text(
                                    lang == 'tr' ? 'Temizle' : 'Clear',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _cuisines.map((c) {
                              final key = c['key']!;
                              final isSelected =
                                  provider.selectedCuisines.contains(key);
                              return GestureDetector(
                                onTap: () => provider.toggleCuisine(key),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.divider,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(c['flag']!,
                                          style: const TextStyle(
                                              fontSize: 16)),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang == 'tr'
                                            ? c['tr']!
                                            : c['en']!,
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (provider.selectedCuisines.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                lang == 'tr'
                                    ? 'Seçim yapmazsanız tüm dünya mutfaklarından tarif gelir'
                                    : 'If none selected, recipes from all cuisines',
                                style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: AppTheme.textHint,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Dietary Filter Selector ───────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppStrings.get('dietary_filters', lang),
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              if (provider.selectedDietaryFilters.isNotEmpty)
                                GestureDetector(
                                  onTap: provider.clearDietaryFilters,
                                  child: Text(
                                    lang == 'tr' ? 'Temizle' : 'Clear',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _dietaryFilters.map((f) {
                              final key = f['key']!;
                              final isSelected =
                                  provider.selectedDietaryFilters.contains(key);
                              return GestureDetector(
                                onTap: () =>
                                    provider.toggleDietaryFilter(key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.secondary
                                        : AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.secondary
                                          : AppTheme.divider,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.secondary
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(f['icon']!,
                                          style:
                                              const TextStyle(fontSize: 15)),
                                      const SizedBox(width: 6),
                                      Text(
                                        lang == 'tr' ? f['tr']! : f['en']!,
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Ingredient Input ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get('ingredients_label', lang),
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ingredientCtrl,
                                  focusNode: _focusNode,
                                  onSubmitted: (_) => _addIngredient(),
                                  decoration: InputDecoration(
                                    hintText: AppStrings.get(
                                        'ingredients_hint', lang),
                                    prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: AppTheme.textHint),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _addIngredient,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.warmGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      color: Colors.white, size: 26),
                                ),
                              ),
                            ],
                          ),
                          if (_ingredients.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _ingredients
                                  .map((i) => IngredientChip(
                                        label: i,
                                        onRemove: () =>
                                            _removeIngredient(i),
                                      ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _ingredients.isEmpty || isLoading
                                      ? null
                                      : () => _search(provider),
                              icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 20),
                              label: Text(AppStrings.get(
                                  'generate_recipes', lang)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 17),
                                disabledBackgroundColor: AppTheme.divider,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Calorie Info ──────────────────────────────────────────
                  if (provider.calorieMap.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                                title: AppStrings.get(
                                    'calorie_info', lang)),
                            ...provider.calorieMap.entries.map((e) =>
                                Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: CalorieCard(
                                    ingredient: e.key,
                                    calories: e.value,
                                    language: lang,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                  // ── Recipes ───────────────────────────────────────────────
                  if (provider.recipeState == RecipeState.success)
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i == 0) {
                              return SectionHeader(
                                title: lang == 'tr'
                                    ? '${provider.recipes.length} Tarif Bulundu'
                                    : '${provider.recipes.length} Recipes Found',
                              );
                            }
                            final recipe = provider.recipes[i - 1];
                            return RecipeCard(
                              recipe: recipe,
                              language: lang,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipe),
                                ),
                              ),
                              onFavorite: () =>
                                  provider.toggleFavorite(recipe),
                              onAddToPlan: () =>
                                  _showAddToPlanDialog(context, recipe),
                            );
                          },
                          childCount: provider.recipes.length + 1,
                        ),
                      ),
                    ),

                  // ── Empty / Welcome ───────────────────────────────────────
                  if (provider.recipeState == RecipeState.idle &&
                      _ingredients.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                        child: Center(
                          child: Text(
                            AppStrings.get('ingredients_empty', lang),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Error ─────────────────────────────────────────────────
                  if (provider.recipeState == RecipeState.error)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('😔',
                                style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              provider.errorMessage ?? '',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                  color: AppTheme.error, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _search(provider),
                              child: Text(
                                  AppStrings.get('retry', lang)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Loading ───────────────────────────────────────────────────────
        if (isLoading)
          LoadingOverlay(
              message: AppStrings.get('generating', lang)),
      ],
    );
  }

  void _showAddToPlanDialog(BuildContext context, recipe) {
    final provider = context.read<AppProvider>();
    final lang = provider.language;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.get('select_meal_type', lang),
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            for (final mt in ['breakfast', 'lunch', 'dinner'])
              ListTile(
                leading: Text(
                    mt == 'breakfast' ? '🌅' : mt == 'lunch' ? '☀️' : '🌙',
                    style: const TextStyle(fontSize: 24)),
                title: Text(AppStrings.get(mt, lang),
                    style:
                        GoogleFonts.lato(fontWeight: FontWeight.w600)),
                onTap: () {
                  provider.addToMealPlan(
                      recipe: recipe,
                      date: DateTime.now(),
                      mealType: mt);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(lang == 'tr'
                          ? 'Plana eklendi!'
                          : 'Added to plan!')));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
