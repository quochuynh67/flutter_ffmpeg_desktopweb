import 'package:flutter/material.dart';

class CropBoxBorder {
  /// In square mode, the rounded corners of the border
  final Radius? radius;
  Radius get noNullRadius => radius ?? const Radius.circular(0);

  /// border width
  /// 
  /// default [2]
  final double width;

  /// border color
  ///
  /// Default [Colors.white]
  final Color color;

  CropBoxBorder({this.radius, this.width = 2, this.color = Colors.white});
}