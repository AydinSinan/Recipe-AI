import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'tr';
  final List<String> _selectedCuisines = [];

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const List<Map<String, String>> _cuisines = [
    {'tr': 'Akdeniz', 'en': 'Mediterranean', 'flag': '🌊'},
    {'tr': 'Anadolu', 'en': 'Anatolian', 'flag': '🇹🇷'},
    {'tr': 'Meksika', 'en': 'Mexican', 'flag': '🇲🇽'},
    {'tr': 'Uzak Doğu', 'en': 'Far East', 'flag': '🥢'},
    {'tr': 'Hint', 'en': 'Indian', 'flag': '🇮🇳'},
    {'tr': 'İtalyan', 'en': 'Italian', 'flag': '🇮🇹'},
    {'tr': 'Fransız', 'en': 'French', 'flag': '🇫🇷'},
    {'tr': 'Orta Doğu', 'en': 'Middle East', 'flag': '🌙'},
    {'tr': 'Amerikan', 'en': 'American', 'flag': '🇺🇸'},
    {'tr': 'Tayland', 'en': 'Thai', 'flag': '🇹🇭'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _animatePageChange() {
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    final provider = context.read<AppProvider>();
    await provider.setLanguage(_selectedLanguage);

    // Seçilen mutfakları kaydet
    for (final cuisine in _selectedCuisines) {
      provider.toggleCuisine(cuisine);
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 24),
                child: _currentPage < 4
                    ? GestureDetector(
                        onTap: _finish,
                        child: Text(
                          _selectedLanguage == 'tr' ? 'Geç' : 'Skip',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animatePageChange();
                },
                children: [
                  _buildWelcomePage(),
                  _buildLanguagePage(),
                  _buildCuisinePage(),
                  _buildPremiumPage(),
                  _buildNotificationPage(),
                ],
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => _buildDot(i)),
                  ),
                  const SizedBox(height: 24),
                  // Next button — son sayfada gizle (kendi butonu var)
                  if (_currentPage < 4)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ),
                        child: Text(
                          _selectedLanguage == 'tr' ? 'İleri' : 'Next',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.primary : AppTheme.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Page 1: Welcome ───────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🍳', style: TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'RecipeAI',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Elinizdeki malzemelerle\ndünyayı keşfedin'
                    : 'Explore the world with\ningredients you have',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              _buildFeatureRow(
                  '🌍',
                  _selectedLanguage == 'tr'
                      ? '20+ dünya mutfağı'
                      : '20+ world cuisines'),
              const SizedBox(height: 16),
              _buildFeatureRow(
                  '⚡',
                  _selectedLanguage == 'tr'
                      ? 'Saniyeler içinde tarif'
                      : 'Recipes in seconds'),
              const SizedBox(height: 16),
              _buildFeatureRow(
                  '🥗',
                  _selectedLanguage == 'tr'
                      ? 'Kalori & besin değerleri'
                      : 'Calories & nutrition'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 15,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Page 2: Language ──────────────────────────────────────────────────────
  Widget _buildLanguagePage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌐', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 32),
              Text(
                _selectedLanguage == 'tr' ? 'Dil Seçin' : 'Choose Language',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Tercih ettiğiniz dili seçin'
                    : 'Select your preferred language',
                style: GoogleFonts.lato(
                    fontSize: 15, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              _buildLanguageCard(
                flag: '🇹🇷',
                name: 'Türkçe',
                subtitle: 'Turkish',
                value: 'tr',
              ),
              const SizedBox(height: 16),
              _buildLanguageCard(
                flag: '🇬🇧',
                name: 'English',
                subtitle: 'İngilizce',
                value: 'en',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String flag,
    required String name,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    )),
                Text(subtitle,
                    style: GoogleFonts.lato(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
            const Spacer(),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // ── Page 3: Cuisine Preferences ───────────────────────────────────────────
  Widget _buildCuisinePage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('🥘', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Mutfak Tercihleriniz'
                    : 'Your Cuisine Preferences',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Sevdiğiniz mutfakları seçin (isteğe bağlı)'
                    : 'Select cuisines you love (optional)',
                style: GoogleFonts.lato(
                    fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _cuisines.map((c) {
                      final key = c['tr']!;
                      final isSelected = _selectedCuisines.contains(key);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCuisines.remove(key);
                            } else {
                              _selectedCuisines.add(key);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.divider,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.25),
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
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                _selectedLanguage == 'tr' ? c['tr']! : c['en']!,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 4: Premium ───────────────────────────────────────────────────────
  Widget _buildPremiumPage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _selectedLanguage == 'tr' ? 'Premium\'a Geçin' : 'Go Premium',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Sınırsız tarif, tüm özellikler'
                    : 'Unlimited recipes, all features',
                style: GoogleFonts.lato(
                    fontSize: 15, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              _buildPremiumFeature(
                  '🔓',
                  _selectedLanguage == 'tr'
                      ? 'Sınırsız arama'
                      : 'Unlimited searches'),
              const SizedBox(height: 14),
              _buildPremiumFeature(
                  '🌍',
                  _selectedLanguage == 'tr'
                      ? 'Tüm dünya mutfakları'
                      : 'All world cuisines'),
              const SizedBox(height: 14),
              _buildPremiumFeature(
                  '❤️',
                  _selectedLanguage == 'tr'
                      ? 'Sınırsız favori'
                      : 'Unlimited favorites'),
              const SizedBox(height: 14),
              _buildPremiumFeature(
                  '📅',
                  _selectedLanguage == 'tr'
                      ? 'Haftalık yemek planı'
                      : 'Weekly meal plan'),
              const SizedBox(height: 14),
              _buildPremiumFeature(
                  '🚫',
                  _selectedLanguage == 'tr'
                      ? 'Reklamsız deneyim'
                      : 'Ad-free experience'),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.4)),
                ),
                child: Text(
                  _selectedLanguage == 'tr'
                      ? '₺99/ay · İlk 7 gün ücretsiz deneyin'
                      : '\$4.99/mo · Try free for 7 days',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFA500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF4CAF50), size: 20),
      ],
    );
  }

  // ── Page 5: Notifications ─────────────────────────────────────────────────
  Widget _buildNotificationPage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: Text('🔔', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _selectedLanguage == 'tr' ? 'Bildirimler' : 'Notifications',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedLanguage == 'tr'
                    ? 'Günlük yemek önerileri ve\nyeni özelliklerden haberdar olun'
                    : 'Get daily meal suggestions and\nstay updated with new features',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: Text(
                    _selectedLanguage == 'tr'
                        ? '🔔 Bildirimlere İzin Ver'
                        : '🔔 Allow Notifications',
                    style: GoogleFonts.lato(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _finish,
                child: Text(
                  _selectedLanguage == 'tr' ? 'Şimdi değil' : 'Not now',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: AppTheme.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
