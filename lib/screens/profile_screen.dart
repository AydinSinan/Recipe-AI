import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../l10n/strings.dart';
import 'paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRestoring = false;

  Future<void> _restore(String lang) async {
    setState(() => _isRestoring = true);
    try {
      final success = await SubscriptionService.restorePurchases();
      if (!mounted) return;
      if (success) {
        await context.read<AppProvider>().refreshPremiumStatus();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? AppStrings.get('subscription_refreshed', lang)
              : (lang == 'tr'
                  ? 'Geri yüklenecek satın alma bulunamadı.'
                  : 'No purchases found to restore.')),
          backgroundColor: success ? AppTheme.secondary : AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;
    final user = provider.user;
    final isPremium = provider.isPremium;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppStrings.get('profile_title', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmSignOut(context, lang),
            tooltip: lang == 'tr' ? 'Çıkış Yap' : 'Sign Out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── User Card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.warmGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      provider.isAnonymous
                          ? '👤'
                          : (user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : '👤'),
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isAnonymous
                            ? (lang == 'tr' ? 'Misafir Kullanıcı' : 'Guest User')
                            : (user?.displayName ?? user?.email ?? ''),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (!provider.isAnonymous && user?.email != null)
                        Text(user!.email!,
                            style: GoogleFonts.lato(
                                color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? Colors.amber
                              : Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPremium
                              ? '👑 Premium'
                              : (lang == 'tr' ? '🆓 Ücretsiz Plan' : '🆓 Free Plan'),
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isPremium
                                ? AppTheme.textPrimary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Anonymous upgrade prompt ───────────────────────────────────
          if (provider.isAnonymous)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'tr'
                        ? '⚠️ Misafir modundasınız'
                        : '⚠️ You\'re in guest mode',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang == 'tr'
                        ? 'Favorileriniz ve planlarınız kaybolabilir. Hesap oluşturun.'
                        : 'Your favorites may be lost. Create an account.',
                    style: GoogleFonts.lato(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

          // ── Premium CTA ───────────────────────────────────────────────────
          if (!isPremium) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PaywallScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == 'tr'
                                ? 'Premium\'a Geç'
                                : 'Upgrade to Premium',
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.primary),
                          ),
                          Text(
                            lang == 'tr'
                                ? 'Sınırsız tarif, tüm mutfaklar, haftalık plan'
                                : 'Unlimited recipes, all cuisines, meal plan',
                            style: GoogleFonts.lato(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Subscription Management (premium kullanıcılar) ────────────────
          if (isPremium) ...[
            _sectionTitle(AppStrings.get('subscription_section', lang)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  // Aktif rozet
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Text(
                          AppStrings.get('subscription_active', lang),
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            lang == 'tr' ? 'Aktif' : 'Active',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  // Aboneliği Yönet
                  ListTile(
                    leading: const Icon(Icons.open_in_new_rounded,
                        color: AppTheme.primary, size: 22),
                    title: Text(
                      AppStrings.get('subscription_manage', lang),
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      AppStrings.get('subscription_cancel_info', lang),
                      style: GoogleFonts.lato(
                          fontSize: 12, color: AppTheme.textHint),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.primary),
                    onTap: () => SubscriptionService.manageSubscription(),
                  ),
                  const Divider(height: 1, indent: 56),
                  // Geri Yükle
                  ListTile(
                    leading: _isRestoring
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary)),
                          )
                        : const Icon(Icons.refresh_rounded,
                            color: AppTheme.textHint, size: 22),
                    title: Text(
                      AppStrings.get('subscription_restore', lang),
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary),
                    ),
                    onTap: _isRestoring ? null : () => _restore(lang),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Usage Stats ───────────────────────────────────────────────────
          _sectionTitle(lang == 'tr' ? 'KULLANIM' : 'USAGE'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                _statTile(
                  icon: '🔍',
                  label: lang == 'tr'
                      ? 'Bugünkü Aramalar'
                      : 'Today\'s Searches',
                  value: isPremium
                      ? '${provider.dailySearchCount} / ∞'
                      : '${provider.dailySearchCount} / ${provider.dailySearchLimit}',
                  showBar: !isPremium,
                  barValue: provider.dailySearchCount /
                      provider.dailySearchLimit,
                ),
                const Divider(height: 1, indent: 56),
                _statTile(
                  icon: '❤️',
                  label: lang == 'tr' ? 'Favoriler' : 'Favorites',
                  value: isPremium
                      ? '${provider.favorites.length} / ∞'
                      : '${provider.favorites.length} / ${provider.favoritesLimit}',
                  showBar: !isPremium,
                  barValue: provider.favorites.length /
                      provider.favoritesLimit,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Language ──────────────────────────────────────────────────────
          _sectionTitle(AppStrings.get('language_settings', lang)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                _langTile(context, '🇹🇷', 'Türkçe', 'tr', lang, provider),
                const Divider(height: 1, indent: 56),
                _langTile(context, '🇬🇧', 'English', 'en', lang, provider),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _sectionTitle(lang == 'tr' ? 'UYGULAMA' : 'APP'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                const Text('🍳', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.get('app_name', lang),
                        style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Version 1.0.0 • Powered by Claude AI',
                        style: GoogleFonts.lato(
                            fontSize: 12, color: AppTheme.textHint)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.lato(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppTheme.textHint,
      letterSpacing: 1.2,
    ),
  );

  Widget _statTile({
    required String icon,
    required String label,
    required String value,
    bool showBar = false,
    double barValue = 0,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      Text(value,
                          style: GoogleFonts.lato(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ],
                  ),
                  if (showBar) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: barValue.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          barValue >= 1.0 ? AppTheme.error : AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _langTile(BuildContext context, String flag, String name,
      String code, String current, AppProvider provider) =>
      ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(name,
            style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
        trailing: code == current
            ? const Icon(Icons.check_circle_rounded,
                color: AppTheme.primary)
            : null,
        onTap: () => provider.setLanguage(code),
      );

  void _confirmSignOut(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang == 'tr' ? 'Çıkış Yap' : 'Sign Out'),
        content: Text(lang == 'tr'
            ? 'Hesabınızdan çıkmak istediğinize emin misiniz?'
            : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang == 'tr' ? 'İptal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppProvider>().signOut();
            },
            child: Text(lang == 'tr' ? 'Çıkış Yap' : 'Sign Out',
                style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
