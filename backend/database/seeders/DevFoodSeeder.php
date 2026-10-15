<?php

namespace Database\Seeders;

use App\Models\Country;
use App\Models\Food;
use App\Models\FoodNutrition;
use App\Models\FoodSource;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * ─── DEVELOPMENT SEED DATA ───
 * A small starter food set for Pakistan / UK / US so the app and API can be
 * exercised end to end.
 *
 * Every row is flagged `data_quality_status = 'dev_seed'` and the source row
 * states it explicitly: per-100 g values here are approximations drawn from
 * common USDA FoodData Central reference entries and MUST be re-verified
 * against licensed, current source records (with FDC IDs) before any
 * production use. Values a typical source does not provide are left NULL —
 * never invented.
 */
class DevFoodSeeder extends Seeder
{
    public function run(): void
    {
        $source = FoodSource::updateOrCreate(
            ['name' => 'DEV SEED — approximate USDA FDC-style reference values'],
            [
                'reference' => 'https://fdc.nal.usda.gov/ (re-verify each item and record its FDC ID before production)',
                'retrieved_at' => now()->toDateString(),
                'license_note' => 'Development placeholder dataset. Not verified for production.',
            ],
        );

        $countries = Country::pluck('id', 'iso2');

        // slug, name, category, veg, vegan, halal, countries, [kcal, carbs, fiber, protein, fat, sodium] per 100 g (null = not provided)
        $foods = [
            ['whole-wheat-roti', 'Whole wheat roti', 'grain', true, true, true, ['PK'], [297.0, 59.0, 9.0, 11.0, 4.2, null]],
            ['daal-cooked', 'Daal (cooked lentils)', 'legume', true, true, true, ['PK', 'GB', 'US'], [116.0, 20.1, 7.9, 9.0, 0.4, 2.0]],
            ['chana-cooked', 'Chana (cooked chickpeas)', 'legume', true, true, true, ['PK', 'GB', 'US'], [164.0, 27.4, 7.6, 8.9, 2.6, 7.0]],
            ['grilled-chicken-breast', 'Grilled chicken breast', 'protein', false, false, true, ['PK', 'GB', 'US'], [165.0, 0.0, 0.0, 31.0, 3.6, 74.0]],
            ['bhindi-cooked', 'Bhindi (okra, cooked)', 'vegetable', true, true, true, ['PK'], [33.0, 7.5, 3.2, 1.9, 0.2, 7.0]],
            ['palak-cooked', 'Palak (spinach, cooked)', 'vegetable', true, true, true, ['PK', 'GB', 'US'], [23.0, 3.8, 2.4, 3.0, 0.3, 70.0]],
            ['plain-yogurt', 'Plain yogurt', 'dairy', true, false, true, ['PK', 'GB', 'US'], [61.0, 4.7, 0.0, 3.5, 3.3, 46.0]],
            ['brown-rice-cooked', 'Brown rice (cooked)', 'grain', true, true, true, ['PK', 'GB', 'US'], [123.0, 25.6, 1.6, 2.7, 1.0, 4.0]],
            ['white-rice-cooked', 'White rice (cooked)', 'grain', true, true, true, ['PK', 'GB', 'US'], [130.0, 28.2, 0.4, 2.7, 0.3, 1.0]],
            ['boiled-egg', 'Egg (boiled)', 'protein', true, false, true, ['PK', 'GB', 'US'], [155.0, 1.1, 0.0, 12.6, 10.6, 124.0]],
            ['porridge-oats-dry', 'Porridge oats (dry)', 'grain', true, true, true, ['GB', 'US'], [389.0, 66.3, 10.6, 16.9, 6.9, 2.0]],
            ['wholegrain-bread', 'Wholegrain bread', 'grain', true, true, true, ['GB', 'US'], [247.0, 41.3, 7.0, 13.0, 3.4, 400.0]],
            ['grilled-white-fish', 'Grilled white fish (cod)', 'protein', false, false, true, ['GB', 'US', 'PK'], [105.0, 0.0, 0.0, 23.0, 0.9, 78.0]],
            ['lentil-soup', 'Lentil soup', 'prepared', true, true, true, ['GB', 'US'], [52.0, 8.0, 2.0, 3.2, 0.9, null]],
            ['black-beans-cooked', 'Black beans (cooked)', 'legume', true, true, true, ['US'], [132.0, 23.7, 8.7, 8.9, 0.5, 1.0]],
            ['mixed-salad-greens', 'Mixed salad greens', 'vegetable', true, true, true, ['GB', 'US', 'PK'], [17.0, 3.3, 2.1, 1.5, 0.2, 28.0]],
            ['apple', 'Apple', 'fruit', true, true, true, ['PK', 'GB', 'US'], [52.0, 13.8, 2.4, 0.3, 0.2, 1.0]],
            ['banana', 'Banana', 'fruit', true, true, true, ['PK', 'GB', 'US'], [89.0, 22.8, 2.6, 1.1, 0.3, 1.0]],
            ['pomegranate', 'Pomegranate', 'fruit', true, true, true, ['PK', 'US'], [83.0, 18.7, 4.0, 1.7, 1.2, 3.0]],
            ['guava', 'Guava', 'fruit', true, true, true, ['PK'], [68.0, 14.3, 5.4, 2.6, 1.0, 2.0]],
        ];

        foreach ($foods as [$slug, $name, $category, $veg, $vegan, $halal, $iso2s, $n]) {
            $food = Food::updateOrCreate(['slug' => $slug], [
                'name' => $name,
                'category' => $category,
                'default_serving_size' => 100,
                'serving_unit' => 'g',
                'is_vegetarian' => $veg,
                'is_vegan' => $vegan,
                'is_halal_suitable' => $halal,
                'data_quality_status' => 'dev_seed',
            ]);

            FoodNutrition::updateOrCreate(
                ['food_id' => $food->id, 'version' => 1],
                [
                    'calories_kcal' => $n[0],
                    'carbs_g' => $n[1],
                    'fiber_g' => $n[2],
                    'protein_g' => $n[3],
                    'fat_g' => $n[4],
                    'sodium_mg' => $n[5], // null stays null
                    'food_source_id' => $source->id,
                ],
            );

            foreach ($iso2s as $iso2) {
                if (isset($countries[$iso2])) {
                    DB::table('food_country_availability')->updateOrInsert([
                        'food_id' => $food->id,
                        'country_id' => $countries[$iso2],
                    ]);
                }
            }
        }

        // Example allergen tags for the seed set.
        $allergyIds = DB::table('allergies')->pluck('id', 'code');
        $tags = [
            'boiled-egg' => ['eggs'],
            'plain-yogurt' => ['milk'],
            'whole-wheat-roti' => ['wheat'],
            'wholegrain-bread' => ['wheat'],
            'porridge-oats-dry' => ['wheat'], // oat cross-contact caution; refine in review
            'grilled-white-fish' => ['fish'],
        ];
        foreach ($tags as $slug => $codes) {
            $foodId = Food::where('slug', $slug)->value('id');
            foreach ($codes as $code) {
                if ($foodId && isset($allergyIds[$code])) {
                    DB::table('food_allergens')->updateOrInsert([
                        'food_id' => $foodId,
                        'allergy_id' => $allergyIds[$code],
                    ]);
                }
            }
        }
    }
}
