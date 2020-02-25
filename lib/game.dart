import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tron/controls.dart';
import 'package:flutter_tron/direction.dart';
import 'package:flutter_tron/player.dart';
import 'package:flutter_tron/player_path_painter.dart';
import 'package:flutter_tron/player_type.dart';
import 'package:flutter_tron/point.dart';
import 'package:flutter_tron/constants.dart';

class Game extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GameState();
}

enum GameType { LIGHT_CYCLE, TANKS }
enum GameState { PLAYING, GAME_OVER }
enum GameMode { SINGLE_PLAYER, TWO_PLAYER }



class _GameState extends State<Game> {
  Timer _timer;
  GameType _gameType;
  GameMode _gameMode;
  GameState _gameState;
  List<Player> _players;
  PlayerType _winner;
  FocusNode _focusNode = FocusNode();
  int _score;

  @override
  void initState() {
    super.initState();

    _gameType = GameType.LIGHT_CYCLE;
    //_gameMode = kIsWeb ? GameMode.TWO_PLAYER : GameMode.SINGLE_PLAYER;
    _gameMode = GameMode.SINGLE_PLAYER;
    _gameState = GameState.PLAYING;

    // add players
    _players = List();
    _players.add(Player(type: PlayerType.PLAYER_ONE, colour: Colors.cyanAccent, direction: Direction.UP, positions: []));

    if(_gameMode == GameMode.TWO_PLAYER) {
      _players.add(Player(type: PlayerType.PLAYER_TWO, colour: Colors.greenAccent, direction: Direction.DOWN, positions: []));
    }
    
    // prepare to start
    _prepareStartGame();
  }


  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
    return Container(
        width: LEVEL_SIZE,
        height: LEVEL_SIZE,
//        width: MediaQuery.of(context).size.width,
//        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: Colors.white),
        ),
        child: _getInputBasedOnPlatform());
  }


  Widget _getInputBasedOnPlatform() {
    Widget child;

    if (kIsWeb) {
      child = RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (RawKeyEvent event) {
          _handleKey(event);
        },
        child: _getChildBasedOnGameState(),
      );
    } else {
      // is mobile
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (tapUpDetails) {
          // handle tap for mobile, may be nicer using keyboard keys on web
          _handleTap(tapUpDetails);
        },
        child: _getChildBasedOnGameState(),
      );
    }

    return child;
  }


  Widget _getChildBasedOnGameState() {
    Widget child;

    switch (_gameState) {

      case GameState.PLAYING:
        List<Widget> _children = List();
        if(_gameMode == GameMode.SINGLE_PLAYER) {
          _children.add(Positioned(
            top: 10,
            left: LEVEL_SIZE / 1.3,
            child: Text("SCORE $_score", style: TextStyle(fontSize: 18, color: Colors.red)),
          ));
        }
        List<Widget> _painters = List();
        _players.forEach((i) {
          _painters.add(Container(
            constraints: BoxConstraints.expand(),
            child: CustomPaint(
              painter: PlayerPathPainter(pointsList:i.positions, colour: i.colour),
            ),
          ));
        });

        child = Stack(
          children: [..._painters, ..._children],
        );
        break;

      case GameState.GAME_OVER:
        _timer.cancel();
        child = Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Game Over", style: TextStyle(fontSize: 28, color: Colors.greenAccent)),
            Divider(),
            (_gameMode == GameMode.TWO_PLAYER) ?
              Text("Player ${_winner == PlayerType.PLAYER_ONE ?'one':'two'} wins", style: TextStyle(fontSize: 28, color: Colors.greenAccent))
                : Text("Your score $_score", style: TextStyle(fontSize: 28, color: Colors.white)) ,
            Divider(),
            Text("Press RETURN to play again", style: TextStyle(fontSize: 18, color: Colors.greenAccent)),
          ],
        ));
        break;

    }

    return child;
  }
  

  void _onTimerTick(Timer timer) {
    _move();

    if (_isWallCollision()) {
      _changeGameState(GameState.GAME_OVER);
      return;
    }

    if (_isPlayerCollision()) {
      if (_isBoardFilled()) {
        // its a draw?
      } else {
        _changeGameState(GameState.GAME_OVER);
      }
      return;
    }
  }


  void _prepareStartGame() {
    print("prepare start");
    _resetPlayers();
    _generateStartPositions();
    _winner = null;
    _score = 0;
    _changeGameState(GameState.PLAYING);
    _timer = Timer.periodic(Duration(milliseconds: 50), _onTimerTick);
  }


  Future<void> _resetPlayers() {
    _players.forEach((i) {
      i.direction = i.type == PlayerType.PLAYER_ONE ? Direction.UP : Direction.DOWN;
    });
  }


  void _move() {
    setState(() {
      _players.forEach((i) {
        i.positions.insert(0, _getNewPosition(i.direction, i.positions));
        //i.positions.removeLast();
      });
      _score += 1;
    });
  }


  bool _isWallCollision() {
    bool hasCollision = false;
    _players.forEach((i) {
      var currentPosition = i.positions.first;
      if (currentPosition.x < 0 || currentPosition.y < 0 || currentPosition.x > LEVEL_SIZE / PLAYER_SIZE || currentPosition.y > LEVEL_SIZE / PLAYER_SIZE) {
        hasCollision = true;
      }
    });
    if(hasCollision) return true;
    return false;
  }


  bool _isPlayerCollision() {
    bool hasCollision = false;
    List allPoints = [];

    _players.forEach((i) {
      // add all but current position
      List pointsToAdd = List.from(i.positions);
      pointsToAdd.removeAt(0);
      allPoints.addAll(pointsToAdd);
    });
    _players.forEach((i) {
      Point currentPosition = i.positions.first;
      for (int p = 1; p < allPoints.length; p++) {
        Point point = allPoints[p];
        if (currentPosition.x == point.x && currentPosition.y == point.y) {
          hasCollision = true;
          // todo declare winner, set by passing loser
          setState(() {
            _winner = (i.type == PlayerType.PLAYER_ONE) ? PlayerType.PLAYER_TWO : PlayerType.PLAYER_ONE;
          });
        }
      }
    });
    if (hasCollision) return true;
    return false;
  }


  bool _isBoardFilled() {
    final totalPiecesThatBoardCanFit =
        (LEVEL_SIZE * LEVEL_SIZE) / (PLAYER_SIZE * PLAYER_SIZE);
//    if ((_playerOnePositions.length + _playerTwoPositions.length) == totalPiecesThatBoardCanFit) {
//      return true;
//    }

    return false;
  }


  Point _getNewPosition(Direction playerDirection, List playerPositions) {
    var newPosition;
    switch (playerDirection) {
      case Direction.LEFT:
        var currentHeadPos = playerPositions.first;
        newPosition = Point(currentHeadPos.x - 1, currentHeadPos.y);
        break;

      case Direction.RIGHT:
        var currentHeadPos = playerPositions.first;
        newPosition = Point(currentHeadPos.x + 1, currentHeadPos.y);
        break;

      case Direction.UP:
        var currentHeadPos = playerPositions.first;
        newPosition = Point(currentHeadPos.x, currentHeadPos.y - 1);
        break;

      case Direction.DOWN:
        var currentHeadPos = playerPositions.first;
        newPosition = Point(currentHeadPos.x, currentHeadPos.y + 1);
        break;
    }

    return newPosition;
  }


  void _handleKey(RawKeyEvent event) {

    if(event.runtimeType != RawKeyDownEvent) return;
    switch (_gameState) {
      case GameState.PLAYING:
        _changeDirectionBasedOnKey(event);
        break;
      case GameState.GAME_OVER:
        if (keyValues.map[event.logicalKey.keyId] == KeyboardPress.RETURN) {
          _prepareStartGame();
        }
        break;
    }
  }


  void _changeDirectionBasedOnKey(RawKeyEvent event) {

    print(event.logicalKey.keyId);
    final playerOne = _players.first;
    final playerTwo = _players.length >1 ? _players[1] : _players.first;

    switch(keyValues.map[event.logicalKey.keyId]) {
      case KeyboardPress.UP_ARROW:
        if (playerOne.direction != Direction.DOWN) {
          playerOne.direction = Direction.UP;
        }
        break;
      case KeyboardPress.DOWN_ARROW:
        if (playerOne.direction != Direction.UP) {
          playerOne.direction = Direction.DOWN;
        }
        break;
      case KeyboardPress.LEFT_ARROW:
        if (playerOne.direction != Direction.RIGHT) {
          playerOne.direction = Direction.LEFT;
        }
        break;
      case KeyboardPress.RIGHT_ARROW:
        if (playerOne.direction != Direction.LEFT) {
          playerOne.direction = Direction.RIGHT;
        }
        break;
      case KeyboardPress.RETURN:
        // TODO: Handle this case.
        break;
      case KeyboardPress.W:
        if (playerTwo.direction != Direction.DOWN) {
          playerTwo.direction = Direction.UP;
        }
        break;
      case KeyboardPress.A:
        if (playerTwo.direction != Direction.RIGHT) {
          playerTwo.direction = Direction.LEFT;
        }
        break;
      case KeyboardPress.S:
        if (playerTwo.direction != Direction.UP) {
          playerTwo.direction = Direction.DOWN;
        }
        break;
      case KeyboardPress.D:
        if (playerTwo.direction != Direction.LEFT) {
          playerTwo.direction = Direction.RIGHT;
        }
        break;
    }
  }


  void _handleTap(TapUpDetails tapUpDetails) {
    switch (_gameState) {
      case GameState.PLAYING:
        _changeDirectionBasedOnTap(tapUpDetails);
        break;
      case GameState.GAME_OVER:
        _prepareStartGame();
        break;
    }
  }


  void _changeDirectionBasedOnTap(TapUpDetails tapUpDetails) {
    if(_players.length > 1) {
      // this is no good for two players locally, use keyboard?
      return;
    }
    RenderBox getBox = context.findRenderObject();
    var localPosition = getBox.globalToLocal(tapUpDetails.globalPosition);
    final x = (localPosition.dx / PLAYER_SIZE).round();
    final y = (localPosition.dy / PLAYER_SIZE).round();

    final playerOne = _players.first;
    final currentHeadPos = playerOne.positions.first;

    switch (playerOne.direction) {
      case Direction.LEFT:
        if (y < currentHeadPos.y) {
          playerOne.direction = Direction.UP;
          return;
        }

        if (y > currentHeadPos.y) {
          playerOne.direction = Direction.DOWN;
          return;
        }
        break;

      case Direction.RIGHT:
        if (y < currentHeadPos.y) {
          playerOne.direction = Direction.UP;
          return;
        }

        if (y > currentHeadPos.y) {
          playerOne.direction = Direction.DOWN;
          return;
        }
        break;

      case Direction.UP:
        if (x < currentHeadPos.x) {
          playerOne.direction = Direction.LEFT;
          return;
        }

        if (x > currentHeadPos.x) {
          playerOne.direction = Direction.RIGHT;
          return;
        }
        break;

      case Direction.DOWN:
        if (x < currentHeadPos.x) {
          playerOne.direction = Direction.LEFT;
          return;
        }

        if (x > currentHeadPos.x) {
          playerOne.direction = Direction.RIGHT;
          return;
        }
        break;
    }
  }

  void _changeGameState(GameState gameState) {
    print(gameState);
    setState(() {
      _gameState = gameState;
    });
  }

  void _generateStartPositions() {
    setState(() {
      final midPoint = (LEVEL_SIZE / PLAYER_SIZE / 2);

      // hmm need to seperate if two players
      _players.forEach((i) {
        if(i.type == PlayerType.PLAYER_ONE) {
          if(_players.length == 1) {
            i.positions  = [
              Point(midPoint, midPoint - 2),
              Point(midPoint, midPoint - 1),
              Point(midPoint, midPoint),
              Point(midPoint, midPoint + 1),
              Point(midPoint, midPoint + 2),
            ];
          } else {
            i.positions  = [
              Point(midPoint - 10, midPoint - 2),
              Point(midPoint - 10, midPoint - 1),
              Point(midPoint - 10, midPoint),
              Point(midPoint - 10, midPoint + 1),
              Point(midPoint - 10, midPoint + 2),
            ];
          }
        } else {
          // set player 2 to start in down direction
          i.positions  = [
            Point(midPoint + 10, midPoint + 2),
            Point(midPoint + 10, midPoint + 1),
            Point(midPoint + 10, midPoint),
            Point(midPoint + 10, midPoint - 1),
            Point(midPoint + 10, midPoint - 2),
          ];
        }

      });
    });
  }
}

