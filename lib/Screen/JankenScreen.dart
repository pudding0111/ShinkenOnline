import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../main.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JankenScreen extends StatefulWidget {
  @override
  _JankenScreenState createState() => _JankenScreenState();
}

class _JankenScreenState extends State<JankenScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, String> winAgainst = {
    'rock': 'scissor',
    'paper': 'rock',
    'scissor': 'paper',
  };

  bool ruleView = false;

  String nowScene = 'start'; //start select result ranking
  String nowRanking = 'all'; //all day week month
  String myHand = 'rock';
  String enemyHand = 'scissor';
  String handResult = 'draw';

  int gachaPoint = 0;
  int payPoint = 0;
  int payMaxPoint = 1000;
  int jankenStreak = 0;
  int jankenMaxPoint = 0;

  int currentStreak = 0;
  int currentPoint = 0;
  int currentRound = 1;

  int loseRockThreshold = 33;
  int drawRockThreshold = 66;
  int loseScissorThreshold = 33;
  int drawScissorThreshold = 66;
  int losePaperThreshold = 33;
  int drawPaperThreshold = 66;

  int myWinCount = 0;
  int myPlayCount = 0;

  bool resultView = false;

  //ランキング用変数
  List allStreakRanking = [];
  List allPointRanking = [];
  List weekStreakRanking = [];
  List weekPointRanking = [];


  BannerAd? _bannerAd;
  @override
  void initState() {
    super.initState();
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
    _loadPreferences();
  }

  void _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gachaPoint = prefs.getInt('myGachaPoint') ?? 0;
    jankenStreak = prefs.getInt('myJankenStreak') ?? 0;
    jankenMaxPoint = prefs.getInt('myJankenMaxPoint') ?? 0;
    myWinCount = prefs.getInt('myWinCount') ?? 0;
    myPlayCount = prefs.getInt('myPlayCount') ?? 0;
  }

  void setPlayCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myPlayCount', (prefs.getInt('myPlayCount') ?? 0) + 1);
      myPlayCount = prefs.getInt('myPlayCount') ?? 0;
    });
  }

  void setWinCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myWinCount', (prefs.getInt('myWinCount') ?? 0) + 1);
      myWinCount = prefs.getInt('myWinCount') ?? 0;
    });
  }

  void _usePoint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint') ?? 0) - payPoint);
      gachaPoint = prefs.getInt('myGachaPoint') ?? 0;
    });
  }

  void _getPoint() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      print('獲得:$currentPoint枚');
      prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint') ?? 0) + currentPoint);
      print('現在:${prefs.getInt('myGachaPoint') ?? 0}枚');
      gachaPoint = prefs.getInt('myGachaPoint') ?? 0;
      setMaxPointLog();
    });
  }

  void setStreakLog() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt('myJankenStreak') ?? 0) < currentStreak){
      setState(() {
        prefs.setInt('myJankenStreak', currentStreak);
        jankenStreak = prefs.getInt('myJankenStreak') ?? 0;
      });
    }
  }

  void setMaxPointLog() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('${(prefs.getInt('myJankenMaxPoint') ?? 0)},  $currentPoint');
    if ((prefs.getInt('myJankenMaxPoint') ?? 0) < currentPoint){
      setState(() {
        print('print');
        prefs.setInt('myJankenMaxPoint', currentPoint);
        jankenMaxPoint = prefs.getInt('myJankenMaxPoint') ?? 0;
      });
    }
  }

  void judgeJanken(String myHand, String enemyHand) {
    const Map<String, String> winningHands = {
      'rock': 'scissor',
      'scissor': 'paper',
      'paper': 'rock',
    };

    if (myHand == enemyHand) {
      handResult = 'draw';
    } else if (winningHands[myHand] == enemyHand) {
      handResult = 'win';
      int drawThreshold = 66;
      if (myHand == 'rock') {
        drawThreshold = drawRockThreshold;
      } else if (myHand == 'scissor') {
        drawThreshold = drawScissorThreshold;
      } else if (myHand == 'paper') {
        drawThreshold = drawPaperThreshold;
      }
      setState(() {
        currentStreak += 1;
        if (currentStreak > 1) {
          if ((100 - drawThreshold) <= 20) {
            currentPoint *= 10;
          } else {
            currentPoint *= 2;
          }
        } else if (currentStreak == 1) {
          if ((100 - drawThreshold) <= 20) {
            currentPoint = payPoint * 10;
          } else {
             currentPoint = payPoint;
          }
        }
        setStreakLog();
        setWeekStreakRankingData();
      });
    } else {
      handResult = 'lose';

    }
  }

  void selectEnemyThreshold() {
    // 1〜100の範囲でランダムな数値を生成
    List<int> RockThresholds = List.generate(100, (index) => index + 1)..shuffle();
    loseRockThreshold = RockThresholds[0];
    drawRockThreshold = RockThresholds[1];
    List<int> ScissorThresholds = List.generate(100, (index) => index + 1)..shuffle();
    loseScissorThreshold = ScissorThresholds[0];
    drawScissorThreshold = ScissorThresholds[1];
    List<int> PaperThresholds = List.generate(100, (index) => index + 1)..shuffle();
    losePaperThreshold = PaperThresholds[0];
    drawPaperThreshold = PaperThresholds[1];

    // 小さい方を loseThreshold、大きい方を drawThreshold にする
    if (loseRockThreshold > drawRockThreshold) {
      int temp = loseRockThreshold;
      loseRockThreshold = drawRockThreshold;
      drawRockThreshold = temp;
    }
    if (loseScissorThreshold > drawScissorThreshold) {
      int temp = loseScissorThreshold;
      loseScissorThreshold = drawScissorThreshold;
      drawScissorThreshold = temp;
    }
    if (losePaperThreshold > drawPaperThreshold) {
      int temp = losePaperThreshold;
      losePaperThreshold = drawPaperThreshold;
      drawPaperThreshold = temp;
    }
  }

  void selectEnemyJanken(String myHand) {
    // 1〜100の範囲でランダムな数値を生成
    Random random = Random();
    int randomValue = random.nextInt(100) + 1;
    int drawThreshold = 66;
    int loseThreshold = 33;
    if (myHand == 'rock') {
        drawThreshold = drawRockThreshold;
        loseThreshold = loseRockThreshold;
      } else if (myHand == 'scissor') {
        drawThreshold = drawScissorThreshold;
        loseThreshold = loseScissorThreshold;
      } else if (myHand == 'paper') {
        drawThreshold = drawPaperThreshold;
        loseThreshold = losePaperThreshold;
      }

    if (randomValue <= loseThreshold) {
      // 敵が勝つ場合（自分が負ける）
      enemyHand = winAgainst[myHand]!;
      enemyHand = winAgainst[enemyHand]!;
      print('負け$enemyHand');
    } else if (randomValue <= drawThreshold) {
      // アイコの場合
      enemyHand = myHand;
      print('引き分け$enemyHand');
    } else {
      // 敵が負ける場合（自分が勝つ）
      enemyHand = winAgainst[myHand]!;
      print('勝ち$enemyHand');
    }
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack (
        children: [
          Column(
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
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child:
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Row(
                children: [
                  SizedBox( // サイズ制約を明示
                      width: 50, // 必要に応じて調整
                      height: 50, // 必要に応じて調整
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MovingLeftImage(
                            onTap: () {context.go('/miniGame');},
                            screenHeight: screenHeight,
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),
                    ),
                  Text('連勝じゃんけん', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.06),),
                  Spacer(),
                  if(nowScene == 'ranking')
                  Row(
                    children: [
                      Text(nowRanking == 'all' ? '全期間' : '週間', style: TextStyle(fontFamily: 'makinas', decoration: TextDecoration.underline, fontSize: screenWidth * 0.045)),
                      IconButton(
                      icon: Icon(Icons.change_circle),
                      iconSize: screenWidth * 0.1,
                      onPressed: () {
                        setState(() {
                          if (nowRanking == 'all') {
                            fetchWeekRankingData();
                            nowRanking = 'week'; // ボタンが押されたときに更新
                          } else if (nowRanking == 'week') {
                            fetchAllRankingData();
                            nowRanking = 'all';
                          }
                        });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20,),
              if (nowScene == 'start')
              Column(
                children: [
                  CustomImageButton(screenWidth: screenWidth, buttonText: ruleView ? '閉じる' : 'ルール', onPressed: (){ setState(() {
                    ruleView = !ruleView;
                  });}),
                  if (ruleView)
                  Container(
                    width: screenWidth* 0.85,
                    child:
                    Text('ルール\nここではただのじゃんけんをひたすらにやってもらいます。各ラウンドで勝率が表示されるので、それを元にじゃんけんをするかどうかを慎重に考えましょう。メダルを最初に払った場合は、2連勝してからダブルアップチャレンジに挑戦できます。連勝するたびに貰えるお金が倍になります。ただし、途中で勝負を降りないとメダルは貰えません。引き際が肝心!', style: TextStyle(fontFamily: 'makinas4'),),
                  ),

                  SizedBox(height: screenHeight * 0.02,),
                  Container(
                    margin: EdgeInsets.all(16), // 外側の余白
                    padding: EdgeInsets.all(12), // 内側の余白
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2), // 枠線の設定
                      borderRadius: BorderRadius.circular(8), // 角を丸める
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomImageButton(
                          screenWidth: screenWidth,
                          buttonText: 'ランキング',
                          onPressed: () {
                            setState(() {
                              fetchAllRankingData();
                              nowScene = 'ranking';
                            });
                          },
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('Images/skillActive.svg'),
                            Text(
                              '連勝記録：$jankenStreak回',
                              style: TextStyle(
                                fontFamily: 'makinas4',
                                fontSize: screenWidth * 0.06,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01), // 間隔の調整
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_money),
                            Text(
                              '最大獲得額：$jankenMaxPoint枚',
                              style: TextStyle(
                                fontFamily: 'makinas4',
                                fontSize: screenWidth * 0.06,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),

                  Text('いくら賭けますか？', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.07),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('現在  ', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.05),),
                      Icon(
                        Icons.military_tech, // 条件に応じて変更可能
                        size: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.04, // 大きさを指定
                        color: Colors.black, // 必要に応じて色を指定
                      ),
                      Text('$gachaPoint枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.07),),
                    ],
                  ),
                  SizedBox(height: 20,),


                  if (myWinCount * 5 > myPlayCount)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (){setState(() {
                          if (payPoint - 100 > 0) {
                            payPoint -= 100;
                          } else {
                            payPoint = 0;
                          }
                        });},
                        child: Text("ーー"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 20),
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        ),
                      ),
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: (){setState(() {
                          if (payPoint - 10 > 0) {
                            payPoint -= 10;
                          } else {
                            payPoint = 0;
                          }
                        });},
                        child: Text("ー"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 20),
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text('$payPoint枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.07),),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: (){setState(() {
                          if (payPoint + 10 < payMaxPoint) {
                            payPoint += 10;
                          } else {
                            payPoint = payMaxPoint;
                          }
                        });},
                        child: Text("＋"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 20),
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        ),
                      ),
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: (){setState(() {
                          if (payPoint + 100 < payMaxPoint) {
                            payPoint += 100;
                          } else {
                            payPoint = payMaxPoint;
                          }
                        });},
                        child: Text("＋＋"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(50, 20),
                          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  if (myWinCount * 5 > myPlayCount)
                  Container(
                    width: screenWidth * 0.7,
                    child: Text('残り${myWinCount * 5 - myPlayCount}回、ガチャポイントを賭けることができます', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.05),),
                  ),

                  if (myWinCount * 5 <= myPlayCount)
                  Text('0枚', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.07),),
                  if (myWinCount * 5 <= myPlayCount)
                  Container(
                    width: screenWidth * 0.7,
                    child:
                     Text('ランク対戦で1勝するごとに、ガチャポイントを賭けてプレイする特別なチャンスが5回分手に入ります！', style: TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.04),),
                  ),


                  if (payPoint <= gachaPoint)
                  CustomImageButton(screenWidth: screenWidth, buttonText: '決定！！', onPressed: (){
                    setState(() {
                      _usePoint();
                      if (payPoint != 0){
                        setPlayCount();
                      }
                      currentPoint = 0;
                      currentRound = 1;
                      currentStreak = 0;
                      nowScene = 'select';
                      if (myWinCount * 5 <= myPlayCount) {
                        payPoint = 0;
                      }
                    });
                  }),
                ]
              ),
              if (nowScene == 'select')
              Column(
                children: [
                  Text('ラウンド$currentRound', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.1),),
                  Text('$currentStreak連勝中', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.08),),
                  Text('現在の獲得額$currentPoint枚', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.065),),
                  SizedBox(height: 20,),
                  SvgPicture.asset(
                    'Images/$myHand.svg',
                    height: screenWidth * 0.3,
                    width: screenWidth * 0.3,
                    fit: BoxFit.contain,
                  ),

                  BattleHandSelection(
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  onRockSelected: () {
                    setState(() {
                      myHand = 'rock';
                    });
                  },
                  onScissorsSelected: () {
                    setState(() {
                      myHand = 'scissor';
                    });
                  },
                  onPaperSelected: () {
                    setState(() {
                      myHand = 'paper';
                    });
                  },
                  losePaper: losePaperThreshold,
                  loseRock: loseRockThreshold,
                  loseScissor: loseScissorThreshold,
                  drawPaper: drawPaperThreshold,
                  drawRock: drawRockThreshold,
                  drawScissor: drawScissorThreshold,
                ),

                  CustomImageButton(screenWidth: screenWidth, buttonText: '決定！！', onPressed: (){
                    setState(() {
                      selectEnemyJanken(myHand);
                      judgeJanken(myHand, enemyHand);
                      selectEnemyThreshold();
                      nowScene = 'result';

                    });
                  })
                ],
              ),
              if (nowScene == 'result')
              Column(
                children: [
                  Text('ラウンド$currentRound', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.1),),
                  Text('$currentStreak連勝中', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.08),),
                  Text('現在の獲得額$currentPoint枚', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.065),),
                  Transform.rotate(
                    angle: 180 * (3.14159265359 / 180),
                    child: SvgPicture.asset(
                      'Images/$enemyHand.svg',
                      height: screenHeight * 0.1,
                      width: screenHeight * 0.1,
                    ),
                  ),
                  if (handResult == 'win')
                  Text('勝利！！', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.065),),
                  if (handResult == 'draw')
                  Text('引き分け！', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.065),),
                  if (handResult == 'lose')
                  Text('敗北...', style:  TextStyle(fontFamily: 'makinas4', fontSize: screenWidth * 0.065),),
                  SvgPicture.asset(
                    'Images/$myHand.svg',
                    height: screenHeight * 0.1,
                    width: screenHeight * 0.1,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.05,),

                  if (handResult != 'lose')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImageButton(screenWidth: screenWidth, buttonText: '降りる', onPressed:  () { setState(() {
                        resultView = true;
                      });}),
                      CustomImageButton(screenWidth: screenWidth, buttonText: '挑戦', onPressed: (){setState(() {
                        nowScene = 'select';
                        currentRound += 1;
                      });}),
                    ],
                  ),
                  if (handResult == 'lose')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomImageButton(screenWidth: screenWidth, buttonText: '戻る', onPressed:  () {setState(() {
                        nowScene = 'start';
                      });} ),
                    ],
                  )

                ],
              ),

              if (nowScene == 'ranking')
              Column(
                children: [
                  // 連勝ランキング
                  Text(
                    '連勝ランキング',
                    style: TextStyle(fontSize: screenHeight * 0.03, fontWeight: FontWeight.bold, fontFamily: 'makinas4'),
                  ),
                  SizedBox(
                    height: (screenHeight - 100)* 0.35, // 画面の高さの50% height: _bannerAd!.size.height.toDouble(),
                    child: Column(
                      children: [
                        if(allStreakRanking.isEmpty)
                        Text('データなし'),
                        if (allStreakRanking.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: allStreakRanking.length,
                            itemBuilder: (context, index) {
                              final rank = allStreakRanking[index];
                              return ListTile(
                                leading: Text(
                                  '${index + 1}位',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ),
                                trailing: Text(
                                  '${rank[1]}',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ), // ユーザー名
                                title: Text(
                                  '${rank[2]} 連勝',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // 間隔

                  // 獲得額ランキング
                  Text(
                    '獲得額ランキング',
                    style: TextStyle(fontSize: screenHeight * 0.03, fontWeight: FontWeight.bold, fontFamily: 'makinas4'),
                  ),
                  SizedBox(
                    height: (screenHeight - 100) * 0.35, // 画面の高さの50%
                    child: Column(
                      children: [
                        if(allPointRanking.isEmpty)
                        Text('データなし'),
                        if (allPointRanking.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: allPointRanking.length,
                            itemBuilder: (context, index) {
                              final rank = allPointRanking[index];
                              return ListTile(
                                leading: Text(
                                  '${index + 1}位',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ),
                                trailing: Text(
                                  '${rank[1]}',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ), // ユーザー名
                                title: Text(
                                  '${rank[2]} 枚',
                                  style: const TextStyle(fontFamily: 'makinas4'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )

                ],
              ),
              )
            ],
          ),

          if (resultView)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PointsContainer(currentPoint: currentPoint, myPoint: gachaPoint,screenHeight: screenHeight, screenWidth: screenWidth,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageButton(screenWidth: screenWidth, buttonText: '戻る', onPressed: () {setState(() {
                    _getPoint();
                    resultView = false;
                    nowScene = 'start';
                    setWeekPointRankingData();
                  });})
                ],
              )
            ],
          )
        ]
      )
    );
  }


  //ランキング実装関数
  Future<void> fetchAllRankingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      // ユーザー情報を取得
      final currentUser = _auth.currentUser;
      final userId = currentUser?.uid ?? '';
      final userName = prefs.getString('myName') ?? '名前はまだない'; // ユーザー名は必要に応じて取得してください
      final userStreak = (prefs.getInt('myJankenStreak') ?? 0).toString(); // 初期値を設定（Firestoreから取得してください）
      final userPoint = (prefs.getInt('myJankenMaxPoint') ?? 0).toString(); // 初期値を設定（Firestoreから取得してください）

      // 初期データとして現在のユーザーを追加
      List<List<String>> streakArrayOfArrays = [
        [userId, userName, userStreak],
      ];

      List<List<String>> pointArrayOfArrays = [
        [userId, userName, userPoint],
      ];

      // Firestoreからデータを取得
      final allDoc = await _firestore
          .collection('jankenStreak')
          .doc('all')
          .get();

      if (allDoc.exists) {
        final data = allDoc.data() ?? {};
        final streakUids = List<String>.from((data['streakUid'] as List).map((e) => e.toString()));
        final streakNames = List<String>.from((data['streakName'] as List).map((e) => e.toString()));
        final streaks = List<String>.from((data['streak'] as List).map((e) => e.toString()));
        final pointUids = List<String>.from((data['pointUid'] as List).map((e) => e.toString()));
        final pointNames = List<String>.from((data['pointName'] as List).map((e) => e.toString()));
        final points = List<String>.from((data['point'] as List).map((e) => e.toString()));

        // データを配列の配列に変換
        for (int i = 0; i < streakUids.length; i++) {
          if (streakUids[i] != userId) {
            streakArrayOfArrays.add([streakUids[i], streakNames[i], streaks[i]]);
          }
        }

        for (int i = 0; i < pointUids.length; i++) {
          if (pointUids[i] != userId) {
            pointArrayOfArrays.add([pointUids[i], pointNames[i], points[i]]);
          }
        }

        // トロフィー数でソート
        streakArrayOfArrays.sort((a, b) {
          final int aTrophy = int.tryParse(a[2]) ?? 0;
          final int bTrophy = int.tryParse(b[2]) ?? 0;
          return bTrophy.compareTo(aTrophy);
        });

        pointArrayOfArrays.sort((a, b) {
          final int aTrophy = int.tryParse(a[2]) ?? 0;
          final int bTrophy = int.tryParse(b[2]) ?? 0;
          return bTrophy.compareTo(aTrophy);
        });

        // トップ100に制限
        if (streakArrayOfArrays.length > 100) {
          streakArrayOfArrays = streakArrayOfArrays.sublist(0, 100);
        }

        if (pointArrayOfArrays.length > 100) {
          pointArrayOfArrays = pointArrayOfArrays.sublist(0, 100);
        }

        setState(() {
          allStreakRanking = streakArrayOfArrays;
          allPointRanking = pointArrayOfArrays;
        });

        // Firestoreに更新
        await _firestore.collection('jankenStreak').doc('all').set({
          'streakUid': streakArrayOfArrays.map((e) => e[0]).toList(),
          'streakName': streakArrayOfArrays.map((e) => e[1]).toList(),
          'streak': streakArrayOfArrays.map((e) => e[2]).toList(),
          'pointUid': pointArrayOfArrays.map((e) => e[0]).toList(),
          'pointName': pointArrayOfArrays.map((e) => e[1]).toList(),
          'point': pointArrayOfArrays.map((e) => e[2]).toList(),
        });
      }
    } catch (e) {
      print('Error fetching ranking data: $e');
    }
  }

  DateTime getWeekStart(DateTime date) {
    int daysToSunday = (date.weekday % 7); // 日曜日を基準
    return date.subtract(Duration(days: daysToSunday));
  }

  DateTime getWeekEnd(DateTime date) {
    DateTime startOfWeek = getWeekStart(date);
    return startOfWeek.add(Duration(days: 6));
  }

  Future<void> fetchWeekRankingData() async {
    try {
      allStreakRanking = [];
      allPointRanking = [];
      DateTime now = DateTime.now();
      DateTime weekStart = getWeekStart(now);
      DateTime weekEnd = getWeekEnd(now);
      String weekRange = '${weekStart.toString().substring(0, 10).replaceAll('-', '')}-${weekEnd.toString().substring(0, 10).replaceAll('-', '')}';
      // Firestoreからデータを取得
      final allDoc = await _firestore
          .collection('jankenStreak')
          .doc(weekRange)
          .get();

      if (allDoc.exists) {
        print('doc exists!');
        final data = allDoc.data() ?? {};
        final streakUids = List<String>.from((data['streakUid'] as List).map((e) => e.toString()));
        final streakNames = List<String>.from((data['streakName'] as List).map((e) => e.toString()));
        final streaks = List<String>.from((data['streak'] as List).map((e) => e.toString()));
        final pointUids = List<String>.from((data['pointUid'] as List ).map((e) => e.toString())) ?? [];
        final pointNames = List<String>.from((data['pointName'] as List).map((e) => e.toString())) ?? [];
        final points = List<String>.from((data['point'] as List).map((e) => e.toString())) ?? [];


        // データを配列の配列に変換
        for (int i = 0; i < streakUids.length; i++) {
          setState(() {
            allStreakRanking.add([streakUids[i], streakNames[i], streaks[i]]);
            allPointRanking.add([pointUids[i], pointNames[i], points[i]]);
          });
        }
      } else {
        print('doc not exsit!');
        setState(() {
          allStreakRanking = [];
          allPointRanking = [];
        });
      }

    } catch (e) {
      print('Error fetching ranking data: $e');
    }
  }

  Future<void> setWeekStreakRankingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      // ユーザー情報を取得
      final currentUser = _auth.currentUser;
      final userId = currentUser?.uid ?? '';
      final userName = prefs.getString('myName') ?? '名前はまだない'; // ユーザー名は必要に応じて取得してください

      DateTime now = DateTime.now();
      DateTime weekStart = getWeekStart(now);
      DateTime weekEnd = getWeekEnd(now);
      String weekRange = '${weekStart.toString().substring(0, 10).replaceAll('-', '')}-${weekEnd.toString().substring(0, 10).replaceAll('-', '')}';

      // 初期データとして現在のユーザーを追加
      List<List<String>> streakArrayOfArrays = [
        [userId, userName, currentStreak.toString()],
      ];
      print(currentStreak);

      // Firestoreからデータを取得
      final allDoc = await _firestore
          .collection('jankenStreak')
          .doc(weekRange)
          .get();

      if (allDoc.exists) {
        print('doc exists!');
        final data = allDoc.data() ?? {};
        final streakUids = List<String>.from((data['streakUid'] as List).map((e) => e.toString()));
        final streakNames = List<String>.from((data['streakName'] as List).map((e) => e.toString()));
        final streaks = List<String>.from((data['streak'] as List).map((e) => e.toString()));


        // データを配列の配列に変換
        for (int i = 0; i < streakUids.length; i++) {
          if (streakUids[i] != userId) {
            streakArrayOfArrays.add([streakUids[i], streakNames[i], streaks[i]]);
          } else {
            if ((int.tryParse(streaks[i]) ?? 0) > currentStreak) {
              streakArrayOfArrays.removeAt(0);
              streakArrayOfArrays.add([streakUids[i], streakNames[i], streaks[i]]);
            }
          }
        }
        // トロフィー数でソート
        streakArrayOfArrays.sort((a, b) {
          final int aTrophy = int.tryParse(a[2]) ?? 0;
          final int bTrophy = int.tryParse(b[2]) ?? 0;
          return bTrophy.compareTo(aTrophy);
        });

        // トップ100に制限
        if (streakArrayOfArrays.length > 100) {
          streakArrayOfArrays = streakArrayOfArrays.sublist(0, 100);
        }


        setState(() {
          allStreakRanking = streakArrayOfArrays;
        });
        await _firestore.collection('jankenStreak').doc(weekRange).update({
          'streakUid': streakArrayOfArrays.map((e) => e[0]).toList(),
          'streakName': streakArrayOfArrays.map((e) => e[1]).toList(),
          'streak': streakArrayOfArrays.map((e) => e[2]).toList(),
        });
      } else {
        print('doc not exsit!');
        setState(() {
          allStreakRanking = streakArrayOfArrays;
        });
        await _firestore.collection('jankenStreak').doc(weekRange).set({
          'pointUid': [],
          'pointName': [],
          'point': [],
          'streakUid': streakArrayOfArrays.map((e) => e[0]).toList(),
          'streakName': streakArrayOfArrays.map((e) => e[1]).toList(),
          'streak': streakArrayOfArrays.map((e) => e[2]).toList(),
        });
      }

    } catch (e) {
      print('Error fetching ranking data: $e');
    }
  }

  Future<void> setWeekPointRankingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      // ユーザー情報を取得
      final currentUser = _auth.currentUser;
      final userId = currentUser?.uid ?? '';
      final userName = prefs.getString('myName') ?? '名前はまだない'; // ユーザー名は必要に応じて取得してください

      DateTime now = DateTime.now();
      DateTime weekStart = getWeekStart(now);
      DateTime weekEnd = getWeekEnd(now);
      String weekRange = '${weekStart.toString().substring(0, 10).replaceAll('-', '')}-${weekEnd.toString().substring(0, 10).replaceAll('-', '')}';

      // 初期データとして現在のユーザーを追加

      List<List<String>> pointArrayOfArrays = [
        [userId, userName, currentPoint.toString()],
      ];

      // Firestoreからデータを取得
      final allDoc = await _firestore
          .collection('jankenStreak')
          .doc(weekRange)
          .get();

      if (allDoc.exists) {
        final data = allDoc.data() ?? {};
        final pointUids = List<String>.from((data['pointUid'] as List ).map((e) => e.toString())) ?? [];
        final pointNames = List<String>.from((data['pointName'] as List).map((e) => e.toString())) ?? [];
        final points = List<String>.from((data['point'] as List).map((e) => e.toString())) ?? [];

        // データを配列の配列に変換

        for (int i = 0; i < pointUids.length; i++) {
          if (pointUids[i] != userId) {
            pointArrayOfArrays.add([pointUids[i], pointNames[i], points[i]]);
          } else {
            if ((int.tryParse(points[i]) ?? 0) > currentPoint) {
              pointArrayOfArrays.removeAt(0);
              pointArrayOfArrays.add([pointUids[i], pointNames[i], points[i]]);
            }
          }
        }

        // トロフィー数でソート

        pointArrayOfArrays.sort((a, b) {
          final int aTrophy = int.tryParse(a[2]) ?? 0;
          final int bTrophy = int.tryParse(b[2]) ?? 0;
          return bTrophy.compareTo(aTrophy);
        });

        // トップ100に制限

        if (pointArrayOfArrays.length > 100) {
          pointArrayOfArrays = pointArrayOfArrays.sublist(0, 100);
        }

        setState(() {
          allPointRanking = pointArrayOfArrays;
        });
        // Firestoreに更新
        await _firestore.collection('jankenStreak').doc(weekRange).update({
          'pointUid': pointArrayOfArrays.map((e) => e[0]).toList(),
          'pointName': pointArrayOfArrays.map((e) => e[1]).toList(),
          'point': pointArrayOfArrays.map((e) => e[2]).toList(),
        });
      } else {
        setState(() {
          allPointRanking = pointArrayOfArrays;
        });
        // Firestoreに更新
        await _firestore.collection('jankenStreak').doc(weekRange).set({
          'streakUid':[],
          'streakName':[],
          'streak': [],
          'pointUid': pointArrayOfArrays.map((e) => e[0]).toList(),
          'pointName': pointArrayOfArrays.map((e) => e[1]).toList(),
          'point': pointArrayOfArrays.map((e) => e[2]).toList(),
        });
      }





    } catch (e) {
      print('Error fetching ranking data: $e');
    }
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


class CustomImageButton extends StatelessWidget {
  final double screenWidth;
  final String buttonText;
  final VoidCallback onPressed;

  CustomImageButton({
    required this.screenWidth,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ボタンの背景画像
          Image.asset(
            'Images/button.png',
            width: screenWidth * 0.3, // 画面幅に応じたサイズ設定
            fit: BoxFit.contain,
          ),
          // ボタンのテキスト
          Text(
            buttonText,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BattleHandSelection extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final VoidCallback onRockSelected;
  final VoidCallback onScissorsSelected;
  final VoidCallback onPaperSelected;
  final int loseRock;
  final int drawRock;
  final int loseScissor;
  final int drawScissor;
  final int losePaper;
  final int drawPaper;

  BattleHandSelection({
    required this.screenHeight,
    required this.screenWidth,
    required this.onRockSelected,
    required this.onScissorsSelected,
    required this.onPaperSelected,
    required this.drawPaper,
    required this.drawRock,
    required this.drawScissor,
    required this.losePaper,
    required this.loseRock,
    required this.loseScissor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '勝負する手を選べ！！',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.07,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: screenHeight * 0.02),
          // グー、チョキ、パーのボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onRockSelected,
                    icon: SvgPicture.asset(
                      'Images/rock.svg',
                      height: screenHeight * 0.07,
                      width: screenHeight * 0.07,
                    ),
                  ),
                  Text('勝${100 - drawRock}％', style: TextStyle(fontFamily: 'makinas4',),),
                  Text('負${loseRock}％', style: TextStyle(fontFamily: 'makinas4',),),
                  if ((100 - drawRock) <= 20)
                  Text('勝てば10倍', style: TextStyle(fontFamily: 'makinas4',),),

                ],
              ),

              SizedBox(width: screenWidth * 0.05),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onScissorsSelected,
                    icon: SvgPicture.asset(
                      'Images/scissor.svg',
                      height: screenHeight * 0.07,
                      width: screenHeight * 0.07,
                    ),
                  ),
                  Text('勝${100 - drawScissor}％', style: TextStyle(fontFamily: 'makinas4',),),
                  Text('負${loseScissor}％', style: TextStyle(fontFamily: 'makinas4',),),
                  if ((100 - drawScissor) <= 20)
                  Text('勝てば10倍', style: TextStyle(fontFamily: 'makinas4',),),
                ],
              ),

              SizedBox(width: screenWidth * 0.05),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onPaperSelected,
                    icon: SvgPicture.asset(
                      'Images/paper.svg',
                      height: screenHeight * 0.07,
                      width: screenHeight * 0.07,
                    ),
                  ),
                  Text('勝${100 - drawPaper}％', style: TextStyle(fontFamily: 'makinas4',),),
                  Text('負${losePaper}％', style: TextStyle(fontFamily: 'makinas4',),),
                  if ((100 - drawPaper) <= 20)
                  Text('勝てば10倍', style: TextStyle(fontFamily: 'makinas4',),),
                ],
              ),

            ],
          ),
          SizedBox(height: screenHeight * 0.02),

        ],
      ),
    );
  }
}

class PointsContainer extends StatefulWidget {
  final int currentPoint; // 今回取得したポイント
  final int myPoint; // 現在の合計ポイント
  final double screenWidth;
  final double screenHeight;

  const PointsContainer({
    super.key,
    required this.currentPoint,
    required this.myPoint,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  State<PointsContainer> createState() => _PointsContainerState();
}

class _PointsContainerState extends State<PointsContainer> {
  late int updatedPoint; // 更新後のポイント

  @override
  void initState() {
    super.initState();
    updatedPoint = widget.myPoint + widget.currentPoint; // 最終ポイントを計算
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      width: widget.screenWidth * 0.8,
      height: widget.screenHeight * 0.35,
      decoration: BoxDecoration(
        color: Colors.white, // コンテナの背景色
        border: Border.all(
          color: Colors.black, // 外枠の色
          width: 2.0, // 外枠の太さ
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(1), // 影の色
            offset: const Offset(8, 8), // 影の位置
            blurRadius: 0, // ぼかしの強さ
          ),
        ],
        borderRadius: BorderRadius.circular(0), // 角丸を少し付ける（任意）
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake, size: widget.screenWidth * 0.1,),
              Text(
                '勝利！！',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget. screenWidth * 0.1, // テキストサイズ
                  fontWeight: FontWeight.bold, // 太字
                  color: Colors.black, // テキストの色
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          SizedBox(height: 30,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.military_tech, size: widget.screenWidth * 0.07,),
              Text(
                '${widget.currentPoint}枚獲得！',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: widget. screenWidth * 0.07, // テキストサイズ
                  fontWeight: FontWeight.bold, // 太字
                  color: Colors.black, // テキストの色
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 16), // 間隔を空ける
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: widget.myPoint, // 初期ポイント
              end: updatedPoint, // 最終ポイント
            ),
            duration: const Duration(seconds: 2), // アニメーションの長さ
            builder: (context, value, child) {
              return
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '現在',
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.05,
                      fontFamily: 'makinas4',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Icon(Icons.military_tech, size: widget.screenWidth * 0.05,),
                  Text(
                    '$value枚',
                    style: TextStyle(
                      fontSize: widget.screenWidth * 0.05,
                      fontFamily: 'makinas4',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}




