<?php

namespace Tests\Unit;

use App\Services\GlucoseUnitConverter;
use PHPUnit\Framework\TestCase;

class GlucoseUnitConverterTest extends TestCase
{
    public function test_mmol_l_converts_with_18_016_factor(): void
    {
        $this->assertSame(99.1, GlucoseUnitConverter::toMgDl(5.5, 'mmol_l'));
        $this->assertSame(126.0, GlucoseUnitConverter::toMgDl(126.0, 'mg_dl'));
    }

    public function test_round_trip_is_stable(): void
    {
        $mgDl = GlucoseUnitConverter::toMgDl(7.2, 'mmol_l');
        $this->assertEqualsWithDelta(7.2, GlucoseUnitConverter::toMmolL($mgDl), 0.01);
    }

    public function test_unknown_unit_is_rejected(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        GlucoseUnitConverter::toMgDl(100, 'grams');
    }
}
