import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/states.dart';
import '../../foods/data/food_catalog.dart';
import '../../home/application/home_controller.dart';
import '../application/diet_controller.dart';
import '../application/plan_generator.dart';
import '../domain/local_plan.dart';

/// Meal detail: ingredients with grams, nutrition breakdown, serving size,
/// eaten/skip, and the Replace This Meal flow with nutrition deltas.
class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key, required this.mealId});

  final int mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stateAsync = ref.watch(dietControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/diet'),
        ),
        title: Text(l10n.mealDetails),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: l10n.errorGeneric),
        data: (state) {
          final meal = state.plan?.mealById(mealId);
          final template = meal?.template;
          if (meal == null || template == null) {
            return ErrorState(message: l10n.errorGeneric);
          }
          final n = meal.nutrition;
          final ctrl = ref.read(dietControllerProvider.notifier);

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Text(meal.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${meal.time} · ${template.cuisine.isEmpty ? l10n.mealSnack : template.cuisine} · ${template.prepMinutes} min',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Nutrition card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.nutrition, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Nutrient(label: l10n.kcal, value: n.kcal.round().toString()),
                        _Nutrient(label: l10n.carbsShort, value: '${n.carbs.round()} g'),
                        _Nutrient(label: l10n.protein, value: '${n.protein.round()} g'),
                        _Nutrient(label: l10n.fat, value: '${n.fat.round()} g'),
                        _Nutrient(label: l10n.fiber, value: '${n.fiber.round()} g'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Serving size
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.servingSize,
                          style: theme.textTheme.titleMedium),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: meal.scale <= 0.5
                          ? null
                          : () => ctrl.setScale(mealId, meal.scale - 0.25),
                    ),
                    Text('${(meal.scale * 100).round()}%',
                        style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: meal.scale >= 2.5
                          ? null
                          : () => ctrl.setScale(mealId, meal.scale + 0.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Ingredients
              Text(l10n.ingredients, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    for (final entry in template.components.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 8,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                FoodCatalog.foods[entry.key]?.name ??
                                    entry.key,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              '${(entry.value * meal.scale).round()} g',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: meal.status == 'eaten'
                          ? l10n.mealEatenDone
                          : l10n.markEaten,
                      icon: Icons.check_rounded,
                      onPressed: meal.status == 'eaten'
                          ? null
                          : () async {
                              await ctrl.setStatus(mealId, 'eaten');
                              ref
                                  .read(todayPlanProvider.notifier)
                                  .refresh();
                            },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppSecondaryButton(
                      label: l10n.skip,
                      icon: Icons.close_rounded,
                      onPressed: () async {
                        await ctrl.setStatus(mealId, 'skipped');
                        ref.read(todayPlanProvider.notifier).refresh();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                label: l10n.replaceThisMeal,
                icon: Icons.swap_horiz_rounded,
                onPressed: () =>
                    _showReplaceSheet(context, ref, state, meal),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.medicalDisclaimer,
                  style: theme.textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }

  void _showReplaceSheet(BuildContext context, WidgetRef ref,
      DietState state, LocalMeal meal) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = state.profile ?? const StoredProfile(displayName: '');
    final options = PlanGenerator.alternatives(profile, meal);
    final current = meal.nutrition;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (options.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.noAlternatives,
                style: theme.textTheme.bodyLarge),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0,
                AppSpacing.gutter, AppSpacing.xl),
            children: [
              Text(l10n.replaceWith, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final option in options)
                Builder(builder: (context) {
                  final n = FoodCatalog.nutritionOf(option, 1);
                  final deltaKcal = n.kcal - current.kcal;
                  final deltaCarbs = n.carbs - current.carbs;
                  String signed(double v, String unit) =>
                      '${v >= 0 ? '+' : ''}${v.round()} $unit';
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await ref
                            .read(dietControllerProvider.notifier)
                            .replace(meal.id, option.id);
                        ref.read(todayPlanProvider.notifier).refresh();
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(option.name,
                                    style:
                                        theme.textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${n.kcal.round()} ${l10n.kcal} (${signed(deltaKcal, l10n.kcal)}) · ${n.carbs.round()} g ${l10n.carbsShort} (${signed(deltaCarbs, 'g')})',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz_rounded),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _Nutrient extends StatelessWidget {
  const _Nutrient({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
