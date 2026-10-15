import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/l10n_ext.dart';
import '../../features/authentication/application/auth_controller.dart';
import '../../features/authentication/presentation/auth_form_screens.dart';
import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_wizard.dart';
import '../shell/main_shell.dart';
import 'routes.dart';

/// Bridges Riverpod auth state into GoRouter's refreshListenable.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      final inAuthFlow = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.signUp ||
          location == AppRoutes.forgotPassword;

      switch (auth.status) {
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.signedOut:
          return inAuthFlow ? null : AppRoutes.welcome;
        case AuthStatus.needsOnboarding:
          return location == AppRoutes.onboarding
              ? null
              : AppRoutes.onboarding;
        case AuthStatus.signedIn:
          final onMainTabs = location.startsWith(AppRoutes.home) ||
              location.startsWith(AppRoutes.diet) ||
              location.startsWith(AppRoutes.sugar) ||
              location.startsWith(AppRoutes.progress);
          return onMainTabs ? null : AppRoutes.home;
      }
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.welcome,
          builder: (_, __) => const WelcomeScreen()),
      GoRoute(
          path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.signUp,
          builder: (_, __) => const SignUpScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingWizard()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.diet,
              builder: (context, _) => ComingSoonTab(
                icon: Icons.restaurant_menu_rounded,
                message: context.l10n.dietTabPlaceholder,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.sugar,
              builder: (context, _) => ComingSoonTab(
                icon: Icons.water_drop_rounded,
                message: context.l10n.sugarTabPlaceholder,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.progress,
              builder: (context, _) => ComingSoonTab(
                icon: Icons.insights_rounded,
                message: context.l10n.progressTabPlaceholder,
              ),
            ),
          ]),
        ],
      ),
    ],
  );
});
