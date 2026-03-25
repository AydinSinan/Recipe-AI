import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Stream ────────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final result = await _auth.signInWithPopup(provider);
        await _createOrUpdateUser(result.user!);
        return result;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        await _createOrUpdateUser(result.user!);
        return result;
      }
    } catch (e) {
      throw Exception('Google giriş hatası: $e');
    }
  }

  // ── Apple Sign In ─────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple ile giriş sadece iOS/macOS\'ta desteklenir.');
    }
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('fullName');
      final result = await _auth.signInWithProvider(provider);
      await _createOrUpdateUser(result.user!);
      return result;
    } catch (e) {
      throw Exception('Apple giriş hatası: $e');
    }
  }

  // ── Email & Password ──────────────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user!.updateDisplayName(displayName);
      await _createOrUpdateUser(result.user!);
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _createOrUpdateUser(result.user!);
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Şifre sıfırlama hatası: $e');
    }
  }

  // ── Link Anonymous → Google ───────────────────────────────────────────────
  Future<UserCredential?> linkAnonymousWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final result = await _auth.currentUser!.linkWithPopup(provider);
        await _createOrUpdateUser(result.user!);
        return result;
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await _auth.currentUser!.linkWithCredential(credential);
        await _createOrUpdateUser(result.user!);
        return result;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Hesap zaten var — normal giriş yap
        return await signInWithGoogle();
      }
      throw Exception('Hesap bağlama hatası: ${e.message}');
    }
  }

  // ── Anonymous ─────────────────────────────────────────────────────────────
  Future<UserCredential> signInAnonymously() async {
    try {
      // Anonim kullanıcı için Firestore'a yazma — sadece Firebase Auth yeterli
      final result = await _auth.signInAnonymously();
      return result;
    } catch (e) {
      throw Exception('Anonim giriş hatası: $e');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // ── Firestore User Doc ────────────────────────────────────────────────────
  Future<void> _createOrUpdateUser(User user) async {
    // Anonim kullanıcılar için Firestore işlemi yapma
    if (user.isAnonymous) return;

    try {
      final ref = _db.collection('users').doc(user.uid);
      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'Kullanıcı',
          'photoUrl': user.photoURL ?? '',
          'isAnonymous': false,
          'isPremium': false,
          'dailySearchCount': 0,
          'dailySearchDate': DateTime.now().toIso8601String().substring(0, 10),
          'totalSearchCount': 0,
          'favoritesCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'language': 'tr',
        });
      } else {
        final data = doc.data() ?? {};
        await ref.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'email': user.email ?? data['email'] ?? '',
          'displayName': user.displayName ?? data['displayName'] ?? 'Kullanıcı',
        });
      }
    } catch (e) {
      // Firestore hatası girişi engellemez
      debugPrint('Firestore user update error: $e');
    }
  }

  // ── User Data ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('getUserData error: $e');
      return null;
    }
  }

  Stream<DocumentSnapshot> get userStream {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    return _db.collection('users').doc(user.uid).snapshots();
  }

  // ── Search Count ──────────────────────────────────────────────────────────
  Future<bool> canSearch(bool isPremium) async {
    if (isPremium) return true;
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.isAnonymous) return true; // Anonim: local limit app_provider'da

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastDate = data['dailySearchDate'] ?? '';
      final count = lastDate == today ? (data['dailySearchCount'] ?? 0) : 0;
      return count < 5;
    } catch (e) {
      return true;
    }
  }

  Future<void> incrementSearchCount() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final ref = _db.collection('users').doc(user.uid);
      final doc = await ref.get();
      final data = doc.data() ?? {};
      final lastDate = data['dailySearchDate'] ?? '';
      final currentCount =
          lastDate == today ? (data['dailySearchCount'] ?? 0) : 0;

      await ref.update({
        'dailySearchCount': currentCount + 1,
        'dailySearchDate': today,
        'totalSearchCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('incrementSearchCount error: $e');
    }
  }

  // ── Error Handler ─────────────────────────────────────────────────────────
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Bu e-posta ile kayıtlı kullanıcı bulunamadı.');
      case 'wrong-password':
        return Exception('Hatalı şifre.');
      case 'email-already-in-use':
        return Exception('Bu e-posta zaten kullanımda.');
      case 'weak-password':
        return Exception('Şifre çok zayıf. En az 6 karakter olmalı.');
      case 'invalid-email':
        return Exception('Geçersiz e-posta adresi.');
      default:
        return Exception('Giriş hatası: ${e.message}');
    }
  }
}
