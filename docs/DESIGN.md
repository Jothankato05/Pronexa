# Pronexa design system

Pronexa uses the **Asteria** visual language supplied by the project owner: a dark "night" canvas with a soft blue-indigo gradient, glass surfaces, white pill actions, a white "paper" sheet for lists, and a floating pill navigation. The AI entry point is the **Assistant Pill** (plasma orb, rotating prompts, sweeping status steps). The product voice stays warm and kind: no red warnings, no "bad food" labels, carbs are fuel, and every number is an estimate.

All tokens live in `src/styles/app.css` under `:root`, with a `.paper` scope that switches the same components to light tokens.

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
| Token | Value | Use |
|-------|-------|-----|
| `--night` | `#07101C` | Canvas (Asteria base) |
| `--night-2` | `#0A0E17` | Key Feature / Settings base |
| `--grad-header` | `#6F8BB2 → #3B4C7B → #24315B → #141D43 → #07101C` | Dashboard header (top stop raised for contrast) |
| `--grad-card` | `#6D86B3 → #1C2462 → #07101C` | Hero cards, celebration |
| `--grad-cta` | `#07101B → #293477` | Active nav button, primary on paper |
| `--surface` | `rgb(255 255 255 / .05)` + `--line` `rgb(255 255 255 / .10)` | Glass |
| `--ink` / `--ink-2` / `--ink-3` | white / 74% / 62% | Text on night (62% = 7.2:1; the design's 40% fails AA, so it is not used for text) |
| `--accent` | `#50A2FF` | Settings icons, toggles, tags |
| `--good` | `#5FD38A` (night) / `#00873A` (paper) | Protein gains |
| `--gap` | `#F5B971` (night) / `#A85A12` (paper) | The gap: warm amber, never red |
| paper `--ink-3` | `rgb(0 0 0 / .58)` | Secondary text on white (the design's 40% black is 2.8:1, so it is raised) |

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
Shadows: `0 25px 50px rgb(0 0 0/.25)` for pills and nav; `0 40px 80px rgb(0 0 0/.5)` for hero cards.

### Motion
Ease `cubic-bezier(.22,1,.36,1)`; screens rise 8 px and fade; the ring fills over 900 ms; the gap-closed moment is a burst plus a gradient card. The plasma orb animates only when allowed. `prefers-reduced-motion` stills everything, and low-data mode keeps the CSS orb and the system font.

### Touch and layout
Single column, max 480 px, 24 px gutters (18 px under 370 px). Tap targets are 40 px or more (most 48–64). The floating nav has four 56 px buttons. Primary actions sit in the bottom third.

## 3. Assistant Pill integration
- `src/assistant/plasmaOrb.js`: the HorizonX orb renderer (WebGL 2), unchanged and lazy-loaded (6.7 KB gzipped).
- `src/assistant/AssistantPill.tsx`: Preact port of the pill. It keeps the prompt rotation, the blur in and out, the status sweep and the orb states (idle, thinking, warm error). The demo chat and simulated voice are dropped, since Android WebView has no speech recognition.
- Used on Today (quick describe) and on Describe it.
