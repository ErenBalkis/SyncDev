# Ambient Transparent Glass — Style Reference
> Frosted Glass · Black & Solar Orange · Spatial Depth

**Theme:** Dark Glassmorphism — "Ambient Transparent Glass"

OnyxFi adopts a deep, immersive dark aesthetic built on a Black & Solar Orange abstract background. Glass cards are highly transparent to let the vivid background show through the blur, creating true depth. Inter typography at white/white-opacity provides maximum legibility on the dark substrate. Solar Orange is the singular, energetic accent for all interactive and financial data elements.

---

## Tokens — Colors & Opacity

In a dark glassmorphic UI, solid colors are replaced by opacities. **All text must be white-based** for contrast over the dark background.

| Name | Value | Token | Role |
|------|-------|-------|------|
| Midnight Ink | `#0A0000` | `AppColors.midnightInk` | Near-black base with warm orange undertone. Fallback scaffold bg. |
| Obsidian Surface | `#120400` | `AppColors.obsidianSurface` | Elevated surface for tooltip/popup backgrounds. |
| Deep Slate | `#1A0800` | `AppColors.deepSlate` | Inactive button fill, disabled states. |
| Glass Heavy | `rgba(255,255,255, 0.08)` | `AppColors.glassHeavy` | Sidebars and modals. Slightly more opaque for hierarchy. |
| Glass Light | `rgba(255,255,255, 0.05)` | `AppColors.glassLight` | Input field fills, secondary panels. |
| Frost Border | `rgba(255,255,255, 0.20)` | `AppColors.frostBorder` | **Critical 1px border on ALL glass elements.** Defines the edge. |
| Snow White | `#FFFFFF` | `AppColors.snowWhite` | Primary headings, balances, emphasized text. |
| Silver Mist | `rgba(255,255,255, 0.70)` | `AppColors.silverMist` | Secondary body text, AI chat messages, labels. |
| Stone Grey | `rgba(255,255,255, 0.45)` | `AppColors.stoneGrey` | Tertiary text, placeholders, inactive icons, timestamps. |
| Solar Orange | `#FF7A00` | `AppColors.solarOrange` | **Primary accent.** CTAs, active nav, chart lines, toggles. |
| Solar Orange Subtle | `rgba(255,122,0, 0.15)` | `AppColors.solarOrangeSubtle` | Hover/active pill backgrounds for nav items. |
| Growth Mint | `#10B981` | `AppColors.growthMint` | Semantic "success/online" indicator only. |
| Amber Flame | `#F59E0B` | `AppColors.amberFlame` | Semantic "warning" indicator only. |
| Crimson Pulse | `#EF4444` | `AppColors.crimsonPulse` | Semantic "danger/error" indicator only. |
| Solid White | `#FFFFFF` | `AppColors.solidWhite` | Text placed directly on Solar Orange elements. |

---

## Tokens — Effects (Crucial for Glassmorphism)

| Name | Value | Flutter Implementation | Role |
|------|-------|------------------------|------|
| Blur Medium | `20px` | `ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)` | Standard backdrop blur for cards and panels. |
| Blur Heavy | `24px` | `ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0)` | Sidebar and modal blur for stronger visual hierarchy. |
| Glass Shadow | `0 8px 32px rgba(0,0,0, 0.30)` | `BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 32)` | Lifts glass off the background. |
| Orange Glow | `0 4px 24px rgba(255,122,0, 0.30)` | `AppColors.orangeGlow` | Primary CTA and accent element glow. |
| Orange Glow Subtle | `0 4px 16px rgba(255,122,0, 0.18)` | `AppColors.orangeGlowSubtle` | Inner glow for selected/active states. |

---

## Tokens — Typography

### Inter — Primary typeface · `--font-inter`
- **Role:** All UI text. Clean and legible over complex dark backgrounds.
- **Weights:** 400 (Body), 500 (Buttons/Labels), 600 (Headings), 700 (Balances).

### Type Scale
| Role | Size | Line Height | Letter Spacing | Color |
|------|------|-------------|----------------|-------|
| caption | 12px | 1.5 | -0.007px | `Stone Grey (45%)` |
| body-sm | 14px | 1.43 | -0.013px | `Silver Mist (70%)` |
| body | 16px | 1.38 | -0.02px | `Silver Mist (70%)` |
| subheading | 20px | 1.33 | -0.022px | `Snow White` |
| heading | 32px | 1.25 | -0.025px | `Snow White` |

> **Rule:** Never use dark `Ink Text` or `Slate Text` colors. All text is white or white-with-opacity.

---

## Tokens — Spacing & Shapes

**Density:** Comfortable — the background must breathe through the transparent glass.
- **Card padding:** 24px or 32px
- **Element gap:** 8px or 16px
- **Border Radius:**
  - Cards: `20px`
  - Sidebar: `24px`
  - Buttons/Pills: `9999px` (fully rounded)

---

## Components & Flutter Guide

### Glass Card
**Role:** Main container for dashboard widgets and GenUI components.
**Flutter Spec:**
```dart
ClipRRect(borderRadius: BorderRadius.circular(20))
  └─ BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))
       └─ Container(
            color: Colors.white.withOpacity(0.05),      // highly transparent
            border: Border.all(
              color: Colors.white.withOpacity(0.20),    // frost border
              width: 1.0,
            ),
          )
```
Use `GlassContainer` widget — all parameters pre-configured.

### Primary Action Button (Solid)
**Role:** Main CTA ("Onayla", "Başlayalım", "Devam").
**Flutter Spec:** Solid `Solar Orange (#FF7A00)` background with orange glow shadow. Text: `Solid White`, weight 600. Radius: 9999px. **No blur** — creates contrast against glass.

### Ghost / Glass Button
**Role:** Secondary actions ("Atla", "İptal").
**Flutter Spec:** `Glass Light` background + Blur 20. `Frost Border` 1px. Text: `Snow White`.

---

## Do's and Don'ts

### Do
- Always use a visually interesting background (abstract Black & Orange image or gradient) so the blur effect is visible and meaningful.
- Apply `Frost Border (rgba(255,255,255,0.20))` to **every** glass element — this is what makes glass look like glass on a dark background.
- Use `Snow White` and `Silver Mist` for text. Never dark colors.
- Use `Solar Orange` exclusively for interactive accents (buttons, chart lines, active nav, selected states).
- Keep the legibility overlay at **40% black** — not heavier — so the background shows through the transparent cards.

### Don't
- Don't use `Ink Text (#1A1B20)` or `Slate Text (#4A4D59)` — these are from the old light theme and will be invisible on a dark background.
- Don't replace `glassHeavy`/`glassLight` with solid dark colors — it destroys the glass effect.
- Don't use `Electric Blue (#3B82F6)` — Solar Orange is the sole primary accent.
- Don't make the legibility overlay too heavy (>60% black) — glass cards won't show any background through them.
- Don't add heavy shadows (>30% opacity) — use the dispersed `glassShadow`.

---

## Agent Prompt Guide (Flutter Context)

When generating Flutter code for this UI, ALWAYS adhere to these strict rules:

1. **Core Layout:** Root of every screen MUST be a `Stack`.
   - **Layer 0:** Dynamic `Image.asset(bgImage, fit: BoxFit.cover)` with error fallback to `AppColors.midnightGradient`. **Do NOT remove the dynamic image mechanism.**
   - **Layer 1:** `Container(color: Colors.black.withOpacity(0.40))` legibility overlay. Sits directly above the image.
   - **Layer 2:** Ambient `Container` glows using `RadialGradient` with `AppColors.solarOrange` at 15–25% opacity. Positioned off-screen at corners.
   - **Layer 3:** `SafeArea` with all interactive UI.

2. **Glass Cards:** Use the `GlassContainer` widget. NEVER use solid `Colors.white` or solid dark colors for card backgrounds.
   - Standard card: `opacity: 0.05`, `blurSigma: 20`, `borderRadius: 20`
   - Heavy (sidebar/modal): `GlassContainer.heavy()` — `opacity: 0.10`, `blurSigma: 24`, `borderRadius: 24`

3. **Typography:** Primary text → `AppColors.snowWhite`. Secondary → `AppColors.silverMist`. Tertiary → `AppColors.stoneGrey`. Never use `Color(0xFF1A1B20)` or similar dark ink.

4. **Accents:** Use `AppColors.solarOrange` for all interactive elements. Use `AppColors.orangeGradient` for gradient buttons and icon containers. Apply `AppColors.orangeGlow` or `AppColors.orangeGlowSubtle` as glow shadows on interactive elements.

5. **Charts (fl_chart):**
   - Line color: `AppColors.solarOrange`
   - Dot color: `AppColors.solarOrange`, stroke: `AppColors.midnightInk`
   - Below-bar gradient: Solar Orange 28% → 0%
   - Grid lines: `AppColors.frostBorder` (white 20% opacity), vertical lines hidden

---

## Components — Data Visualization (Charts)

**Aesthetics:** Minimalist, no harsh grid lines, smooth bezier curves.
- **Line Charts:** `isCurved: true`. Primary line: `Solar Orange (#FF7A00)`. Gradient fill below fades from `rgba(255,122,0, 0.28)` to transparent.
- **Grid Lines:** Vertical lines hidden. Horizontal lines use `Frost Border` (white 20% opacity).
- **Tooltips:** Dark glass pill (`ObsidianSurface` bg, 92% opacity). Value text in `Solar Orange`.

---

## Layout & Architecture

- **Stack is Mandatory:** Every screen root is a `Stack`.
- **Layer 0 (Bottom):** Full-screen dynamic background image (`Image.asset`).
- **Layer 1 (Middle):** `Container(color: Colors.black.withOpacity(0.40))` — contrast equalizer.
- **Layer 2 (Glows):** `Positioned` circular containers with `RadialGradient` Solar Orange glows.
- **Layer 3 (Top):** `SafeArea` → main UI content (`Row` for desktop sidebar layout, `Column` for mobile).

---

## Components — Navigation

### Sidebar (Desktop)
- `GlassContainer.heavy()`: `ClipRRect(radius: 24)` + `BackdropFilter(sigmaX: 24)` + `color: white 10%`
- **Active nav item:** `Solar Orange` icon + text, `solarOrangeActive` pill background, `Solar Orange 30%` border
- **Inactive nav item:** `Stone Grey` icon + text, no background
- **AI status indicator:** Solar Orange pulsing dot with orange-tinted pill background

### Bottom Nav (Mobile)
- `GlassContainer` with `borderRadius: 0`
- Active icon: `Solar Orange`; Inactive icon: `Stone Grey`