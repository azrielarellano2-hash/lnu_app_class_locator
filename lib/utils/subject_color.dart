import 'package:flutter/material.dart';

Color subjectBlockColor(String subjectCode) {
  final hash = subjectCode.hashCode.abs();
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.45, 0.82).toColor();
}

Color subjectBlockBorderColor(String subjectCode) {
  final base = subjectBlockColor(subjectCode);
  return HSLColor.fromColor(base).withLightness(0.55).toColor();
}
