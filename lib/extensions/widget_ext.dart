// ignore_for_file: prefer_tap_extension
import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  Widget tap(
    VoidCallback? onTap, {
    HitTestBehavior behavior = .opaque,
    Duration debounce = const Duration(milliseconds: 500),
    VoidCallback? onLongPress,
  }) {
    bool clicked = false;
    bool longClicked = false;

    void handleTap() {
      if (onTap == null) return;
      if (clicked) return;
      clicked = true;
      onTap();
      Future.delayed(debounce, () => clicked = false);
    }

    void handleLongPress() {
      if (onLongPress == null) return;
      if (longClicked) return;
      longClicked = true;
      onLongPress();
      Future.delayed(debounce, () => longClicked = false);
    }

    return GestureDetector(
      onTap: handleTap,
      onLongPress: handleLongPress,
      behavior: behavior,
      child: this,
    );
  }
}
