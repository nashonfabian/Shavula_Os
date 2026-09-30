import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db_helper.dart';

const String _kSessionUserIdKey = 'shavula_session_user_id';

/// Matokeo ya kujisajili/kuingia - yanaonesha kama yamefanyika
/// mtandaoni (online) au kwa kutumia data ya ndani tu (offline).
class AuthResult {
  final String userId;
  final String email;
  final String? fullName;
  final bool wasOffline;

  AuthResult({
    required this.userId,
    required this.email,
    this.fullName,
    required this.wasOffline,
  });
}

class AuthHelper {
  final supabase = Supabase.instance.client;
  static const _passwordHashIterations = 120000;
  static final _passwordKdf = Pbkdf2.hmacSha256(
    iterations: _passwordHashIterations,
    bits: 256,
  );

  String _legacyPasswordHash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<String> _hashPassword(String password) async {
    final secureRandom = math.Random.secure();
    final salt = List<int>.generate(16, (_) => secureRandom.nextInt(256));
    final key = await _passwordKdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final hash = await key.extractBytes();
    return 'pbkdf2-sha256\$$_passwordHashIterations\$'
        '${base64Url.encode(salt)}\$${base64Url.encode(hash)}';
  }

  Future<bool> _verifyPassword(String password, String? storedHash) async {
    if (storedHash == null || storedHash.isEmpty) return false;

    final parts = storedHash.split('\$');
    if (parts.length == 4 && parts[0] == 'pbkdf2-sha256') {
      final iterations = int.tryParse(parts[1]);
      if (iterations != _passwordHashIterations) return false;
      try {
        final salt = base64Url.decode(parts[2]);
        final expectedHash = base64Url.decode(parts[3]);
        final key = await _passwordKdf.deriveKeyFromPassword(
          password: password,
          nonce: salt,
        );
        return _constantTimeEquals(await key.extractBytes(), expectedHash);
      } on FormatException {
        return false;
      }
    }

    return _constantTimeEquals(
      utf8.encode(_legacyPasswordHash(password)),
      utf8.encode(storedHash),
    );
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }

  /// Hifadhi userId ya sasa kwenye kifaa ili app isimuulize mtumiaji
  /// kuingia tena kila akifungua app (session persistence).
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionUserIdKey, userId);
  }

  /// Futa session iliyohifadhiwa - hutumika wakati wa logout.
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionUserIdKey);
  }

  /// Angalia kama kuna mtumiaji aliyeshaingia awali (session iliyohifadhiwa),
  /// na kama ndivyo, mrudishie taarifa zake kutoka SQLite ili main.dart
  /// aweze kumpeleka moja kwa moja SupplierHomePage bila LoginPage.
  Future<AuthResult?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString(_kSessionUserIdKey);
    if (savedUserId == null) return null;

    final localUser = await DatabaseHelper.instance.getUserById(savedUserId);
    if (localUser == null) {
      // Session ipo lakini data ya mtumiaji haipo tena SQLite - futa session
      // chakavu badala ya kumuachia app katika hali isiyoeleweka.
      await _clearSession();
      return null;
    }

    return AuthResult(
      userId: localUser['id'] as String,
      email: localUser['email'] as String? ?? '',
      fullName: localUser['full_name'] as String?,
      wasOffline: true,
    );
  }

  // 1. Kujisajili (Register)
  Future<AuthResult?> registerUser(
    String email,
    String password,
    String fullName,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    late AuthResponse res;
    try {
      res = await supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': fullName,
          'account_type': 'supplier',
        },
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw Exception(
          'Imeshindwa kuunganisha na mtandao. Usajili wa kwanza unahitaji internet.');
    }

    final user = res.user;
    if (user == null) {
      throw Exception('Usajili haukufanikiwa. Jaribu tena.');
    }

    // Supabase returns no session until email confirmation when confirmation
    // is enabled. Do not cache the account or grant app access in that case.
    if (res.session == null) return null;

    final passwordHash = await _hashPassword(password);
    await DatabaseHelper.instance.insertOrUpdate('users', {
      'id': user.id,
      'full_name': fullName,
      'email': cleanEmail,
      'password_hash': passwordHash,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_synced': 1,
    });

    await _saveSession(user.id);

    return AuthResult(
      userId: user.id,
      email: cleanEmail,
      fullName: fullName,
      wasOffline: false,
    );
  }

  // 2. Kuingia (Login) - Online kwanza, Offline kama hifadhi (fallback)
  Future<AuthResult> loginUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    late AuthResponse res;
    try {
      res = await supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
    } on AuthRetryableFetchException {
      return _loginOffline(cleanEmail, password);
    } on AuthException {
      rethrow;
    } catch (_) {
      return _loginOffline(cleanEmail, password);
    }

    final user = res.user;
    if (user == null) throw Exception('Kuingia hakukufanikiwa.');

    final existing = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    final passwordHash = await _hashPassword(password);
    await DatabaseHelper.instance.insertOrUpdate('users', {
      'id': user.id,
      'full_name': existing?['full_name'],
      'email': cleanEmail,
      'password_hash': passwordHash,
      'created_at': existing?['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_synced': 1,
    });

    await _saveSession(user.id);

    return AuthResult(
      userId: user.id,
      email: cleanEmail,
      fullName: existing?['full_name'] as String?,
      wasOffline: false,
    );
  }

  Future<AuthResult> _loginOffline(String email, String password) async {
    final localUser = await DatabaseHelper.instance.getUserByEmail(email);
    if (localUser == null) {
      throw Exception(
          'Hakuna mtandao na hujawahi kuingia na akaunti hii kwenye kifaa hiki.');
    }

    final storedHash = localUser['password_hash'] as String?;
    if (!await _verifyPassword(password, storedHash)) {
      throw Exception('Barua pepe au namba ya siri si sahihi.');
    }

    if (storedHash != null && !storedHash.startsWith('pbkdf2-sha256\$')) {
      await DatabaseHelper.instance.insertOrUpdate('users', {
        ...localUser,
        'password_hash': await _hashPassword(password),
        'is_synced': 1,
      });
    }

    await _saveSession(localUser['id'] as String);
    return AuthResult(
      userId: localUser['id'] as String,
      email: email,
      fullName: localUser['full_name'] as String?,
      wasOffline: true,
    );
  }

  // 3. Kutoka (Logout)
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {
      // Ikiwa hakuna mtandao, bado tunaruhusu logout ya local session.
    }
    await _clearSession();
  }
}
