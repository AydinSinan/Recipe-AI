import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';

class GroceryListScreen extends StatelessWidget {
  const GroceryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final items = provider.groceryList;

    // Tariflere göre grupla
    final Map<String, List<GroceryItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.recipeId, () => []).add(item);
    }

    final checkedCount = provider.groceryCheckedCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10)
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppTheme.textPrimary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('grocery_list', lang),
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (items.isNotEmpty)
              Text(
                '$checkedCount/${items.length} ${AppStrings.get('grocery_checked_count', lang)}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.error),
              onPressed: () => _confirmClear(context, provider, lang),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmpty(lang)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: grouped.entries.map((entry) {
                final recipeItems = entry.value;
                final recipeName = recipeItems.first.recipeName;
                final allChecked = recipeItems.every((i) => i.isChecked);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarif başlığı
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_menu_rounded,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recipeName,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            // Tarifi listeden kaldır
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: AppTheme.textHint),
                              onPressed: () => provider
                                  .removeGroceryRecipe(entry.key),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                          height: 1, color: AppTheme.divider, indent: 16),
                      // Malzemeler
                      ...recipeItems.map((item) => _GroceryItemTile(
                            item: item,
                            onTap: () =>
                                provider.toggleGroceryItem(item.id),
                          )),
                      // Tümü tamamlandı badge
                      if (allChecked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppTheme.success),
                              const SizedBox(width: 6),
                              Text(
                                lang == 'tr'
                                    ? 'Tüm malzemeler alındı!'
                                    : 'All ingredients collected!',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmpty(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 64, color: AppTheme.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('grocery_empty', lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 15,
                color: AppTheme.textHint,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(
      BuildContext context, AppProvider provider, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.get('grocery_clear_all', lang),
          style: GoogleFonts.playfairDisplay(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          AppStrings.get('grocery_clear_confirm', lang),
          style: GoogleFonts.lato(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancel', lang),
                style: GoogleFonts.lato(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () {
              provider.clearGroceryList();
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.get('grocery_clear_all', lang),
                style: GoogleFonts.lato(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onTap;

  const _GroceryItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.isChecked ? AppTheme.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isChecked
                      ? AppTheme.secondary
                      : AppTheme.divider,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: item.isChecked
                      ? AppTheme.textHint
                      : AppTheme.textPrimary,
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.amount.isNotEmpty || item.unit.isNotEmpty)
              Text(
                '${item.amount} ${item.unit}'.trim(),
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: item.isChecked
                      ? AppTheme.textHint
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
