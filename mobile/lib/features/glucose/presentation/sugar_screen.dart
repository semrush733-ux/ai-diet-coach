import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/states.dart';
import '../data/tracking_repository.dart';

final _sugarDataProvider = FutureProvider.autoDispose(
    (ref) async {
  final repo = ref.watch(trackingRepositoryProvider);
  final glucose = await repo.glucose();
  final hba1c = await repo.hba1c();
  return (glucose, hba1c);
});

/// Sugar tab: glucose readings with both units, 7-day trend, HbA1c history.
class SugarScreen extends ConsumerWidget {
  const SugarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dataAsync = ref.watch(_sugarDataProvider);

    return SafeArea(
      child: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: l10n.errorGeneric),
        data: (data) {
          final glucose = data.$1;
          final hba1c = data.$2;
          final latest = glucose.isEmpty ? null : glucose.first;
          final locale = Localizations.localeOf(context).toLanguageTag();

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.navSugar,
                      style: theme.textTheme.headlineMedium),
                  FilledButton.icon(
                    onPressed: () => _showAddSheet(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.addReading),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (latest == null)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.water_drop_rounded,
                    title: l10n.noReadingsTitle,
                    message: l10n.noReadingsMessage,
                    actionLabel: l10n.addReading,
                    onAction: () => _showAddSheet(context, ref),
                  ),
                )
              else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.latestReading,
                          style: theme.textTheme.labelSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${latest.valueMgDl.round()}',
                              style: theme.textTheme.displaySmall),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                                'mg/dL · ${latest.valueMmolL.toStringAsFixed(1)} mmol/L',
                                style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_contextLabel(context, latest.context)} · ${DateFormat.MMMd(locale).add_jm().format(latest.measuredAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: l10n.last7Days),
                const SizedBox(height: AppSpacing.md),
                AppCard(child: _TrendBars(entries: glucose)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: l10n.hba1c,
                actionLabel: l10n.add,
                onAction: () => _showHbA1cDialog(context, ref),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (hba1c.isEmpty)
                Text(l10n.noHba1c, style: theme.textTheme.bodyMedium)
              else
                AppCard(
                  child: Column(
                    children: [
                      for (final entry in hba1c.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                    DateFormat.yMMMd(locale)
                                        .format(entry.testedAt),
                                    style: theme.textTheme.bodyLarge),
                              ),
                              Text('${entry.valuePercent}%',
                                  style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (glucose.isNotEmpty) ...[
                SectionHeader(title: l10n.glucoseHistory),
                const SizedBox(height: AppSpacing.sm),
                for (final entry in glucose.take(14))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.valueOriginal} ${entry.unitOriginal == 'mg_dl' ? 'mg/dL' : 'mmol/L'}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${_contextLabel(context, entry.context)} · ${DateFormat.MMMd(locale).add_jm().format(entry.measuredAt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(
                                Icons.delete_outline_rounded),
                            onPressed: () async {
                              await ref
                                  .read(trackingRepositoryProvider)
                                  .deleteGlucose(entry.id);
                              ref.invalidate(_sugarDataProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l10n.medicalDisclaimer,
                  style: theme.textTheme.bodySmall),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final valueController = TextEditingController();
    var unit = 'mg_dl';
    var readingContext = 'fasting';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                MediaQuery.of(context).viewInsets.bottom +
                    AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.addReading,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.value,
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  suffixText: unit == 'mg_dl' ? 'mg/dL' : 'mmol/L',
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    SelectableChip(
                      label: 'mg/dL',
                      selected: unit == 'mg_dl',
                      onTap: () => setState(() => unit = 'mg_dl'),
                    ),
                    SelectableChip(
                      label: 'mmol/L',
                      selected: unit == 'mmol_l',
                      onTap: () => setState(() => unit = 'mmol_l'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in const [
                      'fasting',
                      'before_breakfast',
                      'after_breakfast',
                      'before_lunch',
                      'after_lunch',
                      'before_dinner',
                      'after_dinner',
                      'bedtime',
                      'random',
                    ])
                      SelectableChip(
                        label: _contextLabel(context, c),
                        selected: readingContext == c,
                        onTap: () =>
                            setState(() => readingContext = c),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: l10n.save,
                  onPressed: () async {
                    final value =
                        double.tryParse(valueController.text.trim());
                    final max = unit == 'mg_dl' ? 1000.0 : 55.5;
                    if (value == null || value <= 0 || value > max) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(l10n.validationNumber)));
                      return;
                    }
                    await ref
                        .read(trackingRepositoryProvider)
                        .addGlucose(
                            value: value,
                            unit: unit,
                            context: readingContext);
                    ref.invalidate(_sugarDataProvider);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showHbA1cDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.add} ${l10n.hba1c}'),
        content: AppTextField(
          label: l10n.value,
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          suffixText: '%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 3 || value > 20) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.validationNumber)));
                return;
              }
              await ref
                  .read(trackingRepositoryProvider)
                  .addHbA1c(value);
              ref.invalidate(_sugarDataProvider);
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

String _contextLabel(BuildContext context, String code) {
  final l10n = context.l10n;
  switch (code) {
    case 'fasting':
      return l10n.ctxFasting;
    case 'before_breakfast':
      return l10n.ctxBeforeBreakfast;
    case 'after_breakfast':
      return l10n.ctxAfterBreakfast;
    case 'before_lunch':
      return l10n.ctxBeforeLunch;
    case 'after_lunch':
      return l10n.ctxAfterLunch;
    case 'before_dinner':
      return l10n.ctxBeforeDinner;
    case 'after_dinner':
      return l10n.ctxAfterDinner;
    case 'bedtime':
      return l10n.ctxBedtime;
    default:
      return l10n.ctxRandom;
  }
}

/// Simple last-7-days bar trend (daily averages, mg/dL).
class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.entries});

  final List<GlucoseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = <DateTime>[
      for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)
    ];

    final averages = <double?>[];
    for (final day in days) {
      final dayEntries = entries.where((e) =>
          e.measuredAt.year == day.year &&
          e.measuredAt.month == day.month &&
          e.measuredAt.day == day.day);
      if (dayEntries.isEmpty) {
        averages.add(null);
      } else {
        final sum = dayEntries.fold<double>(0, (s, e) => s + e.valueMgDl);
        averages.add(sum / dayEntries.length);
      }
    }

    final values = averages.whereType<double>().toList();
    final maxValue = values.isEmpty
        ? 200.0
        : values
            .reduce((a, b) => a > b ? a : b)
            .clamp(120.0, 400.0)
            .toDouble();

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (averages[i] != null)
                      Text('${averages[i]!.round()}',
                          style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      height: averages[i] == null
                          ? 6.0
                          : (90 * averages[i]! / maxValue)
                              .clamp(8.0, 90.0)
                              .toDouble(),
                      decoration: BoxDecoration(
                        color: averages[i] == null
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.E(Localizations.localeOf(context)
                              .toLanguageTag())
                          .format(days[i])
                          .substring(0, 1),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
