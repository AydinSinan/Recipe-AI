import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import 'recipe_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final plan = provider.mealPlan;

    // Build week days starting Monday
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final weekDays =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final selectedKey =
        '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
    final dayMeals = plan?.days[selectedKey];

    final dayNames = lang == 'tr'
        ? ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppStrings.get('meal_plan_title', lang)),
      ),
      body: Column(
        children: [
          // ── Week Strip ────────────────────────────────────────────────
          Container(
            color: AppTheme.surfaceCard,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: weekDays.asMap().entries.map((entry) {
                final i = entry.key;
                final day = entry.value;
                final isSelected = day.day == _selectedDay.day &&
                    day.month == _selectedDay.month;
                final isToday = day.day == now.day &&
                    day.month == now.month;
                final dayKey =
                    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                final hasMeals = plan?.days[dayKey] != null;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(dayNames[i],
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.textHint,
                              )),
                          const SizedBox(height: 4),
                          Text('${day.day}',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                              )),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasMeals
                                  ? (isSelected
                                      ? Colors.white
                                      : AppTheme.secondary)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Daily Total ───────────────────────────────────────────────
          if (dayMeals != null && dayMeals.totalCalories > 0)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.warmGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '${AppStrings.get('total_calories_day', lang)}: ${dayMeals.totalCalories} kcal',
                    style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ],
              ),
            ),

          // ── Meal Slots ────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              children: [
                _mealSlot(
                  context: context,
                  emoji: '🌅',
                  label: AppStrings.get('breakfast', lang),
                  recipe: dayMeals?.breakfast,
                  mealType: 'breakfast',
                  lang: lang,
                  provider: provider,
                ),
                const SizedBox(height: 14),
                _mealSlot(
                  context: context,
                  emoji: '☀️',
                  label: AppStrings.get('lunch', lang),
                  recipe: dayMeals?.lunch,
                  mealType: 'lunch',
                  lang: lang,
                  provider: provider,
                ),
                const SizedBox(height: 14),
                _mealSlot(
                  context: context,
                  emoji: '🌙',
                  label: AppStrings.get('dinner', lang),
                  recipe: dayMeals?.dinner,
                  mealType: 'dinner',
                  lang: lang,
                  provider: provider,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealSlot({
    required BuildContext context,
    required String emoji,
    required String label,
    required Recipe? recipe,
    required String mealType,
    required String lang,
    required AppProvider provider,
  }) {
    if (recipe == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.divider, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary)),
                Text(AppStrings.get('meal_plan_empty', lang),
                    style: GoogleFonts.lato(
                        fontSize: 12, color: AppTheme.textHint)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppTheme.textHint, size: 20),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(recipe.cultureFlag,
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 5),
                  Text(recipe.name,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${recipe.totalCalories} kcal · ${recipe.cookTimeMinutes} ${AppStrings.get('minutes', lang)}',
                    style: GoogleFonts.lato(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
