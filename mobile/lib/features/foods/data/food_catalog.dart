/// In-app food & meal-template catalog for the standalone planner.
///
/// Nutrition values are per-100 g approximations drawn from common USDA
/// FoodData Central reference entries (development dataset — re-verify
/// against licensed sources before production). Missing values are null and
/// are never invented.
library;

class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.name,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
    this.allergens = const [],
  });

  final String id;
  final String name;

  /// Per 100 g.
  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
  final List<String> allergens;
}

class MealTemplate {
  const MealTemplate({
    required this.id,
    required this.name,
    required this.mealTypes,
    required this.countries,
    required this.components, // foodId -> grams
    this.cuisine = '',
    this.isVegetarian = false,
    this.isVegan = false,
    this.isHalal = true,
    this.hasDairy = false,
    this.hasGluten = false,
    this.budgetTier = 1, // 1 budget, 2 balanced, 3 premium
    this.prepMinutes = 15,
  });

  final String id;
  final String name;
  final List<String> mealTypes; // breakfast, lunch, dinner, snack
  final List<String> countries; // PK, GB, US, ANY
  final Map<String, double> components;
  final String cuisine;
  final bool isVegetarian;
  final bool isVegan;
  final bool isHalal;
  final bool hasDairy;
  final bool hasGluten;
  final int budgetTier;
  final int prepMinutes;

  Set<String> allergens(Map<String, CatalogFood> foods) {
    final result = <String>{};
    for (final foodId in components.keys) {
      final food = foods[foodId];
      if (food != null) result.addAll(food.allergens);
    }
    return result;
  }
}

/// Computed nutrition for a scaled template.
class MealNutrition {
  const MealNutrition({
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.fiber,
  });

  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
  final double fiber;
}

abstract final class FoodCatalog {
  static final Map<String, CatalogFood> foods = {
    for (final f in _foods) f.id: f,
  };

  static const List<CatalogFood> _foods = [
    CatalogFood(id: 'roti', name: 'Whole wheat roti', kcal: 297, carbs: 59, protein: 11, fat: 4.2, fiber: 9, allergens: ['wheat']),
    CatalogFood(id: 'daal', name: 'Daal (cooked lentils)', kcal: 116, carbs: 20.1, protein: 9, fat: 0.4, fiber: 7.9),
    CatalogFood(id: 'chana', name: 'Chana (chickpeas, cooked)', kcal: 164, carbs: 27.4, protein: 8.9, fat: 2.6, fiber: 7.6),
    CatalogFood(id: 'chicken', name: 'Grilled chicken breast', kcal: 165, carbs: 0, protein: 31, fat: 3.6, fiber: 0),
    CatalogFood(id: 'chicken_curry', name: 'Chicken curry (light oil)', kcal: 150, carbs: 4, protein: 17, fat: 7.5, fiber: 1),
    CatalogFood(id: 'bhindi', name: 'Bhindi (okra, cooked)', kcal: 33, carbs: 7.5, protein: 1.9, fat: 0.2, fiber: 3.2),
    CatalogFood(id: 'palak', name: 'Palak (spinach, cooked)', kcal: 23, carbs: 3.8, protein: 3, fat: 0.3, fiber: 2.4),
    CatalogFood(id: 'mixed_veg', name: 'Mixed vegetables', kcal: 60, carbs: 12, protein: 2.6, fat: 0.5, fiber: 4),
    CatalogFood(id: 'yogurt', name: 'Plain yogurt', kcal: 61, carbs: 4.7, protein: 3.5, fat: 3.3, fiber: 0, allergens: ['milk']),
    CatalogFood(id: 'brown_rice', name: 'Brown rice (cooked)', kcal: 123, carbs: 25.6, protein: 2.7, fat: 1, fiber: 1.6),
    CatalogFood(id: 'white_rice', name: 'White rice (cooked)', kcal: 130, carbs: 28.2, protein: 2.7, fat: 0.3, fiber: 0.4),
    CatalogFood(id: 'egg', name: 'Egg (boiled)', kcal: 155, carbs: 1.1, protein: 12.6, fat: 10.6, fiber: 0, allergens: ['eggs']),
    CatalogFood(id: 'oats', name: 'Porridge oats (dry)', kcal: 389, carbs: 66.3, protein: 16.9, fat: 6.9, fiber: 10.6),
    CatalogFood(id: 'milk', name: 'Low-fat milk', kcal: 50, carbs: 5, protein: 3.4, fat: 2, fiber: 0, allergens: ['milk']),
    CatalogFood(id: 'bread', name: 'Wholegrain bread', kcal: 247, carbs: 41.3, protein: 13, fat: 3.4, fiber: 7, allergens: ['wheat']),
    CatalogFood(id: 'fish', name: 'Grilled white fish', kcal: 105, carbs: 0, protein: 23, fat: 0.9, fiber: 0, allergens: ['fish']),
    CatalogFood(id: 'beans', name: 'Black beans (cooked)', kcal: 132, carbs: 23.7, protein: 8.9, fat: 0.5, fiber: 8.7),
    CatalogFood(id: 'salad', name: 'Mixed salad greens', kcal: 17, carbs: 3.3, protein: 1.5, fat: 0.2, fiber: 2.1),
    CatalogFood(id: 'cucumber_salad', name: 'Cucumber & tomato salad', kcal: 20, carbs: 4, protein: 1, fat: 0.2, fiber: 1.4),
    CatalogFood(id: 'apple', name: 'Apple', kcal: 52, carbs: 13.8, protein: 0.3, fat: 0.2, fiber: 2.4),
    CatalogFood(id: 'banana', name: 'Banana', kcal: 89, carbs: 22.8, protein: 1.1, fat: 0.3, fiber: 2.6),
    CatalogFood(id: 'pomegranate', name: 'Pomegranate', kcal: 83, carbs: 18.7, protein: 1.7, fat: 1.2, fiber: 4),
    CatalogFood(id: 'guava', name: 'Guava', kcal: 68, carbs: 14.3, protein: 2.6, fat: 1, fiber: 5.4),
    CatalogFood(id: 'almonds', name: 'Almonds', kcal: 579, carbs: 21.6, protein: 21.2, fat: 49.9, fiber: 12.5, allergens: ['nuts']),
    CatalogFood(id: 'peanut_chana', name: 'Roasted chana snack', kcal: 369, carbs: 55, protein: 20, fat: 6, fiber: 17),
    CatalogFood(id: 'olive_oil', name: 'Olive oil', kcal: 884, carbs: 0, protein: 0, fat: 100, fiber: 0),
    CatalogFood(id: 'tofu', name: 'Tofu', kcal: 76, carbs: 1.9, protein: 8, fat: 4.8, fiber: 0.3, allergens: ['soy']),
    CatalogFood(id: 'lentil_soup', name: 'Lentil soup', kcal: 52, carbs: 8, protein: 3.2, fat: 0.9, fiber: 2),
  ];

  static const List<MealTemplate> templates = [
    // ── Breakfasts ──
    MealTemplate(id: 'b_pk_1', name: 'Roti with daal & yogurt', mealTypes: ['breakfast'], countries: ['PK'], cuisine: 'Pakistani', components: {'roti': 70, 'daal': 150, 'yogurt': 100}, isVegetarian: true, hasDairy: true, hasGluten: true, budgetTier: 1, prepMinutes: 20),
    MealTemplate(id: 'b_pk_2', name: 'Anda (boiled eggs) with roti', mealTypes: ['breakfast'], countries: ['PK'], cuisine: 'Pakistani', components: {'egg': 100, 'roti': 70, 'cucumber_salad': 80}, isVegetarian: true, hasGluten: true, budgetTier: 1, prepMinutes: 15),
    MealTemplate(id: 'b_any_1', name: 'Porridge with banana', mealTypes: ['breakfast'], countries: ['ANY'], cuisine: 'International', components: {'oats': 50, 'milk': 200, 'banana': 80}, isVegetarian: true, hasDairy: true, budgetTier: 1, prepMinutes: 10),
    MealTemplate(id: 'b_gb_1', name: 'Wholegrain toast with eggs', mealTypes: ['breakfast'], countries: ['GB', 'US'], cuisine: 'British', components: {'bread': 70, 'egg': 100, 'salad': 40}, isVegetarian: true, hasGluten: true, budgetTier: 2, prepMinutes: 12),
    MealTemplate(id: 'b_any_2', name: 'Yogurt bowl with fruit & oats', mealTypes: ['breakfast'], countries: ['ANY'], cuisine: 'International', components: {'yogurt': 200, 'oats': 30, 'apple': 100}, isVegetarian: true, hasDairy: true, budgetTier: 2, prepMinutes: 5),
    MealTemplate(id: 'b_any_3', name: 'Oats with apple (dairy-free)', mealTypes: ['breakfast'], countries: ['ANY'], cuisine: 'International', components: {'oats': 55, 'apple': 120, 'almonds': 15}, isVegetarian: true, isVegan: true, budgetTier: 2, prepMinutes: 10),

    // ── Lunches ──
    MealTemplate(id: 'l_pk_1', name: 'Daal, roti & cucumber salad', mealTypes: ['lunch', 'dinner'], countries: ['PK'], cuisine: 'Pakistani', components: {'daal': 250, 'roti': 70, 'cucumber_salad': 100}, isVegetarian: true, isVegan: true, hasGluten: true, budgetTier: 1, prepMinutes: 30),
    MealTemplate(id: 'l_pk_2', name: 'Chicken curry with brown rice', mealTypes: ['lunch', 'dinner'], countries: ['PK'], cuisine: 'Pakistani', components: {'chicken_curry': 180, 'brown_rice': 180, 'salad': 60}, budgetTier: 2, prepMinutes: 35),
    MealTemplate(id: 'l_pk_3', name: 'Chana masala with roti', mealTypes: ['lunch', 'dinner'], countries: ['PK'], cuisine: 'Pakistani', components: {'chana': 220, 'roti': 70, 'cucumber_salad': 80}, isVegetarian: true, isVegan: true, hasGluten: true, budgetTier: 1, prepMinutes: 25),
    MealTemplate(id: 'l_pk_4', name: 'Bhindi with roti & yogurt', mealTypes: ['lunch', 'dinner'], countries: ['PK'], cuisine: 'Pakistani', components: {'bhindi': 200, 'roti': 70, 'yogurt': 100}, isVegetarian: true, hasDairy: true, hasGluten: true, budgetTier: 1, prepMinutes: 25),
    MealTemplate(id: 'l_any_1', name: 'Grilled chicken with rice & salad', mealTypes: ['lunch', 'dinner'], countries: ['ANY'], cuisine: 'International', components: {'chicken': 140, 'brown_rice': 170, 'salad': 80, 'olive_oil': 7}, budgetTier: 2, prepMinutes: 25),
    MealTemplate(id: 'l_gb_1', name: 'Lentil soup with wholegrain bread', mealTypes: ['lunch'], countries: ['GB', 'US'], cuisine: 'British', components: {'lentil_soup': 350, 'bread': 60}, isVegetarian: true, isVegan: true, hasGluten: true, budgetTier: 1, prepMinutes: 15),
    MealTemplate(id: 'l_us_1', name: 'Chicken & black bean bowl', mealTypes: ['lunch', 'dinner'], countries: ['US'], cuisine: 'American', components: {'chicken': 120, 'beans': 150, 'brown_rice': 140, 'salad': 60}, budgetTier: 2, prepMinutes: 20),
    MealTemplate(id: 'l_any_2', name: 'Tofu & vegetable stir-fry with rice', mealTypes: ['lunch', 'dinner'], countries: ['ANY'], cuisine: 'Asian', components: {'tofu': 150, 'mixed_veg': 180, 'brown_rice': 160, 'olive_oil': 7}, isVegetarian: true, isVegan: true, budgetTier: 2, prepMinutes: 20),

    // ── Dinners ──
    MealTemplate(id: 'd_any_1', name: 'Grilled fish with vegetables', mealTypes: ['dinner', 'lunch'], countries: ['ANY'], cuisine: 'International', components: {'fish': 160, 'mixed_veg': 200, 'brown_rice': 120, 'olive_oil': 7}, budgetTier: 3, prepMinutes: 25),
    MealTemplate(id: 'd_pk_1', name: 'Palak with roti & yogurt', mealTypes: ['dinner', 'lunch'], countries: ['PK'], cuisine: 'Pakistani', components: {'palak': 220, 'roti': 70, 'yogurt': 100}, isVegetarian: true, hasDairy: true, hasGluten: true, budgetTier: 1, prepMinutes: 25),
    MealTemplate(id: 'd_any_2', name: 'Chicken with salad plate', mealTypes: ['dinner'], countries: ['ANY'], cuisine: 'International', components: {'chicken': 150, 'salad': 120, 'cucumber_salad': 100, 'olive_oil': 10}, budgetTier: 2, prepMinutes: 20),
    MealTemplate(id: 'd_us_1', name: 'Bean & vegetable bowl', mealTypes: ['dinner', 'lunch'], countries: ['US', 'GB'], cuisine: 'American', components: {'beans': 200, 'mixed_veg': 150, 'brown_rice': 130}, isVegetarian: true, isVegan: true, budgetTier: 1, prepMinutes: 20),

    // ── Snacks ──
    MealTemplate(id: 's_any_1', name: 'Apple', mealTypes: ['snack'], countries: ['ANY'], cuisine: '', components: {'apple': 150}, isVegetarian: true, isVegan: true, budgetTier: 1, prepMinutes: 1),
    MealTemplate(id: 's_any_2', name: 'Handful of almonds', mealTypes: ['snack'], countries: ['ANY'], cuisine: '', components: {'almonds': 25}, isVegetarian: true, isVegan: true, budgetTier: 3, prepMinutes: 1),
    MealTemplate(id: 's_pk_1', name: 'Roasted chana', mealTypes: ['snack'], countries: ['PK'], cuisine: 'Pakistani', components: {'peanut_chana': 35}, isVegetarian: true, isVegan: true, budgetTier: 1, prepMinutes: 1),
    MealTemplate(id: 's_pk_2', name: 'Guava', mealTypes: ['snack'], countries: ['PK'], cuisine: '', components: {'guava': 150}, isVegetarian: true, isVegan: true, budgetTier: 1, prepMinutes: 1),
    MealTemplate(id: 's_any_3', name: 'Yogurt cup', mealTypes: ['snack'], countries: ['ANY'], cuisine: '', components: {'yogurt': 170}, isVegetarian: true, hasDairy: true, budgetTier: 1, prepMinutes: 1),
    MealTemplate(id: 's_any_4', name: 'Banana', mealTypes: ['snack'], countries: ['ANY'], cuisine: '', components: {'banana': 120}, isVegetarian: true, isVegan: true, budgetTier: 1, prepMinutes: 1),
    MealTemplate(id: 's_pk_3', name: 'Pomegranate bowl', mealTypes: ['snack'], countries: ['PK', 'US'], cuisine: '', components: {'pomegranate': 140}, isVegetarian: true, isVegan: true, budgetTier: 2, prepMinutes: 5),
  ];

  static MealTemplate? templateById(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Nutrition for a template at the given scale (1.0 = listed grams).
  static MealNutrition nutritionOf(MealTemplate template, double scale) {
    double kcal = 0, carbs = 0, protein = 0, fat = 0, fiber = 0;
    template.components.forEach((foodId, grams) {
      final food = foods[foodId];
      if (food == null) return;
      final factor = grams * scale / 100.0;
      kcal += food.kcal * factor;
      carbs += food.carbs * factor;
      protein += food.protein * factor;
      fat += food.fat * factor;
      fiber += food.fiber * factor;
    });
    return MealNutrition(
        kcal: kcal, carbs: carbs, protein: protein, fat: fat, fiber: fiber);
  }
}
