import '../../foods/data/food_catalog.dart';

/// Stored user profile used by the local planner (standalone mode).
class StoredProfile {
  const StoredProfile({
    required this.displayName,
    this.age,
    this.heightCm,
    this.weightKg,
    this.countryCode = 'PK',
    this.goals = const [],
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.breakfastTime = '08:00',
    this.lunchTime = '13:30',
    this.dinnerTime = '19:30',
    this.wantsSnacks = true,
    this.budgetTier = 2,
    this.glucoseUnit = 'mg_dl',
  });

  final String displayName;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String countryCode;
  final List<String> goals;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final bool wantsSnacks;
  final int budgetTier; // 1..3
  final String glucoseUnit;

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'country_code': countryCode,
        'goals': goals,
        'dietary_preferences': dietaryPreferences,
        'allergies': allergies,
        'breakfast_time': breakfastTime,
        'lunch_time': lunchTime,
        'dinner_time': dinnerTime,
        'wants_snacks': wantsSnacks,
        'budget_tier': budgetTier,
        'glucose_unit': glucoseUnit,
      };

  factory StoredProfile.fromJson(Map<String, dynamic> json) => StoredProfile(
        displayName: '${json['display_name'] ?? ''}',
        age: (json['age'] as num?)?.toInt(),
        heightCm: (json['height_cm'] as num?)?.toDouble(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        countryCode: '${json['country_code'] ?? 'PK'}',
        goals: [for (final g in (json['goals'] as List? ?? [])) '$g'],
        dietaryPreferences: [
          for (final g in (json['dietary_preferences'] as List? ?? [])) '$g'
        ],
        allergies: [for (final g in (json['allergies'] as List? ?? [])) '$g'],
        breakfastTime: '${json['breakfast_time'] ?? '08:00'}',
        lunchTime: '${json['lunch_time'] ?? '13:30'}',
        dinnerTime: '${json['dinner_time'] ?? '19:30'}',
        wantsSnacks: json['wants_snacks'] != false,
        budgetTier: (json['budget_tier'] as num?)?.toInt() ?? 2,
        glucoseUnit: '${json['glucose_unit'] ?? 'mg_dl'}',
      );
}

/// One planned meal in the locally generated plan.
class LocalMeal {
  LocalMeal({
    required this.id,
    required this.mealType,
    required this.templateId,
    required this.time, // "HH:mm"
    this.scale = 1.0,
    this.status = 'planned',
  });

  final int id;
  final String mealType; // breakfast/morning_snack/lunch/afternoon_snack/dinner
  String templateId;
  final String time;
  double scale;
  String status; // planned/eaten/skipped

  MealTemplate? get template => FoodCatalog.templateById(templateId);

  MealNutrition get nutrition {
    final t = template;
    if (t == null) {
      return const MealNutrition(
          kcal: 0, carbs: 0, protein: 0, fat: 0, fiber: 0);
    }
    return FoodCatalog.nutritionOf(t, scale);
  }

  String get title => template?.name ?? 'Meal';

  Map<String, dynamic> toJson() => {
        'id': id,
        'meal_type': mealType,
        'template_id': templateId,
        'time': time,
        'scale': scale,
        'status': status,
      };

  factory LocalMeal.fromJson(Map<String, dynamic> json) => LocalMeal(
        id: (json['id'] as num).toInt(),
        mealType: '${json['meal_type']}',
        templateId: '${json['template_id']}',
        time: '${json['time'] ?? '12:00'}',
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        status: '${json['status'] ?? 'planned'}',
      );
}

class LocalPlanDay {
  LocalPlanDay({required this.date, required this.meals});

  final String date; // yyyy-MM-dd
  final List<LocalMeal> meals;

  Map<String, dynamic> toJson() => {
        'date': date,
        'meals': [for (final m in meals) m.toJson()],
      };

  factory LocalPlanDay.fromJson(Map<String, dynamic> json) => LocalPlanDay(
        date: '${json['date']}',
        meals: [
          for (final m in (json['meals'] as List? ?? []))
            if (m is Map<String, dynamic>) LocalMeal.fromJson(m),
        ],
      );
}

class LocalPlan {
  LocalPlan({required this.startDate, required this.days});

  final String startDate;
  final List<LocalPlanDay> days;

  LocalPlanDay? dayFor(DateTime date) {
    final key = dateKey(date);
    for (final d in days) {
      if (d.date == key) return d;
    }
    return null;
  }

  LocalMeal? mealById(int id) {
    for (final d in days) {
      for (final m in d.meals) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'start_date': startDate,
        'days': [for (final d in days) d.toJson()],
      };

  factory LocalPlan.fromJson(Map<String, dynamic> json) => LocalPlan(
        startDate: '${json['start_date']}',
        days: [
          for (final d in (json['days'] as List? ?? []))
            if (d is Map<String, dynamic>) LocalPlanDay.fromJson(d),
        ],
      );

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
