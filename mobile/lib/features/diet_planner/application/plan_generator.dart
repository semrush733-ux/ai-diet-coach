import 'dart:math';

import '../../foods/data/food_catalog.dart';
import '../domain/local_plan.dart';

/// Deterministic, rules-based meal plan generator (standalone mode).
///
/// Order of operations mirrors the product architecture:
///  1. filter templates by hard constraints (allergies first — never relaxed),
///  2. apply preference filters (diet, country, budget) with safe relaxation,
///  3. pick varied meals and scale portions toward a personal energy estimate.
///
/// The energy estimate is a general wellness heuristic, not medical advice;
/// targets are not clinical values.
abstract final class PlanGenerator {
  static LocalPlan generate(StoredProfile profile, {int days = 7}) {
    final start = DateTime.now();
    final seed = profile.displayName.hashCode ^ start.day ^ start.month;
    final random = Random(seed);

    final targetKcal = _dailyKcalTarget(profile);
    final carbConscious = profile.goals.any((g) =>
        g == 'manage_carbs' || g == 'prediabetes_support' || g == 'type2_support');

    final slots = _slots(profile, targetKcal);

    final planDays = <LocalPlanDay>[];
    var mealId = 1;
    // Per-slot rotation queues for variety.
    final queues = <String, List<MealTemplate>>{};

    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final meals = <LocalMeal>[];
      for (final slot in slots) {
        final pool = _eligible(profile, slot.catalogType, carbConscious);
        if (pool.isEmpty) continue;
        final queue = queues.putIfAbsent(
            slot.mealType, () => _shuffled(pool, random));
        if (queue.isEmpty) {
          queue.addAll(_shuffled(pool, random));
        }
        final template = queue.removeAt(0);
        final baseKcal = FoodCatalog.nutritionOf(template, 1).kcal;
        var scale = baseKcal <= 0 ? 1.0 : slot.kcal / baseKcal;
        scale = scale.clamp(0.6, 1.6).toDouble();
        meals.add(LocalMeal(
          id: mealId++,
          mealType: slot.mealType,
          templateId: template.id,
          time: slot.time,
          scale: double.parse(scale.toStringAsFixed(2)),
        ));
      }
      planDays.add(
          LocalPlanDay(date: LocalPlan.dateKey(date), meals: meals));
    }

    return LocalPlan(
        startDate: LocalPlan.dateKey(start), days: planDays);
  }

  /// Alternatives for a meal: same slot type, same constraints, nearest kcal.
  static List<MealTemplate> alternatives(
      StoredProfile profile, LocalMeal meal, {int limit = 4}) {
    final carbConscious = profile.goals.any((g) =>
        g == 'manage_carbs' || g == 'prediabetes_support' || g == 'type2_support');
    final catalogType =
        meal.mealType.contains('snack') ? 'snack' : meal.mealType;
    final pool = _eligible(profile, catalogType, carbConscious)
        .where((t) => t.id != meal.templateId)
        .toList();
    final currentKcal = meal.nutrition.kcal;
    pool.sort((a, b) {
      final ka = (FoodCatalog.nutritionOf(a, 1).kcal - currentKcal).abs();
      final kb = (FoodCatalog.nutritionOf(b, 1).kcal - currentKcal).abs();
      return ka.compareTo(kb);
    });
    return pool.take(limit).toList();
  }

  // ───────────────────────────────────────────────────────────────────

  static double _dailyKcalTarget(StoredProfile profile) {
    final weight = profile.weightKg;
    var kcal = weight != null && weight > 0 ? 31 * weight : 2000.0;
    kcal = kcal.clamp(1500.0, 2800.0).toDouble();
    if (profile.goals.contains('manage_weight')) {
      kcal = (kcal * 0.85).clamp(1400.0, 2800.0).toDouble();
    }
    return kcal;
  }

  static List<_Slot> _slots(StoredProfile profile, double targetKcal) {
    if (profile.wantsSnacks) {
      return [
        _Slot('breakfast', 'breakfast', profile.breakfastTime, targetKcal * 0.25),
        _Slot('morning_snack', 'snack', _midTime(profile.breakfastTime, profile.lunchTime), targetKcal * 0.08),
        _Slot('lunch', 'lunch', profile.lunchTime, targetKcal * 0.30),
        _Slot('afternoon_snack', 'snack', _midTime(profile.lunchTime, profile.dinnerTime), targetKcal * 0.07),
        _Slot('dinner', 'dinner', profile.dinnerTime, targetKcal * 0.30),
      ];
    }
    return [
      _Slot('breakfast', 'breakfast', profile.breakfastTime, targetKcal * 0.30),
      _Slot('lunch', 'lunch', profile.lunchTime, targetKcal * 0.35),
      _Slot('dinner', 'dinner', profile.dinnerTime, targetKcal * 0.35),
    ];
  }

  static List<MealTemplate> _eligible(
      StoredProfile profile, String catalogType, bool carbConscious) {
    final allergies = profile.allergies.toSet();
    final prefs = profile.dietaryPreferences.toSet();

    bool safe(MealTemplate t) {
      // Allergies are hard constraints — never relaxed.
      if (t.allergens(FoodCatalog.foods).intersection(allergies).isNotEmpty) {
        return false;
      }
      if (allergies.contains('milk') && t.hasDairy) return false;
      if (allergies.contains('wheat') && t.hasGluten) return false;
      return true;
    }

    bool matchesPrefs(MealTemplate t) {
      if (prefs.contains('vegan') && !t.isVegan) return false;
      if (prefs.contains('vegetarian') && !(t.isVegetarian || t.isVegan)) {
        return false;
      }
      if (prefs.contains('halal') && !t.isHalal) return false;
      if (prefs.contains('dairy_free') && t.hasDairy) return false;
      if (prefs.contains('gluten_free') && t.hasGluten) return false;
      return true;
    }

    bool matchesCountry(MealTemplate t) =>
        t.countries.contains('ANY') ||
        t.countries.contains(profile.countryCode);

    bool matchesBudget(MealTemplate t) => t.budgetTier <= profile.budgetTier;

    var pool = FoodCatalog.templates
        .where((t) => t.mealTypes.contains(catalogType))
        .where(safe)
        .where(matchesPrefs)
        .toList();

    var narrowed =
        pool.where(matchesCountry).where(matchesBudget).toList();
    // Safe relaxation: budget first, then country. Never prefs/allergies.
    if (narrowed.isEmpty) {
      narrowed = pool.where(matchesCountry).toList();
    }
    if (narrowed.isEmpty) narrowed = pool;

    if (carbConscious && narrowed.length > 2) {
      narrowed.sort((a, b) {
        final na = FoodCatalog.nutritionOf(a, 1);
        final nb = FoodCatalog.nutritionOf(b, 1);
        final ra = na.kcal <= 0 ? 1.0 : na.carbs * 4 / na.kcal;
        final rb = nb.kcal <= 0 ? 1.0 : nb.carbs * 4 / nb.kcal;
        return ra.compareTo(rb);
      });
      narrowed = narrowed.take(max(2, (narrowed.length * 2 / 3).ceil())).toList();
    }
    return narrowed;
  }

  static List<MealTemplate> _shuffled(
      List<MealTemplate> list, Random random) {
    final copy = [...list];
    copy.shuffle(random);
    return copy;
  }

  static String _midTime(String a, String b) {
    int minutes(String t) {
      final parts = t.split(':');
      if (parts.length != 2) return 12 * 60;
      return (int.tryParse(parts[0]) ?? 12) * 60 +
          (int.tryParse(parts[1]) ?? 0);
    }

    final mid = ((minutes(a) + minutes(b)) ~/ 2) % (24 * 60);
    final h = (mid ~/ 60).toString().padLeft(2, '0');
    final m = (mid % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Slot {
  const _Slot(this.mealType, this.catalogType, this.time, this.kcal);

  final String mealType;
  final String catalogType; // breakfast/lunch/dinner/snack
  final String time;
  final double kcal;
}
