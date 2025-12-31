import 'package:flutter/material.dart';

extension BuildContexExt on BuildContext {
  TargetPlatform get platform => Theme.of(this).platform;
  TextTheme get textTheme => Theme.of(this).textTheme;
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  double get viewInsets => MediaQuery.of(this).viewInsets.bottom;
  SizedBox get empty => const SizedBox.shrink();
}
