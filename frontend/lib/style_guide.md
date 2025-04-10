# Roomio Authentication Screens Style Guide

## Overview
This style guide provides comprehensive guidelines for creating consistent authentication screens in the Roomio app. It covers layout, typography, colors, and component styling.

## Screen Layout

### Background Setup
- **Base Background Color**: `Color(0xFF0F1A24)` (Dark blue)
- **Background Pattern**:
  - Use `FurniturePatternBackground` widget
  - Opacity: 0.2
  - Spacing: 70
  - Icon Color: `Color(0xFF293542)`
- **Gradient Overlay**:
  - Position: Bottom of screen
  - Height: 60% of screen height
  - Colors (from top to bottom):
    1. Base color with 0% opacity
    2. Base color with 50% opacity
    3. Base color with 90% opacity
    4. Base color with 100% opacity
  - Stops: [0.0, 0.3, 0.6, 1.0]

### Content Container
- **Padding**: 24px horizontal
- **Layout**: SingleChildScrollView within SafeArea
- **Spacing**:
  - Top padding: 24px
  - Between major sections: 32px
  - Between form elements: 20px
  - Between label and input: 8px

## Typography

### Headers
- **Main Title**:
  - Font Size: 28px
  - Font Weight: Bold
  - Color: White
  - Centered
- **Welcome Text**:
  - Font Size: 24px
  - Font Weight: Bold
  - Color: White with 90% opacity
- **Subtitle**:
  - Font Size: 18px
  - Color: White with 70% opacity

### Form Labels
- **Label Text**:
  - Font Size: 16px
  - Color: White with 90% opacity
  - Left padding: 4px
  - Bottom margin: 8px

### Input Fields
- **Text Style**:
  - Color: White
  - Font Size: Inherited from system
- **Placeholder Text**:
  - Color: White with 40% opacity
  - Text: "Write here"

## Form Elements

### Text Fields
- **Container**:
  - Background: White with 10% opacity
  - Border Radius: 16px
  - No border
- **Input Decoration**:
  - Padding: 20px horizontal, 16px vertical
  - No border
  - Hint text color: White with 40% opacity

### Password Fields
- **Additional Features**:
  - Toggle visibility icon
  - Icon color: White with 70% opacity
  - Icon size: Standard
  - Position: Right side

### Buttons
- **Primary Button**:
  - Background: `AppColors.buttonBlue` (0xFF2979FF)
  - Text Color: White
  - Height: 56px
  - Width: Full width
  - Border Radius: 16px
  - Elevation: 0
  - Text Style:
    - Font Size: 18px
    - Font Weight: 600
- **Loading State**:
  - CircularProgressIndicator
  - Color: White
  - Size: Standard

### Social Login Section
- **Divider**:
  - Color: White with 20% opacity
  - Height: 1px
  - Text: "Continue with"
  - Text Color: White with 70% opacity
  - Font Size: 16px
- **Social Buttons**:
  - Container:
    - Background: White with 10% opacity
    - Border Radius: 12px
    - Padding: 24px horizontal, 12px vertical
  - Icons:
    - Color: White
    - Size: 32px

## Navigation Elements

### Back Button
- **Container**:
  - Size: 36x36px
  - Background: White with 10% opacity
  - Shape: Circle
  - Margin: Left 4px
- **Icon**:
  - Arrow back
  - Color: White
  - Size: 20px
  - No padding

### Link Text
- **Regular Text**:
  - Color: White with 70% opacity
  - Font Size: 16px
- **Link Text**:
  - Color: White
  - Font Size: 16px
  - Font Weight: Bold

## Icons
- **General Guidelines**:
  - Use Material Icons
  - Color: White with appropriate opacity
  - Size: Standard Material Icon sizes
- **Specific Icons**:
  - Visibility: `Icons.visibility`
  - Visibility Off: `Icons.visibility_off`
  - Google: `Icons.g_mobiledata`
  - Apple: `Icons.apple`
  - Back: `Icons.arrow_back`
  - Camera: `Icons.camera_alt`

## Responsive Design
- Use `MediaQuery` for dynamic sizing
- Maintain aspect ratios for background elements
- Ensure text remains readable on all screen sizes
- Use `SingleChildScrollView` to handle overflow

## Error States
- **Error Messages**:
  - Use SnackBar
  - Background: Red
  - Text Color: White
  - Duration: Standard
- **Input Validation**:
  - Show error messages below input fields
  - Use red color for error text
  - Maintain consistent spacing

## Loading States
- **Button Loading**:
  - Replace text with CircularProgressIndicator
  - Maintain button dimensions
  - Disable button interaction
- **Form Loading**:
  - Show loading indicator
  - Disable all form inputs
  - Maintain layout structure

## Accessibility
- Ensure sufficient color contrast
- Use semantic HTML elements
- Provide clear focus indicators
- Support screen readers
- Maintain touch target sizes of at least 48x48px

## Best Practices
1. Always use the theme colors from `AppColors`
2. Maintain consistent spacing using the defined values
3. Use the provided background pattern for authentication screens
4. Follow the established typography hierarchy
5. Ensure all interactive elements have proper feedback states
6. Keep the design clean and minimal
7. Use the gradient overlay to improve text readability
8. Maintain consistent padding and margins
9. Use the established button and input field styles
10. Follow the social login section layout for consistency 