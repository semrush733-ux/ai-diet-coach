import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../application/plan_generator.dart';
import '../domain/local_plan.dart';

final localPlanRepositoryProvider = Provider<LocalPlanRepository>(
    (ref) => LocalPlanRepository(ref.watch(localStoreProvider)));

/// On-device plan + profile persistence and plan actions (standalone mode).
class LocalPlanRepository {
  LocalPlanRepository(this._store);

  final LocalStore _store;

  Future<StoredProfile?> loadProfile() async {
    final json = await _store.readJson(StoreKeys.profile);
    return json == null ? null : StoredProfile.fromJson(json);
  }

  Future<void> saveProfile(StoredProfile profile) =>
      _store.writeJson(StoreKeys.profile, profile.toJson());

  Future<LocalPlan?> loadPlan() async {
    final json = await _store.readJson(StoreKeys.plan);
    return json == null ? null : LocalPlan.fromJson(json);
  }

  Future<void> savePlan(LocalPlan plan) =>
      _store.writeJson(StoreKeys.plan, plan.toJson());

  /// Generates (or regenerates) a 7-day plan from the stored profile.
  /// Returns null on success, or an error message.
  Future<String?> generate() async {
    final profile = await loadProfile();
    if (profile == null) {
      return 'Please complete onboarding first so the plan can be personalized.';
    }
    final plan = PlanGenerator.generate(profile, days: 7);
    await savePlan(plan);
    return null;
  }

  Future<void> setMealStatus(int mealId, String status) async {
    final plan = await loadPlan();
    if (plan == null) return;
    final meal = plan.mealById(mealId);
    if (meal == null) return;
    meal.status = status;
    await savePlan(plan);
  }

  Future<void> replaceMeal(int mealId, String newTemplateId) async {
    final plan = await loadPlan();
    if (plan == null) return;
    final meal = plan.mealById(mealId);
    if (meal == null) return;
    meal.templateId = newTemplateId;
    meal.status = 'planned';
    await savePlan(plan);
  }

  Future<void> setMealScale(int mealId, double scale) async {
    final plan = await loadPlan();
    if (plan == null) return;
    final meal = plan.mealById(mealId);
    if (meal == null) return;
    meal.scale = double.parse(scale.clamp(0.5, 2.5).toStringAsFixed(2));
    await savePlan(plan);
  }
}
