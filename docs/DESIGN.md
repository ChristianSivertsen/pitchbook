# Sva design language

Sva is named after the smooth, sea-worn granite of the Norwegian coast. The brand comes from one scene: Lofoten granite rising straight out of the sea under the midnight sun. Read from left to right, the peaks rise like a graph, because the app is about seeing your climbing grow. A low midnight sun sits beside them at night and stands over them by day.

Every screen should feel like that scene: calm and dark like a summer night by the sea, warm where it matters, and clear enough to read at a glance.

The clickable prototype in [`prototype/index.html`](../prototype/index.html) shows the screens and behaviour. This document wins over the prototype on look and feel.

## Principles

1. **Calm, then warm.** Surfaces are quiet: night blue in dark mode, sand in light mode. Colour is saved for what matters: your progress, the next action, the route line.
2. **Data first, decoration never.** Numbers, grades and charts must be readable in one glance. No ornament that competes with them.
3. **One accent at a time.** Each screen has at most one primary action in the accent colour.
4. **Climbers' language.** Use the words climbers use: send, onsight, redpoint, crux, pitch, rack. Short sentences, no hype.
5. **Same in the dark.** Dark mode (Midnight sun) is the brand's home. Light mode (Daylight) is the same palette inverted, not a different brand.

## Logo

The mark is three shapes on a horizon line: the sun, a peak and a higher peak. The wordmark is always lowercase: **sva**.

The sun tells the time of day. In Midnight sun it hangs low on the left, just above the horizon. In Daylight it stands high on the upper right of the higher peak. Wherever the theme changes, the sun rises or sets along an arc, slipping behind the summit (`SvaMotion.daybreak`, 900 ms), and the mark's colours fade with it. With reduce motion on, it moves straight to its new place.

| Asset | File | Use |
|---|---|---|
| Mark, dark background | [`assets/brand/sva-mark-midnight.svg`](../assets/brand/sva-mark-midnight.svg) | Dark mode, splash, social |
| Mark, light background | [`assets/brand/sva-mark-daylight.svg`](../assets/brand/sva-mark-daylight.svg) | Light mode, documents (sun upper right) |
| Mark, one colour | [`assets/brand/sva-mark-mono.svg`](../assets/brand/sva-mark-mono.svg) | Watermarks, embossing, single-colour print |
| App icon | [`assets/brand/sva-app-icon.svg`](../assets/brand/sva-app-icon.svg) | 1024 × 1024 source for iOS and Android icons |
| Lockup | [`assets/brand/sva-lockup-midnight.svg`](../assets/brand/sva-lockup-midnight.svg) | Splash screen, store listing, stickers |

Rules:

- **Clear space** around the mark equals the sun's diameter.
- **Minimum size:** 24 px for the mark with wordmark, 16 px for the mark alone.
- **Do not** recolour the mark outside the palettes below, rotate it, add effects, or change the order of the peaks. The rising peaks are the progress story; only the sun moves, and only between its two places.
- The app icon is full-bleed and square; iOS and Android apply their own rounding.

## Colour

Two palettes, one brand. Values are tokens in `packages/sva_ui` (ticket M0-4). Screens never use raw hex values.

### Midnight sun (dark, default)

| Token | Hex | Use |
|---|---|---|
| `background` | `#1B2240` | Page background (the night sky) |
| `surface` | `#232B4D` | Cards, sheets |
| `surfaceSunk` | `#141A33` | Inputs, wells, tab bar |
| `line` | `#343D63` | Borders, dividers, chart grid |
| `text` | `#F7E7CE` | Primary text (foam) |
| `textMuted` | `#A9AECB` | Secondary text, labels |
| `granite` | `#E07A5F` | Brand colour: higher peak, route lines, selected states |
| `graniteLight` | `#F0A08A` | Lower peak, secondary brand fills |
| `sun` | `#F2B544` | **Accent**: log button, primary action, personal bests |
| `onSun` | `#1B2240` | Text and icons on `sun` |
| `sea` | `#6FB3C2` | Links, information, sea and water |

### Daylight (light)

| Token | Hex | Use |
|---|---|---|
| `background` | `#FBF5EC` | Page background (sand) |
| `surface` | `#FFFFFF` | Cards, sheets |
| `surfaceSunk` | `#F3EADB` | Inputs, wells, tab bar |
| `line` | `#E4D8C5` | Borders, dividers, chart grid |
| `text` | `#1B2240` | Primary text (night) |
| `textMuted` | `#5B6185` | Secondary text, labels |
| `granite` | `#AC482F` | Brand colour, darkened for contrast on light |
| `graniteLight` | `#D4694C` | Secondary brand fills and chart marks (3.3 : 1 on sand) |
| `sun` | `#AC482F` | **Accent** (in daylight the sun is the coral one) |
| `onSun` | `#FFFFFF` | Text and icons on the accent |
| `sea` | `#2E6E7E` | Links, information |

### Semantic and climbing colours

These keep their meaning in both modes. Shades are adjusted per mode in the tokens so text on them meets contrast rules.

| Meaning | Midnight sun | Daylight |
|---|---|---|
| Success, OK | `#7CC49A` | `#2D764C` |
| Warning, due soon | `#F2B544` | `#85590A` |
| Danger, overdue, delete | `#F07A70` | `#B33A30` |
| Onsight | `#6FB3C2` | `#2E6E7E` |
| Flash | `#F2B544` | `#85590A` |
| Redpoint | `#E07A5F` | `#AC482F` |
| Repeat | `textMuted` | `textMuted` |
| Attempt | outline in `textMuted` | outline in `textMuted` |

Gym colour grades use the gym's own colours from the data, shown as a filled chip with automatic black or white text.

### Contrast

- Body text and labels: at least 4.5 : 1 against their background (WCAG AA).
- Large text (24 px and up, or 19 px bold), icons and chart marks: at least 3 : 1.
- The token tests in M0-4 check every text/background pair listed here.

## Typography

| Role | Family | Size / line height | Weight | Use |
|---|---|---|---|---|
| Wordmark | Fraunces | — | 600 | The logo only |
| Display | Fraunces | 32 / 36 | 600 | Screen titles (Feed, History, CV) |
| Title | Fraunces | 22 / 28 | 600 | Session titles, section headers |
| Headline | Inter | 17 / 24 | 600 | Card titles, route names |
| Body | Inter | 15 / 22 | 400 | Running text |
| Label | Inter | 13 / 18 | 500 | Buttons, chips, form labels |
| Caption | Inter | 12 / 16 | 400 | Metadata, timestamps |
| Number | Inter, tabular figures | 22 / 26 | 600 | Stats, grades in stat rows |
| Grade badge | Inter, tabular figures | 14 / 16 | 700 | Grade chips |

- Both fonts are open source (SIL Open Font License) and bundled with the app, not loaded at runtime.
- Serif (Fraunces) is for titles only. Everything you read or tap is sans (Inter).
- Sentence case everywhere. Uppercase only for tiny overlines, with 0.08 em letter spacing.
- Numbers that line up in columns or change (stats, timers, tables) always use tabular figures.
- Text scales with the system setting up to 200 %. Layouts wrap; they never clip.

## Space, shape and depth

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 20, 24, 32, 40, 48 |
| Screen side padding | 16 (20 on large phones) |
| Corner radius | 8 small (chips, inputs), 12 cards, 16 large cards and photos, 24 sheets, full for pills and avatars |
| Touch target | At least 44 × 44 |
| Borders | 1 px `line` |

Depth comes from surface colour, not shadows: `surfaceSunk` < `background` < `surface`. Only sheets and the log button carry a soft shadow.

## Components

| Component | Rules |
|---|---|
| **Log button** | Centre of the tab bar, `sun` fill, `onSun` plus icon, 52 × 52, radius 16. The single most important action in the app |
| **Primary button** | `sun` fill, `onSun` label. One per screen |
| **Secondary button** | Transparent, 1 px `line` border, `text` label |
| **Destructive button** | Transparent, `danger` border and label; confirmation states what will be lost |
| **Chip** | Radius 8, `surfaceSunk` fill; selected: `text` fill with `background` label. Disabled chips are struck through with a hint explaining why |
| **Grade badge** | Radius 6, `text` fill with `background` label, tabular figures. Gym grades use the gym colour |
| **Style tag** | Small rounded label in the climbing colour for onsight, flash, redpoint; outline for attempt |
| **Card** | `surface`, radius 12, 16 padding, no shadow. Session cards lead with the topo or wall image |
| **Sheet** | Slides up, radius 24 at the top, header with close or back on the left and title in the centre |
| **Stat** | Number in the Number style, caption below in `textMuted` |
| **Empty state** | One line saying what will appear and one action to add the first item. Never an apology |
| **Toast** | `text` fill, `background` label, bottom above the tab bar, 2.5 s |

## Icons and illustration

- **Icons:** Lucide (outline), 24 px (20 px in dense rows). One family only. The selected tab uses the same icon in the `text` colour; unselected tabs use `textMuted`.
- **Topos:** the route line is `granite` with a 2 px foam (`#F7E7CE`) casing so it reads on any photo. Symbols: bolts as white circles with a cross, gear as `sea` triangles, belays as double rings, crux as a small `danger` square with C.
- **Gear and shoe drawings:** flat shapes with one light-to-dark shading direction, item colour from the data, on a neutral tile.
- **Gym walls:** plywood tones with holds in the climbed colours.
- **Photos** are always the user's own; never stock imagery.

## Data visualisation

- Chart series in this order: `granite`, `sun`, `sea`, `graniteLight`, `textMuted`.
- Ascent styles always use the climbing colours above, in the order onsight, flash, redpoint.
- Charts sit on `background` or `surface`, never inside `surfaceSunk` wells (the lighter series would drop below 3 : 1 there).
- Grid lines in `line`, axis labels in `textMuted` Caption, values in tabular figures.
- The latest or best data point is emphasised (larger dot, label); everything else stays quiet.
- Every chart has a text summary for screen readers.

## Motion

| Use | Duration | Curve |
|---|---|---|
| Taps, chip toggles | 120 ms | ease out |
| Cards, list changes | 200 ms | ease out |
| Sheets in and out | 300 ms | ease out / ease in |
| A new personal best | 600 ms, once | spring; the only celebratory motion in the app |
| The sun in the mark when the theme changes | 900 ms | ease in and out, along an arc |

All motion respects the system's reduce-motion setting: transitions become fades or none.

## Writing

- Short, direct, sentence case. No exclamation marks, no "successfully", no "please".
- Buttons say exactly what happens: "Save session", "Add climb", "Remove from rack".
- Errors say what went wrong and what to do: "Couldn't save. Check your connection and try again."
- Use climbing terms as climbers do. Grades are shown in the user's chosen system.
- Units: metric, with a space before the unit (`15 m`, `14 °C`). Dates like `1 Nov 2026`, times in 24-hour format.
- **Every text the user can see is translated.** Norwegian Bokmål and English ship from the start; more languages are added as one file each. See [Languages](#languages).

## Languages

- Text lives in ARB files (JSON) in `app/lib/l10n/`: `app_en.arb` (English, the template) and `app_nb.arb` (Norwegian Bokmål). Flutter generates typed accessors (`AppLocalizations.of(context).logButton`).
- The app follows the phone's language. Norwegian phones (Bokmål, Nynorsk or plain Norwegian) get Bokmål; any other language falls back to English. A manual language choice comes with the settings screen.
- Add a language: copy `app_en.arb` to `app_<code>.arb`, translate it, and add the code to the language test.
- Never hard-code user-facing text in widgets. The brand name "sva" is the only exception.
- Plurals, numbers, dates and units use the ARB plural and placeholder syntax with the locale's formats, never string concatenation.
- Norwegian copy follows the same voice: short, direct, sentence case. Climbing terms stay as Norwegian climbers say them (onsight, flash, redpoint, crux; "økt" for a session, "taulengde" for a pitch).

## Accessibility

- Contrast rules above, checked in tests.
- Every interactive element has a semantic label; every chart has a text alternative.
- Colour is never the only signal: styles also have text, states also have icons or labels.
- Text scaling to 200 %, reduce motion, and both VoiceOver and TalkBack are part of every UI ticket's definition of done.
