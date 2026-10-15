import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';

/// Shown while the session is being restored; router moves on automatically.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.appName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(context.l10n.tagline,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xxl),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}
