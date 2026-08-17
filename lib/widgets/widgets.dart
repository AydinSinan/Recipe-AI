import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme.dart';
import '../l10n/strings.dart';

// ── RecipeCard ────────────────────────────────────────────────────────────────
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String language;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onAddToPlan;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.language,
    required this.onTap,
    required this.onFavorite,
    this.onAddToPlan,
  });

  String get _difficultyLabel {
    switch (recipe.difficulty) {
      case 'easy': return AppStrings.get('difficulty_easy', language);
      case 'hard': return AppStrings.get('difficulty_hard', language);
      default: return AppStrings.get('difficulty_medium', language);
    }
  }

  Color get _difficultyColor {
    switch (recipe.difficulty) {
      case 'easy': return AppTheme.secondary;
      case 'hard': return AppTheme.error;
      default: return AppTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header band
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.08),
                    AppTheme.accent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag + culture
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.cultureFlag,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(recipe.culture,
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            )),
                        const SizedBox(height: 6),
                        Text(recipe.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            )),
                      ],
                    ),
                  ),
                  // Favorite button
                  GestureDetector(
                    onTap: onFavorite,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        recipe.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(recipe.isFavorite),
                        color: recipe.isFavorite
                            ? AppTheme.error
                            : AppTheme.textHint,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _stat(
                    Icons.timer_outlined,
                    '${recipe.cookTimeMinutes} ${AppStrings.get('minutes', language)}',
                  ),
                  const SizedBox(width: 16),
                  _stat(
                    Icons.local_fire_department_outlined,
                    '${recipe.totalCalories} ${AppStrings.get('calories', language)}',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _stat(
                    Icons.people_outline_rounded,
                    '${recipe.servings} ${AppStrings.get('servings', language)}',
                  ),
                  const Spacer(),
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_difficultyLabel,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _difficultyColor,
                        )),
                  ),
                ],
              ),
            ),
            // Tags + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: recipe.tags
                          .take(3)
                          .map((t) => _tag(t))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onAddToPlan != null)
                    GestureDetector(
                      onTap: onAddToPlan,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_outlined,
                            color: AppTheme.secondary, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String text, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color ?? AppTheme.textHint),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.lato(
            fontSize: 13,
            color: color ?? AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          )),
    ],
  );

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Text(label,
        style: GoogleFonts.lato(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500)),
  );
}

// ── IngredientChip ────────────────────────────────────────────────────────────
class IngredientChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool isSaved;
  final VoidCallback? onTogglePantry;

  const IngredientChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.isSaved = false,
    this.onTogglePantry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              )),
          if (onTogglePantry != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTogglePantry,
              child: Icon(
                isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
          ],
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

// ── PantryChip ───────────────────────────────────────────────────────────────
class PantryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PantryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                )),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded,
                  size: 15,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppTheme.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NutritionRow ─────────────────────────────────────────────────────────────
class NutritionBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String unit;

  const NutritionBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value / max).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = (constraints.maxWidth * 0.30).clamp(80.0, 120.0);
        final valueWidth = (constraints.maxWidth * 0.15).clamp(44.0, 64.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: valueWidth,
                child: Text('${value.toStringAsFixed(1)}$unit',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── CalorieCard ───────────────────────────────────────────────────────────────
class CalorieCard extends StatelessWidget {
  final String ingredient;
  final int calories;
  final String language;

  const CalorieCard({
    super.key,
    required this.ingredient,
    required this.calories,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_outlined,
                color: AppTheme.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ingredient,
                style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$calories',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              Text(
                  '${AppStrings.get('calories', language)} / ${AppStrings.get('per_100g', language)}',
                  style: GoogleFonts.lato(
                      fontSize: 10, color: AppTheme.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading Overlay ───────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(message,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('✨ 🍜 🌮 🍝 🥘',
                style: TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
