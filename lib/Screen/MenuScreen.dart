import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_application_1/Screen/SkillScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}
class _MenuScreenState extends State<MenuScreen> {
  BannerAd? _bannerAd;
  //ユーザー情報
  String name = 'ゲスト';
  String rank = 'bronze1';
  int level = 0;
  int levelExp = 0;
  int rankCount = 0;
  int winStreak = 0;
  int trophy = 0;

  //スキル情報
  int skillNumber = 50;

  List<Map<String, dynamic>> rankList =
  [
    {'rank': 'ブロンズ ', 'number': 0},
    {'rank': 'シルバー ', 'number': 0},
    {'rank': 'ゴールド ', 'number': 0},
    {'rank': 'プラチナ ', 'number': 0},
    {'rank': 'ダイヤ　 ', 'number': 0},
    {'rank': 'エリート ', 'number': 0},
    {'rank': 'マスター ', 'number': 0},
    {'rank': 'チャンプ ', 'number': 0},
  ];
  bool rankCheckFinish = false;
  bool rankView = false;
  bool versionUpView = false;

  //アイコン掲示板用
  int iconInfoCount = 0;

  void goTutorial() {
    context.go('/option');
  }

  Future<void> updateFieldsInFirebase({
    required Map<String, dynamic> fieldsToUpdate, // 更新するフィールドとその値
  }) async {
    try {
      // Firebaseのドキュメント参照
      final DocumentReference docRef = FirebaseFirestore.instance.collection('newUserData').doc(uid);

      // ドキュメントの存在を確認
      final DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // ドキュメントが存在する場合は更新
        await docRef.update(fieldsToUpdate);
        print(fieldsToUpdate);
        print("Fields updated successfully in Firebase.");
      } else {
        // ドキュメントが存在しない場合は作成しつつデータを設定
        await docRef.set(fieldsToUpdate);
        print("Document created and fields set successfully in Firebase.");
      }
    } catch (e) {
      print("Error updating fields in Firebase: $e");
    }
  }

  Future<dynamic> getFieldFromFirebase({
    required String collection,
    required String document,
    required String field, // 読み取るフィールド名
  }) async {
    try {
      // Firebaseのドキュメント参照
      DocumentReference docRef =
          FirebaseFirestore.instance.collection(collection).doc(document);

      // ドキュメントを取得
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // データを取得
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        // フィールドが存在すればその値を返す
        if (data != null && data.containsKey(field)) {
          return data[field];
        } else {
          print("Field '$field' does not exist.");
          return null;
        }
      } else {
        print("Document does not exist.");
        return null;
      }
    } catch (e) {
      print("Error reading field from Firebase: $e");
      return null;
    }
  }


  @override
  void initState() {
    super.initState();
    _loadPreferences();  // アプリ起動時にカウントを読み込む
    loadIconPostStateFromFirebase();
    checkCurrentVersion();
    _loadRoutePass('/menu');
    setMyInfo();
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
    // dispose を使って、状態変更やリソースの解放を行う
    super.dispose();
  }

  loadFromFirebase() async {
    print(getFieldFromFirebase(collection: 'population', document: 'rank', field: 'bronze'));
    rankList[0]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'bronze');
    rankList[1]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'silver');
    rankList[2]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'gold');
    rankList[3]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'platina');
    rankList[4]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'diamond');
    rankList[5]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'elite');
    rankList[6]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'master');
    rankList[7]['number'] = await getFieldFromFirebase(collection: 'population', document: 'rank', field: 'champion');
    print(rankList);
    setState(() {
      if (rankList[0]['number'] != null){
        rankCheckFinish = true;
      }
    });
  }

  loadIconPostStateFromFirebase() async {
    int? iconLikeCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconLikeCount',
        )) as int? ?? 0;
    int iconInstallCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconInstallCount',
        )) as int? ?? 0;
    int? iconDoneCount = (await getFieldFromFirebase(
          collection: 'newUserData',
          document: uid,
          field: 'iconDoneCount',
        )) as int? ?? 0;
    setState(() {
      iconInfoCount = iconLikeCount + iconInstallCount - iconDoneCount;
      print(iconInfoCount);
    });
  }

  checkCurrentVersion() async {
    String? currentVersion = (await getFieldFromFirebase(
          collection: 'version',
          document: 'newShinkenOnline',
          field: 'version',
        )) as String? ?? '0.0.0';
    setState(() {
      print('現在のバージョン${versionToInt(version)},最新のバージョン${versionToInt(currentVersion)}');
      if (versionToInt(currentVersion) > versionToInt(version)){
        versionUpView = true;
      }
    });
  }

  int versionToInt(String stringVersion) {
    List<String> versionIntList = stringVersion.split('.');
    if (versionIntList.length == 3) {
      int versionInt = (int.tryParse(versionIntList[0]) ?? 0) * 1000000 +  (int.tryParse(versionIntList[1]) ?? 0) * 1000 + (int.tryParse(versionIntList[2]) ?? 0);
      return versionInt;
    } else {
      return 0;
    }

  }

  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('myName') ?? '名前はまだ無い';
      rank = prefs.getString('myRank') ?? 'bronze1';
      rankCount = prefs.getInt('myRankCount') ?? 0;
      winStreak = prefs.getInt('myWinStreak') ?? 0;
      level = prefs.getInt('myLevel') ?? 0;
      levelExp = prefs.getInt('myLevelExp') ?? 0;
      trophy = prefs.getInt('myTrophy') ?? 0;
    });
  }

  _setPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('myRank', 'bronze1');
    });
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

  void setMyInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await updateFieldsInFirebase(
      fieldsToUpdate: {
        'name': prefs.getString('myName') ?? '名前はまだ無い',
        'rank': prefs.getString('myRank') ?? 'bronze1',
        'rankCount': prefs.getInt('myRankCount') ?? 0,
        'skillList': prefs.getStringList('myOwnSkillList') ?? ['No1','No2','No3','No4','No5','No6','No7','No8','No9','No10',],
        'rockCount': prefs.getInt('myRockCount') ?? 0,
        'scissorCount': prefs.getInt('myScissorCount') ?? 0,
        'paperCount': prefs.getInt('myPaperCount') ?? 0,
        'battleCount': prefs.getInt('myBattleCount') ?? 0,
        'winCount': prefs.getInt('myWinCount') ?? 0,
        'winStreak': prefs.getInt('myWinStreak') ?? 0,
        'honestCount': prefs.getInt('myHonestCount') ?? 0,
        'gachaPoint': prefs.getInt('myGachaPoint') ?? 0,
        'trophy': prefs.getInt('myTrophy') ?? 0,
        'level': prefs.getInt('myLevel') ?? 1,
        'exp': prefs.getInt('myLevelExp') ?? 0,
      },
    );
    List<int> skillUseCountList = [];
    List<int> skillActiveCountList = [];
    for (int i = 0; i < skills.length; i ++) {
      skillUseCountList.add(prefs.getInt('mySkillCount_No${i + 1}') ?? 0);
      skillActiveCountList.add(prefs.getInt('mySkillActive_No${i + 1}') ?? 0);
    }
    print(skillUseCountList);

    await updateFieldsInFirebase(
      fieldsToUpdate: {
        'skillUseList': skillUseCountList,
        'skillActiveList': skillActiveCountList,
      },
    );
  }

  Future<void> _changeRoutePass(String routeName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
     // nullの場合は空のリストを使用
    setState(() {
      routePass.add(routeName);
      print(routePass.join(', '));
      routePass = routePass;
    });

    await prefs.setStringList('routePass', routePass);
    // 更新したリストを保存
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double buttonWidth = screenSize.width * 0.7; // ボタンの幅
    final double buttonHeight = screenSize.height * 0.08;  // ボタンの高さ
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final int requiredExp =  (5 * (pow(level, 1.5).round())) + 200;


    return Scaffold(
      body:
      Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [

                  SizedBox(width: 20,)
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                  padding: const EdgeInsets.only(left: 10.0), // 左端の余白
                  child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'makinas4',
                            fontSize: name.length > 5 ? screenWidth * 0.3 / name.length : screenWidth * 0.06,
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset('Images/trophy.png', width: screenWidth * 0.13,),
                            Text(
                              '$trophy',
                              style: TextStyle(
                                fontFamily: 'makinas4',
                                fontSize: screenWidth * 0.05,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$winStreak連勝中！',
                          style: TextStyle(
                            fontFamily: 'makinas4',
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        if (iconInfoCount > 0)
                        IconButton(
                          icon: Stack(
                            children: [
                              // メールアイコン
                              Icon(
                                Icons.email,
                                size: 36,
                              ),
                              // 通知数バッジ
                              Positioned(
                                right: 0, // 右上に配置
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.red, // バッジの背景色
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      iconInfoCount.toString(), // 通知数（動的に変更可能）
                                      style: TextStyle(
                                        color: Colors.white, // テキストの色
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            // ボタンが押されたときの処理
                            context.go('/makeIcon');
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 0.0), // 左端の余白
                    child:
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              loadFromFirebase();
                              rankView = !rankView;
                            });
                          },
                          child:
                        SvgPicture.asset(
                          'Images/$rank.svg',
                          width:  screenWidth * 0.2,
                          fit: BoxFit.contain,
                        ),
                        ),
                        Text('$rankCount / 100',
                        style: TextStyle(
                          fontFamily: 'makinas4',
                          fontSize: screenWidth * 0.04,
                        ),),
                      ],

                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0), // 左端の余白
                    child:
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        SemiCircularProgressBar(
                          currentExp: levelExp,
                          level: level,
                          requiredExp: requiredExp,
                          screenHeight: screenHeight,
                          screenWidth: screenWidth,
                        ),
                        Positioned(
                          top: screenHeight * 0.02,
                          child:
                          Column(
                            children: [
                              Text(
                                'Lv. $level',
                                style: TextStyle(
                                  fontFamily: 'makinas4',
                                  fontSize: screenWidth * 0.065,
                                ),
                              ),
                              Text(
                                ' $levelExp exp / \n   $requiredExp exp',
                                style: TextStyle(
                                  fontFamily: 'makinas4',
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ]
                          )
                        ),
                      ]
                    ),
                  )
                ],
              ),
              Spacer(),
              RankBattleButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              FriendBattleButton(buttonWidth: buttonWidth , buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              MiniGameButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              SkillSelectButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              BattleDataButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              RankingButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              SizedBox(height: screenSize.height * 0.01),
              BoardButton(buttonWidth: buttonWidth, buttonHeight: buttonHeight),
              Spacer()
            ],
          ),
          if (rankView && rankCheckFinish)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChartScreen(rankCheckFinish: rankCheckFinish, rankView: rankView, rankList: rankList, rank: rank),
              CustomImageButton(screenWidth: screenWidth, buttonText: '閉じる', onPressed: () {
                setState(() {
                  rankView = false;
                });
              })
            ]
          ),
          if (versionUpView)
          UpdateNotificationCard(),


        ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: goTutorial,
        tooltip: 'Increment',
        child: Icon(Icons.settings),
      ),
    );
  }
}

class RankBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  RankBattleButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed rank battle");
        context.go('/onlineBattle');
        // onlineBattle = true; // 状態管理の方法によって変わります
        // path.add(ViewIdentifier.onlineBattle); // 状態管理の方法によって変わります
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight),// ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            Icons.flag, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "ランク対戦",
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

class FriendBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  FriendBattleButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed friend battle");
        context.go('/friendBattle');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight),// ボタンサイズ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "友達と対戦",
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

class SkillSelectButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  SkillSelectButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed skill Select");
        context.go('/skill');
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
            Icons.star, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "スキル選択",
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

class BattleDataButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  BattleDataButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed  battle data");
        context.go('/data');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey, // 背景色
        foregroundColor: Colors.white, // テキスト色
        maximumSize: Size(buttonWidth, buttonHeight),
        minimumSize: Size(buttonWidth, buttonHeight),// ボタンサイズ
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
            "対戦データ",
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

class RankingButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  RankingButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed ranking button");
        context.go('/ranking');
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
            Icons.emoji_events, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "ランキング",
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

class MiniGameButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  MiniGameButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed miniGame button");
        context.go('/miniGame');
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
            Icons.rocket_launch, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "ミニゲーム",
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

class BoardButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  BoardButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("pushed miniGame button");
        context.go('/board');
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
            Icons.assignment, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            "掲示板",
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

class SemiCircularProgressBar extends StatelessWidget {
  final int currentExp;
  final int level;
  final int requiredExp;
  final double screenWidth;
  final double screenHeight;

  SemiCircularProgressBar({required this.currentExp, required this.level, required this.requiredExp, required this.screenHeight, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    // 必要な経験値の計算
    double progress = currentExp / requiredExp;
    double size =  screenWidth * 0.3;
    return CustomPaint(
      size: Size(size, size / 2), // 幅200、高さ100の半円
      painter: SemiCircularPainter(progress: progress),
    );
  }
}

class SemiCircularPainter extends CustomPainter {
  final double progress;

  SemiCircularPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double strokeWidth = 10.0;

    // 背景の半円
    Paint backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 進捗の半円
    Paint progressPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 描画範囲を設定
    Rect rect = Rect.fromLTWH(0, 0, width, height * 2);

    // 描画
    canvas.drawArc(rect, pi / 2, 2 * pi, false, backgroundPaint); // 背景半円
    canvas.drawArc(rect, -pi / 2, 2 * pi  * progress, false, progressPaint); // 進捗半円
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RankDistributionChart extends StatefulWidget {
  final List<Map<String, dynamic>> rankData; // ランクデータ
  final String myRank; // 自分のランク
  final double screenHeight;

  RankDistributionChart({required this.rankData, required this.myRank, required this.screenHeight});

  @override
  _RankDistributionChartState createState() => _RankDistributionChartState();
}

class _RankDistributionChartState extends State<RankDistributionChart> {
  late String myRankJapan;
  late String onlyRank;

  @override
  void initState() {
    super.initState();
    // 自分のランクを日本語に変換
    if (widget.myRank.contains('bronze')) {
      myRankJapan = 'ブロンズ ';
      onlyRank = 'bronze3';
    } else if (widget.myRank.contains('silver')) {
      myRankJapan = 'シルバー ';
      onlyRank = 'silver3';
    } else if (widget.myRank.contains('gold')) {
      myRankJapan = 'ゴールド ';
      onlyRank = 'gold3';
    } else if (widget.myRank.contains('platina')) {
      myRankJapan = 'プラチナ ';
      onlyRank = 'platina3';
    } else if (widget.myRank.contains('diamond')) {
      myRankJapan = 'ダイヤ ';
      onlyRank = 'diamond3';
    } else if (widget.myRank.contains('elite')) {
      myRankJapan = 'エリート ';
      onlyRank = 'elite3';
    } else if (widget.myRank.contains('master')) {
      myRankJapan = 'マスター ';
      onlyRank = 'master3';
    } else if (widget.myRank.contains('champion')) {
      myRankJapan = 'チャンプ ';
      onlyRank = 'champion3';
    } else {
      myRankJapan = '未知のランク';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ランクごとの人数の合計
    int totalCount = widget.rankData.fold(0, (sum, item) => sum + (item['number'] as int));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // グラフタイトル
        Text(
          'ランクの分布',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'makinas4',
          ),
        ),
        SizedBox(height: 20),

        // ランクの分布を表示
        ...widget.rankData.map((data) {
          double percentage = (((data['number'] ?? 0) as int) / totalCount) * 100; // 割合を計算
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: RankBar(
              rank: data['rank'] as String,
              percentage: percentage,
              isMyRank: data['rank'] == myRankJapan,
              onlyRank: onlyRank, // 自分のランクかどうかを判定
              screenHeight: widget.screenHeight,
            ),
          );
        }).toList(),
      ],
    );
  }
}

class RankBar extends StatelessWidget {
  final String rank;
  final double percentage;
  final bool isMyRank;
  final String onlyRank;
  final double screenHeight;

  RankBar({required this.rank, required this.percentage, required this.isMyRank, required this.onlyRank, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ランクの名前を表示
        SvgPicture.asset(
          'Images/${_getImageForRank(rank)}.svg',
          width: screenHeight * 0.07,
          fit: BoxFit.cover,
        ),
        Text(
          rank,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'makinas4',
            fontWeight: FontWeight.bold,
            color: isMyRank ? const Color.fromARGB(255, 208, 51, 51) : Colors.black,  // 自分のランクは赤で強調
          ),
        ),
        // 横棒（割合）を表示
        Container(
          width: MediaQuery.of(context).size.width * 0.6 * (percentage / 100), // 横棒の幅
          height: 15,
          decoration: BoxDecoration(
            color: _getColorForRank(rank),
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // 影の色
                offset: Offset(3, 3), // 影の位置（右下）
                blurRadius: 0, // 影のぼかし具合
              ),
            ],
          ),
        ),
        // パーセンテージのテキストを右側に表示
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,fontFamily: 'makinas4',),
          ),
        ),

      ],
    );
  }

  // ランクに応じた色を返す
  Color _getColorForRank(String rank) {
    switch (rank) {
      case 'ブロンズ ':
        return const Color.fromARGB(255, 199, 146, 60);
      case 'シルバー ':
        return const Color.fromARGB(255, 213, 213, 213);
      case 'ゴールド ':
        return const Color.fromARGB(255, 238, 252, 33);
      case 'プラチナ ':
        return const Color.fromARGB(255, 255, 245, 176);
      case 'ダイヤ　 ':
        return const Color.fromARGB(255, 87, 224, 248);
      case 'エリート ':
        return const Color.fromARGB(255, 39, 255, 223);
      case 'マスター ':
        return const Color.fromARGB(255, 231, 72, 72);
      case 'チャンプ ':
        return const Color.fromARGB(255, 0, 0, 0);
      default:
        return Colors.black;
    }
  }
  String _getImageForRank(String rank) {
    switch (rank) {
      case 'ブロンズ ':
        return 'bronze3';
      case 'シルバー ':
        return 'silver3';
      case 'ゴールド ':
        return 'gold3';
      case 'プラチナ ':
        return 'platina3';
      case 'ダイヤ　 ':
        return 'diamond3';
      case 'エリート ':
        return 'elite3';
      case 'マスター ':
        return 'master3';
      case 'チャンプ ':
        return 'champion3';
      default:
        return 'none';
    }
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

class ChartScreen extends StatelessWidget {
  final bool rankCheckFinish;
  final bool rankView;
  final List<Map<String, dynamic>> rankList;
  final String rank;

  ChartScreen({
    required this.rankCheckFinish,
    required this.rankView,
    required this.rankList,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景画像
        if (rankCheckFinish && rankView)
          Container(
          width: screenWidth,
          height: screenHeight * 0.9,
          decoration: BoxDecoration(
            color: Colors.white, // 背景色を白に設定
            border: Border.all(color: Colors.black, width: 1), // 黒い枠線
            boxShadow: [
              BoxShadow(
                color: Colors.black26, // 影の色
                blurRadius: 0, // 影のぼかし具合
                offset: Offset(10, 10), // 影の位置
              ),
            ],
          ),
        ),
        // RankDistributionChartを重ねる
        if (rankCheckFinish && rankView)
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 60), // 上部スペース
                    RankDistributionChart(
                      rankData: rankList,
                      myRank: rank,
                      screenHeight: screenHeight,
                    ),
                  ],
                ),
              ),
            ),
          ),

        Positioned(
          top: screenHeight * 0.05,
          right: screenWidth * 0.06,
          child:
          SvgPicture.asset(
            'Images/$rank.svg',
            width: screenWidth * 0.2,
          )
        ),
      ],
    );
  }
}

void main() {
  runApp(UpdateNotificationApp());
}

class UpdateNotificationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Update Notification'),
        ),
        body: Center(
          child: UpdateNotificationCard(),
        ),
      ),
    );
  }
}

class UpdateNotificationCard extends StatelessWidget {
  final Uri _url = Platform.isIOS
    ? Uri.parse('https://apps.apple.com/jp/app/%E5%BF%83%E6%8B%B3%E3%82%AA%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%B3-%E8%B6%85%E9%AB%98%E5%BA%A6%E5%BF%83%E7%90%86%E6%88%A6%E3%82%AA%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%B3%E3%81%98%E3%82%83%E3%82%93%E3%81%91%E3%82%93/id6740071891')
    : Uri.parse('https://play.google.com/store/apps/details?id=com.shinken.flutter_shinkenOnline&pcampaignid=web_share');

  Future<void> _launchUrl() async {
    try {
        await launchUrl(_url);
    } catch (e) {
      print("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.blueAccent,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.update,
            size: 48.0,
            color: Colors.blueAccent,
          ),
          SizedBox(height: 16.0),
          Text(
            'アップデートがあります',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'ストアから更新してください',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 16.0),
          ElevatedButton.icon(
            onPressed: () {_launchUrl();},
            icon: Icon(Icons.open_in_new),
            label: Text('ストアを開く'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}













