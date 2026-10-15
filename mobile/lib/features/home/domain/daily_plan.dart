/// Today's plan as served by GET /meal-plans/today.
class DailyPlan {
  const DailyPlan({required this.date, required this.meals});

  final DateTime date;
  final List<PlannedMeal> meals;

  /// The next meal that is still planned, by scheduled time.
  PlannedMeal? nextMeal(DateTime now) {
    final upcoming = meals
        .where((m) =>
            m.status == 'planned' &&
            (m.scheduledAt == null || m.scheduledAt!.isAfter(now)))
        .toList()
      ..sort((a, b) => (a.scheduledAt ?? now).compareTo(b.scheduledAt ?? now));
    if (upcoming.isNotEmpty) return upcoming.first;
    final planned = meals.where((m) => m.status == 'planned');
    return planned.isEmpty ? null : planned.first;
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
        meals: [
          for (final m in (json['meals'] as List? ?? const []))
            if (m is Map<String, dynamic>) PlannedMeal.fromJson(m),
        ],
      );
}

class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.mealType,
    required this.title,
    required this.status,
    this.scheduledAt,
    this.imageUrl,
    this.servingLabel,
    this.caloriesKcal,
    this.carbsG,
  });

  final int id;
  final String mealType; // breakfast / morning_snack / ...
  final String title;
  final String status; // planned / eaten / skipped / replaced
  final DateTime? scheduledAt;
  final String? imageUrl;
  final String? servingLabel;

  /// Nullable on purpose: missing nutrition data stays missing — the UI
  /// shows a dash rather than a fabricated number.
  final double? caloriesKcal;
  final double? carbsG;

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition_snapshot'];
    double? num_(dynamic v) => v == null ? null : (v as num).toDouble();
    return PlannedMeal(
      id: (json['id'] as num).toInt(),
      mealType: '${json['meal_type'] ?? 'meal'}',
      title: '${json['title'] ?? json['name'] ?? ''}',
      status: '${json['status'] ?? 'planned'}',
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.tryParse('${json['scheduled_at']}'),
      imageUrl: json['image_url'] as String?,
      servingLabel: json['serving_label'] as String?,
      caloriesKcal: nutrition is Map
          ? num_(nutrition['calories_kcal'])
          : num_(json['calories_kcal']),
      carbsG:
          nutrition is Map ? num_(nutrition['carbs_g']) : num_(json['carbs_g']),
    );
  }
}
