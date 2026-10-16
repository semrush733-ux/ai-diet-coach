import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_plan_repository.dart';
import '../domain/local_plan.dart';

class DietState {
  const DietState({this.plan, this.profile});

  final LocalPlan? plan;
  final StoredProfile? profile;
}

/// Full local plan + profile for the My Diet tab and meal detail screens.
final dietControllerProvider =
    AsyncNotifierProvider<DietController, DietState>(DietController.new);

class DietController extends AsyncNotifier<DietState> {
  LocalPlanRepository get _repo => ref.read(localPlanRepositoryProvider);

  @override
  Future<DietState> build() async {
    final plan = await _repo.loadPlan();
    final profile = await _repo.loadProfile();
    return DietState(plan: plan, profile: profile);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final plan = await _repo.loadPlan();
      final profile = await _repo.loadProfile();
      return DietState(plan: plan, profile: profile);
    });
  }

  Future<String?> generate() async {
    final error = await _repo.generate();
    await refresh();
    return error;
  }

  Future<void> setStatus(int mealId, String status) async {
    await _repo.setMealStatus(mealId, status);
    await refresh();
  }

  Future<void> replace(int mealId, String templateId) async {
    await _repo.replaceMeal(mealId, templateId);
    await refresh();
  }

  Future<void> setScale(int mealId, double scale) async {
    await _repo.setMealScale(mealId, scale);
    await refresh();
  }
}
