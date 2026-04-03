# Design System Specification: The Mindful Athlete

## 1. Overview & Creative North Star
Most running applications rely on aggressive "high-performance" aesthetics—neon accents, italicized "fast" fonts, and high-contrast dark modes. This design system rejects that tension in favor of a **Creative North Star: The Pastoral Path.**

This system is built on **Soft Minimalism**. It treats the interface not as a cockpit of data, but as a digital landscape that is calm, breathable, and deeply intentional. We move beyond the "template" look by utilizing asymmetrical white space and a high-end editorial typography scale. The goal is to make the user feel as though they are reading a premium wellness journal rather than a utility app.

---

## 2. Colors & Tonal Depth
We utilize a sophisticated palette of Forest Greens and Mint washes to create an environment that feels organic and fresh.

### The Palette (Material Design Tokens)
*   **Primary (Action):** `#005235` (High-contrast Forest)
*   **Primary Container (Brand):** `#1B6B4A` (The signature Forest Green)
*   **Surface:** `#F7FAF5` (A warm, off-white "Paper" base)
*   **Secondary Container:** `#D6E3DC` (Used for inactive states or secondary grouping)
*   **Tertiary (Accent/Alert):** `#753134` (A muted, earthy red for critical data)

### The "No-Line" Rule
To maintain a premium editorial feel, **1px solid borders are prohibited for sectioning.** Boundaries must be defined solely through background color shifts. 
*   Place a `surface-container-lowest` (#FFFFFF) card on a `surface` (#F7FAF5) background to define the container.
*   Use `secondary-container` to highlight a specific data cell without "boxing" it in.

### Surface Hierarchy & Nesting
Treat the UI as stacked sheets of fine paper. 
*   **Base Level:** `surface` (#F7FAF5)
*   **Level 1 (Sections):** `surface-container-low` (#F1F5EF)
*   **Level 2 (Interactive Cards):** `surface-container-lowest` (#FFFFFF)
*   **Level 3 (Floating Overlays):** Use semi-transparent `primary-fixed-dim` (#8AD6AE) with a `20px` backdrop-blur to create a "Frosted Mint" glass effect for navigation bars.

---

## 3. Typography: The Editorial Voice
We use **Manrope** (or SF Pro as a fallback) to provide a modern, geometric clarity that feels more "designed" than standard system fonts.

*   **The Display Scale:** Use `display-sm` (2.25rem) for daily mileage. The large scale creates an "editorial hero" moment on the dashboard.
*   **The Headline/Body Relationship:** Use `headline-sm` (1.5rem) for section titles (e.g., "Weekly Progress") paired with `body-md` (0.875rem) for descriptions. 
*   **Intentional Contrast:** Keep label text (`label-md`) in `on-surface-variant` (#3F4943) to ensure it stays secondary to the primary metrics.

---

## 4. Elevation & Depth
Depth in this system is achieved through **Tonal Layering**, not structural shadows.

*   **The Layering Principle:** A "Card" is simply a `#FFFFFF` shape on a `#F7FAF5` background. The slight shift in hue provides all the affordance necessary.
*   **Ambient Shadows:** If a floating action button (FAB) or high-priority modal requires a shadow, it must be an "Ambient Glow":
    *   *Y: 8px, Blur: 24px, Spread: -4px, Color: rgba(24, 29, 26, 0.06)*. This mimics natural light rather than a digital drop shadow.
*   **The "Ghost Border" Fallback:** If accessibility requires a border (e.g., in high-glare outdoor running conditions), use `outline-variant` (#BFC9C0) at **20% opacity**. It should be felt, not seen.

---

## 5. Components

### Cards & Lists
*   **Card Radius:** Always `12dp` (0.75rem). 
*   **No Dividers:** Forbid the use of horizontal lines. Use `16dp` or `24dp` of vertical white space to separate list items. 
*   **The "Metric Block":** A `surface-container-highest` block with centered `display-sm` text for key data points (Pace, Heart Rate).

### Buttons
*   **Primary:** `primary-container` (#1B6B4A) background with `on-primary` (#FFFFFF) text. High-pill radius (`full`). 
*   **Secondary:** `secondary-container` background with `on-secondary-container` text. This is for "Add Note" or "Share" actions.
*   **Ghost:** No background, `primary` text. Used for "Cancel" or "View All."

### Chips
*   **Filter Chips:** Use `secondary-fixed` for unselected and `primary-fixed` for selected. Avoid heavy outlines; the color shift is the indicator.

### Input Fields
*   **Minimalist Entry:** No bottom-line or box. Use a subtle `surface-container-low` background with a `12dp` corner radius. The label should sit `8dp` above the field in `label-md` uppercase.

### Progress Indicators
*   **The "Organic Track":** Use a thick (8dp) track in `secondary-container` with the progress fill in `primary`. Avoid rounded caps on progress bars to maintain a modern, architectural look.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical padding. Give the top of a page `48dp` of breathing room, while sides stay at `20dp`.
*   **Do** use "Glassmorphism" for the bottom navigation bar to allow the run-map or content to bleed through elegantly.
*   **Do** prioritize "Tonal Transition" over "Line Separation."

### Don't
*   **Don't** use 100% black (#000000). Use `on-surface` (#181D1A) for all "black" text to keep the look soft.
*   **Don't** use "Sporty" italics. All typography must be upright and stable to maintain the "Calm" brand personality.
*   **Don't** use standard iOS blue for links. Everything interactive must stem from the Forest (`primary`) or Mint (`primary-fixed`) tones.