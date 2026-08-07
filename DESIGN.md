---
name: Azure Horizon Desktop
colors:
  surface: '#faf9fd'
  surface-dim: '#dad9de'
  surface-bright: '#faf9fd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f7'
  surface-container: '#eeedf1'
  surface-container-high: '#e9e7ec'
  surface-container-highest: '#e3e2e6'
  on-surface: '#1a1c1f'
  on-surface-variant: '#42474f'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f4'
  outline: '#727780'
  outline-variant: '#c2c7d1'
  surface-tint: '#2a6196'
  primary: '#003760'
  on-primary: '#ffffff'
  primary-container: '#0e4e82'
  on-primary-container: '#8ec0fb'
  inverse-primary: '#9fcaff'
  secondary: '#535f70'
  on-secondary: '#ffffff'
  secondary-container: '#d7e3f8'
  on-secondary-container: '#596576'
  tertiary: '#6e5d16'
  on-tertiary: '#ffffff'
  tertiary-container: '#bfaa5c'
  on-tertiary-container: '#4c3e00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#9fcaff'
  on-primary-fixed: '#001d36'
  on-primary-fixed-variant: '#02497d'
  secondary-fixed: '#d7e3f8'
  secondary-fixed-dim: '#bbc7db'
  on-secondary-fixed: '#101c2b'
  on-secondary-fixed-variant: '#3c4858'
  tertiary-fixed: '#fae28d'
  tertiary-fixed-dim: '#dcc574'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#554600'
  background: '#faf9fd'
  on-background: '#1a1c1f'
  surface-variant: '#e3e2e6'
typography:
  display-lg:
    fontFamily: Work Sans
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Work Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Work Sans
    fontSize: 28px
    fontWeight: '500'
    lineHeight: 36px
  title-lg:
    fontFamily: Work Sans
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Work Sans
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  gutter: 24px
  margin-desktop: 32px
  container-max: 1440px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

This design system is built for high-stakes professional environments within the real estate and construction sectors. The visual narrative centers on **Corporate Modernism**, utilizing Material Design 3 (M3) principles to ensure clarity, efficiency, and structural integrity. 

The aesthetic is characterized by:
- **Professionalism:** A disciplined use of whitespace and alignment that mirrors architectural precision.
- **Trust & Reliability:** A cooling color palette and stable typography that communicate long-term value and structural safety.
- **Functional Density:** Optimized for desktop users who manage complex data, multi-step registrations, and project dashboards.

The interface evokes a sense of "digital blueprints"—organized, layered, and purposeful. It avoids unnecessary decoration, focusing instead on utilitarian elegance and systemic consistency.

## Colors

The color strategy follows the M3 tonal palette system, anchored by the brand's primary navy.

- **Primary (#0E4E82):** Used for key action buttons, active states, and brand identifiers. It represents authority and the "Azure" sky of the horizon.
- **Secondary:** A muted slate blue-grey used for utility components, supporting icons, and less prominent UI elements to prevent visual fatigue.
- **Tertiary:** A golden-ochre used sparingly for specialized highlights, such as project status indicators or "Urgent" construction alerts.
- **Neutral:** A comprehensive scale of greys used for surfaces, borders, and secondary text.

**Surface Tones:**
The design utilizes "Surface Tint" logic. In light mode, surfaces are primarily white (#FFFFFF) with container levels (1-5) gaining subtle grey increments to distinguish nested content.

## Typography

The typographic scale provides a clear hierarchy for information-dense applications.

- **Headlines (Work Sans):** Chosen for its professional and grounded feel. Heavy weights are used for project titles and dashboard headers.
- **Body (Inter):** A systematic, utilitarian typeface that remains highly legible in long-form registration forms and data tables.
- **Labels (JetBrains Mono):** Introduced for technical data points (e.g., Plot IDs, SKU numbers, or Coordinates) to provide a distinct "technical" texture to the construction-focused UI.

**Hierarchy Rules:**
- Use **Title-MD** for card headers and navigation items.
- Use **Body-MD** for all input fields and descriptions.
- Use **Label-MD** exclusively for metadata and technical indicators.

## Layout & Spacing

The design system employs a **Fixed Grid** system for desktop environments to maintain structural alignment across wide monitors.

- **Grid:** A 12-column grid with 24px gutters.
- **Max Width:** Content is capped at 1440px to ensure line lengths remain readable.
- **Density:** High-density spacing is used for dashboards (4px/8px increments), while registration forms use more generous vertical rhythm (16px/32px) to reduce cognitive load during complex data entry.

**Responsive Behavior:**
On desktop, side navigation is persistent (256px width). On tablet/smaller screens, the navigation collapses into a rail or drawer, and the grid shifts to 8 columns.

## Elevation & Depth

Consistent with M3, depth is communicated through **Tonal Layers** rather than heavy shadows.

- **Level 0 (Flat):** The main background.
- **Level 1 (Surface):** Default card state. Uses a subtle +5% neutral tint.
- **Level 2 (Hover/Raised):** Used for interactive cards. Includes a soft, diffused shadow (0px 2px 6px rgba(0,0,0,0.08)).
- **Level 3 (Overlays):** Used for modals and dropdown menus. These use a more pronounced shadow and a 1px border (#E1E2E6) to ensure separation from the background.

Avoid "floating" elements. Every component should feel like it is part of a structured, physical plane.

## Shapes

The shape language is **Soft (0.25rem)**. While M3 often defaults to highly rounded or pill-shaped buttons, this design system uses more conservative radii to maintain a serious, corporate tone.

- **Small Components:** Checkboxes and Radio buttons use a 2px radius.
- **Standard Components:** Buttons and Input fields use the base 4px (0.25rem) radius.
- **Large Components:** Dashboard cards and Modals use 8px (0.5rem) to provide a modern, contained feel without appearing "playful."

## Components

### Buttons
- **Primary:** Solid #0E4E82 with white text. High emphasis for "Submit Registration" or "Add Project."
- **Tonal:** Secondary color tint with dark text. Medium emphasis for "Save Draft."
- **Outlined:** 1px border for "Cancel" or "Go Back" actions.

### Input Fields
- **Style:** M3 "Outlined" style. Labels should be small and sit on the border when active.
- **Validation:** Clear error states using a semantic red (#B3261E) with supporting icons for accessibility.
- **Complex Forms:** Use "Sectioned" inputs with horizontal dividers to group related data (e.g., Company Info vs. Site Location).

### Data Tables
- Use **Inter** at 14px.
- Alternate row shading is omitted in favor of thin 1px horizontal dividers to maintain a "blueprint" look.
- Header rows use a subtle neutral background with **Title-Small** typography.

### Cards
- Use for dashboard metrics and individual project previews.
- Ensure 24px internal padding (gutter-match) for visual consistency.

### Steppers
- Crucial for construction company registration. Use a vertical stepper on desktop sidebars to show progress through the multi-page application.