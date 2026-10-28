---
name: Risotto
colors:
  surface: '#f6fbf5'
  surface-dim: '#d7dbd6'
  surface-bright: '#f6fbf5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f5f0'
  surface-container: '#ebefea'
  surface-container-high: '#e5e9e4'
  surface-container-highest: '#dfe4df'
  on-surface: '#181d1a'
  on-surface-variant: '#514534'
  inverse-surface: '#2c322e'
  inverse-on-surface: '#edf2ed'
  outline: '#837561'
  outline-variant: '#d6c4ad'
  surface-tint: '#7f5700'
  primary: '#7f5700'
  on-primary: '#ffffff'
  primary-container: '#e8a317'
  on-primary-container: '#5b3d00'
  inverse-primary: '#ffba3e'
  secondary: '#2d694d'
  on-secondary: '#ffffff'
  secondary-container: '#aeedca'
  on-secondary-container: '#326e51'
  tertiary: '#b22b18'
  on-tertiary: '#ffffff'
  tertiary-container: '#ff927f'
  on-tertiary-container: '#890b00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdeae'
  primary-fixed-dim: '#ffba3e'
  on-primary-fixed: '#281900'
  on-primary-fixed-variant: '#604100'
  secondary-fixed: '#b1f0cd'
  secondary-fixed-dim: '#96d4b2'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#105137'
  tertiary-fixed: '#ffdad4'
  tertiary-fixed-dim: '#ffb4a6'
  on-tertiary-fixed: '#400200'
  on-tertiary-fixed-variant: '#8f1002'
  background: '#f6fbf5'
  on-background: '#181d1a'
  surface-variant: '#dfe4df'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
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

This design system embodies a warm, human, grounded, and modern professional networking environment crafted specifically for African professionals, premiering across Francophone West Africa. Moving away from cold, clinical Western enterprise aesthetics, the visual language draws inspiration from vibrant markets, rich culinary hospitality, and human-centric connection. 

The aesthetic is Tactile Modernism meets Warm Minimalism:
- Welcoming, community-first tone that prioritizes mutual trust, mentorship, and professional growth.
- High visual legibility engineered for varied ambient lighting (bright outdoors to dim evening markets).
- Resource-light interfaces optimized for performant rendering on low-tier and mid-tier mobile hardware.
- Complete dedication to a native Light Mode presentation to preserve luminosity, cheer, and visual comfort.

## Colors

The palette is anchored in an earthy, warm, sun-drenched hierarchy:

- **Primary (`#E8A317` - Saffron)**: The core action color. Used for primary CTAs, active tab selections, connection triggers, and milestone badges. To maintain rigorous WCAG AA accessibility, buttons filled with Saffron must always utilize Charcoal text (`#1F2421`), never white.
- **Secondary (`#2F6B4F` - Basil Green)**: Represents growth, trust, validated career markers, affirmative notifications, verified checkmarks, and active links.
- **Tertiary / Alerts (`#D6452F` - Tomato)**: Used for destructive operations, critical warnings, form validation failures, and urgent connection requests.
- **Neutral / Text (`#1F2421` - Charcoal)**: The primary ink for high-contrast reading, iconography, and structured borders.
- **Canvas (`#FFF6E0` - Cream)**: The foundational background canvas that provides warmth without causing eye fatigue.
- **Surfaces (`#FFFFFF` - Pure White)**: Applied to distinct content containers and feed cards to separate foreground data from the cream canvas cleanly.

## Typography

Typography relies on **Plus Jakarta Sans** across all hierarchies to combine approachable geometric curves with crisp structural terminals. 

Guidelines:
- Francophone text length expands by an average of 15–25% compared to English equivalents. Line heights are intentionally generous (`26px` for `16px` body copy) to avoid visual density and clipping.
- Dynamic Headlines are bold and expressive to deliver warmth and human presence.
- Avoid allcaps in long French copy to respect accented characters (`É`, `À`, `Ç`) and preserve reading speed. Allcaps is strictly reserved for `label-sm` metadata tags.

## Layout & Spacing

A mobile-first fluid layout calibrated for smartphones of various screen widths (360dp to 430dp):

- **Grid & Gutters:** A 4-column fluid layout with `16px` (`1rem`) gutters and `16px` outer horizontal margins. On tablets or foldables (600dp+), max canvas width is constrained to `540px` centered to maintain intimate mobile single-column reading ergonomics.
- **Touch Ergonomics:** All interactive touch points enforce a minimum bounding box of `48px` (height and width) to guarantee effortless thumb taps during transit or single-handed usage.
- **Spacing Rhythm:** Structured on a consistent 4px/8px modular scale (`space-xs` = 4px, `space-sm` = 8px, `space-md` = 16px, `space-lg` = 24px, `space-xl` = 32px).

## Elevation & Depth

Depth is established through natural tonal contrast (White `#FFFFFF` layered over Cream `#FFF6E0`) supplemented by subtle ambient shadows:

- **Level 0 (Canvas):** Pure `#FFF6E0`.
- **Level 1 (Cards, Feed Tiles, Lists):** Surface `#FFFFFF` with an ambient shadow: `box-shadow: 0 2px 8px -2px rgba(31, 36, 33, 0.06), 0 1px 3px 0 rgba(31, 36, 33, 0.04)`.
- **Level 2 (Modals, Bottom Sheets, Floating Action Buttons):** Surface `#FFFFFF` with elevated shadow: `box-shadow: 0 10px 25px -5px rgba(31, 36, 33, 0.12), 0 4px 10px -2px rgba(31, 36, 33, 0.04)`.
- **Hardware Performance Optimization:** Avoid backdrop blurs (`backdrop-filter`) and complex multi-layered box shadows to guarantee smooth 60fps scrolling on entry-level Android devices.

## Shapes

The shape system blends friendly structural containers with soft interactive pills:

- **Cards and Containers:** Feature a consistent corner radius of `16px` (`rounded-lg` according to base scale), creating a modern, welcoming pebble feel.
- **Buttons, Badges, and Chips:** Use full pill roundness (`9999px` / `rounded-full`), accentuating touchability and actionability.
- **Input Fields:** Styled with `12px` to `16px` border radii to maintain harmonious corner nesting with parent cards.

## Components

All interface elements are presented in standard French terminology:

### Boutons (Buttons)
- **Bouton Principal (Primary):** Background Saffron (`#E8A317`), text Charcoal (`#1F2421`, `label-lg`), height `48px` minimum, fully rounded (`rounded-full`), horizontal padding `24px`.
- **Bouton Secondaire (Secondary):** Surface transparent, border 1.5px solid Basil Green (`#2F6B4F`), text Basil Green, fully rounded.
- **Bouton Neutre (Ghost):** Background transparent, text Charcoal, fully rounded, active state reveals an 8% Saffron tint.

### Fiches (Cards)
- Background `#FFFFFF`, border-radius `16px`, ambient drop shadow, internal padding `16px` (`space-md`).
- Used for profile summaries (*Profils recommandés*), connection activity (*Activité du réseau*), and opportunity posts (*Opportunités*).

### Puces & Badges (Chips & Tags)
- **Puce de filtre (Filter Chip):** Unselected uses `#FFFFFF` with a 1px border `#E5DAC1` and Charcoal text. Selected uses Basil Green (`#2F6B4F`) fill with `#FFFFFF` text. Fully rounded, height `36px`, padding `12px`.
- **Badge de statut:** Compact pill container, height `24px`, font `label-sm`, pairing secondary/tertiary colors at 12% opacity with solid text (e.g., *Vérifié* in Basil Green).

### Champs de Saisie (Input Fields)
- Height `52px`, background `#FFFFFF`, border 1.5px solid `#E6DECA`, border-radius `12px`, padding `0 16px`.
- Active focus state changes border to Basil Green (`#2F6B4F`) with no outer glow. Error state uses Tomato (`#D6452F`) with contextual error message placed directly beneath in `body-sm`.
- Placeholder text in softened charcoal (`#6C746E`).

### Cases à cocher & Boutons Radio (Checkboxes & Radios)
- Minimum tap area `48px × 48px` centered on a `20px` visible mark.
- Selected state fills with Basil Green (`#2F6B4F`) with pure white icon check/dot.

### Navigation Inférieure (Bottom Navigation)
- Fixed at screen bottom, surface `#FFFFFF`, height `64px`, border-top 1px solid `#EFE6CF`.
- Active item uses Saffron highlight indicator dot beneath the icon, active label in Charcoal (`#1F2421`).