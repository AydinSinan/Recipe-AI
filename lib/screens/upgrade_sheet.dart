import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../l10n/strings.dart';

class UpgradeSheet extends StatefulWidget {
  const UpgradeSheet({super.key});

  @override
  State<UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<UpgradeSheet> {
  bool _loading = false;

  Future<void> _onGoogle() async {
    setState(() => _loading = true);
    final provider = context.read<AppProvider>();
    final lang = provider.language;
    final success = await provider.linkAnonymousWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.get(
            success ? 'upgrade_success' : 'upgrade_error', lang)),
        backgroundColor: success ? AppTheme.secondary : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppProvider>().language;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            AppStrings.get('upgrade_title', lang),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            AppStrings.get('upgrade_subtitle', lang),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Benefits
          _benefit(Icons.favorite_rounded, AppStrings.get('upgrade_benefit_1', lang)),
          const SizedBox(height: 10),
          _benefit(Icons.shopping_cart_rounded, AppStrings.get('upgrade_benefit_2', lang)),
          const SizedBox(height: 10),
          _benefit(Icons.refresh_rounded, AppStrings.get('upgrade_benefit_3', lang)),
          const SizedBox(height: 28),

          // Google button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _onGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: Text(
                AppStrings.get('upgrade_google', lang),
                style: GoogleFonts.lato(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Later button
          TextButton(
            onPressed: _loading
                ? null
                : () {
                    context.read<AppProvider>().dismissUpgradePrompt();
                    Navigator.of(context).pop();
                  },
            child: Text(
              AppStrings.get('upgrade_later', lang),
              style: GoogleFonts.lato(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String text) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.secondary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.lato(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      );
}
