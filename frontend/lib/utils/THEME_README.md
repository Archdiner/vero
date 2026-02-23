# Theme System Documentation

## Overview
This document outlines the theming system for the Roomio roommate matching app. The system has been designed to provide a consistent color scheme and styling across all screens, making it easy to change the app's appearance globally.

## Key Components

### 1. Theme Definition (`themes.dart`)
The theme system is centralized in `utils/themes.dart` and consists of:

- **AppColors**: A class with static color constants for all UI elements including:
  - Primary colors (blue theme)
  - Neutral background colors
  - Text colors
  - Feedback colors (success, error, etc.)
  - UI element colors

- **AppTheme**: Provides complete ThemeData objects for:
  - `lightTheme`: For potential light mode support
  - `darkTheme`: The current default theme with dark backgrounds and blue accents

- **ThemeExtension**: Extension methods on BuildContext for easy theme access:
  ```dart
  context.primaryColor       // Access the primary color
  context.textPrimaryColor   // Access text color
  ```

## How to Use the Theme

### In Widgets
To use the theme in your widgets:

1. Import the theme file:
   ```dart
   import '../utils/themes.dart';
   ```

2. Access colors directly:
   ```dart
   color: AppColors.primaryBlue
   ```

3. Or use the extension methods (preferred):
   ```dart
   color: context.primaryColor
   ```

### Customizing Theme Elements
All styling is now controlled through the theme system. To change styles:

1. **Colors**: Modify the color values in `AppColors` class
2. **Typography**: Update the `textTheme` in `AppTheme.darkTheme`
3. **Component Styles**: Update component themes like `elevatedButtonTheme`, `inputDecorationTheme`, etc.

## Changing the Theme

### To Change the Primary Color
To change the primary color throughout the app, simply update these values in `AppColors`:
```dart
static const Color primaryBlue = Color(0xFF1E88E5);
static const Color primaryLightBlue = Color(0xFF64B5F6);
static const Color primaryDarkBlue = Color(0xFF0D47A1);
```

### To Switch Between Light/Dark Themes
In `main.dart`, the app is configured to use the dark theme by default:
```dart
theme: AppTheme.darkTheme
```

To switch to light theme:
```dart
theme: AppTheme.lightTheme
```

## Best Practices

1. **Never use hardcoded colors** in your widgets
2. Always refer to theme colors via `AppColors` or context extensions
3. When creating new UI components, use the existing theme properties
4. If you need a new type of color/style, add it to the theme system rather than using one-off styles

By following these guidelines, the app will maintain visual consistency and be easier to maintain and update. 