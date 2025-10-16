import 'dart:io';

import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiniGameScreen extends StatefulWidget {
  @override
  _MiniGameScreenState createState() => _MiniGameScreenState();
}
class _MiniGameScreenState extends State<MiniGameScreen> {

  BannerAd? _bannerAd;

  String friendId = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      friendId = prefs.getString('myFriendId') ?? '名無し';
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width ; // ボタンの幅
    final double screenHeight = screenSize.height ;  // ボタンの高さ


    _changeRoutePass() {
      context.go('/menu');
    }



    return Scaffold(
      body: Center( // Columnを画面全体の中央に配置
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center, // 子ウィジェットを横方向の中央に揃える
          children: [
            if(_bannerAd != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
            if (_bannerAd == null)
            SizedBox(height: 50.0,),
            Row(
              children: [
                SizedBox( // サイズ制約を明示
                  width: 50, // 必要に応じて調整
                  height: 50, // 必要に応じて調整
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MovingLeftImage(
                        onTap: _changeRoutePass,
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
                Text('ミニゲーム', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
              ]
            ),
            Spacer(),
            JankenButton(buttonWidth: screenWidth * 0.8, buttonHeight: screenHeight * 0.1),
            Text('スキル解放用のメダルはここでざっくり稼ごう！'),
            SizedBox(height: 20,),
            MasFillButton(buttonWidth: screenWidth * 0.8, buttonHeight: screenHeight * 0.1),
            Text('みんなで一つの絵を完成させよう！荒らしはやめようね'),
            SizedBox(height: 20,),
            MakeIconButton(buttonWidth: screenWidth * 0.8, buttonHeight: screenHeight * 0.1),
            Text('自分のアイコンを作ったり投稿したりできるよ'),
            SizedBox(height: 20,),
            if (friendId == 'delightStudy')
            DelightStudyButton(buttonWidth: screenWidth * 0.8, buttonHeight: screenHeight* 0.1),
            if (friendId == 'delightStudy')
            Text('勉強記録ができます。'),
            Spacer(),
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

class MasFillButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  MasFillButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed mas fill button");
        context.go('/masFill');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_3x3, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "ピクセルアート",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（makinas4はデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class MakeIconButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  MakeIconButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed make icon button");
        context.go('/makeIcon');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view_sharp, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "アイコンメーカー",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（makinas4はデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class JankenButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  JankenButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed mas fill button");
        context.go('/janken');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pan_tool, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "連勝じゃんけん",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（makinas4はデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class DelightStudyButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  DelightStudyButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.go('/study');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight), // ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "勉強記録",
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（makinas4はデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}


