# Nutrition & Medical Safety Review Checklist

Every item must be signed off by a qualified reviewer (registered dietitian and, where marked ⚕, clinician) **before production release**. Status column starts `OPEN`.

| # | Item | Reviewer | Status |
|---|---|---|---|
| 1 | App never diagnoses diabetes or any condition (copy audit across all screens) | ⚕ | OPEN |
| 2 | No medication prescribing, dose calculation, or insulin math anywhere | ⚕ | OPEN |
| 3 | Glucose alert thresholds & wording clinically reviewed; context-aware; urgent-symptom guidance approved | ⚕ | OPEN |
| 4 | High readings never described as harmless; no false reassurance copy | ⚕ | OPEN |
| 5 | Specialized conditions (T1D, gestational, renal disease, eating disorders) flagged to clinician-guided planning; templates blocked for them | ⚕ | OPEN |
| 6 | Nutrient targets individualized — no universal carb/calorie targets for all diabetic users | RD | OPEN |
| 7 | Allergy exclusion engine test suite passes incl. severe-allergy scenarios | RD + QA | OPEN |
| 8 | Food data: no fabricated nutrient values; missing = null/estimated with label; sources licensed & recorded | RD | OPEN |
| 9 | Seasonal/fruit content: no cure/"lowers sugar automatically"/"produces blood" claims; no blanket fruit prohibition | RD | OPEN |
| 10 | Supportive, non-shaming language audit (missed meals, weight) | RD | OPEN |
| 11 | Water guidance has no universal targets; fluid-restriction caveat present | ⚕ | OPEN |
| 12 | AI assistant scope limits: refuses diagnosis/dosing; uncertainty statements; validated calculations outside LLM | RD + Eng | OPEN |
| 13 | Safety rules served from versioned backend content (`safety_rule_versions`), reviewed per locale | ⚕ | OPEN |
| 14 | Photo scanner feature-flagged off until accuracy study complete; uncertainty always displayed | RD + QA | OPEN |
| 15 | Report/PDF outputs distinguish recorded facts from AI suggestions | RD | OPEN |
| 16 | Essential safety information available on free tier | Product | OPEN |
| 17 | Lock-screen notifications exclude sensitive medical detail by default | Eng | OPEN |
| 18 | Regulatory assessment: is any feature medical-device software in target markets? | Legal | OPEN |

Glucose unit conversion reference: 1 mmol/L = 18.016 mg/dL (display rounding: mg/dL whole numbers, mmol/L one decimal). Covered by automated test `backend/tests/Feature/GlucoseConversionTest.php`.
