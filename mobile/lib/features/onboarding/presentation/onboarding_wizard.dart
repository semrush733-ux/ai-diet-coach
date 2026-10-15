import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/units.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/states.dart';
import '../application/onboarding_controller.dart';

/// 7-page onboarding wizard (basic → goals → health → food → schedule →
/// budget → review/generate). Step 1 "Welcome" lives on the Welcome screen.
class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final _pageController = PageController();
  int _page = 0;
  bool _submitting = false;
  static const _pageCount = 7;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  bool _validateCurrent() {
    final draft = ref.read(onboardingControllerProvider);
    switch (_page) {
      case 0:
        return draft.displayName.trim().isNotEmpty;
      case 1:
        return draft.goals.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (!_validateCurrent()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.validationRequired)),
      );
      return;
    }
    if (_page < _pageCount - 1) {
      _goTo(_page + 1);
      return;
    }
    setState(() => _submitting = true);
    final error =
        await ref.read(onboardingControllerProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
    // On success the auth state flips to signedIn and the router redirects.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      appBar: AppBar(
        leading: _page > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l10n.back,
                onPressed: () => _goTo(_page - 1),
              )
            : null,
        title: Text(l10n.obStepOf(_page + 1, _pageCount),
            style: theme.textTheme.labelLarge),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_page + 1) / _pageCount,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _BasicProfileStep(),
                  _GoalsStep(),
                  _HealthStep(),
                  _FoodPreferencesStep(),
                  _ScheduleStep(),
                  _BudgetStep(),
                  _ReviewStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: AppPrimaryButton(
                label: isLast ? l10n.generateMyDiet : l10n.next,
                icon: isLast ? Icons.auto_awesome_rounded : null,
                loading: _submitting,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell(
      {required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xl),
        ...children,
      ],
    );
  }
}

// ── Step: basic profile ────────────────────────────────────────────────
class _BasicProfileStep extends ConsumerWidget {
  const _BasicProfileStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final metric = draft.unitSystem == UnitSystem.metric;

    return _StepShell(
      title: l10n.obBasicTitle,
      subtitle: l10n.obBasicSubtitle,
      children: [
        AppTextField(
          label: l10n.displayName,
          onChanged: (v) => ctrl.update((d) => d.copyWith(displayName: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l10n.age,
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              ctrl.update((d) => d.copyWith(age: int.tryParse(v))),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.units, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            SelectableChip(
              label: l10n.unitsMetric,
              selected: metric,
              onTap: () => ctrl
                  .update((d) => d.copyWith(unitSystem: UnitSystem.metric)),
            ),
            SelectableChip(
              label: l10n.unitsImperial,
              selected: !metric,
              onTap: () => ctrl.update(
                  (d) => d.copyWith(unitSystem: UnitSystem.imperial)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l10n.height,
          keyboardType: TextInputType.number,
          suffixText: metric ? 'cm' : 'in',
          helper: metric ? null : 'Total inches (e.g. 5 ft 8 in = 68)',
          onChanged: (v) {
            final value = double.tryParse(v);
            if (value == null) return;
            ctrl.update((d) => d.copyWith(
                heightCm: metric ? value : value * Units.cmPerInch));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: l10n.weight,
          keyboardType: TextInputType.number,
          suffixText: metric ? 'kg' : 'lb',
          onChanged: (v) {
            final value = double.tryParse(v);
            if (value == null) return;
            ctrl.update((d) =>
                d.copyWith(weightKg: metric ? value : Units.lbToKg(value)));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.country, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (code, name) in const [
              ('PK', 'Pakistan'),
              ('GB', 'United Kingdom'),
              ('US', 'United States'),
            ])
              SelectableChip(
                label: name,
                selected: draft.countryCode == code,
                onTap: () =>
                    ctrl.update((d) => d.copyWith(countryCode: code)),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step: goals ────────────────────────────────────────────────────────
class _GoalsStep extends ConsumerWidget {
  const _GoalsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final goals = <(String, String, IconData)>[
      ('eat_healthier', l10n.goalEatHealthier, Icons.favorite_outline),
      ('maintain_weight', l10n.goalMaintainWeight, Icons.balance_rounded),
      ('manage_weight', l10n.goalManageWeight, Icons.monitor_weight_outlined),
      ('meal_consistency', l10n.goalMealConsistency, Icons.schedule_rounded),
      ('manage_carbs', l10n.goalManageCarbs, Icons.bakery_dining_outlined),
      ('prediabetes_support', l10n.goalPrediabetes, Icons.shield_outlined),
      ('type2_support', l10n.goalType2, Icons.health_and_safety_outlined),
    ];

    return _StepShell(
      title: l10n.obGoalsTitle,
      subtitle: l10n.obGoalsSubtitle,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (code, label, icon) in goals)
              SelectableChip(
                label: label,
                icon: icon,
                selected: draft.goals.contains(code),
                onTap: () => ctrl.toggleIn((d) => d.goals, code,
                    (d, set) => d.copyWith(goals: set)),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step: health information ───────────────────────────────────────────
class _HealthStep extends ConsumerWidget {
  const _HealthStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final options = <(DiabetesStatus, String)>[
      (DiabetesStatus.none, l10n.healthNone),
      (DiabetesStatus.prediabetes, l10n.healthPrediabetes),
      (DiabetesStatus.type2, l10n.healthType2),
      (DiabetesStatus.other, l10n.healthOther),
      (DiabetesStatus.unsure, l10n.healthUnsure),
    ];

    return _StepShell(
      title: l10n.obHealthTitle,
      subtitle: l10n.obHealthSubtitle,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (status, label) in options)
              SelectableChip(
                label: label,
                selected: draft.diabetesStatus == status,
                onTap: () =>
                    ctrl.update((d) => d.copyWith(diabetesStatus: status)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.glucoseUnit, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            SelectableChip(
              label: 'mg/dL',
              selected: draft.glucoseUnit == 'mg_dl',
              onTap: () =>
                  ctrl.update((d) => d.copyWith(glucoseUnit: 'mg_dl')),
            ),
            SelectableChip(
              label: 'mmol/L',
              selected: draft.glucoseUnit == 'mmol_l',
              onTap: () =>
                  ctrl.update((d) => d.copyWith(glucoseUnit: 'mmol_l')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(l10n.healthSpecialistNote,
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step: food preferences ─────────────────────────────────────────────
class _FoodPreferencesStep extends ConsumerWidget {
  const _FoodPreferencesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final prefs = <(String, String)>[
      ('halal', l10n.prefHalal),
      ('vegetarian', l10n.prefVegetarian),
      ('vegan', l10n.prefVegan),
      ('pescatarian', l10n.prefPescatarian),
      ('omnivore', l10n.prefOmnivore),
      ('dairy_free', l10n.prefDairyFree),
      ('gluten_free', l10n.prefGlutenFree),
    ];
    final allergies = <(String, String)>[
      ('nuts', l10n.allergyNuts),
      ('shellfish', l10n.allergyShellfish),
      ('eggs', l10n.allergyEggs),
      ('milk', l10n.allergyMilk),
      ('wheat', l10n.allergyWheat),
      ('soy', l10n.allergySoy),
    ];

    return _StepShell(
      title: l10n.obFoodTitle,
      subtitle: l10n.obFoodSubtitle,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (code, label) in prefs)
              SelectableChip(
                label: label,
                selected: draft.dietaryPreferences.contains(code),
                onTap: () => ctrl.toggleIn((d) => d.dietaryPreferences, code,
                    (d, set) => d.copyWith(dietaryPreferences: set)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.allergies, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final (code, label) in allergies)
              SelectableChip(
                label: label,
                icon: Icons.warning_amber_rounded,
                selected: draft.allergies.contains(code),
                onTap: () => ctrl.toggleIn((d) => d.allergies, code,
                    (d, set) => d.copyWith(allergies: set)),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Step: schedule ─────────────────────────────────────────────────────
class _ScheduleStep extends ConsumerWidget {
  const _ScheduleStep();

  Future<void> _pick(BuildContext context, WidgetRef ref, TimeOfDay current,
      OnboardingDraft Function(OnboardingDraft, TimeOfDay) write) async {
    final picked =
        await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      ref
          .read(onboardingControllerProvider.notifier)
          .update((d) => write(d, picked));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final rows = <(String, IconData, TimeOfDay,
        OnboardingDraft Function(OnboardingDraft, TimeOfDay))>[
      (l10n.wakeTime, Icons.wb_sunny_outlined, draft.wakeTime,
          (d, t) => d.copyWith(wakeTime: t)),
      (l10n.breakfastTime, Icons.free_breakfast_outlined,
          draft.breakfastTime, (d, t) => d.copyWith(breakfastTime: t)),
      (l10n.lunchTime, Icons.lunch_dining_outlined, draft.lunchTime,
          (d, t) => d.copyWith(lunchTime: t)),
      (l10n.dinnerTime, Icons.dinner_dining_outlined, draft.dinnerTime,
          (d, t) => d.copyWith(dinnerTime: t)),
      (l10n.bedTime, Icons.bedtime_outlined, draft.bedTime,
          (d, t) => d.copyWith(bedTime: t)),
    ];

    return _StepShell(
      title: l10n.obScheduleTitle,
      subtitle: l10n.obScheduleSubtitle,
      children: [
        for (final (label, icon, time, write) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              onTap: () => _pick(context, ref, time, write),
              child: Row(
                children: [
                  Icon(icon,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  Text(time.format(context),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        SwitchListTile.adaptive(
          value: draft.wantsSnacks,
          onChanged: (v) =>
              ctrl.update((d) => d.copyWith(wantsSnacks: v)),
          title: Text(l10n.wantSnacks),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

// ── Step: budget ───────────────────────────────────────────────────────
class _BudgetStep extends ConsumerWidget {
  const _BudgetStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    final tiers = <(BudgetTier, String, IconData)>[
      (BudgetTier.budget, l10n.budgetFriendly, Icons.savings_outlined),
      (BudgetTier.balanced, l10n.budgetBalanced, Icons.tune_rounded),
      (BudgetTier.premium, l10n.budgetPremium, Icons.star_outline_rounded),
    ];

    return _StepShell(
      title: l10n.obBudgetTitle,
      subtitle: l10n.obBudgetSubtitle,
      children: [
        for (final (tier, label, icon) in tiers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              onTap: () =>
                  ctrl.update((d) => d.copyWith(budgetTier: tier)),
              child: Row(
                children: [
                  Icon(icon,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Text(label,
                          style:
                              Theme.of(context).textTheme.titleMedium)),
                  Icon(
                    draft.budgetTier == tier
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: draft.budgetTier == tier
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Step: review & generate ────────────────────────────────────────────
class _ReviewStep extends ConsumerWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = ref.watch(onboardingControllerProvider);

    String time(TimeOfDay t) => t.format(context);

    final entries = <(String, String)>[
      (l10n.displayName, draft.displayName),
      if (draft.age != null) (l10n.age, '${draft.age}'),
      if (draft.heightCm != null)
        (l10n.height, '${draft.heightCm!.toStringAsFixed(0)} cm'),
      if (draft.weightKg != null)
        (l10n.weight, '${draft.weightKg!.toStringAsFixed(1)} kg'),
      (l10n.country, draft.countryCode),
      (l10n.obGoalsTitle, draft.goals.isEmpty ? '—' : '${draft.goals.length}'),
      (l10n.breakfastTime, time(draft.breakfastTime)),
      (l10n.lunchTime, time(draft.lunchTime)),
      (l10n.dinnerTime, time(draft.dinnerTime)),
    ];

    return _StepShell(
      title: l10n.obReviewTitle,
      subtitle: l10n.obReviewSubtitle,
      children: [
        AppCard(
          child: Column(
            children: [
              for (final (label, value) in entries)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ),
                      Text(value, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.medicalDisclaimer, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
