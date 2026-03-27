import 'package:recipe_ai/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/upgrade_sheet.dart';
import 'screens/splash_screen.dart';
import 'services/subscription_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'l10n/strings.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await SubscriptionService.initialize();
    await NotificationService.initialize();
    await NotificationService.subscribeToLanguageTopics('tr');
  }

  // Onboarding daha önce tamamlandı mı?
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  FlutterNativeSplash.remove();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: RecipeAIApp(showOnboarding: !onboardingDone),
    ),
  );
}

class RecipeAIApp extends StatelessWidget {
  final bool showOnboarding;
  const RecipeAIApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppSplash(showOnboarding: showOnboarding),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AuthGate(),
      },
    );
  }
}

// ── App Splash — animasyon biter, sonra AuthGate/Onboarding'e geç ────────────
class AppSplash extends StatefulWidget {
  final bool showOnboarding;
  const AppSplash({super.key, required this.showOnboarding});

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              widget.showOnboarding ? const OnboardingScreen() : const AuthGate(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.isAuthLoading) {
      return const Scaffold(backgroundColor: AppTheme.background);
    }

    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
    MealPlanScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;

    if (provider.showUpgradePrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const UpgradeSheet(),
        );
      });
    } else if (provider.errorMessage != null &&
        (provider.errorMessage!.contains('Premium') ||
            provider.errorMessage!.contains('limit'))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DraggableScrollableSheet(
            initialChildSize: 0.92,
            builder: (_, ctrl) => PaywallScreen(
              reason: provider.errorMessage,
            ),
          ),
        ).then((_) => provider.clearError());
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: provider.selectedTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          border:
              const Border(top: BorderSide(color: AppTheme.divider, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context: context,
                  icon: Icons.search_rounded,
                  label: AppStrings.get('nav_search', lang),
                  index: 0,
                  provider: provider,
                ),
                _navItem(
                  context: context,
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: AppStrings.get('nav_favorites', lang),
                  index: 1,
                  provider: provider,
                  badge: provider.favorites.isNotEmpty
                      ? '${provider.favorites.length}'
                      : null,
                ),
                _navItem(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: AppStrings.get('nav_meal_plan', lang),
                  index: 2,
                  provider: provider,
                  lockForFree: !provider.isPremium,
                ),
                _navItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: AppStrings.get('nav_profile', lang),
                  index: 3,
                  provider: provider,
                  showDot: !provider.isPremium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required int index,
    required AppProvider provider,
    String? badge,
    bool showDot = false,
    bool lockForFree = false,
  }) {
    final isActive = index == provider.selectedTab;
    return GestureDetector(
      onTap: () {
        if (lockForFree) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaywallScreen(
                reason: provider.language == 'tr'
                    ? 'Haftalık yemek planı Premium\'a özeldir'
                    : 'Weekly meal plan is a Premium feature',
              ),
            ),
          );
          return;
        }
        provider.setTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? (activeIcon ?? icon) : icon,
                  color: lockForFree
                      ? AppTheme.textHint
                      : isActive
                          ? AppTheme.primary
                          : AppTheme.textHint,
                  size: 24,
                ),
                if (lockForFree)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Text('🔒', style: TextStyle(fontSize: 10)),
                  ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (showDot && !lockForFree)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
