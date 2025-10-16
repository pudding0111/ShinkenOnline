import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'IconBoardScreen.dart';

class BattleScreen extends StatefulWidget {
  @override
  _BattleScreenState createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  StreamSubscription? _subscription;
  Timer? _timeoutTimer;

  bool _hasNavigated = false;

  BannerAd? _bannerAd;

  void cancelMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _timeoutTimer?.cancel();
    print("checkRoom: Monitoring canceled.");
  }

  @override
  void initState() {
    super.initState();
    startTimeoutTimer();
    checkRoom(context, battleRoomType, battleRoomName, battlePlayerNumber);
    _loadRoutePass('/onlineBattle');
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

  @override
  void dispose() {
    super.dispose();
    cancelMonitoring();
  }

  void startTimeoutTimer() {
    if (!battleRoomType.contains('friend')){
      _timeoutTimer = Timer(Duration(seconds: 7), () async {
        if (!_hasNavigated) {
          print("Timeout: No opponent found. Resetting num1 and num2...");
          await resetRoomValues();
          _hasNavigated = true;
          cancelMonitoring();
          switch (battleRoomType) {
            case 'strategy':
            context.go('/fakeStrategyBattle');
            break;

            case 'random':
            context.go('/fakeRandomBattle');
            break;
          }
        }
      });
    }
  }

  Future<void> resetRoomValues() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference docRef = db.collection(battleRoomType).doc(battleRoomName);

      await docRef.update({
        "num1": 0,
        "num2": 0,
        'time': 0,
      });

      print("Room values reset: num1 and num2 set to 0.");
    } catch (e) {
      print("Error resetting room values: $e");
    }
  }

  void _loadRoutePass(String route) {
    print("Navigating to $route");
  }

  void backButton() {
    context.go('/onlineBattle');
  }

  void checkRoom(BuildContext context, String battleRoomType, String battleRoomName, int battlePlayerNumber) async {
    if (_hasNavigated) return;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference docRef = db.collection(battleRoomType).doc(battleRoomName);

    Future.delayed(Duration(seconds: 1), () async {
      if (_hasNavigated) return;
      print('searching enemy');
      try {
        DocumentSnapshot documentSnapshot = await docRef.get();

        if (!documentSnapshot.exists) {
          print("checkRoom: Document does not exist: $battleRoomName");
          return;
        }

        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        String targetField = battlePlayerNumber == 1 ? "num2" : "num1";
        print('空き状況:${data[targetField]}');

        if (data.containsKey(targetField) && data[targetField] == 1 && data['time'] != 0) {
          if (DateTime.now().millisecondsSinceEpoch < (data['time'] as int)) {
            _hasNavigated = true;
            print("checkRoom: $targetField updated to 1. Navigating to 'realStrategyBattle'...");
            cancelMonitoring();

            Future.delayed(Duration(milliseconds: 1500), () {
              switch (battleRoomType) {
                case 'strategy':
                print('戦略バトル開始！');
                context.go('/realStrategyBattle');
                break;

                case 'friendStrategy':
                print('フレンド戦略バトル開始！');
                context.go('/realStrategyBattle');
                break;

                case 'random':
                print('ランダムバトル開始!');
                context.go('/realRandomBattle');
                break;

                case 'friendRandom':
                print('フレンドランダムバトル開始！');
                context.go('/realRandomBattle');
                break;
              }
            });
          }
        }
      } catch (e) {
        print("checkRoom: Error getting document: $e");
      }

      checkRoom(context, battleRoomType, battleRoomName, battlePlayerNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
            if (battleRoomType.contains('friend'))
            Row(
              children: [
                SizedBox( // サイズ制約を明示
                  width: 50, // 必要に応じて調整
                  height: 50, // 必要に応じて調整
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MovingLeftImage(
                        onTap: (){
                          setState(() {
                            _hasNavigated = true;
                          });
                          cancelMonitoring();
                          resetRoomValues();
                          context.go('/friendBattle');
                        },
                        screenHeight: screenHeight,
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                ),
              ]
            ),
            WaveText(text: 'Waiting for...'),
            SizedBox(height: screenHeight * 0.1),
            if (battleRoomType == 'friendStrategy')
            Text('フレンドバトルモード：戦略バトル', style: TextStyle(fontFamily: 'makinas4', fontSize: 17),),
            if (battleRoomType == 'friendRandom')
            Text('フレンドバトルモード：ランダムバトル', style: TextStyle(fontFamily: 'makinas4', fontSize: 17),),
            if (battleRoomType.contains('friend'))
            Text('合言葉:"${battleRoomName}"', style: TextStyle(fontFamily: 'makinas4', fontSize: 20),),
            Container(
              height: screenHeight * 0.4,
              width: screenWidth * 0.9,
              child: TipsPage(),
            ),
            SizedBox(height: screenHeight * 0.1),
            Text('対戦相手を探しています。\n1分以上マッチしない場合は\nエラーもしくは相手がいません'),
          ],
        ),
      ),
    );
  }
}

class WaveText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration duration;
  final double waveHeight;

  WaveText({
    required this.text,
    this.textStyle = const TextStyle(fontSize: 40, color: Colors.black,
                    fontFamily: 'makinas4',
                  ),
    this.duration = const Duration(milliseconds: 1000),
    this.waveHeight = 2.5,
  });

  @override
  _WaveTextState createState() => _WaveTextState();
}

class _WaveTextState extends State<WaveText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(); // 永続的に繰り返す
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.text.length, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // ウェーブの位相を調整
            final offsetY = widget.waveHeight *
                sin(2 * pi * (_controller.value + index / widget.text.length));
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Text(
                widget.text[index],
                style: widget.textStyle,
              ),
            );
          },
        );
      }),
    );
  }
}

class TipsPage extends StatelessWidget {
  final List<String> tips = [
    "豆知識 1: ここをスライドすると心拳オンラインに関する様々な豆知識を見ることができます。",
    "豆知識 2: 通常スキルを解放するにはスキルごとにクエストをクリアする必要がありますが、ガチャメダルを多く使うと強制解放できます。",
    "豆知識 3: 相手を6ターン以内に倒す「ノックアウト」に成功すると経験値、ガチャメダルなどがより多く貰えます！積極的にノックアウトを狙いましょう！",
    "豆知識 4: ランキング画面では自分の順位だけではなく、どんなスキルが人気があるのかを見ることができます。",
    "豆知識 5: 掲示板に行って自分の好きなスキルを投稿したり、自分の考えたスキルを投稿したりできます。\n実際にスキルとして採用された投稿もあるみたい",

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PageView.builder(
          itemCount: tips.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TIPS",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black, // 枠線の色
                        width: 2.0,         // 枠線の太さ
                      ),
                      borderRadius: BorderRadius.circular(8), // 角を丸くする（任意）
                    ),
                    child: Text(
                      tips[index],
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'makinas4',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

}


