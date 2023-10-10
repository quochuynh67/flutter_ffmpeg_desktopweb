import 'package:flutter/material.dart';

class GridLine {
  /// Grid line color
  /// Default `Colors.white`
  Color color;
  /// grid line width
  double width;
  /// Grid line padding
  EdgeInsets? padding;

  /// Gridlines
  GridLine({this.color = Colors.white, this.width = 0.5, this.padding});
}