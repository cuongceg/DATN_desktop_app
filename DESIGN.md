# Design DNA: Crystalline Classroom (Edu Deaf)

This document outlines the visual identity and design system for the **Edu Deaf** project, extracted from its core design tokens and screen patterns.

## Brand & Style
The design system is built on the principles of **Glassmorphism**, tailored for a desktop productivity environment. It aims to evoke clarity, depth, and modern sophistication. The UI utilizes multi-layered translucency for spatial awareness without sacrificing legibility. The emotional response is intended to be "calmly energetic"—professional yet vibrant.

## Colors
The palette centers on high-vibrancy "Electric Blue" and "Soft Purple" against a neutral foundation of translucent whites and cool grays.

### Core Palette
- **Primary (Electric Blue):** `#0040e0` / `#2e5bff` (Container)
- **Secondary (Soft Purple):** `#731be5` / `#8d42ff` (Container)
- **Tertiary:** `#005e67` / `#007984` (Container)
- **Surface:** `#f7f9fb` (Background) / `#eceef0` (Container)
- **Outline:** `#747688` / `#c4c5d9` (Variant)

### Surface Strategy
Backgrounds are never fully opaque, utilizing varying degrees of alpha-transparency. Every glass element features a 1px "luminous" border—a high-opacity white or light-blue stroke to define edges.

## Typography
A dual-font strategy is used to maximize character and readability.

- **Lexend (Headlines/Display):** rhythmic, wide-aperture design to reduce visual stress.
  - **Display Large:** 36px, Bold (700), 44px Line Height
  - **Headline Medium:** 24px, Semi-Bold (600), 32px Line Height
- **Inter (Body/Labels/Tables):** neutral, systematic clarity.
  - **Body Large:** 16px, Regular (400), 24px Line Height
  - **Body Small:** 14px, Regular (400), 20px Line Height
  - **Label Caps:** 12px, Semi-Bold (600), 16px Line Height, 0.05em Tracking
  - **Table Header:** 13px, Semi-Bold (600), 18px Line Height

## Layout & Spacing
A fluid grid model with an 8px linear scale.

- **Spacing Unit:** 8px
- **Standard Gutters:** 24px
- **Page Margins:** 32px
- **Component Gap:** 16px
- **Sidebar:** 260px (Expanded) / 72px (Collapsed)

## Shapes (Border Radius)
The design employs a **Rounded** aesthetic to feel approachable.

- **Small (Buttons/Inputs):** `4px` (0.25rem)
- **Default (Standard Elements):** `8px` (0.5rem)
- **Medium (Cards/Tables):** `12px` (0.75rem)
- **Large (Main Content):** `16px` (1rem)
- **XL (Modals/Shells):** `24px` (1.5rem)
- **Full:** `9999px`

## Elevation & Depth
Depth is achieved through **Backdrop Blur** and **Z-axis Layering**.

1. **Level 0 (Background):** Subtle mesh gradient.
2. **Level 1 (Main Canvas):** 20px backdrop blur, `rgba(255, 255, 255, 0.4)`.
3. **Level 2 (Cards/Sidebar):** 40px backdrop blur, `rgba(255, 255, 255, 0.7)`.
4. **Level 3 (Modals/Popovers):** 60px backdrop blur, 2px luminous border.

## Component Patterns

### Collapsible Sidebar
- Glass background with 40px blur.
- Vertical pill indicator in primary color for active states.
- 1px luminous border on the right.

### Data Tables
- Transparent rows with `rgba(255, 255, 255, 0.2)` hover highlights and subtle blur.
- Headers with 1px bottom border.

### Quick Filter Buttons
- Translucent white with 1px luminous border.
- Active state uses a primary-to-secondary gradient.

### Input Fields
- Understated glass "wells" with inner luminous strokes.
- Focus state uses a primary color 2px border.

### Classroom Cards
- "Frosted" header area and more transparent body area for internal hierarchy.
