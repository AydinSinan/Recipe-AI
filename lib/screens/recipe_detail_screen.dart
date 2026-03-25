import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
  }

  double get _servingMultiplier => _servings / widget.recipe.servings;

  String _scaledAmount(String amount) {
    final num = double.tryParse(amount.replaceAll(',', '.'));
    if (num == null) return amount;
    final scaled = num * _servingMultiplier;
    if (scaled == scaled.roundToDouble()) return scaled.toInt().toString();
    return scaled.toStringAsFixed(1);
  }

  int _scaledCalories(int calories) => (calories * _servingMultiplier).round();

  int get _scaledTotalCalories =>
      (widget.recipe.totalCalories * _servingMultiplier).round();

  NutritionInfo get _scaledNutrition => NutritionInfo(
        calories:
            (widget.recipe.nutrition.calories * _servingMultiplier).round(),
        protein: widget.recipe.nutrition.protein * _servingMultiplier,
        carbs: widget.recipe.nutrition.carbs * _servingMultiplier,
        fat: widget.recipe.nutrition.fat * _servingMultiplier,
        fiber: widget.recipe.nutrition.fiber * _servingMultiplier,
      );

  String _buildShareText(String lang) {
    final recipe = widget.recipe;
    final buffer = StringBuffer();
    buffer.writeln('🍽️ ${recipe.name}');
    buffer.writeln('${recipe.cultureFlag} ${recipe.culture}');
    buffer.writeln();
    buffer.writeln(lang == 'tr'
        ? '📋 Malzemeler ($_servings kişilik):'
        : '📋 Ingredients (serves $_servings):');
    for (final ing in recipe.ingredients) {
      buffer
          .writeln('• ${ing.name} - ${_scaledAmount(ing.amount)} ${ing.unit}');
    }
    buffer.writeln();
    buffer.writeln(lang == 'tr' ? '👨‍🍳 Hazırlanışı:' : '👨‍🍳 Instructions:');
    for (int i = 0; i < recipe.steps.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.steps[i]}');
    }
    buffer.writeln();
    buffer.writeln(lang == 'tr'
        ? '⏱ ${recipe.cookTimeMinutes} dk • 🔥 $_scaledTotalCalories kcal'
        : '⏱ ${recipe.cookTimeMinutes} min • 🔥 $_scaledTotalCalories kcal');
    buffer.writeln();
    buffer.writeln(lang == 'tr'
        ? 'RecipeAI ile oluşturuldu 🤖'
        : 'Created with RecipeAI 🤖');
    return buffer.toString();
  }

  Future<void> _shareWhatsApp(String lang) async {
    final text = _buildShareText(lang);
    final encoded = Uri.encodeComponent(text);

    if (kIsWeb) {
      final uri = Uri.parse('https://wa.me/?text=$encoded');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final uri = Uri.parse('whatsapp://send?text=$encoded');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.get('share_not_available', lang)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final recipe = widget.recipe;
    final isFav = provider.favorites.any((f) => f.id == recipe.id);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08), blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textPrimary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // WhatsApp paylaş butonu
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _shareWhatsApp(lang),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10)
                      ],
                    ),
                    child: const Icon(Icons.share_rounded,
                        color: Color(0xFF25D366), size: 22),
                  ),
                ),
              ),
              // Favori butonu
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => provider.toggleFavorite(recipe),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10)
                      ],
                    ),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.error : AppTheme.textHint,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.12),
                      AppTheme.accent.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(recipe.cultureFlag,
                        style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(recipe.culture,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      )),
                  const SizedBox(height: 8),
                  Text(recipe.description,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      )),

                  const SizedBox(height: 20),
                  _statsRow(lang),

                  if (recipe.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: recipe.tags
                          .map((t) => Chip(
                                label: Text(t),
                                backgroundColor:
                                    AppTheme.secondary.withOpacity(0.08),
                                side: const BorderSide(
                                    color: AppTheme.secondary, width: 0.5),
                                labelStyle: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppTheme.secondary,
                                    fontWeight: FontWeight.w600),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Divider(),

                  // ── Nutrition ───────────────────────────────────────────
                  const SizedBox(height: 20),
                  SectionHeader(title: AppStrings.get('nutrition_title', lang)),
                  _nutritionSection(lang),

                  const SizedBox(height: 24),
                  const Divider(),

                  // ── Porsiyon hesaplayıcı ────────────────────────────────
                  const SizedBox(height: 20),
                  _servingCalculator(lang),

                  const SizedBox(height: 24),
                  const Divider(),

                  // ── Ingredients ─────────────────────────────────────────
                  const SizedBox(height: 20),
                  SectionHeader(
                      title:
                          '${AppStrings.get('ingredients_title', lang)} ($_servings ${AppStrings.get('servings', lang)})'),
                  ...recipe.ingredients.map((ing) => _ingredientRow(ing)),

                  const SizedBox(height: 24),
                  const Divider(),

                  // ── Steps ───────────────────────────────────────────────
                  const SizedBox(height: 20),
                  SectionHeader(title: AppStrings.get('steps_title', lang)),
                  ...recipe.steps.asMap().entries.map(
                        (e) => _stepCard(e.key + 1, e.value),
                      ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _servingCalculator(String lang) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Text(
              lang == 'tr' ? '👥 Porsiyon' : '👥 Servings',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (_servings > 1) setState(() => _servings--);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _servings > 1
                      ? AppTheme.primary.withOpacity(0.1)
                      : AppTheme.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.remove_rounded,
                    color: _servings > 1 ? AppTheme.primary : AppTheme.textHint,
                    size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_servings',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () {
                if (_servings < 20) setState(() => _servings++);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
              ),
            ),
          ],
        ),
      );

  Widget _statsRow(String lang) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('⏱', '${widget.recipe.cookTimeMinutes}',
                AppStrings.get('minutes', lang)),
            _dividerV(),
            _statItem('🔥', '$_scaledTotalCalories',
                AppStrings.get('calories', lang)),
            _dividerV(),
            _statItem('👥', '$_servings', AppStrings.get('servings', lang)),
            _dividerV(),
            _statItem(
              widget.recipe.difficulty == 'easy'
                  ? '😊'
                  : widget.recipe.difficulty == 'hard'
                      ? '😤'
                      : '🙂',
              widget.recipe.difficulty == 'easy'
                  ? 'Easy'
                  : widget.recipe.difficulty == 'hard'
                      ? 'Hard'
                      : 'Med',
              AppStrings.get('difficulty_${widget.recipe.difficulty}', lang),
            ),
          ],
        ),
      );

  Widget _statItem(String emoji, String value, String label) => Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label,
              style: GoogleFonts.lato(fontSize: 11, color: AppTheme.textHint)),
        ],
      );

  Widget _dividerV() =>
      Container(height: 40, width: 1, color: AppTheme.divider);

  Widget _nutritionSection(String lang) {
    final n = _scaledNutrition;
    return Column(
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.warmGradient,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${n.calories}',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text(AppStrings.get('calories', lang),
                    style:
                        GoogleFonts.lato(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        NutritionBar(
            label: AppStrings.get('protein', lang),
            value: n.protein,
            max: 50 * _servingMultiplier,
            color: AppTheme.primary),
        NutritionBar(
            label: AppStrings.get('carbs', lang),
            value: n.carbs,
            max: 100 * _servingMultiplier,
            color: AppTheme.accent),
        NutritionBar(
            label: AppStrings.get('fat', lang),
            value: n.fat,
            max: 40 * _servingMultiplier,
            color: AppTheme.secondary),
        NutritionBar(
            label: AppStrings.get('fiber', lang),
            value: n.fiber,
            max: 25 * _servingMultiplier,
            color: const Color(0xFF6A9E76)),
        const SizedBox(height: 6),
        Text(AppStrings.get('per_serving', lang),
            style: GoogleFonts.lato(fontSize: 12, color: AppTheme.textHint)),
      ],
    );
  }

  Widget _ingredientRow(RecipeIngredient ing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(ing.name,
                  style: GoogleFonts.lato(
                      fontSize: 15, color: AppTheme.textPrimary)),
            ),
            Text('${_scaledAmount(ing.amount)} ${ing.unit}',
                style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            if (ing.calories > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_scaledCalories(ing.calories)} kcal',
                    style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentDark)),
              ),
            ],
          ],
        ),
      );

  Widget _stepCard(int number, String step) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.warmGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('$number',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(step,
                  style: GoogleFonts.lato(
                      fontSize: 15, color: AppTheme.textPrimary, height: 1.6)),
            ),
          ],
        ),
      );
}
