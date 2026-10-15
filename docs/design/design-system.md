# AI Diet Coach — Design System (Phase 1)

Identity: modern, clean, minimal, trustworthy, premium, friendly. Professional icons (Material Symbols rounded), no decorative emoji.

## Color tokens
| Token | Light | Dark | Use |
|---|---|---|---|
| primary | #168B72 | #2BAA8E | Brand actions, active tab |
| primaryDark | #106D5B | #168B72 | Pressed states, gradients |
| background | #F7FAF9 | #0B1420 | Scaffold |
| surface | #FFFFFF | #13202E | Cards |
| textPrimary | #17212B | #ECF2F1 | Headlines/body |
| textSecondary | #64748B | #93A3B5 | Captions, labels |
| success | #16A34A | #34C06A | In-range, confirmations |
| warning | #D97706 | #ED9B3C | Attention |
| danger | #DC2626 | #EF5350 | Errors, destructive |
| outline | #E2E8F0 | #223246 | Dividers, borders |

Contrast: primary on white = 4.6:1 (AA for normal text); textSecondary reserved for ≥14 pt medium or non-essential labels. Semantic colors never the sole signal (pair with icon/label).

## Typography (Inter via google_fonts; falls back to system)
display 32/38 w700 · headline 24/30 w700 · title 18/24 w600 · body 15/22 w400 · label 13/18 w600 (0.2 ls) · caption 12/16 w500.
Dynamic type: all styles respond to MediaQuery textScaler; layouts tested to 1.3×.

## Spacing & shape
4-pt grid: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32. Screen gutter 20.
Radii: card 20, button 14, chip 999, input 14. Elevation: soft shadow `0 6 18 rgba(11,20,32,0.06)` light / outline-only dark.
Touch targets ≥ 48×48. Reduced motion respected (durations → 0 when `disableAnimations`).

## Core components (lib/shared/widgets)
AppPrimaryButton (filled, 52 h, loading state), AppSecondaryButton (tonal), AppTextField (label, helper, error, obscure toggle), AppCard, SelectableChip (multi/single select), SectionHeader (title + optional action), SkeletonBox (shimmer-free pulse, reduced-motion safe), EmptyState (icon, title, message, action), ErrorState (retry), MealCard (image, title, time, kcal + carbs labels), MetricTile.

## Navigation
Bottom bar: Home · My Diet · Sugar · Progress (NavigationBar, labeled, 64 h). AI Coach: FloatingActionButton (chat icon) docked above bar on main tabs. Top app area: greeting/profile avatar left, notifications bell right.

## States
Every data screen implements: loading (skeleton), empty (friendly illustration + primary action), error (message + retry), success. No screen ships with fabricated numbers — empty states are explicit.

## Localization & RTL
en + ur ARB files; `Directionality` derives from locale; icons with horizontal meaning use directional variants; numerals follow locale formatting via intl.
