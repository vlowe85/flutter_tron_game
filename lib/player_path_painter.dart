import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_tron/point.dart';
import 'package:flutter_tron/constants.dart';

class PlayerPathPainter extends CustomPainter {
  List<Point> pointsList;
  Color colour;
  List<Offset> offsetPoints = List();

  PlayerPathPainter({this.pointsList, this.colour});

  @override
  void paint(Canvas canvas, Size size) {
    pointsList.forEach((i) {
      offsetPoints.add(Offset(i.x * PLAYER_SIZE, i.y * PLAYER_SIZE));
    });
    final pointMode = ui.PointMode.polygon;
    final points = offsetPoints;
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(pointMode, points, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}