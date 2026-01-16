# VoiceType Design System

## Overview
This design system ensures visual consistency across the VoiceType macOS Application, Floating Widget, and Website. The aesthetic is **Minimal**, **Native-feeling**, and **Productive**.

## Color Palette

### Primary Colors
*   **Pro Blue**: `#007AFF` (System Blue)
    *   *Usage*: Primary Actions, Links, AI Rewrite Icon, Active States, Settings Accent.
*   **Deep Space (Black)**: `#171717` (Gray 900)
    *   *Usage*: Widget Background, Primary Text, Hero Headings.
*   **Clean White**: `#FFFFFF`
    *   *Usage*: Card Backgrounds, Widget Text, Secondary Buttons.

### Secondary Colors
*   **Canvas (Warm Gray)**: `#FAFAFA` (Gray 50)
    *   *Usage*: Website Backgrounds (The "Pale Yellowish" tone), App Secondary Backgrounds.
*   **Alert Orange**: `#FF9500`
    *   *Usage*: Error states, Warnings.

## Typography
*   **Font Family**: `Inter`, `-apple-system`, `SF Pro Text`
*   **Checklist**:
    *   Headings: SemiBold (600)
    *   Body: Regular (400) / Standard macOS System Font rules.

## Components

### 1. Buttons
*   **Primary**: `Pro Blue` Background, `White` Text. Rounded Capsules.
    *   *Website*: Download Button.
    *   *App*: Save/Action Buttons.
*   **Secondary**: `White` Background, `Gray` Border.
    *   *Website*: "How it works".
*   **Icon-Only**: `Glass` styling (White opacity) on Dark backgrounds.
    *   *Widget*: Close, Stop, Cancel.

### 2. Widget (The Floating Pill)
*   **Background**: `Black` (90% Opacity).
*   **Stroke**: `White` (15% Opacity) [Idle] -> `Blue` (30% Opacity) [AI Mode].
*   **Motion**: Fluid animations for state transitions.

### 3. Website
*   **Background**: `Canvas` (#FAFAFA) for texture/warmth.
*   **Hero**: Clean, centered, large typography.
*   **Consistency Fix**: Align primary buttons to `Pro Blue` (matching App Accent).

## Implementation Guide

### CSS Variables (Web)
```css
:root {
    --primary: #007AFF;
    --black: #171717;
    --background: #FAFAFA;
}
```

### Swift Colors
```swift
// Use standard System Colors for native feel
Color.accentColor // Set to Blue in Assets
Color.blue // For specific AI highlights
Color.primary // For text
```
