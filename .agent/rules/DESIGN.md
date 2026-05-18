# Lucid Frost — Style Reference
> Frosted Glass, Ambient Light, Spatial Depth

**Theme:** Light Glassmorphism

Lucid Frost adopts a modern, light-themed spatial aesthetic focused on "glassmorphism." It uses semi-transparent white canvases with backdrop blurs over a subtle, warm-toned mesh background. Inter typography provides utilitarian clarity, ensuring legibility across translucent surfaces. The system minimizes solid backgrounds, relying on opacity, blur, and delicate white borders to define hierarchy, while using a vibrant energetic orange for critical accents and data visualization.

## Tokens — Colors & Opacity

In a glassmorphic UI, solid colors are replaced by opacities. The text must remain dark for contrast.

| Name | Value | Token | Role |
|------|-------|-------|------|
| Ambient Canvas | `#F5F7FA` | `--color-ambient-canvas` | The solid base background color behind all glass elements. Best combined with abstract gradient blobs. |
| Glass Surface Heavy | `rgba(255, 255, 255, 0.05)` | `--color-glass-heavy` | Primary elevated cards. High opacity for readability. |
| Glass Surface Light | `rgba(255, 255, 255, 0.2)` | `--color-glass-light` | Secondary cards, panels, and input backgrounds. |
| Frost Border | `rgba(255, 255, 255, 0.3)` | `--color-frost-border` | Critical 1px border applied to all glass elements to give the "edge" effect. |
| Ink Text | `#1A1B20` | `--color-ink-text` | Primary headings, active states, emphasized text. |
| Slate Text | `#4A4D59` | `--color-slate-text` | Secondary body text, subtle labels. |
| Ash Text | `#8A8D98` | `--color-ash-text` | Tertiary text, placeholders, inactive icons. |
| Solar Orange | `#FF7A00` | `--color-solar-orange` | Primary calls to action, active toggles, chart lines. (Brings the energy from the reference image). |
| Solid White | `#FFFFFF` | `--color-solid-white` | Icons, or text placed directly on top of the Solar Orange accent. |

## Tokens — Effects (Crucial for Glassmorphism)

| Name | Value | Flutter Implementation | Role |
|------|-------|------------------------|------|
| Blur Medium | `16px` | `ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)` | Standard backdrop blur for most cards and panels. |
| Blur Heavy | `24px` | `ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0)` | Deep blur for top-level navigation or modals. |
| Glass Shadow | `0 8px 32px rgba(0, 0, 0, 0.05)` | `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 32)` | Soft shadow to lift the glass off the background. |

## Tokens — Typography

### Inter — Primary typeface · `--font-inter`
- **Role:** Functional text, numbers, and UI elements. Clean and legible over complex backgrounds.
- **Weights:** 400 (Body), 500 (Buttons/Labels), 600 (Headings), 700 (Balances/Key Metrics).

### Type Scale
| Role | Size | Line Height | Letter Spacing | Token |
|------|------|-------------|----------------|-------|
| caption | 12px | 1.5 | -0.007px | `--text-caption` |
| body-sm | 14px | 1.43 | -0.013px | `--text-body-sm` |
| body | 16px | 1.38 | -0.02px | `--text-body` |
| subheading | 20px | 1.33 | -0.022px | `--text-subheading` |
| heading | 32px | 1.25 | -0.025px | `--text-heading` |

## Tokens — Spacing & Shapes

**Density:** Comfortable, allowing the background to breathe.
- **Card padding:** 24px or 32px
- **Element gap:** 8px or 16px
- **Border Radius:** - Cards: `20px` (Softer corners fit glassmorphism better).
  - Buttons/Pills: `9999px` (Fully rounded).

## Components & Flutter Guide

### Glass Card
**Role:** Main container for dashboard widgets.
**Flutter Spec:** Use `ClipRRect` (radius 20) -> `BackdropFilter` (blur 16) -> `Container`. 
Container decoration: `color: rgba(255, 255, 255, 0.5)`, `border: 1px solid rgba(255, 255, 255, 0.8)`, soft `BoxShadow`.

### Primary Action Button (Solid)
**Role:** Main CTA (e.g., "Transfer", "Send").
**Flutter Spec:** Solid `Solar Orange (#FF7A00)` background. Text: `Solid White (#FFFFFF)`, Font Weight 600. Radius: 9999px. NO blur needed here to create contrast against the glass.

### Ghost / Glass Button
**Role:** Secondary actions.
**Flutter Spec:** `Glass Surface Light` background with medium blur. 1px `Frost Border`. Text: `Ink Text (#1A1B20)`.

## Do's and Don'ts

### Do
- Always place glass components over a visually interesting background (mesh gradients, abstract shapes, or subtle imagery) so the blur effect is visible.
- Ensure all glass containers have a subtle white border (`rgba(255, 255, 255, 0.8)`) to simulate the reflective edge of glass.
- Use `Ink Text` and `Slate Text` for high legibility on light glass.
- Emphasize financial data (balances, charts) using the `Solar Orange` accent color.

### Don't
- Don't use solid white `#FFFFFF` for large card backgrounds; it destroys the glass effect.
- Avoid heavy, dark drop shadows. Shadows should be highly dispersed and low opacity (max 5-8% black).
- Don't clutter the interface; glassmorphism requires negative space to look premium.

## Agent Prompt Guide (Flutter Context)

When generating Flutter code for this UI, ALWAYS adhere to these strict glassmorphism rules:
1. **Never use standard solid Colors.white for Cards.** Instead, wrap your Container in a `ClipRRect` and a `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))`.
2. The Container inside the BackdropFilter MUST have a semi-transparent color: `color: Colors.white.withOpacity(0.5)`.
3. The Container MUST have a border to define the glass edge: `border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)`.
4. Text on these glass cards must be dark: `color: Color(0xFF1A1B20)` for headings, `Color(0xFF4A4D59)` for subtitles.
5. Use `Color(0xFFFF7A00)` for primary buttons, active chart elements, and important highlights.

## Tokens — Imagery & Background

| Name | Role | Flutter Implementation |
|------|------|------------------------|
| Dynamic Background Image | The foundational layer of the app. Nature landscapes provide organic color variations that enhance the glassmorphism blur effect. | `BoxDecoration` with `DecorationImage(image: AssetImage('...'), fit: BoxFit.cover)` |
| Default Theme | "Soft Nature Landscape". Minimalist, serene nature scenes (e.g., misty mountains, soft sunrise forests, calm oceans) to ensure UI elements remain legible. | Set as the default state variable for the background. |

## Layout & Architecture (Crucial for Dynamic Background)

- **The Stack is Mandatory:** The core layout MUST use a Flutter `Stack` widget.
- **Layer 0 (Bottom):** A full-screen `Container` with the `Dynamic Background Image` (Nature landscape). This layer must listen to a state change so the user can update the background dynamically.
- **Layer 1 (Middle - Legibility Overlay):** A subtle overlay spanning the whole screen to normalize the background contrast. If the landscape is too bright, use `rgba(255, 255, 255, 0.15)`. If it's too dark, adjust accordingly. This ensures the text on the glass cards remains readable regardless of the user's background choice.
- **Layer 2 (Top):** The `SafeArea` containing the scrollable content with the Glass Cards (`ClipRRect` + `BackdropFilter`).

## Agent Prompt Guide (Flutter Context)

When generating Flutter code for this UI, ALWAYS adhere to these strict glassmorphism rules:
1. **Core Layout:** You MUST use a `Stack` as the root of the screen. The bottom layer of the Stack must be an `Image.asset` or `Container` with a `DecorationImage` set to `BoxFit.cover` displaying a soft nature landscape.
2. **State Management for Background:** Ensure the background image path is managed via state so the user can pick different nature scenes later.
3. **Contrast & Legibility:** Always include a semi-transparent `Container` directly above the background image to act as a contrast equalizer before adding the UI elements.
4. **Glass Cards:** Never use solid colors. Wrap your Container in a `ClipRRect` and a `BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16))`.
5. The Container inside the BackdropFilter MUST have `color: Colors.white.withOpacity(0.5)` and `border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)`.
6. Text on these glass cards must be dark: `color: Color(0xFF1A1B20)` for headings, `Color(0xFF4A4D59)` for subtitles.
7. Use `Color(0xFFFF7A00)` (Solar Orange) for primary buttons, active chart elements, and important highlights to create a vibrant contrast against the nature background.

## Components — Data Visualization (Charts)

**Role:** Displaying financial or analytical data in a premium, highly legible format over glass surfaces.
**Aesthetics:** Minimalist, no harsh grid lines, smooth curves, and vibrant data points.
- **Line Charts:** Use smooth bezier curves. The primary line should use `Solar Orange (#FF7A00)` with a soft, semi-transparent gradient fill below the line fading into the glass background.
- **Bar Charts:** Bars should have heavily rounded top corners (e.g., radius 6px) and use a mix of `Solar Orange` for active/current data and a subdued `Ash Text` color with lower opacity for past data.
- **Grid Lines:** Hide vertical grid lines entirely. Make horizontal grid lines extremely subtle: `rgba(26, 27, 32, 0.05)` (Ink Text color with 5% opacity).
- **Tooltips:** When a user taps on a data point, the tooltip should be a distinct, small glass pill (Heavy Blur) to clearly show the exact number.

## Layout & Architecture (Crucial for Customizable Dashboard)

- **The Stack is Mandatory:** The core layout MUST use a Flutter `Stack` widget.
- **Layer 0 (Bottom):** Full-screen `Container` with the `Dynamic Background Image` (Nature landscape).
- **Layer 1 (Middle):** Legibility overlay `rgba(255, 255, 255, 0.15)`.
- **Layer 2 (Top - Draggable Dashboard):** The main content area must use a customizable grid layout. 
  - **Flutter Implementation:** Use a package like `reorderable_grid_view` or flutter's native `Draggable` and `DragTarget` widgets combined with a `Wrap` or `GridView`.
  - **Widget States:** Each glass card (chart, balance, stats) must be treated as an individual, movable widget. The layout order must be saved in the state so the user's custom arrangement persists.

## Agent Prompt Guide (Flutter Context)

When generating Flutter code for this UI, ALWAYS adhere to these strict glassmorphism and interactivity rules:
1. **Core Layout:** `Stack` -> Background Image (Nature) -> Legibility Overlay -> SafeArea content.
2. **Draggable Dashboard:** Implement the dashboard area using a reorderable grid structure (e.g., `ReorderableGridView` or custom `LongPressDraggable` setup). The user MUST be able to long-press and drag a chart/card to swap its position with another.
3. **Glass Cards:** Wrap movable Containers in `ClipRRect(radius: 20)` -> `BackdropFilter(sigmaX: 16, sigmaY: 16)`. Use `color: Colors.white.withOpacity(0.5)` and `border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)`.
4. **Premium Charts:** If implementing charts (e.g., using the `fl_chart` package):
   - Set `isCurved: true` for line charts.
   - Use `Color(0xFFFF7A00)` for the main data lines.
   - Remove background grid lines (`drawVerticalLine: false`, `drawHorizontalLine: false` or extremely low opacity).
   - Add a subtle gradient below line charts using `Colors.orange.withOpacity(0.2)` fading to transparent.
5. Text on these glass cards must be dark: `Color(0xFF1A1B20)` for headings, `Color(0xFF4A4D59)` for subtitles.

## Components — Navigation (Sidebar/Drawer)

**Role:** Primary navigation, user profile access, and quick settings (like Theme/Background change) located on the left side of the screen.
**Aesthetics:** A "floating" glass panel. It should not stretch fully from top to bottom; instead, it should have margins to appear as if it's floating above the nature landscape.
- **Glass Sidebar:** Higher blur than regular cards for stronger hierarchy. `ClipRRect(radius: 24)` with `BackdropFilter(sigmaX: 24, sigmaY: 24)`. 
- **User Avatar:** A prominent circular image at the top of the sidebar.
- **Nav Items (Inactive):** Text and icons in `Ash Text (#8A8D98)`.
- **Nav Items (Active):** Text and icons in `Solar Orange (#FF7A00)` with a very subtle, soft orange background pill `rgba(255, 122, 0, 0.1)`.

## Layout & Architecture (Crucial for Layout Structure)

- **The Stack is Mandatory:** The core layout MUST use a Flutter `Stack`.
- **Layer 0 & 1:** Nature Background Image + Legibility Overlay.
- **Layer 2 (Top - Main UI):** A `SafeArea` containing a `Row`.
  - **Left Child (Sidebar):** A fixed-width container (e.g., 250px) for the Glass Sidebar, with external margins (e.g., `EdgeInsets.all(16)`).
  - **Right Child (Main Content):** An `Expanded` widget containing the draggable dashboard area and main content.

## Agent Prompt Guide (Flutter Context)

When generating Flutter code for this UI, ALWAYS adhere to these layout rules:
1. **Screen Structure:** Use a `Scaffold` where the `body` is a `Stack`.
2. **Foreground Layout:** Inside the Top layer of the Stack, use a `Row`. The left side of the Row must be the Sidebar (fixed width, floating appearance with margins). The right side must be `Expanded` for the dashboard.
3. **Sidebar Styling:** The Sidebar MUST be a floating glass card. `ClipRRect(radius: 24)` -> `BackdropFilter(sigmaX: 24, sigmaY: 24)` -> `Container` with `color: Colors.white.withOpacity(0.4)` and a white `border`.
4. **Sidebar Content:** Include a user avatar at the top, a list of navigation items (Home, Analytics, Settings, Change Background) in the middle, and a logout button at the bottom.
5. **Active States:** Highlight the currently selected navigation item using the `Color(0xFFFF7A00)` (Solar Orange).