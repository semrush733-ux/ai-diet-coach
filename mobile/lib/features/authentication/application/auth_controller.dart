import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

/// Overall session status that drives router redirects.
enum AuthStatus { unknown, signedOut, needsOnboarding, signedIn }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool busy;
  final ApiException? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? busy,
    ApiException? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState();
  }

  AuthStatus _statusFor(AuthUser? user) {
    if (user == null) return AuthStatus.signedOut;
    return user.onboarded ? AuthStatus.signedIn : AuthStatus.needsOnboarding;
  }

  Future<void> restore() async {
    try {
      final user = await _repo.restoreSession();
      state = AuthState(status: _statusFor(user), user: user);
    } on ApiException {
      // Offline at launch: keep user signed out of guarded areas but don't
      // destroy the stored token; next launch retries.
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<bool> register(
      {required String name,
      required String email,
      required String password}) async {
    return _run(() => _repo.register(
        name: name.trim(), email: email.trim(), password: password));
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() => _repo.login(email: email.trim(), password: password));
  }

  Future<bool> _run(Future<AuthUser> Function() action) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(status: _statusFor(user), user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repo.forgotPassword(email.trim());
      state = state.copyWith(busy: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(busy: false, error: e);
      return false;
    }
  }

  /// Called by onboarding when the server confirms completion.
  void markOnboarded() {
    final user = state.user?.copyWith(onboarded: true);
    state = AuthState(status: AuthStatus.signedIn, user: user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.signedOut);
  }
}
