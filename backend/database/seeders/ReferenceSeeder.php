<?php

namespace Database\Seeders;

use App\Models\Country;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ReferenceSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([
            ['iso2' => 'PK', 'name' => 'Pakistan', 'hemisphere' => 'northern', 'default_currency' => 'PKR'],
            ['iso2' => 'GB', 'name' => 'United Kingdom', 'hemisphere' => 'northern', 'default_currency' => 'GBP'],
            ['iso2' => 'US', 'name' => 'United States', 'hemisphere' => 'northern', 'default_currency' => 'USD'],
        ] as $country) {
            Country::updateOrCreate(['iso2' => $country['iso2']], $country);
        }

        foreach ([
            ['code' => 'nuts', 'name' => 'Tree nuts & peanuts'],
            ['code' => 'shellfish', 'name' => 'Shellfish'],
            ['code' => 'eggs', 'name' => 'Eggs'],
            ['code' => 'milk', 'name' => 'Milk / dairy'],
            ['code' => 'wheat', 'name' => 'Wheat / gluten'],
            ['code' => 'soy', 'name' => 'Soy'],
            ['code' => 'fish', 'name' => 'Fish'],
            ['code' => 'sesame', 'name' => 'Sesame'],
        ] as $allergy) {
            DB::table('allergies')->updateOrInsert(
                ['code' => $allergy['code']],
                [...$allergy, 'created_at' => now(), 'updated_at' => now()],
            );
        }
    }
}
