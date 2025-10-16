import 'package:flutter/material.dart';
import '../main.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:math';

class OnlineBattleScreen extends StatefulWidget {
  @override
  _OnlineBattleScreenState createState() => _OnlineBattleScreenState();
}
class _OnlineBattleScreenState extends State<OnlineBattleScreen> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  String collectionName = ''; // 部屋が保存されるコレクション
  bool waitBattle = false;

  BannerAd? _bannerAd;

  Future<void> joinRoom(Function(Map<String, dynamic>) onRoomJoined) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //ランダムバトルよう関数
    List<int> intList = List.generate(50, (index) => index + 1);
    intList.shuffle(Random());
    List<int> top10Numbers = intList.take(10).toList();
    List<String> skillRandomStringList = top10Numbers.map((number) => 'No$number').toList();
    prefs.setStringList('RandomSkillNoList', skillRandomStringList);

    //ここまでがランダムバトル用関数　


  const int maxRetries = 3; // 最大リトライ回数
  int retryCount = 0;
  bool successState = false;

  bool isInRoom = false;
  isInRoom = prefs.getBool('isInRoom') ?? false;
  String myName = prefs.getString('myName') ?? '名前はまだ無い';
  if (isInRoom) {
    throw Exception('You are already in a room');
  }
  while (retryCount < maxRetries && !successState && !isInRoom) {
    try {
      final String roomTime = _getRoomTime();
      final List<int> roomNumbers = List.generate(1000, (index) => index + 1);
      for (final int n in roomNumbers) {
        final String roomName = 'room$roomTime$n';
        final DocumentReference roomRef = db.collection(collectionName).doc(roomName);
        // トランザクションの実行
        final result = await db.runTransaction((transaction) async {
          try {
            // トランザクション内で非同期操作を行う
            final roomDoc = await transaction.get(roomRef);
            if (roomDoc.exists) {
              // 既存の部屋の処理
              final data = roomDoc.data() as Map<String, dynamic>;

              if ((data['name1'] == myName || data['name2'] == myName) &&
                data['battleState'] == false &&
                !successState &&
                !isInRoom) {
              // 部屋を初期化
              transaction.update(roomRef, {
                'battleState': false,
                'battleCount1': prefs.getInt('myBattleCount'),
                'battleCount2': 0,
                'comment1': '',
                'comment2': '',
                'openCard1_1': '',
                'openCard1_2': '',
                'openCard2_1': '',
                'openCard2_2': '',
                'decide1': false,
                'decide2': false,
                'declarePoint1': 20,
                'declarePoint2': 20,
                'declareHand1': 'rock',
                'declareHand2': 'rock',
                'giveUp1': false,
                'giveUp2': false,
                'battleSkillNo1': 'No1',
                'battleSkillNo2': 'No1',
                'battleHand1': 'scissor',
                'battleHand2': 'scissor',
                'icon1': prefs.getStringList('myIcon') ?? [],
                'icon2': [],
                'name1': myName,
                'name2': '',
                'num1': 1,
                'num2': 0,
                'point1': 150,
                'point2': 150,
                'reStartState': false,
                'skillList1': (collectionName == 'strategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
                'skillList2': '',
                'skillParameter1': '',
                'skillParameter2': '',
                'rank1': prefs.getString('myRank') ?? 'champion1',
                'rank2': 'bronze1',
                'time': 0,
                'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
                'uid2': '',
                'winCount1': prefs.getInt('myWinCount') ?? 0,
                'winCount2': 0,
                'winStreak1': prefs.getInt('myWinStreak') ?? 0,
                'winStreak2': 0,
                'rockCount1': prefs.getInt('myRockCount') ?? 0,
                'rockCount2': 0,
                'scissorCount1': prefs.getInt('myScissorCount') ?? 0,
                'scissorCount2': 0,
                'paperCount1': prefs.getInt('myPaperCount') ?? 0,
                'paperCount2': 0,
                'honestCount1': prefs.getInt('myHonestCount') ?? 0,
                'honestCount2': 0,
              });
              return {'roomName': roomName, 'num': 1}; // 初期化してnum1に入室
            }
              // num1が空いている場合
              if (data['num1'] == 0 && data['battleState'] == false && !successState && !isInRoom) {
                transaction.update(roomRef, {
                'battleState': false,
                'battleCount1': prefs.getInt('myBattleCount'),
                'comment1': '',
                'openCard1_1': '',
                'openCard1_2': '',
                'decide1': false,
                'declarePoint1': 20,
                'declareHand1': 'rock',
                'giveUp1': false,
                'battleSkillNo1': 'No1',
                'battleHand1': 'scissor',
                'icon1': prefs.getStringList('myIcon') ?? [],
                'name1': prefs.getString('myName') ?? '名前はまだ無い',
                'num1': 1,
                'point1': 150,
                'reStartState': false,
                'skillList1':  (collectionName == 'strategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
                'skillParameter1': '',
                'rank1': prefs.getString('myRank') ?? 'champion1',
                'time': 0,
                'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
                'winCount1': prefs.getInt('myWinCount') ?? 0,
                'winStreak1': prefs.getInt('myWinStreak') ?? 0,
                'rockCount1': prefs.getInt('myRockCount') ?? 0,
                'scissorCount1': prefs.getInt('myScissorCount') ?? 0,
                'paperCount1': prefs.getInt('myPaperCount') ?? 0,
                'honestCount1': prefs.getInt('myHonestCount') ?? 0,
                });
                return {'roomName': roomName, 'num': 1};
              }
              // num2が空いている場合
              else if (data['num1'] == 1 && data['num2'] == 0 && data['battleState'] == false && !successState && !isInRoom) {
                transaction.update(roomRef, {
                'battleState': false,
                'battleCount2': prefs.getInt('myBattleCount'),
                'comment2': '',
                'openCard2_1': '',
                'openCard2_2': '',
                'decide2': false,
                'declarePoint2': 20,
                'declareHand2': 'rock',
                'giveUp2': false,
                'battleSkillNo1': 'No1',
                'battleHand1': 'scissor',
                'name2': prefs.getString('myName') ?? '名前はまだ無い',
                'icon2': prefs.getStringList('myIcon') ?? [],
                'num2': 1,
                'point2': 150,
                'reStartState': false,
                'skillList2':  (collectionName == 'strategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
                'skillParameter2': '',
                'rank2': prefs.getString('myRank') ?? 'champion2',
                'time': DateTime.now().millisecondsSinceEpoch + 10000,
                'uid2': FirebaseAuth.instance.currentUser?.uid ?? '',
                'winCount2': prefs.getInt('myWinCount') ?? 0,
                'winStreak2': prefs.getInt('myWinStreak') ?? 0,
                'rockCount2': prefs.getInt('myRockCount') ?? 0,
                'scissorCount2': prefs.getInt('myScissorCount') ?? 0,
                'paperCount2': prefs.getInt('myPaperCount') ?? 0,
                'honestCount2': prefs.getInt('myHonestCount') ?? 0,
                });
                return {'roomName': roomName, 'num': 2};
              }
            } else if (!successState && !isInRoom) {
              // 部屋が存在しない場合は新しい部屋を作成して入室
              transaction.set(roomRef, {
                'battleState': false,
                'battleCount1': prefs.getInt('myBattleCount'),
                'battleCount2': 0,
                'comment1': '',
                'comment2': '',
                'openCard1_1': '',
                'openCard1_2': '',
                'openCard2_1': '',
                'openCard2_2': '',
                'decide1': false,
                'decide2': false,
                'declarePoint1': 20,
                'declarePoint2': 20,
                'declareHand1': 'rock',
                'declareHand2': 'rock',
                'giveUp1': false,
                'giveUp2': false,
                'battleSkillNo1': 'No1',
                'battleSkillNo2': 'No1',
                'battleHand1': 'scissor',
                'battleHand2': 'scissor',
                'icon1': prefs.getStringList('myIcon') ?? [],
                'icon2': [],
                'name1': prefs.getString('myName') ?? '名前はまだ無い',
                'name2': '',
                'num1': 1,
                'num2': 0,
                'point1': 150,
                'point2': 150,
                'reStartState': false,
                'skillList1': (collectionName == 'strategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
                'skillList2': '',
                'skillParameter1': '',
                'skillParameter2': '',
                'rank1': prefs.getString('myRank') ?? 'champion1',
                'rank2': 'bronze1',
                'time': 0,
                'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
                'uid2': '',
                'winCount1': prefs.getInt('myWinCount') ?? 0,
                'winCount2': 0,
                'winStreak1': prefs.getInt('myWinStreak') ?? 0,
                'winStreak2': 0,
                'rockCount1': prefs.getInt('myRockCount') ?? 0,
                'rockCount2': 0,
                'scissorCount1': prefs.getInt('myScissorCount') ?? 0,
                'scissorCount2': 0,
                'paperCount1': prefs.getInt('myPaperCount') ?? 0,
                'paperCount2': 0,
                'honestCount1': prefs.getInt('myHonestCount') ?? 0,
                'honestCount2': 0,
                'favoriteSkillNo1':  prefs.getString('myFavoriteSkillNo') ?? 'No48',
                'favoriteSkillNo2': 'No1',
                'favoriteSkillName1': prefs.getString('myFavoriteSkillName') ?? '盗人の極意',
                'favoriteSkillName2': '硬い拳',
              });
              return {'roomName': roomName, 'num': 1}; // num1が1の状態で部屋に入室
            }
          } catch (error) {
            print('Failed to get room document: $error');
            rethrow; // エラーが発生した場合に再スロー
          }
          return null; // それ以外の場合はnull
        });
        if (result != null) {
          successState = true;
          onRoomJoined(result); // 部屋に入室した後にコールバックを呼び出す
          return;
        }
      }
      throw Exception('No vacant room found');
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        rethrow; // 最大リトライ回数に達したらエラーをスロー
      }
      await Future.delayed(Duration(seconds: 3)); // 待機時間
    }
  }
  throw Exception('Failed to join or create a room after retries');
}

// Future<void> joinRoom(Function(Map<String, dynamic>) onRoomJoined) async {
//   const int maxRetries = 3; // 最大リトライ回数
//   int retryCount = 0;
//   bool successState = false;
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   bool isInRoom = prefs.getBool('isInRoom') ?? false;
//   String myName = prefs.getString('myName') ?? '名前はまだ無い';

//   if (isInRoom) {
//     throw Exception('You are already in a room');
//   }

//   while (retryCount < maxRetries && !successState && !isInRoom) {
//     try {
//       final String roomTime = _getRoomTime();
//       final List<int> roomNumbers = List.generate(1000, (index) => index + 1);

//       for (final int n in roomNumbers) {
//         final String roomName = 'room$roomTime$n';
//         final DocumentReference roomRef = db.collection(collectionName).doc(roomName);

//         // トランザクションの実行
//         final result = await db.runTransaction((transaction) async {
//           final roomDoc = await transaction.get(roomRef);

//           if (roomDoc.exists) {
//             final data = roomDoc.data() as Map<String, dynamic>;

//             // 自分の名前が既存の部屋に含まれている場合
//             if ((data['name1'] == myName || data['name2'] == myName) &&
//                 data['battleState'] == false &&
//                 !successState &&
//                 !isInRoom) {
//               // 部屋を初期化
//               transaction.update(roomRef, {
//                 'battleState': false,
//                 'battleCount1': prefs.getInt('myBattleCount'),
//                 'battleCount2': 0,
//                 'comment1': '',
//                 'comment2': '',
//                 'openCard1_1': '',
//                 'openCard1_2': '',
//                 'openCard2_1': '',
//                 'openCard2_2': '',
//                 'decide1': false,
//                 'decide2': false,
//                 'declarePoint1': 20,
//                 'declarePoint2': 20,
//                 'declareHand1': 'rock',
//                 'declareHand2': 'rock',
//                 'giveUp1': false,
//                 'giveUp2': false,
//                 'battleSkillNo1': 'No1',
//                 'battleSkillNo2': 'No1',
//                 'battleHand1': 'scissor',
//                 'battleHand2': 'scissor',
//                 'name1': myName,
//                 'name2': '',
//                 'num1': 1,
//                 'num2': 0,
//                 'point1': 150,
//                 'point2': 150,
//                 'reStartState': false,
//                 'skillList1': prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10'],
//                 'skillList2': '',
//                 'skillParameter1': '',
//                 'skillParameter2': '',
//                 'rank1': prefs.getString('myRank') ?? 'champion1',
//                 'rank2': 'bronze1',
//                 'time': 0,
//                 'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
//                 'uid2': '',
//                 'winCount1': prefs.getInt('myWinCount') ?? 0,
//                 'winCount2': 0,
//                 'winStreak1': prefs.getInt('myWinStreak') ?? 0,
//                 'winStreak2': 0,
//                 'rockCount1': prefs.getInt('myRockCount') ?? 0,
//                 'rockCount2': 0,
//                 'scissorCount1': prefs.getInt('myScissorCount') ?? 0,
//                 'scissorCount2': 0,
//                 'paperCount1': prefs.getInt('myPaperCount') ?? 0,
//                 'paperCount2': 0,
//                 'honestCount1': prefs.getInt('myHonestCount') ?? 0,
//                 'honestCount2': 0,
//                 'favoriteSkillNo1': prefs.getString('myFavoriteSkillNo') ?? 'No48',
//                 'favoriteSkillNo2': 'No1',
//                 'favoriteSkillName1': prefs.getString('myFavoriteSkillName') ?? '盗人の極意',
//                 'favoriteSkillName2': '硬い拳',
//               });
//               return {'roomName': roomName, 'num': 1}; // 初期化してnum1に入室
//             }

//             // num1が空いている場合
//             if (data['num1'] == 0 && data['battleState'] == false && !successState && !isInRoom) {
//               transaction.update(roomRef, {
//                 'name1': myName,
//                 'num1': 1,
//                 'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
//               });
//               return {'roomName': roomName, 'num': 1};
//             }

//             // num2が空いている場合
//             if (data['num1'] == 1 && data['num2'] == 0 && data['battleState'] == false && !successState && !isInRoom) {
//               transaction.update(roomRef, {
//                 'name2': myName,
//                 'num2': 1,
//                 'uid2': FirebaseAuth.instance.currentUser?.uid ?? '',
//               });
//               return {'roomName': roomName, 'num': 2};
//             }
//           } else if (!successState && !isInRoom) {
//             // 部屋が存在しない場合は新しい部屋を作成して入室
//             transaction.set(roomRef, {
//               'name1': myName,
//               'num1': 1,
//               'uid1': FirebaseAuth.instance.currentUser?.uid ?? '',
//               'battleState': false,
//               // 必要な初期値を追加
//             });
//             return {'roomName': roomName, 'num': 1};
//           }
//           return null;
//         });

//         if (result != null) {
//           successState = true;
//           onRoomJoined(result);
//           return;
//         }
//       }

//       throw Exception('No vacant room found');
//     } catch (e) {
//       retryCount++;
//       if (retryCount >= maxRetries) {
//         rethrow;
//       }
//       await Future.delayed(Duration(seconds: 3));
//     }
//   }

//   throw Exception('Failed to join or create a room after retries');
// }


  String _getRoomTime() {
    final int minutes = DateTime.now().minute;

    if (minutes <= 14) return 'a';
    if (minutes <= 29) return 'b';
    if (minutes <= 44) return 'c';
    return 'd';
  }

  @override
  void initState() {
    super.initState(); // アプリ起動時にカウントを読み込む
    _loadRoutePass('/onlineBattle');
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

  _changeRoutePass() {
      context.go('/menu');
    }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width; // ボタンの幅
    final double screenHeight = screenSize.height;  // ボタンの高さ




    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: screenWidth,
                  height: 50,
                  child: SizedBox(),
                ),
              ),
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
                  SizedBox(width: screenWidth* 0.75,)
                ],
              ),
              Spacer(),
              if (!waitBattle)
              RealStrategyBattleButton(buttonWidth: screenWidth * 0.8, buttonHeight:screenHeight * 0.1,
              onPressed: () {
                setState(() {
                  waitBattle = true;
                  collectionName = 'strategy';
                });

                joinRoom((result) {
                  String roomName = result['roomName'] as String;
                  int num = result['num'] as int;
                  battleRoomName = roomName;
                  battlePlayerNumber = num;
                  battleRoomType = 'strategy';
                  print('Joined room: $roomName, num: $num');
                  print('$battleRoomName, $battlePlayerNumber, $battleRoomType');
                  context.go('/battle');
                });
              },
              ),
              if (!waitBattle)
              Text('自分で選んだ10のスキルでバトル！', style: TextStyle(fontFamily: 'makinas4'),),
              if (!waitBattle)
              SizedBox(height: 30,),
              if (!waitBattle)
              RealRandomBattleButton(buttonWidth: screenWidth * 0.8, buttonHeight:screenHeight * 0.1,
              onPressed: () {
                setState(() {
                  waitBattle = true;
                  collectionName = 'random';
                });

                joinRoom((result) {
                  String roomName = result['roomName'] as String;
                  int num = result['num'] as int;
                  battleRoomName = roomName;
                  battlePlayerNumber = num;
                  battleRoomType = 'random';
                  print('Joined room: $roomName, num: $num');
                  print('$battleRoomName, $battlePlayerNumber, $battleRoomType');
                  context.go('/battle');
                });
              },
              ),
              if (!waitBattle)
              Text('ランダムで選ばれる10のスキルでバトル！', style: TextStyle(fontFamily: 'makinas4'),),

              if (waitBattle)
              WaveText(text: '部屋検索中...'),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class RealBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  RealBattleButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.go('/realSpeedBattle');
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
            'RealBattle',
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'Rounded', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class FakeBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;

  FakeBattleButton({required this.buttonWidth, required this.buttonHeight});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.go('/fakeSpeedBattle');
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
            'FakeBattle',
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'Rounded', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class RealStrategyBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;
  final VoidCallback onPressed; // コールバック関数を追加

  RealStrategyBattleButton({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.onPressed, // コールバック関数を受け取る
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // 引数で受け取ったコールバックを使用
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
            Icons.flag, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            '戦略バトル',
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
      ),
    );
  }
}

class RealRandomBattleButton extends StatelessWidget {
  final double buttonWidth;
  final double buttonHeight;
  final VoidCallback onPressed; // コールバック関数を追加

  RealRandomBattleButton({
    required this.buttonWidth,
    required this.buttonHeight,
    required this.onPressed, // コールバック関数を受け取る
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // 引数で受け取ったコールバックを使用
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
            Icons.flag, // Flutterのアイコンに変更
            size: 24,
          ),
          SizedBox(width: 8), // アイコンとテキストの間のスペース
          Text(
            'ランダムバトル',
            style: TextStyle(
              fontSize: 24, // テキストサイズ
              fontFamily: 'makinas4', // フォントのスタイル（Roundedはデフォルトにはない）
            ),
          ),
        ],
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


