import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro_platform_interface.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_midi_pro/dart_midi_pro.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'dart:typed_data'; // ByteData
import 'package:path_provider/path_provider.dart'; // getTemporaryDirectory
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/services.dart';


import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/gestures.dart';

class BlockBreakScreen extends StatefulWidget {
  const BlockBreakScreen({Key? key}) : super(key: key);

  @override
  _BlockBreakScreenState createState() => _BlockBreakScreenState();
}

class _BlockBreakScreenState extends State<BlockBreakScreen> {
  // 状態管理用の変数（例えばゲーム開始のフラグなど）
  bool _isGameStarted = false;

  void _startGame() {
    setState(() {
      _isGameStarted = true; // ゲームを開始
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Breaker Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isGameStarted) ...[
              // ゲームが開始されていない場合のUI
              Text(
                'Welcome to Block Breaker!',
              ),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('Start Game'),
              ),
            ] else ...[
              // ゲームが開始された場合のUI
              Expanded(
                child: GameWidget<BreakoutGame>( // GameWidgetでBreakoutGameを表示
                  game: BreakoutGame(),
                ),
              ),
              // ゲームのUIや操作をここに追加できます
            ],
          ],
        ),
      ),
    );
  }
}
class MovingLeftImage extends StatefulWidget {
  final VoidCallback onTap; // The function to execute on tap
  final double screenHeight;
  final double screenWidth;

  const MovingLeftImage({
    Key? key,
    required this.onTap,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  @override
  _MovingLeftImageState createState() => _MovingLeftImageState();
}

class _MovingLeftImageState extends State<MovingLeftImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth easing effect
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: _animation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Image.asset(
              'Images/left.png',
              width: 50,
              height: 50,
            ),
          ),
        );
      },
    );
  }
}

class CopyableText extends StatelessWidget {
  final String text;

  const CopyableText(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$text」をコピーしました！')),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class Ball extends PositionComponent {
  Ball(Vector2 position) : super(position: position, size: Vector2.all(20.0));

  final _paint = Paint()..color = Colors.blue;

  // ボールの速度
  Vector2 velocity = Vector2.zero();

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, size.x / 2, _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt; // 速度に応じてボールを移動
  }

  // ボールを移動させるメソッド
  void move(Vector2 newPosition) {
    position.setFrom(newPosition);
  }

  // ボールに力を加えるメソッド
  void applyForce(Vector2 force) {
    velocity += force; // 力に応じてボールの速度を変更
  }
}

// ゲームコンポーネント
class BreakoutComponent extends PositionComponent with DragCallbacks {
  BreakoutComponent();

  final _paint = Paint();
  bool _isDragged = false;
  Vector2? _dragStartPosition; // ドラッグ開始位置
  Vector2 _dragEndPosition = Vector2.zero(); // ドラッグ終了位置

  Ball? _ball; // ボール

  // ボールをセットするメソッド
  void setBall(Ball ball) {
    _ball = ball;
  }

  @override
  void onDragStart(DragStartEvent event) {
    _isDragged = true;
    _dragStartPosition = event.localPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_isDragged && _ball != null) {
      // ボールをドラッグで動かす
      final dragDelta = event.localPosition - _dragStartPosition!;
      _ball!.move(_ball!.position + dragDelta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (_dragStartPosition != null && _ball != null) {
      // ドラッグ終了後、ボールを反対方向に射出
      final dragDelta = _dragEndPosition - _dragStartPosition!;
      final force = -dragDelta * 0.1; // 力を調整
      _ball!.applyForce(force); // ボールに力を加える
    }
    _isDragged = false;
  }

  @override
  void render(Canvas canvas) {
    _paint.color = _isDragged ? Colors.red : Colors.white;
    canvas.drawRect(size.toRect(), _paint);
  }
}

class BreakoutGame extends FlameGame {
  late Ball ball;
  late BreakoutComponent breakoutComponent;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    ball = Ball(Vector2(100, 200)); // ボールの位置
    breakoutComponent = BreakoutComponent()
      ..size = Vector2(1000, 1000) // 四角形のサイズ
      ..position = Vector2(100, 100); // 四角形の位置

    breakoutComponent.setBall(ball); // BreakoutComponentにボールをセット
    add(breakoutComponent); // ゲーム内にBreakoutComponentを追加
    add(ball); // ボールをゲームに追加
  }
}