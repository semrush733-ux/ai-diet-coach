import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useFakeApi) {
    // DEV-ONLY in-memory fake, selected via --dart-define=USE_FAKE_API=true.
    return DevFakeAuthRepository(ref.watch(tokenStorageProvider));
  }
  return ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract class AuthRepository {
  /// Returns the current user if a valid session token exists, else null.
  Future<AuthUser?> restoreSession();

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthUser> login({required String email, required String password});

  Future<void> forgotPassword(String email);

  Future<void> logout();
}

/// Real backend implementation (Laravel Sanctum).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _tokens.read();
    if (token == null) return null;
    try {
      final res = await _api.get('/profile');
      final data = res['data'];
      if (data is Map<String, dynamic>) return AuthUser.fromJson(data);
      return null;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      // Network problems should not log the user out.
      if (e.isNetwork) rethrow;
      return null;
    }
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'device_name': 'mobile',
    });
    return _storeSession(res);
  }

  @override
  Future<AuthUser> login(
      {required String email, required String password}) async {
    final res = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
      'device_name': 'mobile',
    });
    return _storeSession(res);
  }

  Future<AuthUser> _storeSession(Map<String, dynamic> res) async {
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    final token = data['token'] as String?;
    if (token != null) await _tokens.write(token);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  @override
  Future<void> forgotPassword(String email) =>
      _api.post('/auth/forgot-password', body: {'email': email});

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Best effort: local session is cleared regardless.
    } finally {
      await _tokens.clear();
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────
/// DEV FAKE — clearly labeled development adapter.
/// Lets the app run end-to-end without a backend. Data lives in memory
/// for the app session only; nothing here is a real user record.
/// Never ship with USE_FAKE_API=true.
/// ─────────────────────────────────────────────────────────────────────
class DevFakeAuthRepository implements AuthRepository {
  DevFakeAuthRepository(this._tokens);

  final TokenStorage _tokens;
  final Map<String, ({String name, String password})> _accounts = {};
  AuthUser? _current;

  @override
  Future<AuthUser?> restoreSession() async => _current;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (_accounts.containsKey(email)) {
      throw const ApiException(
        code: 'validation_error',
        message: 'That email is already registered.',
        statusCode: 422,
        fieldErrors: {
          'email': ['That email is already registered.']
        },
      );
    }
    _accounts[email] = (name: name, password: password);
    await _tokens.write('dev-fake-token');
    _current = AuthUser(
      id: _accounts.length,
      email: email,
      displayName: name,
      emailVerified: true, // dev convenience, labeled
      onboarded: false,
    );
    return _current!;
  }

  @override
  Future<AuthUser> login(
      {required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final account = _accounts[email];
    if (account == null || account.password != password) {
      throw const ApiException(
        code: 'invalid_credentials',
        message: 'Email or password is incorrect.',
        statusCode: 401,
      );
    }
    await _tokens.write('dev-fake-token');
    _current = AuthUser(
      id: 1,
      email: email,
      displayName: account.name,
      emailVerified: true,
      onboarded: false,
    );
    return _current!;
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> logout() async {
    _current = null;
    await _tokens.clear();
  }
}
