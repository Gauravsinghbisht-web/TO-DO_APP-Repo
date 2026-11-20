---
name: TaskFlow
colors:
  surface: '#fcf8ff'
  surface-dim: '#dad6ff'
  surface-bright: '#fcf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2ff'
  surface-container: '#efebff'
  surface-container-high: '#e9e5ff'
  surface-container-highest: '#e3dfff'
  on-surface: '#181445'
  on-surface-variant: '#464555'
  inverse-surface: '#2d2a5b'
  inverse-on-surface: '#f3eeff'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4f44e2'
  primary: '#4d41df'
  on-primary: '#ffffff'
  primary-container: '#675df9'
  on-primary-container: '#fffbff'
  inverse-primary: '#c4c0ff'
  secondary: '#4b41e1'
  on-secondary: '#ffffff'
  secondary-container: '#645efb'
  on-secondary-container: '#fffbff'
  tertiary: '#006947'
  on-tertiary: '#ffffff'
  tertiary-container: '#00855b'
  on-tertiary-container: '#f5fff6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e3dfff'
  primary-fixed-dim: '#c4c0ff'
  on-primary-fixed: '#100069'
  on-primary-fixed-variant: '#3622ca'
  secondary-fixed: '#e2dfff'
  secondary-fixed-dim: '#c3c0ff'
  on-secondary-fixed: '#0f0069'
  on-secondary-fixed-variant: '#3323cc'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#fcf8ff'
  on-background: '#181445'
  surface-variant: '#e3dfff'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system targets focused knowledge workers, high-performing individuals, and modern professionals seeking cognitive clarity through their mobile workflow. It fuses Material You (Material Design 3) tactile utility with the refined restraint of premium Scandinavian minimalism. 

The aesthetic is characterized by calm, expansive negative space, delicate tonal surfaces, and deliberate interactive pops of focused violet. The emotional tone is reassuring, ordered, and friction-free—transforming chaotic cognitive overload into structured, calm productivity.

## Colors
The color palette establishes an airy, lavender-washed atmosphere contrasted with deep slate typography for effortless legibility outdoors and under direct light.

- **Primary (`#6C63FF`)**: Deep electric violet used for active states, primary Floating Action Buttons (FABs), completed highlights, and core brand indicators.
- **Secondary (`#4F46E5`)**: Saturated indigo anchor used for structural actions, selection rings, segmented control pills, and secondary badges.
- **Tertiary (`#10B981`)**: Crisp emerald reserved for completed state celebrations, productivity streaks, and success notifications.
- **Warning / Accent (`#F59E0B`)**: Warm amber for urgent deadlines, priority indicators, and overdue reminders.
- **Neutral Surface Hierarchy**:
  - Base canvas: `#F7F6FD` (soft lavender wash).
  - Surface Container / Card base: `#FFFFFF` (clean optical white for sharp edge clarity against lavender).
  - Surface High: `#F4F2FF` (recessed inputs and secondary component wrappers).
- **Text & Contrast**:
  - Primary text: `#1E1B4B` (dense slate indigo, avoiding harsh pure black).
  - Secondary text: `#4B5563` (neutral slate).
  - Subtle / Placeholder text: `#9CA3AF`.

## Typography
Built around `Inter` across all structural tiers, the typography relies on strict weight differentiation and tight letter tracking rather than mixed font families. This preserves high utility and rapid scanning inside native Android lists and dense kanban boards.

Headings leverage negative tracking (`-0.02em` to `-0.03em`) and medium/semibold weights to evoke a calm architectural feel. Micro-labels and metadata tags employ uppercase tracking (`+0.04em` to `+0.06em`) for instant readability at 10–12px on high-DPI displays.

## Layout & Spacing
The layout follows a strict 8px incremental spatial grid aligned with Android Material 3 guidelines.

- **Mobile Canvas**: Handheld layout relies on a single-column fluid frame with a default 16px (`1rem`) outer margin. Bottom navigation bar respects Android edge-to-edge gesture insets, adding dynamic safe-area padding at the bottom.
- **Top App Bar**: 64px standard height for compact top app bars, expanding to 112px for prominent collapsible headline variants.
- **Bottom Navigation**: 80px fixed height container, housing 4 to 5 core destination icons with interactive indicator pills.
- **Adaptive Breakpoints**:
  - Phone (<600dp): 1-column fluid, 16px gutter, persistent bottom navigation.
  - Foldable / Small Tablet (600dp–840dp): 2-column or master-detail split, 24px gutter, navigation rail replacing bottom nav.
  - Large Tablet / Desktop (>840dp): Expanded multi-column layout (max width 1200px centered), navigation rail or modal navigation drawer.

## Elevation & Depth
Depth is created through subtle tonal contrasts rather than deep muddy dropshadows. Surfaces sit on the `#F7F6FD` background canvas using light refraction and tinted indigo ambient occlusion.

- **Level 0 (Flat Canvas)**: `#F7F6FD`, 0px elevation. Used for backgrounds and segmented track groups.
- **Level 1 (Card Resting / List Item)**: `#FFFFFF` with `0px 2px 8px -2px rgba(30, 27, 75, 0.04), 0px 1px 3px 0px rgba(30, 27, 75, 0.02)`. Barely perceptible separation that prevents visual clutter in list-heavy views.
- **Level 2 (Active Drag / Raised Card)**: `#FFFFFF` with `0px 8px 20px -4px rgba(108, 99, 255, 0.12), 0px 3px 6px -1px rgba(30, 27, 75, 0.04)`.
- **Level 3 (Top & Bottom Bars / Sticky Panels)**: Glassmorphic or solid `#FFFFFF` with 85% opacity, `backdrop-filter: blur(16px)`, finished with an ultra-fine border: `1px solid rgba(244, 242, 255, 0.8)`.
- **Level 4 (Floating Action Button / Bottom Sheets)**: Saturated violet shadow tint `0px 12px 28px -6px rgba(108, 99, 255, 0.35)`.

## Shapes
A roundedness factor of 2 provides a balanced, organic curve profile matching modern Android hardware corners.

- **Primary Cards & Modals**: `rounded-lg` (16px) up to `rounded-xl` (24px) for expansive grouping surfaces and task detail bottom sheets.
- **Buttons & Search Bars**: Pill-shaped (`rounded-full`) for high interactive affordance, inviting immediate touch interaction.
- **Chips, Badges & Small Inputs**: `rounded-md` (8px) to `rounded-lg` (16px) depending on interactive density.

## Components

### Buttons
- **Primary FAB (Floating Action Button)**: 56x56dp (standard) or 96x56dp (extended). Roundedness: 16px to 28px (pill). Background `#6C63FF`, icon/text `#FFFFFF`. Elevation level 4 with lavender glow.
- **Filled Button**: Pill shape, `#6C63FF` surface, `#FFFFFF` Inter label (weight 600). Touch target minimum 48dp height.
- **Tonal / Subtle Button**: Pill shape, `#F4F2FF` surface, `#6C63FF` text. Zero shadow. Used for secondary and inline modal actions.

### Cards & Task Rows
- **Task Card**: Background `#FFFFFF`, rounded 16px to 20px, 16px internal padding. Left edge features a 4px vertical accent bar corresponding to task priority or project tag.
- **Completed State**: Background softens to `#F4F2FF` with 60% opacity; text strikes through in `#9CA3AF`.

### Checkboxes & Selection Controls
- **Circular Checkboxes**: 22dp diameter, 2px border in `#CBD5E1`. When checked, smoothly transitions into `#10B981` (emerald) with an animated white checkmark glyph.
- **Radio Buttons**: Concentric circles with active center dot in `#6C63FF`.

### Input Fields
- **Search & Text Input**: Pill or 16px rounded rectangle. Resting fill `#F4F2FF`, border `1px solid transparent`. Focused fill `#FFFFFF`, border `1.5px solid #6C63FF` accompanied by a soft `0 0 0 3px rgba(108, 99, 255, 0.15)` focus ring.

### Filter Chips
- **Resting**: `#FFFFFF` background, border `1px solid #E2E8F0`, text `#4B5563`, rounded-full.
- **Selected**: `#6C63FF` background, `#FFFFFF` text, shadow `0px 4px 10px rgba(108, 99, 255, 0.2)`.

### Bottom Navigation Bar
- Container: Height 80dp, surface `#FFFFFF` (or blurred translucent white), border-top `1px solid #F4F2FF`. Active item highlighted with an elongated horizontal pill indicator (`#F4F2FF`) behind a `#6C63FF` icon.