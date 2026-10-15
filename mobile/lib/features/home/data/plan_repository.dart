import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/daily_plan.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  if (Env.useFakeApi) return DevFakePlanRepository();
  return ApiPlanRepository(ref.watch(apiClientProvider));
});

abstract class PlanRepository {
  /// Today's plan, or null when the user has no generated plan yet.
  Future<DailyPlan?> fetchToday();
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
}

/// DEV FAKE: no plan exists — exercises the honest empty state.
/// (We do not fabricate meal data; real plans arrive in Phase 3.)
class DevFakePlanRepository implements PlanRepository {
  @override
  Future<DailyPlan?> fetchToday() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return null;
  }
}
