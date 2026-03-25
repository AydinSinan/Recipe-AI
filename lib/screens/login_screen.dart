import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePass = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _emailAuth() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final provider = context.read<AppProvider>();
    try {
      if (_isSignUp) {
        await provider.signUpWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
      } else {
        await provider.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      }
      // Başarılı giriş → ana sayfaya git
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final lang = provider.language;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: AppTheme.warmGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                    child: Text('🍳', style: TextStyle(fontSize: 46))),
              ),

              const SizedBox(height: 24),
              Text(
                lang == 'tr'
                    ? 'TarifAI\'ye Hoş Geldiniz'
                    : 'Welcome to RecipeAI',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lang == 'tr'
                    ? 'Dünya mutfaklarını keşfetmek için giriş yapın'
                    : 'Sign in to explore world cuisines',
                style: GoogleFonts.lato(
                    fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              if (!_showEmailForm) ...[
                // ── Social Buttons ───────────────────────────────────────
                _socialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: lang == 'tr'
                      ? 'Google ile Devam Et'
                      : 'Continue with Google',
                  onTap: () async {
                    await context.read<AppProvider>().signInWithGoogle();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (!kIsWeb) ...[
                  _socialButton(
                    icon: Icons.apple_rounded,
                    label: lang == 'tr'
                        ? 'Apple ile Devam Et'
                        : 'Continue with Apple',
                    onTap: () => provider.signInWithApple(),
                  ),
                  const SizedBox(height: 12),
                ],
                _socialButton(
                  icon: Icons.email_outlined,
                  label: lang == 'tr'
                      ? 'E-posta ile Devam Et'
                      : 'Continue with Email',
                  onTap: () => setState(() => _showEmailForm = true),
                ),

                const SizedBox(height: 28),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('veya',
                        style: TextStyle(color: AppTheme.textHint)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // ── Anonim giriş ─────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    await context.read<AppProvider>().signInAnonymously();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                  child: Text(
                    lang == 'tr'
                        ? 'Giriş yapmadan devam et →'
                        : 'Continue without signing in →',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang == 'tr'
                      ? 'Günde 5 arama • Kaydetme yok'
                      : '5 searches/day • No saving',
                  style:
                      GoogleFonts.lato(fontSize: 12, color: AppTheme.textHint),
                ),
              ] else ...[
                // ── Email Form ───────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showEmailForm = false),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isSignUp
                          ? (lang == 'tr' ? 'Hesap Oluştur' : 'Create Account')
                          : (lang == 'tr' ? 'Giriş Yap' : 'Sign In'),
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isSignUp) ...[
                  _field(
                    controller: _nameCtrl,
                    hint: lang == 'tr' ? 'Adınız' : 'Your name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                ],

                _field(
                  controller: _emailCtrl,
                  hint: lang == 'tr' ? 'E-posta' : 'Email',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _passCtrl,
                  hint: lang == 'tr' ? 'Şifre' : 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textHint,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),

                // Şifre field'ından sonra, _errorMsg'den önce
                if (!_isSignUp) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        if (_emailCtrl.text.trim().isEmpty) {
                          setState(() =>
                              _errorMsg = 'Lütfen e-posta adresinizi girin');
                          return;
                        }
                        try {
                          await context
                              .read<AppProvider>()
                              .resetPassword(_emailCtrl.text.trim());
                          if (mounted) {
                            setState(() => _errorMsg = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Şifre sıfırlama maili gönderildi')),
                            );
                          }
                        } catch (e) {
                          setState(() => _errorMsg =
                              e.toString().replaceAll('Exception: ', ''));
                        }
                      },
                      child: Text(
                        'Şifremi Unuttum',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                if (_errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMsg!,
                        style: GoogleFonts.lato(
                            color: AppTheme.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _emailAuth,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          )
                        : Text(_isSignUp
                            ? (lang == 'tr' ? 'Kayıt Ol' : 'Sign Up')
                            : (lang == 'tr' ? 'Giriş Yap' : 'Sign In')),
                  ),
                ),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? (lang == 'tr'
                            ? 'Zaten hesabın var mı? Giriş yap'
                            : 'Already have an account? Sign in')
                        : (lang == 'tr'
                            ? 'Hesabın yok mu? Kayıt ol'
                            : "Don't have an account? Sign up"),
                    style: GoogleFonts.lato(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
              Text(
                lang == 'tr'
                    ? 'Devam ederek Gizlilik Politikamızı ve\nKullanım Koşullarımızı kabul etmiş olursunuz.'
                    : 'By continuing, you agree to our\nPrivacy Policy and Terms of Service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                    fontSize: 11, color: AppTheme.textHint, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 22),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textHint, size: 20),
          suffixIcon: suffix,
        ),
      );
}
