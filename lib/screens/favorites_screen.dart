import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'recipe_detail_screen.dart';

enum _SortOption { date, calories, name, cookTime }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.date;
  bool _sortAsc = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Recipe> _filtered(List<Recipe> favorites) {
    List<Recipe> result = favorites;

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((r) =>
              r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.culture.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.tags.any(
                  (t) => t.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // Sıralama
    result.sort((a, b) {
      int cmp;
      switch (_sortOption) {
        case _SortOption.date:
          cmp = (a.createdAt ?? DateTime(0))
              .compareTo(b.createdAt ?? DateTime(0));
          break;
        case _SortOption.calories:
          cmp = a.totalCalories.compareTo(b.totalCalories);
          break;
        case _SortOption.name:
          cmp = a.name.compareTo(b.name);
          break;
        case _SortOption.cookTime:
          cmp = a.cookTimeMinutes.compareTo(b.cookTimeMinutes);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return result;
  }

  void _showSortSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == 'tr' ? 'Sırala' : 'Sort by',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ..._SortOption.values.map((opt) {
                final labels = lang == 'tr'
                    ? {
                        _SortOption.date: '📅 Tarihe göre',
                        _SortOption.calories: '🔥 Kaloriye göre',
                        _SortOption.name: '🔤 İsme göre',
                        _SortOption.cookTime: '⏱ Pişirme süresine göre',
                      }
                    : {
                        _SortOption.date: '📅 By date',
                        _SortOption.calories: '🔥 By calories',
                        _SortOption.name: '🔤 By name',
                        _SortOption.cookTime: '⏱ By cook time',
                      };

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(labels[opt]!,
                      style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: _sortOption == opt
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  trailing: _sortOption == opt
                      ? Icon(
                          _sortAsc
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setSheetState(() {
                      if (_sortOption == opt) {
                        _sortAsc = !_sortAsc;
                      } else {
                        _sortOption = opt;
                        _sortAsc = false;
                      }
                    });
                    setState(() {});
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(
      BuildContext context, String lang, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          lang == 'tr' ? 'Tümünü Sil' : 'Clear All',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: Text(
          lang == 'tr'
              ? 'Tüm favoriler silinecek. Emin misiniz?'
              : 'All favorites will be removed. Are you sure?',
          style: GoogleFonts.lato(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang == 'tr' ? 'İptal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              for (final r in provider.favorites.toList()) {
                provider.toggleFavorite(r);
              }
            },
            child: Text(
              lang == 'tr' ? 'Sil' : 'Delete',
              style: const TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final favorites = provider.favorites;
    final filtered = _filtered(favorites);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppStrings.get('favorites_title', lang)),
        actions: [
          if (favorites.isNotEmpty) ...[
            // Sırala butonu
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              onPressed: () => _showSortSheet(context, lang),
              tooltip: lang == 'tr' ? 'Sırala' : 'Sort',
            ),
            // Tümünü sil butonu
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.error),
              onPressed: () => _confirmClearAll(context, lang, provider),
              tooltip: lang == 'tr' ? 'Tümünü Sil' : 'Clear All',
            ),
            // Favori sayısı
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${favorites.length}',
                    style: GoogleFonts.lato(
                        color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: favorites.isEmpty
          ? EmptyState(
              emoji: '❤️',
              message: AppStrings.get('favorites_empty', lang),
            )
          : Column(
              children: [
                // ── Arama ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: lang == 'tr'
                          ? 'Favorilerde ara...'
                          : 'Search favorites...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textHint, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // ── Aktif sıralama göstergesi ──────────────────────────────
                if (_sortOption != _SortOption.date)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          _sortLabel(lang),
                          style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _sortAsc
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),

                // ── Liste ──────────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔍', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                lang == 'tr'
                                    ? 'Sonuç bulunamadı'
                                    : 'No results found',
                                style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final recipe = filtered[i];
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
                              onFavorite: () => provider.toggleFavorite(recipe),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _sortLabel(String lang) {
    if (lang == 'tr') {
      switch (_sortOption) {
        case _SortOption.date:
          return 'Tarihe göre';
        case _SortOption.calories:
          return 'Kaloriye göre';
        case _SortOption.name:
          return 'İsme göre';
        case _SortOption.cookTime:
          return 'Pişirme süresine göre';
      }
    } else {
      switch (_sortOption) {
        case _SortOption.date:
          return 'By date';
        case _SortOption.calories:
          return 'By calories';
        case _SortOption.name:
          return 'By name';
        case _SortOption.cookTime:
          return 'By cook time';
      }
    }
  }
}
