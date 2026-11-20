# Pronexa design

Pronexa follows the Asteria design the project owner supplied, screen by screen:

| Asteria screen | Pronexa screen | What carries over |
|----------------|----------------|-------------------|
| Splash | Welcome | The mark on the canvas, a caps headline, one white button |
| Registration | Onboarding steps | Big title, pill-shaped choices with a 10% white outline, white when chosen |
| Dashboard | Today | Indigo header with chips, a 48 px number and four 64 px square actions; a white sheet with plain list rows |
| Key Feature | Close the gap, Check your meal | The number centred on the dark canvas, the details below |
| Settings | Log a meal, Learn, Profile | Caps section labels and outlined groups of rows with blue icons |

**Clean means few things on screen.** Lists are plain rows with a light icon tile, a title and a value, never boxes inside boxes. Secondary text is softer white, not another container. Copy is a title and the number, rarely a sentence. No status badges, no slogans, no exclamation marks.

**Solid colours only.** Asteria's two gradients (header and splash) are flattened: the header and its cards are solid `indigo`, and the welcome screen is the plain `bg` canvas. No gradients, glows or blur anywhere.

## Screens

| Screen | File | Brief step |
|--------|------|------------|
| Welcome | `lib/ui/screens/onboarding.dart` (`_Welcome`) | 1 |
| Diet → allergies → weight → activity → target | `onboarding.dart` | 1 |
| Today (gap, ring, actions, meals) | `today.dart` | 4 |
| Log home | `log_home.dart` | 2 |
| Pick | `quick_pick.dart` | 2a |
| Portion | `portion_mode.dart` | 2b |
| Describe (Assistant Pill) | `describe.dart` | 2c |
| Photo | `photo.dart` | 2d (enabled) |
| Confirm | `confirm.dart` | 3 |
| Close the gap | `suggestions.dart` | 5 |
| Learn (and "coming later" items) | `learn.dart` | later |
| Profile and data | `settings.dart` | n/a |

Screenshots are in `docs/screens/` (render them with `flutter test test_screens --update-goldens`).

## Colours (`lib/ui/theme.dart`)

| Token | Value | Use | Contrast |
|-------|-------|-----|----------|
| `bg` | `#0A0E17` | Canvas, launch screen | n/a |
| `ink` / `ink2` / `ink3` | white / white 70% / white 60% | Text on the canvas | 19.6 / 9.6 / 7.3:1 |
| `line` / `fill` | white 10% / white 5% | Group and input outlines / chip and button fills, hairlines | n/a |
| `indigo` / `indigo2` | `#20296B` / `#293477` | Today header, hero and question cards, active nav, launcher icon / profile avatar | white 13.2 / 11.3:1; white 70% 7.3:1 on indigo |
| `blue` | `#50A2FF` | Icons, progress, switches, protein values on dark | 7.3:1 on canvas |
| `warm` / `good` | `#F5B971` / `#5FD38A` | "Check this", delete (never red) / "Looks clear" | 11.1 / 10.6:1 |
| `sheet`, `sInk`, `sInk2` | white, `#07101C`, `#666666` | White sheet and its text | 19.1 / 5.7:1 |
| `sTile` | `#F2F4F7` | Icon tiles (also on dark, so the food drawings stay visible) | n/a |
| `sGood` / `sWarm` | `#007A2E` / `#9A4A08` | Green and amber text on the sheet | 5.5 / 6.3:1 |

Primary buttons are white with black text, 60 px tall. Selected pills, choices and tiles turn white with black text.

## Type

Asteria uses Gotham, which isn't bundled (no licence). Pronexa uses Poppins (Regular, Medium, SemiBold; OFL, bundled as TTF), mostly Medium as Asteria does, with the ₦ glyph from a 1.4 KB Nunito subset as fallback. Sizes follow Asteria: 48 key number (−2.4 tracking), 30 onboarding title, 18 screen and section titles, 16 row titles, 12 subtitles, 10 caps labels.

## Shape

Radii 13 (icon tiles), 18 (action buttons), 22 (picker tiles), 30 (groups, cards and sheets), pill for buttons, chips and choices. Tap targets 44–72 px. Side padding 28.

## Assistant Pill (`lib/ui/widgets/assistant_pill.dart`)

A 64 px pill with a 5% white fill and a 10% outline (blue when focused), and a flat orb on the left (blue disc with a white seed). The orb turns into a progress ring while reading. Example prompts rotate every 3 seconds with a short fade and rise (stopped under reduced motion). The send button turns white when there is text. The WebGL plasma orb from the original file was removed with the other glow effects.

## Motion (`lib/ui/widgets/motion.dart`)

Short and eased (`easeOutCubic`), 160–420 ms, nothing bouncy and nothing looping except the example prompts.

- Pages fade in with a 4% upward slide; tabs fade through.
- Lists and cards rise in with a 45 ms stagger (`Appear`).
- Tiles, pills, nav buttons and actions shrink slightly while pressed (`Pressable`); selection colours cross-fade.
- Onboarding and Portion steps cross-slide (`FadeSwap`); progress bars glide.
- The protein number counts up and the ring fills over 0.9 s.

Every animation is skipped when the phone's "remove animations" setting is on (`MediaQuery.disableAnimations`).
