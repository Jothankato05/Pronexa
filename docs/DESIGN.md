# Pronexa design

Flat, warm and plain. The layout keeps the structure of the Asteria design the project owner supplied (a header block with the key number and four actions, white list panels, a floating pill navigation) and the Assistant Pill for describing meals, in Pronexa's colours.

**No gradients, glows or blur.** Solid fills only. Copy is short and factual: no slogans, no filler, no exclamation marks.

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
| `bg` | `#FAF7F2` | Warm off-white canvas | n/a |
| `surface` / `surface2` | `#FFFFFF` / `#F2ECE3` | Panels / tiles, tracks | n/a |
| `line` | `#E7DFD3` | Hairlines | n/a |
| `ink` / `ink2` / `ink3` | `#2B2A27` / `#5C574F` / `#6B645A` | Text | 13.4 / 6.7 / 5.5:1 on bg |
| `leaf700` | `#2E6340` | Header block, hero panels, green text | white 6.6:1 |
| `leaf600` | `#3B7A4F` | Buttons, selected states, active nav | white 5.1:1 |
| `leaf800` | `#1F4A33` | Assistant Pill, snack bars | white 10:1 |
| `leaf100` / `leaf50` | `#E4EFE0` / `#F1F6EE` | Selected tiles, "looks clear" | leaf700 text 6.0:1 |
| `clay700` / `clay100` | `#9C4F25` / `#F8E7DA` | Gap, delete (never red) | 5.5 / 4.9:1 |
| `ochre800` / `ochre100` | `#7A5410` / `#F6EBCF` | Value tags, "check this", questions | 5.7:1 |
| `onGreen2` | white at 86% | Secondary text on green | 5.7:1 on leaf700 |

## Type

Poppins (Regular, Medium, SemiBold; OFL, bundled as TTF), with the ₦ glyph from a 1.4 KB Nunito subset as fallback. Sizes: 44 display number, 26 page title, 18 section title, 16 body, 14 secondary, 12.5 caption, 11 caps label.

## Shape

Radii 13 (icon tiles), 18 (action tiles), 22 (panels), 30 (header and sheets), pill for buttons and chips. Tap targets 44–62 px.

## Assistant Pill (`lib/ui/widgets/assistant_pill.dart`)

A 64 px pill in `leaf800` with a flat orb on the left (sage disc with an ochre seed). The orb turns into a progress ring while reading. Example prompts rotate every 3 seconds with a plain fade (stopped under reduced motion), and the send button is cream. The WebGL plasma orb from the original file was removed with the other glow effects.

## Motion

The ring fill eases over 0.9 s. Screens use the platform's default page transitions. Nothing loops except the example prompts. All motion respects the system "reduce motion" setting.
