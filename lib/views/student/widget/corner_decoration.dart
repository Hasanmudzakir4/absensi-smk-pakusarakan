import 'package:flutter/material.dart';

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class CornerDecoration extends StatelessWidget {
  final Corner corner;

  const CornerDecoration({super.key, required this.corner});

  @override
  Widget build(BuildContext context) {
    const lineLength = 30.0;
    const lineWidth = 4.0;
    final color = Colors.greenAccent;

    return SizedBox(
      width: lineLength,
      height: lineLength,
      child: Stack(
        children: [
          if (corner == Corner.topLeft || corner == Corner.bottomLeft)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: lineWidth,
                height: lineLength,
                color: color,
              ),
            ),
          if (corner == Corner.topLeft || corner == Corner.topRight)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: lineLength,
                height: lineWidth,
                color: color,
              ),
            ),
          if (corner == Corner.topRight || corner == Corner.bottomRight)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: lineWidth,
                height: lineLength,
                color: color,
              ),
            ),
          if (corner == Corner.bottomLeft || corner == Corner.bottomRight)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: lineLength,
                height: lineWidth,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
