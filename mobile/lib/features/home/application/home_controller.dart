import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
