import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet_planner/application/diet_controller.dart';
import '../data/plan_repository.dart';
import '../domain/daily_plan.dart';

/// Loads today's plan. AsyncValue drives loading/error/empty/success states.
final todayPlanProvider =
    AsyncNotifierProvider<TodayPlanController, DailyPlan?>(
        TodayPlanController.new);

class TodayPlanController extends AsyncNotifier<DailyPlan?> {
  @override
  Future<DailyPlan?> build() =>
      ref.watch(planRepositoryProvider).fetchToday();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(planRepositoryProvider).fetchToday());
  }

  /// Generates a plan and refreshes. Returns null on success, else error.
  Future<String?> generateNow() async {
    state = const AsyncLoading();
    final error = await ref.read(planRepositoryProvider).generate();
    state = await AsyncValue.guard(
        () => ref.read(planRepositoryProvider).fetchToday());
    ref.invalidate(dietControllerProvider);
    return error;
  }

  Future<void> setStatus(int mealId, String status) async {
    await ref.read(planRepositoryProvider).setMealStatus(mealId, status);
    await refresh();
  }
}
