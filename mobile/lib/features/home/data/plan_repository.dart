import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../diet_planner/data/local_plan_repository.dart';
import '../../diet_planner/domain/local_plan.dart';
import '../domain/daily_plan.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  if (Env.useFakeApi) {
    return LocalModePlanRepository(ref.watch(localPlanRepositoryProvider));
  }
  return ApiPlanRepository(ref.watch(apiClientProvider));
});

abstract class PlanRepository {
  /// Today's plan, or null when the user has no generated plan yet.
  Future<DailyPlan?> fetchToday();

  /// Generates a plan. Returns null on success or an error message.
  Future<String?> generate();

  Future<void> setMealStatus(int mealId, String status);
}

class ApiPlanRepository implements PlanRepository {
  ApiPlanRepository(this._api);
  final ApiClient _api;

  @override
  Future<DailyPlan?> fetchToday() async {
    try {
      final res = await _api.get('/meal-plans/today');
      final data = res['data'];
      if (data is Map<String, dynamic>) return DailyPlan.fromJson(data);
      return null;
    } on ApiException catch (e) {
      // 404 = no plan generated yet → legitimate empty state, not an error.
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<String?> generate() async {
    try {
      await _api.post('/meal-plans/generate', body: {'duration': '7d'});
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  @override
  Future<void> setMealStatus(int mealId, String status) async {
    try {
      await _api.patch('/planned-meals/$mealId', body: {'status': status});
    } on ApiException {
      // Server-side status sync lands in Phase 2.
    }
  }
}

/// Standalone mode: plans generated and stored on-device.
class LocalModePlanRepository implements PlanRepository {
  LocalModePlanRepository(this._local);

  final LocalPlanRepository _local;

  @override
  Future<DailyPlan?> fetchToday() async {
    final plan = await _local.loadPlan();
    final day = plan?.dayFor(DateTime.now());
    if (day == null) return null;
    return dailyPlanFromLocal(day);
  }

  @override
  Future<String?> generate() => _local.generate();

  @override
  Future<void> setMealStatus(int mealId, String status) =>
      _local.setMealStatus(mealId, status);
}

/// Maps a locally generated day to the display model used by Home.
DailyPlan dailyPlanFromLocal(LocalPlanDay day) {
  final date = DateTime.tryParse(day.date) ?? DateTime.now();
  return DailyPlan(
    date: date,
    meals: [
      for (final m in day.meals)
        PlannedMeal(
          id: m.id,
          mealType: m.mealType,
          title: m.title,
          status: m.status,
          scheduledAt: _withTime(date, m.time),
          servingLabel: null,
          caloriesKcal: m.nutrition.kcal,
          carbsG: m.nutrition.carbs,
        ),
    ],
  );
}

DateTime _withTime(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 12 : 12;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, h, m);
}
