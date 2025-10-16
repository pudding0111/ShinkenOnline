import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';


class RealSpeedBattleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // メインコンテンツ
          Center(
            child: Text(
              'Main Content',
              style: TextStyle(fontSize: 24),
            ),
          ),
          
          // スライドビューを配置
          SlideView(
            screenWidth: screenWidth,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slide View',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'This is a sliding view that appears from the left.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                ElevatedButton(onPressed:
                     () => {
                      context.go('/onlineBattle')
                     },
                      child: Text('onlineBattleへ'))
                // 他のコンテンツを追加
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SlideView extends StatefulWidget {
  final double screenWidth;
  final Widget content; // スライドビューに表示するコンテンツをカスタマイズ可能に

  const SlideView({
    Key? key,
    required this.screenWidth,
    required this.content,
  }) : super(key: key);

  @override
  _SlideViewState createState() => _SlideViewState();
}

class _SlideViewState extends State<SlideView> {
  bool isSlideViewVisible = false;

  void toggleSlideView() {
    setState(() {
      isSlideViewVisible = !isSlideViewVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlipCard()
      ],
    );
  }
}

class FlipCard extends StatefulWidget {
  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _flipCard() {
    if (isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    isFront = !isFront;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double angle = _animation.value * pi;
          // 正面か裏面かを判断
          bool isBackVisible = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBackVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBackSide(),
                  )
                : _buildFrontSide(),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      child: Text(
        'Front',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      color: Colors.red,
      alignment: Alignment.center,
      child: Text(
        'Back',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}