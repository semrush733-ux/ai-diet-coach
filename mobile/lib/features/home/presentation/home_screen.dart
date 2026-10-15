import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/states.dart';
import '../../authentication/application/auth_controller.dart';
import '../application/home_controller.dart';
import '../domain/daily_plan.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(todayPlanProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(todayPlanProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
              AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
          children: [
            const _HomeHeader(),
            const SizedBox(height: AppSpacing.xl),
            planAsync.when(
              loading: () => const _PlanSkeleton(),
              error: (e, _) => ErrorState(
                message: context.l10n.errorGeneric,
                onRetry: () =>
                    ref.read(todayPlanProvider.notifier).refresh(),
              ),
              data: (plan) => plan == null || plan.meals.isEmpty
                  ? _NoPlanCard(onCreate: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(context.l10n.planGenerationPending)));
                    })
                  : _PlanContent(plan: plan),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              context.l10n.medicalDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final name = (user?.displayName.isNotEmpty ?? false)
        ? user!.displayName.split(' ').first
        : '';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning(name)
        : hour < 17
            ? l10n.greetingAfternoon(name)
            : l10n.greetingEvening(name);

    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel =
        DateFormat.yMMMMEEEEd(locale).format(DateTime.now());

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            name.isEmpty ? '•' : name.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(dateLabel, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 190, radius: 20),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 20, width: 160),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 64, radius: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 64, radius: 16),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 64, radius: 16),
      ],
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: EmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: l10n.noPlanTitle,
        message: l10n.noPlanMessage,
        actionLabel: l10n.createPlan,
        onAction: onCreate,
      ),
    );
  }
}

class _PlanContent extends StatelessWidget {
  const _PlanContent({required this.plan});
  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final next = plan.nextMeal(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.todayPlanTitle),
        const SizedBox(height: AppSpacing.md),
        if (next != null) _NextMealCard(meal: next),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.todaysTimeline),
        const SizedBox(height: AppSpacing.md),
        for (final meal in plan.meals) _TimelineTile(meal: meal),
      ],
    );
  }
}

class _NextMealCard extends StatelessWidget {
  const _NextMealCard({required this.meal});
  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = meal.scheduledAt == null
        ? null
        : DateFormat.jm(locale).format(meal.scheduledAt!.toLocal());

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meal.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card)),
              child: CachedNetworkImage(
                imageUrl: meal.imageUrl!,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const SkeletonBox(height: 150, radius: 0),
                errorWidget: (_, __, ___) => Container(
                  height: 150,
                  color: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.restaurant_rounded,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time == null
                      ? l10n.nextMeal
                      : '${l10n.nextMeal} · $time',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(meal.title, style: theme.textTheme.titleLarge),
                if (meal.servingLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(meal.servingLabel!,
                      style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _NutrientPill(
                      icon: Icons.local_fire_department_outlined,
                      label: meal.caloriesKcal == null
                          ? '— ${l10n.kcal}'
                          : '${meal.caloriesKcal!.round()} ${l10n.kcal}',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _NutrientPill(
                      icon: Icons.grain_rounded,
                      label: meal.carbsG == null
                          ? '— ${l10n.carbsShort}'
                          : '${meal.carbsG!.round()} g ${l10n.carbsShort}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                          label: l10n.viewMeal, onPressed: () {}),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppSecondaryButton(
                          label: l10n.replaceMeal,
                          icon: Icons.swap_horiz_rounded,
                          onPressed: () {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  const _NutrientPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.meal});
  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = meal.scheduledAt == null
        ? '—'
        : DateFormat.jm(locale).format(meal.scheduledAt!.toLocal());
    final done = meal.status == 'eaten';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done
                  ? AppColors.success
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 72,
              child: Text(time, style: theme.textTheme.labelLarge),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                meal.title,
                style: theme.textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
