import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/states.dart';
import '../../home/application/home_controller.dart';
import '../application/diet_controller.dart';
import '../domain/local_plan.dart';

/// My Diet tab: 7-day plan with per-day meal list and actions.
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stateAsync = ref.watch(dietControllerProvider);

    return SafeArea(
      child: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: l10n.errorGeneric,
          onRetry: () => ref.read(dietControllerProvider.notifier).refresh(),
        ),
        data: (state) {
          final plan = state.plan;
          if (plan == null || plan.days.isEmpty) {
            return EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: l10n.noPlanTitle,
              message: l10n.noPlanMessage,
              actionLabel: l10n.createPlan,
              onAction: () async {
                final error = await ref
                    .read(dietControllerProvider.notifier)
                    .generate();
                ref.read(todayPlanProvider.notifier).refresh();
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
            );
          }

          final dayIndex = _selectedDay.clamp(0, plan.days.length - 1);
          final day = plan.days[dayIndex];
          final totals = _dayTotals(day);
          final locale = Localizations.localeOf(context).toLanguageTag();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.navDiet, style: theme.textTheme.headlineMedium),
                  IconButton(
                    tooltip: l10n.regeneratePlan,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () async {
                      final error = await ref
                          .read(dietControllerProvider.notifier)
                          .generate();
                      ref.read(todayPlanProvider.notifier).refresh();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error ?? l10n.planRegenerated)));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: plan.days.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final date = DateTime.tryParse(plan.days[index].date) ??
                        DateTime.now();
                    final selected = index == dayIndex;
                    return InkWell(
                      borderRadius: AppRadius.buttonRadius,
                      onTap: () => setState(() => _selectedDay = index),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                          borderRadius: AppRadius.buttonRadius,
                          border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.E(locale).format(date),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              '${date.day}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TotalStat(
                        label: l10n.kcal,
                        value: totals.$1.round().toString()),
                    _TotalStat(
                        label: l10n.carbsShort,
                        value: '${totals.$2.round()} g'),
                    _TotalStat(
                        label: l10n.protein,
                        value: '${totals.$3.round()} g'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final meal in day.meals) _MealTile(meal: meal),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.medicalDisclaimer,
                  style: theme.textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }

  (double, double, double) _dayTotals(LocalPlanDay day) {
    double kcal = 0, carbs = 0, protein = 0;
    for (final m in day.meals) {
      final n = m.nutrition;
      kcal += n.kcal;
      carbs += n.carbs;
      protein += n.protein;
    }
    return (kcal, carbs, protein);
  }
}

class _TotalStat extends StatelessWidget {
  const _TotalStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _MealTile extends ConsumerWidget {
  const _MealTile({required this.meal});
  final LocalMeal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final n = meal.nutrition;
    final eaten = meal.status == 'eaten';
    final skipped = meal.status == 'skipped';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => context.go('/diet/meal/${meal.id}'),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(meal.mealType),
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${meal.time} · ${_slotLabel(context, meal.mealType)}',
                      style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    meal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      decoration:
                          skipped ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '${n.kcal.round()} ${l10n.kcal} · ${n.carbs.round()} g ${l10n.carbsShort}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (eaten)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success)
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.cookie_outlined;
    }
  }
}

String _slotLabel(BuildContext context, String mealType) {
  final l10n = context.l10n;
  switch (mealType) {
    case 'breakfast':
      return l10n.mealBreakfast;
    case 'lunch':
      return l10n.mealLunch;
    case 'dinner':
      return l10n.mealDinner;
    case 'morning_snack':
      return l10n.mealMorningSnack;
    case 'afternoon_snack':
      return l10n.mealAfternoonSnack;
    default:
      return l10n.mealSnack;
  }
}
