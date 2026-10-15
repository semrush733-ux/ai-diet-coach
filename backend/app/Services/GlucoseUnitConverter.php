<?php

namespace App\Services;

/**
 * Glucose unit conversion. 1 mmol/L = 18.016 mg/dL
 * (molar mass of glucose ≈ 180.16 g/mol).
 *
 * The original reading and its unit are always stored alongside the
 * canonical mg/dL value — conversion is for display/aggregation only.
 */
final class GlucoseUnitConverter
{
    public const MG_DL_PER_MMOL_L = 18.016;

    public static function toMgDl(float $value, string $unit): float
    {
        return match ($unit) {
            'mg_dl' => round($value, 1),
            'mmol_l' => round($value * self::MG_DL_PER_MMOL_L, 1),
            default => throw new \InvalidArgumentException("Unknown glucose unit: {$unit}"),
        };
    }

    public static function toMmolL(float $mgDl): float
    {
        return round($mgDl / self::MG_DL_PER_MMOL_L, 2);
    }
}
