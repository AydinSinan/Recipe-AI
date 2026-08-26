import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/app_provider.dart';
import '../services/subscription_service.dart';
import '../theme.dart';

class PaywallScreen extends StatefulWidget {
  final String? reason; // neden açıldı
  const PaywallScreen({super.key, this.reason});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      _offerings = await SubscriptionService.getOfferings();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchase() async {
    if (_offerings == null) return;
    setState(() => _isPurchasing = true);

    try {
      final offering = _offerings!.current;
      if (offering == null) throw Exception('Ürün bulunamadı');

      final package = offering.monthly;

      if (package == null) throw Exception('Paket bulunamadı');

      final success = await SubscriptionService.purchase(package);
      if (success && mounted) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        await context.read<AppProvider>().refreshPremiumStatus();
        if (mounted) {
          navigator.pop(true);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('🎉 Premium\'a hoş geldiniz!'),
              backgroundColor: AppTheme.secondary,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    try {
      final success = await SubscriptionService.restorePurchases();
      if (success && mounted) {
        final navigator = Navigator.of(context);
        await context.read<AppProvider>().refreshPremiumStatus();
        if (mounted) navigator.pop(true);
      } else if (mounted) {
        setState(() => _error = 'Geri yüklenecek satın alma bulunamadı.');
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppProvider>().language;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primary)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.warmGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 52)),
                        const SizedBox(height: 12),
                        Text(
                          lang == 'tr'
                              ? 'Premium\'a Geç'
                              : 'Upgrade to Premium',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.reason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.reason!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Features ──────────────────────────────────────────────
                  _featureRow('🔍',
                      lang == 'tr' ? 'Sınırsız günlük arama' : 'Unlimited daily searches',
                      lang == 'tr' ? 'Free: 2/gün' : 'Free: 2/day'),
                  _featureRow('🌍',
                      lang == 'tr' ? 'Tüm dünya mutfakları' : 'All world cuisines',
                      lang == 'tr' ? 'Free: 2 mutfak' : 'Free: 2 cuisines'),
                  _featureRow('🍽️',
                      lang == 'tr' ? 'Arama başına 8 tarif' : '8 recipes per search',
                      lang == 'tr' ? 'Free: 4 tarif' : 'Free: 4 recipes'),
                  _featureRow('❤️',
                      lang == 'tr' ? 'Sınırsız favori' : 'Unlimited favorites',
                      lang == 'tr' ? 'Free: 5 favori' : 'Free: 5 favorites'),
                  _featureRow('📅',
                      lang == 'tr' ? 'Haftalık yemek planı' : 'Weekly meal planner',
                      lang == 'tr' ? 'Sadece Premium' : 'Premium only'),
                  _featureRow('🚫',
                      lang == 'tr' ? 'Reklamsız deneyim' : 'Ad-free experience',
                      ''),

                  const SizedBox(height: 24),

                  // ── Plan ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang == 'tr' ? 'Aylık' : 'Monthly',
                            style: GoogleFonts.lato(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Text('₺99',
                            style: GoogleFonts.lato(
                                fontSize: 13, color: AppTheme.textHint)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13)),
                    ),

                  // ── CTA ───────────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17)),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : Text(
                              lang == 'tr'
                                  ? 'Aylık Planı Başlat — ₺99/ay'
                                  : 'Start Monthly — ₺99/month',
                              style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _isPurchasing ? null : _restore,
                    child: Text(
                      lang == 'tr'
                          ? 'Satın Almaları Geri Yükle'
                          : 'Restore Purchases',
                      style: GoogleFonts.lato(
                          color: AppTheme.textHint, fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    lang == 'tr'
                        ? 'İstediğiniz zaman iptal edebilirsiniz.\nFiyatlar KDV dahildir.'
                        : 'Cancel anytime.\nPrices include VAT.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                        fontSize: 11,
                        color: AppTheme.textHint,
                        height: 1.5),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _featureRow(String emoji, String title, String subtitle) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: GoogleFonts.lato(
                            fontSize: 12, color: AppTheme.textHint)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.secondary, size: 22),
          ],
        ),
      );
}
