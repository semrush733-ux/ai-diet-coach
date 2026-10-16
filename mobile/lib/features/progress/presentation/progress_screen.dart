import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/states.dart';
import '../../diet_planner/data/local_plan_repository.dart';
import '../../glucose/data/tracking_repository.dart';

class _ProgressData {
  const _ProgressData({
    required this.weights,
    required this.waterToday,
    required this.mealsEaten,
    required this.mealsPlanned,
    required this.glucoseAvg7d,
  });

  final List<WeightEntry> weights;
  final int waterToday;
  final int mealsEaten;
  final int mealsPlanned;
  final double? glucoseAvg7d;
}

final _progressProvider =
    FutureProvider.autoDispose<_ProgressData>((ref) async {
  final tracking = ref.watch(trackingRepositoryProvider);
  final planRepo = ref.watch(localPlanRepositoryProvider);

  final weights = await tracking.weights();
  final water = await tracking.waterToday();
  final plan = await planRepo.loadPlan();
  final glucose = await tracking.glucose();

  var eaten = 0;
  var planned = 0;
  final today = DateTime.now();
  if (plan != null) {
    for (final day in plan.days) {
      final date = DateTime.tryParse(day.date);
      if (date == null || date.isAfter(today)) continue;
      for (final meal in day.meals) {
        planned++;
        if (meal.status == 'eaten') eaten++;
      }
    }
  }

  final cutoff = today.subtract(const Duration(days: 7));
  final recent =
      glucose.where((e) => e.measuredAt.isAfter(cutoff)).toList();
  double? avg;
  if (recent.isNotEmpty) {
    avg = recent.fold<double>(0, (s, e) => s + e.valueMgDl) /
        recent.length;
  }

  return _ProgressData(
    weights: weights,
    waterToday: water,
    mealsEaten: eaten,
    mealsPlanned: planned,
    glucoseAvg7d: avg,
  );
});

/// Progress tab: weight log, water tracker, plan adherence, glucose average.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dataAsync = ref.watch(_progressProvider);

    return SafeArea(
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: l10n.errorGeneric),
        data: (data) {
          final locale = Localizations.localeOf(context).toLanguageTag();
          final latestWeight =
              data.weights.isEmpty ? null : data.weights.first;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Text(l10n.navProgress,
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),

              // Adherence + glucose summary row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.mealsCompleted,
                              style: theme.textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            data.mealsPlanned == 0
                                ? '—'
                                : '${data.mealsEaten}/${data.mealsPlanned}',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.glucoseAvg7d,
                              style: theme.textTheme.labelSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            data.glucoseAvg7d == null
                                ? '—'
                                : '${data.glucoseAvg7d!.round()}',
                            style: theme.textTheme.headlineMedium,
                          ),
                          if (data.glucoseAvg7d != null)
                            Text('mg/dL',
                                style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Water tracker
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.waterToday,
                            style: theme.textTheme.titleMedium),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded),
                              onPressed: data.waterToday <= 0
                                  ? null
                                  : () async {
                                      await ref
                                          .read(
                                              trackingRepositoryProvider)
                                          .setWaterToday(
                                              data.waterToday - 1);
                                      ref.invalidate(_progressProvider);
                                    },
                            ),
                            Text('${data.waterToday}',
                                style: theme.textTheme.titleLarge),
                            IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline_rounded),
                              onPressed: () async {
                                await ref
                                    .read(trackingRepositoryProvider)
                                    .setWaterToday(
                                        data.waterToday + 1);
                                ref.invalidate(_progressProvider);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < 8; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.water_drop_rounded,
                              size: 22,
                              color: i < data.waterToday
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Weight
              SectionHeader(
                title: l10n.weight,
                actionLabel: l10n.add,
                onAction: () => _showAddWeight(context, ref),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (latestWeight == null)
                Text(l10n.noWeightYet,
                    style: theme.textTheme.bodyMedium)
              else
                AppCard(
                  child: Column(
                    children: [
                      for (final entry in data.weights.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat.yMMMd(locale)
                                      .format(entry.recordedAt),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              Text(
                                  '${entry.weightKg.toStringAsFixed(1)} kg',
                                  style:
                                      theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
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

  void _showAddWeight(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.add} ${l10n.weight}'),
        content: AppTextField(
          label: l10n.weight,
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          suffixText: 'kg',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 20 || value > 500) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.validationNumber)));
                return;
              }
              await ref
                  .read(trackingRepositoryProvider)
                  .addWeight(value);
              ref.invalidate(_progressProvider);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
