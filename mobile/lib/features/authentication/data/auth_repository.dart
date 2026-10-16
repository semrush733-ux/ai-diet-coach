import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Env.useFakeApi) {
    // Standalone mode (selected via --dart-define=USE_FAKE_API=true):
    // accounts live on this device only.
    return DevFakeAuthRepository(
        ref.watch(tokenStorageProvider), ref.watch(localStoreProvider));
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
/// Standalone-mode auth — clearly labeled development adapter.
/// Lets the app run end-to-end without a backend. Accounts and the session
/// are stored on this device only (SharedPreferences). Not a server record.
/// ─────────────────────────────────────────────────────────────────────
class DevFakeAuthRepository implements AuthRepository {
  DevFakeAuthRepository(this._tokens, this._store);

  final TokenStorage _tokens;
  final LocalStore _store;

  Future<Map<String, dynamic>> _accounts() async =>
      await _store.readJson(StoreKeys.devAccounts) ?? <String, dynamic>{};

  AuthUser _userFromSession(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num?)?.toInt() ?? 1,
        email: '${json['email'] ?? ''}',
        displayName: '${json['name'] ?? ''}',
        emailVerified: true,
        onboarded: json['onboarded'] == true,
      );

  Future<AuthUser> _saveSession({
    required int id,
    required String email,
    required String name,
    required bool onboarded,
  }) async {
    await _store.writeJson(StoreKeys.devSession, {
      'id': id,
      'email': email,
      'name': name,
      'onboarded': onboarded,
    });
    await _tokens.write('dev-local-token');
    return AuthUser(
      id: id,
      email: email,
      displayName: name,
      emailVerified: true,
      onboarded: onboarded,
    );
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final session = await _store.readJson(StoreKeys.devSession);
    return session == null ? null : _userFromSession(session);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final accounts = await _accounts();
    if (accounts.containsKey(email)) {
      throw const ApiException(
        code: 'validation_error',
        message: 'That email is already registered on this device.',
        statusCode: 422,
        fieldErrors: {
          'email': ['That email is already registered on this device.']
        },
      );
    }
    accounts[email] = {'name': name, 'password': password, 'onboarded': false};
    await _store.writeJson(StoreKeys.devAccounts, accounts);
    return _saveSession(
        id: accounts.length, email: email, name: name, onboarded: false);
  }

  @override
  Future<AuthUser> login(
      {required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final accounts = await _accounts();
    final account = accounts[email];
    if (account is! Map || '${account['password']}' != password) {
      throw const ApiException(
        code: 'invalid_credentials',
        message: 'Email or password is incorrect.',
        statusCode: 401,
      );
    }
    return _saveSession(
      id: 1,
      email: email,
      name: '${account['name'] ?? ''}',
      onboarded: account['onboarded'] == true,
    );
  }

  /// Persists the onboarded flag for the active session + account.
  Future<void> markOnboarded() async {
    final session = await _store.readJson(StoreKeys.devSession);
    if (session != null) {
      session['onboarded'] = true;
      await _store.writeJson(StoreKeys.devSession, session);
      final accounts = await _accounts();
      final email = '${session['email']}';
      final account = accounts[email];
      if (account is Map) {
        account['onboarded'] = true;
        accounts[email] = account;
        await _store.writeJson(StoreKeys.devAccounts, accounts);
      }
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> logout() async {
    await _store.remove(StoreKeys.devSession);
    await _tokens.clear();
  }
}
