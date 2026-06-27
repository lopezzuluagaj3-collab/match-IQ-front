---
name: MatchIQ
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#43474c'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#74777d'
  outline-variant: '#c3c7cd'
  surface-tint: '#4c6075'
  primary: '#000f1d'
  on-primary: '#ffffff'
  primary-container: '#0f2537'
  on-primary-container: '#788da3'
  inverse-primary: '#b3c9e0'
  secondary: '#3b618a'
  on-secondary: '#ffffff'
  secondary-container: '#aacffe'
  on-secondary-container: '#325881'
  tertiary: '#001209'
  on-tertiary: '#ffffff'
  tertiary-container: '#002a1a'
  on-tertiary-container: '#009e6d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cfe5fd'
  primary-fixed-dim: '#b3c9e0'
  on-primary-fixed: '#061d2f'
  on-primary-fixed-variant: '#34495c'
  secondary-fixed: '#d1e4ff'
  secondary-fixed-dim: '#a4c9f8'
  on-secondary-fixed: '#001d36'
  on-secondary-fixed-variant: '#204971'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.4'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 16px
  md: 24px
  lg: 40px
  xl: 64px
  container-max: 1280px
  gutter: 24px
---

## Brand & Style
The design system for MatchIQ embodies a sophisticated "Intelligent Professionalism." It bridges the gap between high-stakes B2B enterprise reliability and the agile, innovative spirit of modern AI-driven SaaS. The aesthetic is anchored in **Corporate Modernism** with selective **Glassmorphic** accents to signify technological depth.

The target audience consists of decision-makers and high-output professionals who value clarity, speed, and data-backed confidence. The UI evokes a sense of "Calm Intelligence"—minimizing cognitive load through structured layouts while using vibrant emerald accents to highlight AI-driven insights and successful outcomes.

## Colors
The palette is dominated by a foundational Deep Navy, providing a stable, authoritative backdrop. 

- **Primary & Deep Tones:** Used for high-level structural elements like sidebars, primary text, and headers to establish hierarchy.
- **AI Accents:** Emerald Green is reserved strictly for "Success" states, AI-generated matches, and positive data trends. It should never be used for decorative elements that lack functional meaning.
- **Functional Blues:** Mid-tones serve as secondary interaction colors, while Light Blue acts as a subtle background tint for grouped content.
- **Glass Effects:** Transparent overlays use the `blue-100` tint at low opacities with high blur to maintain legibility.

## Typography
This design system utilizes **Inter** exclusively to leverage its systematic, highly legible nature. 

- **Weight Strategy:** Use ExtraBold (800) for hero displays to create impact. SemiBold (600) is the default for interactive elements like buttons and tabs.
- **Readability:** Body text uses a generous 1.5–1.6 line height to ensure long-form data or descriptions remain approachable.
- **Scale:** On mobile, large headlines scale down aggressively to prevent awkward word breaks, while body text remains consistent at 16px for accessibility.

## Layout & Spacing
The layout follows a **Fluid Grid** model with strict 8px increments. 

- **Desktop:** A 12-column grid with 24px gutters. Page margins are set to 40px minimum.
- **Tablet:** An 8-column grid with 16px gutters and 24px margins.
- **Mobile:** A 4-column grid with 16px gutters and 16px margins.
- **Rhythm:** Vertical spacing between sections should scale from 40px (Mobile) to 64px+ (Desktop) to maintain a feeling of openness and "air."

## Elevation & Depth
Depth is communicated through a combination of tonal layering and soft shadows.

1.  **Level 0 (Base):** Subtle light-blue or neutral-white backgrounds.
2.  **Level 1 (Cards):** Pure white background, `border-subtle`, and a soft shadow (0px 4px 20px rgba(15, 37, 55, 0.08)).
3.  **Level 2 (Modals/Popovers):** Standard card style with an increased shadow spread (0px 12px 32px rgba(15, 37, 55, 0.12)).
4.  **Glass Layer:** Navigation bars use a backdrop filter (blur 12px) over a semi-transparent white (opacity 0.8) to allow content to peak through without sacrificing readability.

## Shapes
The design system uses a generous roundedness strategy to soften the corporate navy tones. 

- **Standard Elements:** Buttons and small inputs use a 0.5rem (8px) radius.
- **Content Containers:** Main cards and content blocks use a prominent **20px to 26px** radius, creating a modern "app-like" feel.
- **Interactive Indicators:** Status badges and active state markers in the sidebar use fully rounded (pill-shaped) ends.

## Components

- **Buttons:** 
    - *Primary:* Deep Navy (#0F2537) background with white text.
    - *AI CTA:* A linear gradient from Emerald-500 to Emerald-600.
    - *Secondary:* Ghost style with `border-subtle` and Navy text.
- **Cards:** White surfaces with 24px corner radius. KPI cards should feature Bold (700) Display-sized numbers in Deep Navy.
- **Sidebars:** Dark Navy background. The active state is indicated by a vertical Emerald bar (4px width) on the leading edge and a subtle Navy-800 background tint for the row.
- **Input Fields:** 1px `border-subtle` with a 8px corner radius. On focus, the border shifts to Blue-500 with a subtle outer glow.
- **Badges:** Use low-saturation background tints of the status color (e.g., light emerald for "Matched") with high-saturation text for contrast.
- **Data Visuals:** Simple, clean progress bars using Emerald for positive completion and Blue-500 for neutral progress.
- **Avatars:** Use circular masks with subtle linear gradients in blue/emerald tones for placeholder states.