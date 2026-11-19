# Pronexa design system

Pronexa's **colours** (warm off-white canvas, soft leaf green, terracotta for the gap, ochre for value) on the **Asteria layout** supplied by the project owner: a gradient header, pill actions, a white "paper" sheet for lists, hero gradient cards and a floating pill navigation. The AI entry point is the **Assistant Pill**, recoloured to forest green with a leaf-and-ochre plasma orb. The product voice stays warm and kind: no red warnings, no "bad food" labels, carbs are fuel, and every number is an estimate.

All tokens live in `src/styles/app.css` under `:root`. A `.green` scope (also applied to the dashboard header, hero cards, splash and totals) switches the same components to light-on-green tokens, and `.paper` softens tiles inside the white sheets.

## 1. Screen list

| Asteria frame | Pronexa screen | Route | Brief step |
|---------------|----------------|-------|------------|
| Splash | Welcome: mark, "Making every meal count", promises, white "Get started" pill | onboarding 0 | 1 |
| Registration | Diet → allergies (separate) → weight → activity → target reveal + backup consent | onboarding 1–5 | 1 |
| Dashboard | **Today**: gradient header with target, gap and diet pills; big "g eaten" with the progress ring; Pick / Portion / Describe / Solve actions; Assistant Pill; white "Today's meals" sheet | `#/today` | 4 |
| (Dashboard pattern) | Log home: Quick pick, Portion mode, Describe it, Photo (coming soon) | `#/log` | 2 |
| (Dashboard pattern) | Quick pick: searchable Nigerian food tiles, plant proteins first, tray | `#/log/quick` | 2a |
| (Dashboard pattern) | Portion mode: container pictures → what filled it → extras → ¾/½/¼ eaten | `#/log/portion` | 2b |
| Assistant Pill | Describe it: English/Pidgin in the pill, status steps while reading, offline fallback | `#/log/describe` | 2c |
| Key Feature | Confirm: confidence, one question, white sheet of editable chips (food, portion, eaten), total | `#/log/confirm` | 3 |
| Key Feature | **Suggestions / Gap Solver**: gradient gap card, budget chips, plant-first toggle, white sheet with combos, upgrades and ranked foods | `#/suggestions` | 5 |
| Settings | Profile: avatar card, How you eat, Your estimate, Preferences (low-data, backup, sync), Privacy, About the numbers, Demo tools | `#/settings` | n/a |
| Key Feature card | Learn + coming-soon screens (lessons, ₦500 Challenge, Meal Planner, Campus Map, Photo mode) | `#/learn`, `#/learn/soon` | later |

## 2. Tokens

### Colour
| Token | Value | Use | Contrast |
|-------|-------|-----|----------|
| `--bg` | `#FAF7F2` | Warm off-white canvas | n/a |
| `--surface` / `--surface-2` | `#FFFFFF` / `#F2ECE3` | Cards / insets, icon tiles, tracks | n/a |
| `--line` | `#E7DFD3` | Hairlines | n/a |
| `--ink` / `--ink-2` / `--ink-3` | `#2B2A27` / `#5C574F` / `#6B645A` | Text | 13.4 / 6.7 / 5.5:1 on bg |
| `--leaf-600` | `#3B7A4F` | Primary buttons, selected chips, toggles | white text 5.1:1 |
| `--leaf-700` | `#2E6340` | Green text, protein gains | 6.6:1 on bg |
| `--leaf-100` / `--leaf-50` | `#E4EFE0` / `#F1F6EE` | Selected tiles, "pretty sure" | leaf-700 text 6.0:1 |
| `--clay-700` / `--clay-100` | `#9C4F25` / `#F8E7DA` | The gap, destructive actions (never red) | 5.5:1 on bg, 4.9:1 on tint |
| `--ochre-800` / `--ochre-100` | `#7A5410` / `#F6EBCF` | Protein-per-₦ tags, guesses to check, questions | 5.7:1 |
| `--grad-header` | `#3E7A51 → #357049 → #2E6340 → #1F4A33` | Dashboard header (Asteria Dashboard shape) | white 5.9:1 at the lightest text point |
| `--grad-card` | `#4A8459 → #2E6340 → #1F4A33` | Hero cards, totals, celebration | white ≥ 5:1 |
| `--grad-cta` | `#3B7A4F → #2E6340` | Primary pill buttons, active nav | white 5.1:1 |
| green scope | white / 90% / 86% text; `#DCEFD5` gains; `#FADFC9` gap; `#F6EBCF` value | Text on green areas | ≥ 4.6:1 |
| Assistant Pill | body `#2C5E41 → #1A3F2C`, text `#F4F1EA`, prompts `#BFD3C2`; orb deep `#1F5A37`, glass `#5A9A68`, rim `#C9DFC3`, plasma `#A8D89A`, spark `#E2B04A` | AI entry point | 8.9 / 6.4:1 |

### Type: Poppins (OFL) in place of Gotham
Gotham is not included with the design and not licensed here; Poppins was named in the project brief and is the closest geometric match. Weights 400/500/700, Latin subset, 7.8 KB each. Poppins has no ₦ glyph, so a 1.3 KB Nunito subset fills in U+20A6 under the same family name.

| Token | Spec | Asteria source |
|-------|------|----------------|
| `--t-display` | 500 48/1, −0.05em | Balance "$24,092.67" |
| `--t-hero` | 500 30/1.08, uppercase on splash | "Redefine your financial orbit" |
| `--t-h2` | 500 18/1.4, −0.025em | "Flow History", "Digital Key" |
| `--t-body` | 400 16/1.5 | Book 16 |
| `--t-caption` | 500 12 | Row subtitles |
| `--t-label` | 500 10.5, +0.1em, uppercase | "ADD", "SYSTEM PROTOCOLS" |

### Shape and depth
`--r-xs 11` (40 px buttons) · `--r-sm 13` (48 px icon tiles) · `--r-md 18` (64 px actions) · `--r-lg 22` (avatar, tiles) · `--r-xl 30` (cards, sheets) · `--r-pill 999`.
Shadows are warm-tinted (`rgb(60 45 25)`) on the canvas and green-tinted (`rgb(31 74 51)`) under green surfaces.

### Motion
Ease `cubic-bezier(.22,1,.36,1)`; screens rise 8 px and fade; the ring (ochre to sage) fills over 900 ms; the gap-closed moment is a leaf/ochre burst plus a green gradient card. The plasma orb animates only when allowed. `prefers-reduced-motion` stills everything, and low-data mode keeps the CSS orb and the system font.

### Touch and layout
Single column, max 480 px, 24 px gutters (18 px under 370 px). Tap targets are 40 px or more (most 48–64). The floating nav has four 56 px buttons. Primary actions sit in the bottom third.

## 3. Assistant Pill integration
- `src/assistant/plasmaOrb.js`: the HorizonX orb renderer (WebGL 2), unchanged and lazy-loaded (6.7 KB gzipped).
- `src/assistant/AssistantPill.tsx`: Preact port of the pill, recoloured to the Pronexa palette. It keeps the prompt rotation, the blur in and out, the status sweep and the orb states (idle, thinking, warm error). The demo chat and simulated voice are dropped, since Android WebView has no speech recognition.
- Used on Today (quick describe) and on Describe it.

## 4. Android
App icon: the leaf mark with an ochre seed on a leaf-green gradient (adaptive background `#2E6340`). Window background `#FAF7F2`. Splash: leaf-green gradient. The status bar uses dark icons on the off-white screens and switches to light icons over the green Today header and the splash (`src/lib/systemBars.ts`).
