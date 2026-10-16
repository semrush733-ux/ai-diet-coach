import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../authentication/application/auth_controller.dart';
import '../../diet_planner/data/local_plan_repository.dart';
import '../../diet_planner/domain/local_plan.dart';

enum UnitSystem { metric, imperial }

enum DiabetesStatus { none, prediabetes, type2, other, unsure }

enum BudgetTier { budget, balanced, premium }

/// Mutable wizard draft — everything the 8-step onboarding collects.
class OnboardingDraft {
  const OnboardingDraft({
    this.displayName = '',
    this.age,
    this.heightCm,
    this.weightKg,
    this.unitSystem = UnitSystem.metric,
    this.countryCode = 'PK',
    this.goals = const {},
    this.diabetesStatus,
    this.glucoseUnit = 'mg_dl',
    this.dietaryPreferences = const {},
    this.allergies = const {},
    this.wakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.breakfastTime = const TimeOfDay(hour: 8, minute: 0),
    this.lunchTime = const TimeOfDay(hour: 13, minute: 30),
    this.dinnerTime = const TimeOfDay(hour: 19, minute: 30),
    this.bedTime = const TimeOfDay(hour: 23, minute: 0),
    this.wantsSnacks = true,
    this.budgetTier = BudgetTier.balanced,
  });

  final String displayName;
  final int? age;
  final double? heightCm; // canonical metric
  final double? weightKg; // canonical metric
  final UnitSystem unitSystem;
  final String countryCode;
  final Set<String> goals;
  final DiabetesStatus? diabetesStatus;
  final String glucoseUnit;
  final Set<String> dietaryPreferences;
  final Set<String> allergies;
  final TimeOfDay wakeTime;
  final TimeOfDay breakfastTime;
  final TimeOfDay lunchTime;
  final TimeOfDay dinnerTime;
  final TimeOfDay bedTime;
  final bool wantsSnacks;
  final BudgetTier budgetTier;

  OnboardingDraft copyWith({
    String? displayName,
    int? age,
    double? heightCm,
    double? weightKg,
    UnitSystem? unitSystem,
    String? countryCode,
    Set<String>? goals,
    DiabetesStatus? diabetesStatus,
    String? glucoseUnit,
    Set<String>? dietaryPreferences,
    Set<String>? allergies,
    TimeOfDay? wakeTime,
    TimeOfDay? breakfastTime,
    TimeOfDay? lunchTime,
    TimeOfDay? dinnerTime,
    TimeOfDay? bedTime,
    bool? wantsSnacks,
    BudgetTier? budgetTier,
  }) =>
      OnboardingDraft(
        displayName: displayName ?? this.displayName,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        unitSystem: unitSystem ?? this.unitSystem,
        countryCode: countryCode ?? this.countryCode,
        goals: goals ?? this.goals,
        diabetesStatus: diabetesStatus ?? this.diabetesStatus,
        glucoseUnit: glucoseUnit ?? this.glucoseUnit,
        dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
        allergies: allergies ?? this.allergies,
        wakeTime: wakeTime ?? this.wakeTime,
        breakfastTime: breakfastTime ?? this.breakfastTime,
        lunchTime: lunchTime ?? this.lunchTime,
        dinnerTime: dinnerTime ?? this.dinnerTime,
        bedTime: bedTime ?? this.bedTime,
        wantsSnacks: wantsSnacks ?? this.wantsSnacks,
        budgetTier: budgetTier ?? this.budgetTier,
      );

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toPayload() => {
        'profile': {
          'display_name': displayName,
          'age': age,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'unit_system': unitSystem.name,
          'country_code': countryCode,
        },
        'goals': goals.toList(),
        'health': {
          'diabetes_status': diabetesStatus?.name ?? 'not_disclosed',
          'glucose_unit': glucoseUnit,
        },
        'dietary_preferences': dietaryPreferences.toList(),
        'allergies': allergies.toList(),
        'schedule': {
          'wake_time': _fmt(wakeTime),
          'breakfast_time': _fmt(breakfastTime),
          'lunch_time': _fmt(lunchTime),
          'dinner_time': _fmt(dinnerTime),
          'bed_time': _fmt(bedTime),
          'wants_snacks': wantsSnacks,
        },
        'budget': {'tier': budgetTier.name},
      };
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
        OnboardingController.new);

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void update(OnboardingDraft Function(OnboardingDraft) change) =>
      state = change(state);

  void toggleIn(Set<String> Function(OnboardingDraft) select, String code,
      OnboardingDraft Function(OnboardingDraft, Set<String>) write) {
    final set = {...select(state)};
    set.contains(code) ? set.remove(code) : set.add(code);
    state = write(state, set);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Submits the completed wizard. Returns error message or null on success.
  Future<String?> submit() async {
    if (Env.useFakeApi) {
      // Standalone mode: persist the profile on-device and generate the
      // first 7-day plan immediately.
      final draft = state;
      final repo = ref.read(localPlanRepositoryProvider);
      await repo.saveProfile(StoredProfile(
        displayName: draft.displayName,
        age: draft.age,
        heightCm: draft.heightCm,
        weightKg: draft.weightKg,
        countryCode: draft.countryCode,
        goals: draft.goals.toList(),
        dietaryPreferences: draft.dietaryPreferences.toList(),
        allergies: draft.allergies.toList(),
        breakfastTime: _fmtTime(draft.breakfastTime),
        lunchTime: _fmtTime(draft.lunchTime),
        dinnerTime: _fmtTime(draft.dinnerTime),
        wantsSnacks: draft.wantsSnacks,
        budgetTier: draft.budgetTier == BudgetTier.budget
            ? 1
            : draft.budgetTier == BudgetTier.premium
                ? 3
                : 2,
        glucoseUnit: draft.glucoseUnit,
      ));
      final error = await repo.generate();
      if (error != null) return error;
      ref.read(authControllerProvider.notifier).markOnboarded();
      return null;
    }
    try {
      await ref
          .read(apiClientProvider)
          .post('/onboarding/complete', body: state.toPayload());
      ref.read(authControllerProvider.notifier).markOnboarded();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
