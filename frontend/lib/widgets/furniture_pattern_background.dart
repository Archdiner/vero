import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math' show pi;

class FurniturePatternBackground extends StatelessWidget {
  // Ensure all fields are immutable so the constructor can be const
  final double iconSize;
  final double spacing;
  final double opacity;
  final Color? iconColor;

  const FurniturePatternBackground({
    super.key,
    this.iconSize = 32.0,
    this.spacing = 80.0,
    this.opacity = 0.05,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final icons = [
          MdiIcons.bed,
          MdiIcons.television,
          MdiIcons.desk,
          MdiIcons.tableFurniture,
          MdiIcons.fridge,
          MdiIcons.flower,
        ];

        // Calculate number of tiles to cover width and height
        final cols = (constraints.maxWidth / spacing).ceil();
        final rows = (constraints.maxHeight / spacing).ceil();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: cols * spacing,
              maxWidth: cols * spacing,
              minHeight: rows * spacing,
              maxHeight: rows * spacing,
              child: Wrap(
                spacing: 0,
                runSpacing: 0,
                children: List.generate(rows * cols, (index) {
                  final icon = icons[index % icons.length];
                  return SizedBox(
                    width: spacing,
                    height: spacing,
                    child: Center(
                      child: Transform.rotate(
                        angle: (index % 4) * pi / 16,
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: iconColor ?? (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}