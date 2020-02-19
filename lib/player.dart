import 'package:flutter/material.dart';
import 'package:flutter_tron/direction.dart';
import 'package:flutter_tron/player_type.dart';
import 'package:flutter_tron/point.dart';

class Player {
  PlayerType type;
  Color colour;
  List<Point> positions;
  Direction direction;

  Player({this.type, this.colour, this.positions, this.direction});
}