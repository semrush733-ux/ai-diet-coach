import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Rounded surface card with the design-system soft shadow (light mode)
/// or outline (dark mode).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.cardRadius,
        border: isDark ? Border.all(color: theme.colorScheme.outline) : null,
        boxShadow: isDark ? null : AppShadows.soft,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
