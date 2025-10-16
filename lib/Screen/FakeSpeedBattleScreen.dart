import 'package:flutter/material.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';





class FakeSpeedBattleScreen extends StatefulWidget {
  @override
  _FakeSpeedBattleScreenState createState() => _FakeSpeedBattleScreenState();
}

class _FakeSpeedBattleScreenState extends State<FakeSpeedBattleScreen>  with SingleTickerProviderStateMixin {
  final List<GlobalKey<_FlipCardState>> flipCardKeys = List.generate(
    4,
    (_) => GlobalKey<_FlipCardState>(),
  );

  String enemyName = 'enemy';
  var myName = 'アイウエオかきくけこ';
  var enemyPoint = 200 ;
  var myPoint = 200 ;
  String enemyRank = 'bronze1';
  String myRank = 'champion3';
  List<Map<String, String>> mySkillCardList = [];
  List<String> mySkillNoList = [];
  List<String> mySkillTypeList = [];
  BannerAd? _bannerAd;
  // カードデータ
  List<Map<String, String>> myCards = [];// ここでListのデータが終了

  List<Map<String, String>> enemyCards = [
    {'open': 'true', 'type': 'secret', 'image': 'Images/rock.svg','skillName': 'ぐーだった', 'skill': 'Images/No1.png', 'description': 'あああああああああああああああああああああああああああああああああああああああああああああああああああああああああこのターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'false', 'type': 'secret', 'image': 'Images/scissor.svg', 'skillName': 'チョキだった', 'skill': 'Images/No2.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'secret', 'image': 'Images/paper.svg', 'skillName': 'パーだった', 'skill': 'Images/No3.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'rock', 'image': 'Images/rock.svg','skillName': 'ぐーだった',  'skill': 'Images/No19.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'secret', 'image': 'Images/scissor.svg','skillName': 'チョキだった',  'skill': 'Images/No28.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'false', 'type': 'paper', 'image': 'Images/paper.svg', 'skillName': 'パーだった', 'skill': 'Images/No20.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'secret', 'image': 'Images/rock.svg', 'skillName': 'ぐーだった', 'skill': 'Images/No12.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'false', 'type': 'scissor', 'image': 'Images/scissor.svg','skillName': 'チョキだった',  'skill': 'Images/No13.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'secret', 'image': 'Images/paper.svg', 'skillName': 'パーだった', 'skill': 'Images/No14.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
    {'open': 'true', 'type': 'rock', 'image': 'Images/rock.svg', 'skillName': 'ぐーだった', 'skill': 'Images/No15.png', 'description': 'このターンに限ってグーを出して勝った場合ポイントが３０ポイント加算される'},
  ];

  List<Map<String, String>> battleLog = [];

  //変数

  int winPoint = 400;
  int myDeclarePoint = 10;
  int enemyDeclarePoint = 30;
  int currentRound = 0;

  String myDeclareHand = 'paper';
  String enemyDeclareHand = 'rock';
  String myBattleHand = 'scissor';
  String enemyBattleHand = 'paper';
  String myBattleSkillNo = 'No1';
  String enemyBattleSkillNo = 'No1';
  String handResult = 'draw';


  List nowMyOpenCardsNo = [];
  List nowMyOpenCardsName = [];
  List nowEnemyOpenCardsNo = [];
  List nowEnemyOpenCardsName = [];



  //アニメーション変数
  int _mySelectedCardIndex = -1;
  int _enemySelectedCardIndex = -1;
  int _myBattleCardIndex = -1;
  int _enemyBattleCardIndex = 0;
  late AnimationController _controller; // 拍動用のコントローラ
  bool slideInBool = false;
  bool mySkillActive = false;
  bool enemySkillActive = false;
  bool flipState = true;


  final Random _random = Random();  // ランダムジェネレータを初期化
  bool mySkillDetail = false;
  bool enemySkillDetail = false;
  bool myInfoDetail = false;
  bool enemyInfoDetail = false;




  int nowSceneIndex = -1;
  String nowScene = 'start';


  @override
  void initState() {
    _arrayCards(myCards);
    _loadRoutePass('/fakeBattle');
    _loadSkillList();
    _loadEnemySkillList();
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(); // アニメーションをループ

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

  _loadRoutePass(String routeName) {
      setState(() {
        if (routePass.isNotEmpty) {
          if (routePass.contains(routeName)) {
            while (routePass.contains(routeName)) {
              if (routePass.last == routeName) {
                return;
              }
              routePass.removeLast();
            }
          } else {
            routePass.add(routeName);
          }

        }
      });
  }

  _changeRoutePass() {
    routePass.removeLast();
    context.go('/onlineBattle');

  }

  @override
  void dispose() { // ウィジェットが破棄されるときの処理
    _controller.dispose();
    _bannerAd?.dispose();
    super.dispose();
  } // dispose 終了

  void _arrayCards(List<Map<String, String>> cards) {
    setState(() {
      cards.sort((a, b) {
        // 'open' の値で比較し、'true' を先にする
        int openComparison = b['open']!.compareTo(a['open']!);

        if (openComparison != 0) {
          return openComparison;
        }

        // 'type' で順番を決定 ('グー' が先、その後 'チョキ', 'パー')
        Map<String, int> typeOrder = {
          'rock': 0,
          'scissor': 1,
          'paper': 2,
        };

        return typeOrder[a['type']!]!.compareTo(typeOrder[b['type']!]!);
      });
    });
  }

  void slideInBoolToggle () {
    setState(() {
      slideInBool = !slideInBool;
    });
  }

  void mySkillActiveToggle() {
    setState(() {
      mySkillActive = !mySkillActive;
    });
  }

  void enemySkillActiveToggle() {
    setState(() {
      enemySkillActive = !enemySkillActive;
    });
  }

  _loadSkillList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      mySkillNoList = (prefs.getStringList('SpeedSkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']);
      mySkillTypeList = (prefs.getStringList('SpeedSkillTypeList') ?? ['rock', 'rock', 'rock', 'rock', 'scissor', 'scissor', 'scissor', 'paper', 'paper', 'paper']);

      // mySkillNoListが空でない場合、myCardsをmySkillNoListとmySkillTypeListに基づいて作り直す
      if (mySkillNoList.isNotEmpty) {
        myCards = List.generate(mySkillNoList.length, (index) {
          String type = mySkillTypeList[index];
          String skillNo = mySkillNoList[index];
          Map<String, String>? matchingSkill = skills.firstWhere(
            (skill) => skill['No'] == skillNo,
            orElse: () => {'name': 'Unknown Skill', 'description': 'No description available'}
          );
          return {
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'type': type,
            'typeOpen': 'false',
            'no': skillNo,
            'image': 'Images/$type.svg',
            'skillName': matchingSkill['name'] ?? '存在しない技',
            'skill': 'Images/${mySkillNoList[index]}.png',
            'description': matchingSkill['description'] ?? '説明文が存在しないスキルです。'
          };
        });
      }
    });
  }

  void _loadEnemySkillList() {
    // ランダム生成用のインスタンス
    final random = Random();

    // rock, scissor, paper のいずれかをランダムに選ぶ関数
    String getRandomType() {
      const types = ['rock', 'scissor', 'paper'];
      return types[random.nextInt(types.length)];
    }


    List<int> shuffledIndexes = List.generate(skills.length, (index) => index)..shuffle();
    Set<int> selectedIndexes = shuffledIndexes.take(10).toSet();

    // enemySkillListを生成
    setState(() {
      enemyCards = selectedIndexes.map((index) {
      var skill = skills[index];
      String type = getRandomType();
      return {
        'open': 'false',
        'belong': 'enemy',
        'used': 'false',
        'type': type,
        'typeOpen': 'false',
        'no': skill['No'] ?? 'Unknown',
        'image': 'Images/$type.svg',
        'skillName': skill['name'] ?? '存在しない技',
        'skill': 'Images/${skill['No']}.png',
        'description': skill['description'] ?? '説明文が存在しないスキルです。'
        };
      }).toList();
    });
  }

  //シーンの遷移
  List<Map<String, dynamic>> scenes = [
    {'scene': 'start', 'seconds': 3},
    {'scene': 'roundOpen', 'seconds': 2},
    {'scene': 'cardOpen', 'seconds': 6},
    {'scene': 'declareSelect', 'seconds': 10},
    {'scene': 'declareOpen', 'seconds': 3},
    {'scene': 'battleSelect', 'seconds': 20},
    {'scene': 'battleOpen', 'seconds': 4},
    {'scene': 'skillOpen', 'seconds': 3},
    {'scene': 'resultOpen', 'seconds': 3},
    {'scene': 'end', 'seconds': 20},
  ];

  void sceneChange(int sceneSeconds) {
    if (!mounted) return;



    if (nowScene == 'resultOpen') {
      if ((enemyPoint < winPoint && myPoint < winPoint && currentRound < 7 && enemyPoint > 0 && myPoint > 0) || (enemyPoint == myPoint && currentRound < 10)) {
        nowSceneIndex = 1;
        nowScene = scenes[nowSceneIndex]['scene'] as String;
      } else {
        nowSceneIndex += 1;
        nowScene = scenes[nowSceneIndex]['scene'] as String;
      }
    } else if (nowSceneIndex + 1 < scenes.length) {
      nowSceneIndex += 1;
      nowScene = scenes[nowSceneIndex]['scene'] as String;
    } else {
      context.go('/onlineBattle');
    }

    setState(() {});  // 状態を更新するだけで具体的な操作はしない

    Future.delayed(Duration(milliseconds: (scenes[nowSceneIndex]['seconds'] as int) * 1000), () {
      if (mounted) {
        if (nowSceneIndex + 1 < scenes.length) {
          sceneChange(scenes[nowSceneIndex]['seconds'] as int);
        } else {
          sceneChange(scenes[1]['seconds'] as int);
        }
        specificSceneFunc();  // 非同期処理の後にspecificSceneFuncを実行
      }
    });
  }

  void specificSceneFunc () {
    if (nowScene == 'start') {

    } else if (nowScene == 'roundOpen') {//ラウンド開始時の諸々の処理
      setState(() {
        currentRound += 1;
      });
      _myBattleCardIndex = -1;
      slideInBool = false;
      mySkillActive = false;
      enemySkillActive = false;
      nowMyOpenCardsNo = [];
      nowMyOpenCardsName = [];
      nowEnemyOpenCardsNo = [];
      nowEnemyOpenCardsName = [];

      List<Map<String, dynamic>> falseMyOpenCards = myCards.where((card) => card['open'] == 'false').toList();
      falseMyOpenCards.shuffle();
      int cardsToOpen = falseMyOpenCards.length >= 2 ? 2 : falseMyOpenCards.length;

      for (int i = 0; i < cardsToOpen; i++) {
        int index = myCards.indexWhere((card) => card == falseMyOpenCards[i]);
        if (index != -1) {
          myCards[index]['open'] = 'true';
          nowMyOpenCardsNo.add(myCards[index]['no']);
          nowMyOpenCardsName.add(myCards[index]['skillName']);
        }
      }

      List<Map<String, dynamic>> falseEnemyOpenCards = enemyCards.where((card) => card['open'] == 'false').toList();

      falseEnemyOpenCards.shuffle();
      int cardsEnemyToOpen = falseEnemyOpenCards.length >= 2 ? 2 : falseEnemyOpenCards.length;

      for (int i = 0; i < cardsEnemyToOpen; i++) {
        int index = enemyCards.indexWhere((card) => card == falseEnemyOpenCards[i]);
        if (index != -1) {
          enemyCards[index]['open'] = 'true';
          nowEnemyOpenCardsNo.add(enemyCards[index]['no']);
          nowEnemyOpenCardsName.add(enemyCards[index]['skillName']);
        }
      }

      List<Map<String, dynamic>> availableCards =
      enemyCards.where((card) => card['used'] == 'false').toList();

      if (availableCards.isNotEmpty) {
        final Random random = Random();
        Map<String, dynamic> selectedCard = availableCards[random.nextInt(availableCards.length)];
        _enemyBattleCardIndex = enemyCards.indexWhere((card) => card == selectedCard);
        print('there is available cards');
        print(_enemyBattleCardIndex.toString());
      } else {
        throw Exception("No available cards with 'used' == false.");
      }

      setState(() {
        enemyBattleHand = enemyCards[_enemyBattleCardIndex]['type']!;
        enemyBattleSkillNo = enemyCards[_enemyBattleCardIndex]['no']!;
      });

      //ターン開始時の諸諸の処理終了
    } else if (nowScene == 'cardOpen') { //ターン開始時のカードオープン
      Future.delayed(Duration(milliseconds: 20), () {
        for (int i = 0; i < flipCardKeys.length; i++) {
          Future.delayed(Duration(milliseconds: 500 * i), () {
            flipCardKeys[i].currentState?.flipCard();
          });
        }
      });
    } else if (nowScene == 'declareOpen') {
      setState(() {
        setState(() {
          List<int> possiblePoints = [10, 20, 30, 40, 50];
          enemyDeclarePoint = possiblePoints[Random().nextInt(possiblePoints.length)];
          List<String> possibleHands = ['rock', 'scissor', 'paper'];
          enemyDeclareHand = possibleHands[Random().nextInt(possibleHands.length)];

        });
      });
    } else if (nowScene == 'battleOpen') { //バトル結果表示の際の動作
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          slideInBool = true;
          myCards[_myBattleCardIndex]['used'] = 'true';
          enemyCards[_enemyBattleCardIndex]['used'] = 'true';
          enemyCards[_enemyBattleCardIndex]['open'] = 'true';
        });
      });
    } else if (nowScene == 'skillOpen') { //スキル発動の有無
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          mySkillActive = true;
          enemySkillActive = true;
          judgeJanken(myBattleHand, enemyBattleHand);
        });
        addBattleLog();

      });
    }
  }

  //各シーン処理の詳細



  void judgeJanken(String myHand, String enemyHand) {
  const Map<String, String> winningHands = {
    'rock': 'scissor',
    'scissor': 'paper',
    'paper': 'rock'
  };

  if (myHand == enemyHand) {
    handResult = 'draw';
  } else if (winningHands[myHand] == enemyHand) {
    handResult = 'win';
    myPoint += 20 + myDeclarePoint;
    enemyPoint -= (20 + enemyDeclarePoint);
  } else {
    handResult = 'lose';
    myPoint -= (20 + myDeclarePoint);
    enemyPoint += 20 + enemyDeclarePoint;
  }
}

void addBattleLog() {
  setState(() {
    battleLog.add({
      'myHand': myBattleHand,
      'enemyHand': enemyBattleHand,
      'mySkill': myBattleSkillNo,
      'enemySkill': enemyBattleSkillNo,
    });
  });
}

 @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body:Stack(
        children: [

          Column(
            children: [
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              if (_bannerAd == null)
                SizedBox(height: 50,),

              Container( //上4分の１画面
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
                width: screenWidth,
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    CardListView(
                      cards: enemyCards,
                      screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                      screenWidth: screenWidth,
                      selectedCardIndex: _enemySelectedCardIndex,
                      onCardTap: (index) {
                        setState(() {
                          _enemySelectedCardIndex = index;
                          enemySkillDetail = true;
                          mySkillDetail = false;
                        });
                      },
                    ),
                    EnemyInfo(
                      screenWidth: screenWidth, screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0), name: enemyName, rank: enemyRank, point: enemyPoint, winPoint: winPoint,
                      onPressed: () => {
                        print('nameTapped!')
                      }
                    ),
                  ]
                )
              ),

              Container( // 真ん中の画面
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.5,
                width: screenWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('ラウンド: ' + currentRound.toString() + ' / 7',
                        style: TextStyle(
                          fontFamily: 'makinas4',
                          fontSize: screenWidth * 0.05,
                        ),

                        textAlign: TextAlign.left,
                      ),
                        SizedBox()
                      ],

                    ),


                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => context.go('/onlineBattle'),
                            child: Text('onlineBattleへ'),
                          ),
                          Text(nowScene),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                sceneChange(nowSceneIndex != -1 ? scenes[nowSceneIndex]['seconds'] as int : scenes[0]['seconds'] as int);
                              });
                            },
                            child: Text('start'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              mySkillActiveToggle();
                              setState(() {
                                myDeclareHand = 'rock';
                              });
                            },
                            child: Text('自発動'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // すべてのカードを反転
                              for (var key in flipCardKeys) {
                                key.currentState?.flipCard();
                              }
                            },
                            child: Text('flip'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              enemySkillActiveToggle();
                              mySkillActiveToggle();
                              setState(() {
                                myDeclareHand = 'paper';
                              });
                            },
                            child: Text('両発動'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                nowScene = 'start';
                              });
                            },
                            child: Text('start'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                nowScene = 'declareSelect';
                              });
                            },
                            child: Text('宣言選'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                nowScene = 'battleSelect';
                              });
                            },
                            child: Text('勝負選'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                nowScene = 'battleOpen';

                                Future.delayed(Duration(milliseconds: 10), () {
                                  slideInBoolToggle();
                                });
                              });
                            },
                            child: Text('勝負見'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {

                              });
                            },
                            child: Text('start'),
                          ),


                        ],
                      ),
                    ),


                    /* *********************
                    *********************
                      scene遷移の部分
                     **********************
                     **********************
                     */

                    //* カードオープンは下の方に記載
                    // if (nowScene == 'cardOpen')
                    // FlipCard(
                    //   key: flipCardKey,
                    //   screenWidth: screenWidth * 0.25,
                    //   screenHeight: screenWidth * 0.6,
                    //   backImage: 'No10',
                    // ),

                    if (nowScene == 'roundOpen')
                    Container(
                      padding: EdgeInsets.all(8.0), // 文字と背景の間の余白を調整
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 197, 197, 197), // 背景色を指定
                        borderRadius: BorderRadius.circular(8.0), // 背景の角を丸くする場合
                      ),
                      child: Text(
                        'ラウンド' + currentRound.toString(),
                        style: TextStyle(fontSize: screenWidth * 0.16, color: const Color.fromARGB(255, 28, 28, 28),
                          fontFamily: 'makinas4',
                        ),
                      ),
                    ),

                    if (nowScene == 'declareSelect')
                    DeclareHandSelection(
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onRockSelected: () {
                        setState(() {
                          myDeclareHand = 'rock';
                        });
                      },
                      onScissorsSelected: () {
                        setState(() {
                          myDeclareHand = 'scissor';
                        });
                      },
                      onPaperSelected: () {
                        setState(() {
                          myDeclareHand = 'paper';
                        });
                      },
                      onPointSelected: (int point) {
                        setState(() {
                          myDeclarePoint = point; // ポイントを設定
                        });
                      },
                    ),

                    if (nowScene == 'battleSelect')
                      BattleHandSelection(cards: myCards, battleIndex: _myBattleCardIndex, screenHeight: screenHeight, screenWidth: screenWidth),


                    if (nowScene == 'battleOpen') Container(
                      height: screenHeight* 0.19,
                      width: screenWidth,
                      child:EnemySlideInStack(screenHeight: screenHeight, screenWidth: screenWidth, isVisible: slideInBool, handType: enemyBattleHand, skillNo: enemyBattleSkillNo,),
                    ),

                    if (nowScene == 'battleOpen')  Container(
                      height: screenHeight* 0.19,
                      width: screenWidth,
                      child:MySlideInStack(screenHeight: screenHeight, screenWidth: screenWidth, isVisible: slideInBool, handType: myBattleHand, skillNo: myBattleSkillNo,),
                    ),
                  ],
                ),
              ),

              Container( // 下4分の１の画面
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
                width: screenWidth,
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyInfo(
                      screenWidth: screenWidth, screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0), name: myName, rank: myRank, point: myPoint, winPoint: winPoint,
                      onPressed: () => {
                        print('nameTapped!')
                      }
                      ),
                    CardListView(
                      cards: myCards,
                      screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                      screenWidth: screenWidth,
                      selectedCardIndex: _mySelectedCardIndex,
                      onCardTap: (index) {
                        setState(() {
                          _mySelectedCardIndex = index;
                          mySkillDetail = true;
                          enemySkillDetail = false;
                        });
                      },
                    ),
                  ]
                )
              )
            ],
          ),

          Positioned( //自分の宣言ポイント
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            child: DeclarationDisplay(hand: myDeclareHand, points: myDeclarePoint.toString())
          ),

          Positioned( //相手の宣言ポイント
            top: (_bannerAd?.size.height.toDouble() ?? 50.0) + (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            right: 0,
            child: DeclarationDisplay(hand: enemyDeclareHand, points: enemyDeclarePoint.toString())
          ),

          Positioned( // battleLogの表示
            left: 0,
            top: (_bannerAd?.size.height.toDouble() ?? 50.0) + (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            width: screenWidth * 0.75, // スライドビューの幅を指定します（画面の75％に設定）
            height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.5, // 高さを画面全体に指定
            child:SlideView(
              screenWidth: screenWidth,
              screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '自分 VS 相手',
                    style: TextStyle(fontSize: screenWidth * 0.08, color: Colors.white,
                      fontFamily: 'makinas4',
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: battleLog.length,
                      itemBuilder: (context, index) {
                        final log = battleLog[index];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text('ラウンド' + (index + 1).toString(),
                              style: TextStyle(fontSize: screenWidth * 0.04,
                                fontFamily: 'makinas4',
                              ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: screenHeight * 0.1,
                                        width: screenWidth * 0.2,
                                        child: Stack(
                                          children: [
                                            // myHandを左上に配置
                                            SvgPicture.asset(
                                              'Images/' + log['myHand']! + '.svg',
                                              height: screenHeight * 0.06,
                                            ),
                                            // mySkillを右下に配置
                                            Positioned(
                                              bottom: 0,
                                              right: 0, // 右下に配置
                                              child: Container(
                                                height: screenHeight * 0.065,
                                                width: screenHeight * 0.065,
                                                child: Stack(
                                                  alignment: Alignment.center, // 中央に揃える
                                                  children: [
                                                    Image.asset( // 中央揃えで画像
                                                      'Images/battleLogSkill.png',
                                                      height: screenHeight * 0.065,
                                                      width: screenHeight * 0.065,
                                                    ),
                                                    Image.asset( // 中央揃えで画像
                                                      'Images/' + log['mySkill']! + '.png',
                                                      height: screenHeight * 0.035,
                                                      width: screenHeight * 0.035,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: screenHeight * 0.1,
                                        width: screenWidth * 0.2,
                                        child: Stack(
                                          children: [
                                            // myHandを左上に配置
                                            SvgPicture.asset(
                                              'Images/' + log['enemyHand']! + '.svg',
                                              height: screenHeight * 0.06,
                                            ),
                                            // mySkillを右下に配置
                                            Positioned(
                                              bottom: 0,
                                              right: 0, // 右下に配置
                                              child: Container(
                                                height: screenHeight * 0.065,
                                                width: screenHeight * 0.065,
                                                child: Stack(
                                                  alignment: Alignment.center, // 中央に揃える
                                                  children: [
                                                    Image.asset( // 中央揃えで画像
                                                      'Images/battleLogSkill.png',
                                                      height: screenHeight * 0.065,
                                                      width: screenHeight * 0.065,
                                                    ),
                                                    Image.asset( // 中央揃えで画像
                                                      'Images/' + log['enemySkill']! + '.png',
                                                      height: screenHeight * 0.035,
                                                      width: screenHeight * 0.035,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ]
                          )
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ),

          Column( //自分のスキルdetail
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                if (mySkillDetail) CardDetailView (
                  selectedCardIndex: _mySelectedCardIndex,
                  cards: myCards,
                  screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                  screenWidth: screenWidth,
                ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                if (mySkillDetail  && nowScene == 'battleSelect' && myCards[_mySelectedCardIndex]['used'] == 'false') CustomImageButton(
                  screenWidth: screenWidth,
                  buttonText: "決定",
                  onPressed: () => {
                    setState(() {
                      mySkillDetail = false;
                      _myBattleCardIndex = _mySelectedCardIndex;
                      myBattleHand = myCards[_myBattleCardIndex]['type'] ?? 'rock';
                      myBattleSkillNo = myCards[_myBattleCardIndex]['no'] ?? 'No0';
                    })
                  }
                  ),
                SizedBox(width: screenWidth * 0.1),
                if (mySkillDetail) CustomImageButton(
                  screenWidth: screenWidth,
                  buttonText: "閉じる",
                  onPressed: () => {
                    setState(() {
                      mySkillDetail = false;
                    })
                  }
                ),
                ]
              )

            ],
          ),

          Column( //敵のスキルdetail
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                if (enemySkillDetail) CardDetailView (
                  selectedCardIndex: _enemySelectedCardIndex,
                  cards: enemyCards,
                  screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                  screenWidth: screenWidth,
                ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                SizedBox(width: screenWidth * 0.1),
                if (enemySkillDetail) CustomImageButton(
                  screenWidth: screenWidth,
                  buttonText: "閉じる",
                  onPressed: () => {
                    setState(() {
                      enemySkillDetail = false;
                    })
                  }
                ),
                ]
              )

            ],
          ),

          Positioned( // 敵のスキル発動ビュー
            bottom:screenHeight * 0.5,
            child:
            EnemyAnimatedSkillWidget(
              cards: enemyCards,
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              isVisible: enemySkillActive,
              skillNo: enemyBattleSkillNo,
            ),
          ),

          Positioned( // 自分のスキル発動ビュー
            top: screenHeight * 0.5,
            child:
            MyAnimatedSkillWidget(
              cards: myCards,
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              isVisible: mySkillActive,
              skillNo: myBattleSkillNo,
            ),
          ),


          if (nowScene == 'cardOpen' && nowEnemyOpenCardsNo.isNotEmpty)
          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.05,
            child:
            FlipCard(
              key: flipCardKeys[0],
              screenWidth: screenWidth,
              screenHeight: screenWidth,
              skillNo: nowEnemyOpenCardsNo[0] as String,
              skillName: nowEnemyOpenCardsName[0] as String,
            ),
          ),
          if (nowScene == 'cardOpen' && nowEnemyOpenCardsNo.length > 1)
          Positioned(
            bottom: screenHeight * 0.55,
            right: screenWidth * 0.05,
            child:
            FlipCard(
              key: flipCardKeys[1],
              screenWidth: screenWidth,
              screenHeight: screenWidth,
              skillNo: nowEnemyOpenCardsNo[1] as String,
              skillName: nowEnemyOpenCardsName[1] as String,
            ),
          ),
          if (nowScene == 'cardOpen' && nowMyOpenCardsNo.isNotEmpty)
          Positioned(
            top: screenHeight * 0.55,
            left: screenWidth *0.05,
            child:
            FlipCard(
              key: flipCardKeys[2],
              screenWidth: screenWidth,
              screenHeight: screenWidth,
              skillNo: nowMyOpenCardsNo[0] as String,
              skillName: nowMyOpenCardsName[0] as String,
            ),
          ),
          if (nowScene == 'cardOpen' && nowMyOpenCardsNo.length > 1)
          Positioned(
            top: screenHeight * 0.55,
            right: screenWidth *0.05,
            child:
            FlipCard(
              key: flipCardKeys[3],
              screenWidth: screenWidth,
              screenHeight: screenWidth,
              skillNo: nowMyOpenCardsNo[1] as String,
              skillName: nowMyOpenCardsName[1] as String,
            ),
          ),
        ]
      )
    );
  }
}

//ここからクラス

class CardListView extends StatefulWidget {
  final List<Map<String, String>> cards;
  final double screenHeight;
  final double screenWidth;
  final int selectedCardIndex;
  final Function(int) onCardTap;

  CardListView({
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.selectedCardIndex,
    required this.onCardTap,
  });

  @override
  _CardListViewState createState() => _CardListViewState();
}

class _CardListViewState extends State<CardListView> with SingleTickerProviderStateMixin {

  @override
  Widget build(BuildContext context) {

    return Positioned(
      right: 0, // 画面の右端に固定
      bottom: 0, // 画面の下端に固定
      child: Container(
        width: widget.screenWidth * 0.6,
        height: widget.screenHeight * 0.25,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  final bool isSelected = widget.selectedCardIndex == index;
                  return GestureDetector(
                    onTap: () => widget.onCardTap(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 1.50), // 上下に8.0のマージンを追加
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Image.asset(
                            'Images/cardView.png',
                            width: widget.screenWidth * 0.6, // カードの幅を画面の80%に設定
                            height: widget.screenHeight * 0.07, // カードの高さを指定
                            fit: BoxFit.fill, // 画像をカードサイズに合わせる
                          ),


                          if (widget.cards[index]['open'] == 'true' || widget.cards[index]['belong'] == 'mine')
                          Positioned(
                            left: widget.screenWidth * 0.8 * 0.03, // カードの左上から8.5%右へ
                            top: widget.screenHeight * 0.015, // カードの上から40.7%下へ
                            child: SvgPicture.asset(
                              widget.cards[index]['image']!, // 手の画像
                              height: widget.screenHeight * 0.03, // 手の画像のサイズ
                            ),
                          ),
                          if (widget.cards[index]['open'] == 'false' && widget.cards[index]['belong'] != 'mine')
                          Positioned(
                            left: widget.screenWidth * 0.8 * 0.03, // カードの左上から8.5%右へ
                            top: widget.screenHeight * 0.015, // カードの上から40.7%下へ
                            child: Icon(Icons.question_mark, size: widget.screenWidth * 0.06)
                          ),


                          if (widget.cards[index]['open'] == 'true' || widget.cards[index]['belong'] == 'mine')
                          Positioned(
                            left: widget.screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                            top: widget.screenHeight * 0.015, // カードの上から48%下へ
                            child: Row(
                              children: [
                                Image.asset(
                                  widget.cards[index]['skill']!, // スキルの画像
                                  height: widget.screenHeight * 0.045,
                                  width: widget.screenHeight * 0.045,
                                  fit: BoxFit.contain, // スキルの画像のサイズ
                                ),
                                SizedBox(width: 5), // スキル名との間にスペースを追加
                                Text(
                                  widget.cards[index]['skillName']!, // スキル名を表示
                                  style: TextStyle(
                                    fontFamily: 'makinas4',
                                    fontSize: widget.screenHeight * 0.02,
                                    color: (widget.cards[index]['used'] != 'true')
                                      ? Colors.black
                                      : const Color.fromARGB(255, 202, 202, 202),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (widget.cards[index]['open'] == 'false' && widget.cards[index]['belong'] != 'mine')
                          Positioned(
                            left: widget.screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                            top: widget.screenHeight * 0.015, // カードの上から48%下へ
                            child: Row(
                              children: [// スキル名との間にスペースを追加
                                Icon(Icons.help_center_outlined, size: widget.screenWidth * 0.07),
                                Icon(Icons.question_mark, size: widget.screenWidth * 0.05),
                                Icon(Icons.question_mark, size: widget.screenWidth * 0.05),
                                Icon(Icons.question_mark, size: widget.screenWidth * 0.05),
                              ],
                            ),
                          ),


                          // 公開されているカードに目のマークを追加
                          if (widget.cards[index]['open']! == 'true' && widget.cards[index]['used'] != 'true')
                            Positioned(
                              right: 5,
                              bottom: 0,
                              child: Icon(
                                Icons.visibility,
                                color: Colors.grey,
                                size: widget.screenHeight * 0.03,
                              ),
                            ),

                          if (widget.cards[index]['used']! == 'true')
                            Positioned(
                              right: 5,
                              bottom: 0,
                              child: Icon(FontAwesomeIcons.cross,
                                color: Colors.grey,
                                size: widget.screenHeight * 0.03,
                              ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: widget.screenHeight * 0.008,
                              left: widget.screenWidth * 0.45,
                                child: Image.asset(
                                  'Images/pointer.png',
                                  height: widget.screenHeight * 0.03,
                                ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardDetailView extends StatelessWidget {
  final int selectedCardIndex;
  final List<Map<String, String>> cards;
  final double screenHeight;
  final double screenWidth;

  CardDetailView({
    required this.selectedCardIndex,
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCardIndex < 0 || selectedCardIndex >= cards.length) {
      return SizedBox(); // 有効なカードが選択されていない場合は空のウィジェットを返す
    }

    final cardData = cards[selectedCardIndex];
    return Stack(
      children: [
        // 背景画像のサイズと位置調整
        Image.asset(
          'Images/cardDetail.png',

          width: screenWidth * 0.9,
          fit: BoxFit.cover,
        ),


        //グーチョキパーの画像
        if (cardData['typeOpen'] == 'true' || cardData['belong'] == 'mine')
        Positioned(
          top: screenWidth * 0.054,
          right: screenWidth * 0.095,
          child: SvgPicture.asset(
            cardData['image']!,
            width: screenWidth * 0.1,
          ),
        ),
        if (cardData['typeOpen'] == 'false' && cardData['belong'] != 'mine')
        Positioned(
          top: screenWidth * 0.054,
          right: screenWidth * 0.095,
          child: Icon(Icons.question_mark, size: screenWidth * 0.1)
        ),

        //敵か自分のカードかどうか
        if (cardData['belong'] == 'enemy')
        Positioned(
          top: screenWidth * 0.2,
          right: screenWidth * 0.15,
          child: Text(
            '敵',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.12,
            ),
          ),
        ),

        // スキル名のテキスト (右上)
        Positioned(
          top: screenWidth * 0.16,
          left: screenWidth * 0.17,
          child: (cardData['belong'] == 'mine' || cardData['open'] == 'true')
          ? Image.asset(
              cardData['skill']!,
            width: screenWidth * 0.27,
            height: screenWidth * 0.27,
          )
          : Icon(Icons.help_center_outlined, size: screenWidth * 0.25),
        ),

        Positioned(
          top: screenHeight * 0.02,
          left: screenWidth * 0.05,
          child: (cardData['belong'] == 'mine' || cardData['open'] == 'true')
           ? Text(
            (cardData['no'] ?? '') + ' ' + (cardData['skillName'] ?? '存在しない技'),
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.07,
            ),
          )
          : Row(
            children: [
              Text('No',
                style: TextStyle(
                fontFamily: 'makinas4',
                fontSize: screenWidth * 0.07,
                ),
              ),
              Icon(Icons.question_mark, size: screenWidth * 0.05),
              Icon(Icons.question_mark, size: screenWidth * 0.05),
              SizedBox(width: 10,),
              Icon(Icons.question_mark, size: screenWidth * 0.07),
              Icon(Icons.question_mark, size: screenWidth * 0.07),
              Icon(Icons.question_mark, size: screenWidth * 0.07),
              Icon(Icons.question_mark, size: screenWidth * 0.07),

            ],
          ),
        ),

        // 説明テキスト (下側中央)
        Positioned(
          top: screenWidth * 0.5,
          left: screenWidth * 0.1,
          right: screenWidth * 0.1,
          bottom: screenWidth * 0.1,
          child: SingleChildScrollView(
          child: (cardData['belong'] == 'mine' || cardData['open'] == 'true')
           ? Text(
            cardData['description'] ?? '',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenHeight * 0.03, // フォントサイズを調整
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.left,
          )
          : Text(
            '????????????',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenHeight * 0.03, // フォントサイズを調整
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.left,
          )
        ),
        ),
      ],
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

class MyInfo extends StatelessWidget {
  final double screenWidth;
  final double screenHeight; // screenHeightも引数として追加
  final String name;
  final String rank;
  final int point;
  final int winPoint;
  final VoidCallback onPressed;

  MyInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.name,
    required this.rank,
    required this.point,
    required this.winPoint,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: screenWidth * 0.4, // 幅をscreenWidthの0.4倍に設定
        height: screenHeight * 0.25, // 高さをscreenHeightの0.25倍に設定
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
                  'Images/' + rank + '.svg',
                  height: screenHeight * 0.12,
                  width: screenWidth * 0.3, // 画面幅に応じたサイズ設定
                  fit: BoxFit.contain,
                ),
            // ボタンの背景画像
            SizedBox(height: screenHeight * 0.013,),
            Row(
              children: [

                Expanded( // テキストが横幅を占有できるように設定
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.35 / (name.length >= 5 ? name.length : 5),
                    ),
                    textAlign: TextAlign.center,

                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // テキストを中央寄せ
              children: [
                Text(point.toString() + 'pt' + '/',
                style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.04,
                    ),
                    textAlign: TextAlign.center,
                ),// テキストとの間隔を追加
                Text(winPoint.toString() + 'pt',
                style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.04,
                    ),
                    textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EnemyInfo extends StatelessWidget {
  final double screenWidth;
  final double screenHeight; // screenHeightも引数として追加
  final String name;
  final String rank;
  final int point;
  final int winPoint;
  final VoidCallback onPressed;

  EnemyInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.name,
    required this.rank,
    required this.point,
    required this.winPoint,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: screenWidth * 0.4, // 幅をscreenWidthの0.4倍に設定
        height: screenHeight * 0.25, // 高さをscreenHeightの0.25倍に設定
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
                  'Images/' + rank + '.svg',
                  height: screenHeight * 0.12,
                  width: screenWidth * 0.3, // 画面幅に応じたサイズ設定
                  fit: BoxFit.contain,
                ),
            // ボタンの背景画像
            Row(
              children: [

                Expanded( // テキストが横幅を占有できるように設定
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.35 / (name.length >= 5 ? name.length : 5),
                    ),
                    textAlign: TextAlign.center,

                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // テキストを中央寄せ
              children: [
                Text(point.toString() + 'pt' + '/',
                style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.04,
                    ),
                    textAlign: TextAlign.center,
                ),// テキストとの間隔を追加
                Text(winPoint.toString() + 'pt',
                style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.04,
                    ),
                    textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SlideView extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final Widget content;

  const SlideView({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.content,
  }) : super(key: key);

  @override
  _SlideViewState createState() => _SlideViewState();
}

class _SlideViewState extends State<SlideView> {
  bool isSlideViewVisible = false;

  void toggleSlideView() {
    print('横のボタンが押されました。');
    setState(() {
      isSlideViewVisible = !isSlideViewVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          top: 0,
          bottom: 0,
          left: isSlideViewVisible ? 0 : -widget.screenWidth * 0.6,
          width: widget.screenWidth * 0.6 + 50, // ボタンの幅を含めたサイズ
          child: Row(
            children: [
              // スライドビューの内容
              Container(
                width: widget.screenWidth * 0.6,
                color: Colors.grey.withOpacity(0.9),
                padding: EdgeInsets.all(16),
                child: widget.content,
              ),

              // スライドボタン
              GestureDetector(
                onTap: toggleSlideView,
                child: Container(
                  width: 20,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child:
                    Text(isSlideViewVisible ? '<' : '>',
                      style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'makinas4',
                            fontSize: 20,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EnemySlideInStack extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final bool isVisible;
  final String handType;
  final String skillNo;

  const EnemySlideInStack({Key? key, required this.screenHeight, required this.screenWidth, required this.isVisible, required this.handType, required this.skillNo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(

      children: [

        // トグルボタン
        Positioned(
          right: 20,
          top: 0,
            child: Transform.rotate(
              angle: 245 * (3.14159265359 / 180), // 45度回転
              child: SvgPicture.asset(
                'Images/$handType.svg',
                height: screenHeight * 0.18,
                width: screenHeight * 0.18,
              ),
            ),
          ),

        // スライドアニメーション用の Positioned ウィジェット
        AnimatedPositioned(
          duration: Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          right: isVisible ? screenWidth * 0.4 : -screenHeight * 1, // 位置を調整
          top: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'Images/battleLogSkill.png',
                height: screenHeight * 0.18,
                width: screenHeight * 0.18,
              ),
              Image.asset(
                'Images/$skillNo.png',
                height: screenHeight * 0.1,
                width: screenHeight * 0.1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MySlideInStack extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final bool isVisible;
  final String handType;
  final String skillNo;

  const MySlideInStack({Key? key, required this.screenHeight, required this.screenWidth, required this.isVisible, required this.handType, required this.skillNo}) : super(key: key);

   @override
  Widget build(BuildContext context) {
    return Stack(

      children: [
        // スライドアニメーション用の Positioned ウィジェット

        // トグルボタン
        Positioned(
          left: 20,
          top: 0,

          child: Transform.rotate(
            angle: 65 * (3.14159265359 / 180), // 45度回転
            child: SvgPicture.asset(
              'Images/$handType.svg',
              height: screenHeight * 0.18,
              width: screenHeight * 0.18,
            ),
          ),
        ),


        AnimatedPositioned(
          duration: Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          left: isVisible ? screenWidth * 0.4 : -screenHeight * 1, // 位置を調整
          top: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'Images/battleLogSkill.png',
                height: screenHeight * 0.18,
                width: screenHeight * 0.18,
              ),
              Image.asset(
                'Images/$skillNo.png',
                height: screenHeight * 0.1,
                width: screenHeight * 0.1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EnemyAnimatedSkillWidget extends StatefulWidget {
  final List<Map<String, String>> cards;
  final double screenHeight;
  final double screenWidth;
  final bool isVisible;
  final String skillNo;

  const EnemyAnimatedSkillWidget({
    Key? key,
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.isVisible,
    required this.skillNo,
  }) : super(key: key);

  @override
  _EnemyAnimatedSkillWidgetState createState() => _EnemyAnimatedSkillWidgetState();
}

class _EnemyAnimatedSkillWidgetState extends State<EnemyAnimatedSkillWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String? findSkillName({
  required List<Map<String, String>> cards,
  required String skillNo,
  }) {
    // 'no'キーがskillNoに一致するカードを探す
    final matchingCard = cards.firstWhere(
      (card) => card['no'] == skillNo,
      orElse: () => {}, // 見つからない場合の処理
    );

    // 見つかった場合'name'キーの値を返す
    return matchingCard.isNotEmpty ? matchingCard['skillName'] : null;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = TweenSequence([
      // 左から素早く中央に移動
      TweenSequenceItem(
        tween: Tween(begin: Offset(300.0, 0.0), end: Offset(0.2, 0.0))
            .chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 10,
      ),
      // 中央でスローモーション
      TweenSequenceItem(
        tween: Tween(begin: Offset(0.2, 0.0), end: Offset(-0.2, 0.0))
            .chain(CurveTween(curve: Curves.linear)),
        weight: 40,
      ),
      // 再度スピードアップして右端に移動
      TweenSequenceItem(
        tween: Tween(begin: Offset(-0.2, 0.0), end: Offset(-300.0, 0.0))
            .chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant EnemyAnimatedSkillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? skillName = findSkillName(
      cards: widget.cards,
      skillNo: widget.skillNo,
    );
    return SlideTransition(
      position: _slideAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
           Image.asset(
            'Images/battleLogSkill.png',
            height: widget.screenHeight * 0.4,
            width: widget.screenHeight * 0.5,
            fit: BoxFit.fill
          ),
          Positioned(
            top: widget.screenHeight * 0.07,
            left: widget.screenHeight * 0.12,
            child: Text(
              skillName?? 'unknown',
              style: TextStyle(
                fontSize: widget.screenHeight * 0.045,
                color: Colors.black,
                fontFamily: 'makinas4',
              ),
            ),
          ),
          Positioned(
            left: widget.screenHeight * 0.06,
            bottom: widget.screenHeight * 0.08,
            child: Image.asset(
              'Images/' + widget.skillNo + '.png',
              height: widget.screenHeight * 0.18,
              width: widget.screenHeight * 0.18,
              fit: BoxFit.contain
            ),
          ),
          Positioned(
            right: widget.screenHeight * 0.16,
            bottom: widget.screenHeight * 0.08,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: '発動'.split('').map((char) {
                return Text(
                  char,
                  style: TextStyle(
                    fontSize: widget.screenHeight * 0.07,
                    color: Colors.black,
                    fontFamily: 'makinas4',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class MyAnimatedSkillWidget extends StatefulWidget {
  final List<Map<String, String>> cards;
  final double screenHeight;
  final double screenWidth;
  final bool isVisible;
  final String skillNo;

  const MyAnimatedSkillWidget({
    Key? key,
    required this.cards,
    required this.screenHeight,
    required this.screenWidth,
    required this.isVisible,
    required this.skillNo,
  }) : super(key: key);

  @override
  _MyAnimatedSkillWidgetState createState() => _MyAnimatedSkillWidgetState();
}

class _MyAnimatedSkillWidgetState extends State<MyAnimatedSkillWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  String? findSkillName({
  required List<Map<String, String>> cards,
  required String skillNo,
  }) {
    // 'no'キーがskillNoに一致するカードを探す
    final matchingCard = cards.firstWhere(
      (card) => card['no'] == skillNo,
      orElse: () => {}, // 見つからない場合の処理
    );

    // 見つかった場合'name'キーの値を返す
    return matchingCard.isNotEmpty ? matchingCard['skillName'] : null;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = TweenSequence([
      // 左から素早く中央に移動
      TweenSequenceItem(
        tween: Tween(begin: Offset(-300.0, 0.0), end: Offset(-0.2, 0.0))
            .chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 10,
      ),
      // 中央でスローモーション
      TweenSequenceItem(
        tween: Tween(begin: Offset(-0.2, 0.0), end: Offset(0.2, 0.0))
            .chain(CurveTween(curve: Curves.linear)),
        weight: 40,
      ),
      // 再度スピードアップして右端に移動
      TweenSequenceItem(
        tween: Tween(begin: Offset(0.2, 0.0), end: Offset(300.0, 0.0))
            .chain(CurveTween(curve: Curves.fastOutSlowIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MyAnimatedSkillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? skillName = findSkillName(
      cards: widget.cards,
      skillNo: widget.skillNo,
    );
    return SlideTransition(
      position: _slideAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'Images/battleLogSkill.png',
            height: widget.screenHeight * 0.4,
            width: widget.screenHeight * 0.5,
            fit: BoxFit.fill
          ),
          Positioned(
            top: widget.screenHeight * 0.07,
            left: widget.screenHeight * 0.12,
            child: Text(
              skillName ?? 'unknown',
              style: TextStyle(
                fontSize: widget.screenHeight * 0.045,
                color: Colors.black,
                fontFamily: 'makinas4',
              ),
            ),
          ),
          Positioned(
            left: widget.screenHeight * 0.06,
            bottom: widget.screenHeight * 0.08,
            child: Image.asset(
              'Images/' + widget.skillNo + '.png',
              height: widget.screenHeight * 0.18,
              width: widget.screenHeight * 0.18,
              fit: BoxFit.contain
            ),
          ),
          Positioned(
            right: widget.screenHeight * 0.16,
            bottom: widget.screenHeight * 0.08,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: '発動'.split('').map((char) {
                return Text(
                  char,
                  style: TextStyle(
                    fontSize: widget.screenHeight * 0.07,
                    color: Colors.black,
                    fontFamily: 'makinas4',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DeclarationDisplay extends StatelessWidget {
  final String points;
  final String hand;

  DeclarationDisplay({
    required this.points,
    required this.hand,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '宣言',
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.08,
          ),
        ),
        SizedBox(width: 5),
        SvgPicture.asset(
          'Images/' + hand + '.svg', // SVG画像へのパスを指定
          height: screenWidth * 0.06,
          width: screenWidth * 0.06,
        ),
        SizedBox(width: 5),
        Text(
          '$points pt',
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.07,
          ),
        ),
      ],
    );
  }
}

class DeclareHandSelection extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final VoidCallback onRockSelected;
  final VoidCallback onScissorsSelected;
  final VoidCallback onPaperSelected;
  final Function(int) onPointSelected; // ポイントを設定する関数を引数に

  DeclareHandSelection({
    required this.screenHeight,
    required this.screenWidth,
    required this.onRockSelected,
    required this.onScissorsSelected,
    required this.onPaperSelected,
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.35,
      width: screenWidth,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '宣言する手とptを選べ！！',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: screenHeight * 0.02),
          // グー、チョキ、パーのボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onRockSelected,
                icon: SvgPicture.asset(
                  'Images/rock.svg',
                  height: screenHeight * 0.1,
                  width: screenHeight * 0.1,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onScissorsSelected,
                icon: SvgPicture.asset(
                  'Images/scissor.svg',
                  height: screenHeight * 0.1,
                  width: screenHeight * 0.1,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onPaperSelected,
                icon: SvgPicture.asset(
                  'Images/paper.svg',
                  height: screenHeight * 0.1,
                  width: screenHeight * 0.1,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // ポイントボタン
          Wrap(
            spacing: screenWidth * 0.03,
            children: [10, 20, 30, 40, 50].map((point) {
              return ElevatedButton(
                onPressed: () => onPointSelected(point), // ポイントを設定
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.04,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '$point pt',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class BattleHandDisplay extends StatelessWidget {
  final String points;
  final String hand;

  BattleHandDisplay({
    required this.points,
    required this.hand,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '宣言',
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.08,
          ),
        ),
        SizedBox(width: 5),
        SvgPicture.asset(
          'Images/' + hand + '.svg', // SVG画像へのパスを指定
          height: screenWidth * 0.06,
          width: screenWidth * 0.06,
        ),
        SizedBox(width: 5),
        Text(
          '$points pt',
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.07,
          ),
        ),
      ],
    );
  }
}

class BattleHandSelection extends StatelessWidget {
  final List<Map<String, String>> cards;
  final int battleIndex;
  final double screenHeight;
  final double screenWidth;

  BattleHandSelection({
    required this.cards,
    required this.battleIndex,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.35,
      width: screenWidth,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '勝負するカードを選べ！！',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            '現在選択中のカード',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
            ),
            textAlign: TextAlign.left,
          ),
          Stack(
            alignment: Alignment.topLeft,
            children: [
              Image.asset(
                'Images/cardView.png',
                width: screenWidth * 0.6, // カードの幅を画面の80%に設定
                height: screenHeight * 0.053, // カードの高さを指定
                fit: BoxFit.fill, // 画像をカードサイズに合わせる
              ),

              Positioned(
                left: screenWidth * 0.8 * 0.032, // カードの左上から8.5%右へ
                top: screenHeight * 0.007, // カードの上から40.7%下へ
                child: SvgPicture.asset(
                  battleIndex >= 0 ? cards[battleIndex]['image']! : 'Images/none.svg', // 手の画像
                  height: screenHeight * 0.025, // 手の画像のサイズ
                ),
              ),

              Positioned(
                left: screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                top: screenHeight * 0.009, // カードの上から48%下へ
                child: Row(
                  children: [
                    Image.asset(
                       battleIndex >= 0 ? cards[battleIndex]['skill']! : 'Images/none.png', // スキルの画像
                      height: screenHeight * 0.035, // スキルの画像のサイズ
                    ),
                    SizedBox(width: 5), // スキル名との間にスペースを追加
                    Text(
                       battleIndex >= 0 ? cards[battleIndex]['skillName']! : '未選択', // スキル名を表示
                      style: TextStyle(
                        fontFamily: 'makinas4',
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),


              // 公開されているカードに目のマークを追加
              if (battleIndex >= 0 ? cards[battleIndex]['open']! == 'true' : false)
                Positioned(
                  right: 5,
                  bottom: 0,
                  child: Icon(
                    Icons.visibility,
                    color: Colors.grey,
                    size: screenHeight * 0.03,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class FlipCard extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final String skillNo;
  final String skillName;
  final bool isInitiallyFront;

  FlipCard({
    required this.screenWidth,
    required this.screenHeight,
    required this.skillNo,
    required this.skillName,
    this.isInitiallyFront = true,
    Key? key, // GlobalKeyを使うために追加
  }) : super(key: key);

  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool isFront;

  @override
  void initState() {
    super.initState();
    isFront = widget.isInitiallyFront;
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void flipCard() { // メソッドを公開
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
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double angle = _animation.value * pi;
          bool isBackVisible = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              width: widget.screenWidth * 0.4,
              height: widget.screenHeight * 0.6,
              child:
              isBackVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBackSide(),
                  )
                : _buildFrontSide(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '?',
        style: TextStyle(
          fontSize: 40,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.skillNo,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenWidth * 0.06,
            ),
          ),
          Image.asset(
            'Images/' + widget.skillNo + '.png',
            width: 100,
            height: 100,
          ),
          Text(widget.skillName,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: widget.screenWidth * 0.06,
            ),
          ),
        ]
      )
    );
  }
}








