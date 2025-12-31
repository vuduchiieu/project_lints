import 'package:flutter/widgets.dart';

extension NumExt on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
  Duration get ms => Duration(milliseconds: toInt());
  Duration get seconds => Duration(seconds: toInt());
}
