# Pronexa design

Dark navy, flat and quiet. The layout keeps the structure of the Asteria design the project owner supplied (an indigo header block with the key number and four actions, navy list panels, a floating white pill navigation) and the Assistant Pill for describing meals.

**No gradients, glows or blur.** Solid fills only. Copy is as short as it can be: a title and the number, rarely a sentence. No status badges, no slogans, no filler, no exclamation marks.

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
| `bg` | `#07101C` | App background, launch screen | n/a |
| `surface` / `surface2` | `#111A2C` / `#18233A` | Panels / tracks, steppers | n/a |
| `line` | `#222E46` | Hairlines | n/a |
| `ink` / `ink2` / `ink3` | `#FFFFFF` / `#C3C8D1` / `#9AA3B2` | Text | 19.1 / 11.4 / 7.5:1 on bg; ink3 6.8:1 on surface |
| `indigo` | `#20296B` | Header, hero panels, Assistant Pill, launcher icon | white 13.2:1 |
| `indigo2` | `#293477` | Selected pills, rows and tiles | white 11.3:1 |
| `onIndigo2` | `#B9C2E8` | Secondary text on indigo | 7.5:1 |
| `blue` / `blueInk` | `#50A2FF` / `#8FC2FF` | Ring, focus, switches / protein numbers on panels | 6.6 / 9.4:1 on surface |
| `good` / `goodBg` | `#5FD38A` / `#13291F` | "Looks clear", gap closed | 9.3:1 on surface |
| `warm` / `warmBg` | `#F5B971` / `#2A2116` | Gaps, guesses, delete (never red) | 10.0:1 on surface |
| `tile` | `#E9EDF5` | Light tile behind food illustrations | n/a |

Primary buttons are white with `bg` text (19.1:1). The nav pill is white; its idle icons are `#5C6478` (5.9:1) and the active button is `indigo`.

## Type

Poppins (Regular, Medium, SemiBold; OFL, bundled as TTF), with the ₦ glyph from a 1.4 KB Nunito subset as fallback. Sizes: 44 display number, 26 page title, 18 section title, 16 body, 14 secondary, 12.5 caption, 11 caps label.

## Shape

Radii 13 (icon tiles), 18 (action tiles), 22 (panels), 30 (header and sheets), pill for buttons and chips. Tap targets 44–62 px.

## Assistant Pill (`lib/ui/widgets/assistant_pill.dart`)

A 64 px pill in `indigo` with a flat orb on the left (blue disc with a white seed). The orb turns into a progress ring while reading. Example prompts rotate every 3 seconds with a short fade and rise (stopped under reduced motion). The send button turns white when there is text. The WebGL plasma orb from the original file was removed with the other glow effects.

## Motion (`lib/ui/widgets/motion.dart`)

Short and eased (`easeOutCubic`), 160–420 ms, nothing bouncy and nothing looping except the example prompts.

- Pages fade in with a 4% upward slide; tabs fade through.
- Lists and cards rise in with a 45 ms stagger (`Appear`).
- Tiles, pills, nav buttons and actions shrink slightly while pressed (`Pressable`); selection colours cross-fade.
- Onboarding and Portion steps cross-slide (`FadeSwap`); progress bars glide.
- The protein number counts up and the ring fills over 0.9 s.

Every animation is skipped when the phone's "remove animations" setting is on (`MediaQuery.disableAnimations`).
