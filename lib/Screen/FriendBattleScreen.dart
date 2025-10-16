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
import 'dart:math';


class FriendBattleScreen extends StatefulWidget {
  @override
  _FriendBattleScreenState createState() => _FriendBattleScreenState();
}
class _FriendBattleScreenState extends State<FriendBattleScreen> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool waitBattle = false;
  bool keyboardView = false;
  BannerAd? _bannerAd;
  String myFriendId = '';
  String friendBattleMode = 'friendStrategy';
  String roomPassword = '';

  final List<String> keyboardCharacters = [
    // 五十音
    'あ', 'い', 'う', 'え', 'お',
    'か', 'き', 'く', 'け', 'こ',
    'さ', 'し', 'す', 'せ', 'そ',
    'た', 'ち', 'つ', 'て', 'と',
    'な', 'に', 'ぬ', 'ね', 'の',
    'は', 'ひ', 'ふ', 'へ', 'ほ',
    'ま', 'み', 'む', 'め', 'も',
    'や', 'ゆ', 'よ', '', '',
    'ら', 'り', 'る', 'れ', 'ろ',
    'わ', 'を', 'ん','', '',
    // 濁音
    '', '','', '','',
    'が', 'ぎ', 'ぐ', 'げ', 'ご',
    'ざ', 'じ', 'ず', 'ぜ', 'ぞ',
    'だ', 'ぢ', 'づ', 'で', 'ど',
    'ば', 'び', 'ぶ', 'べ', 'ぼ',
    'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ',
    // 小さい文字 & 長音
    '', '','', '','',
    'ゃ', 'ゅ', 'ょ', 'っ', 'ー',
    'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ',
  ];

  void addCharacter(String char) {
    setState(() {
      roomPassword += char;
    });
  }

  // 文字を削除
  void removeCharacter() {
    setState(() {
      if (roomPassword.isNotEmpty) {
        roomPassword = roomPassword.substring(0, roomPassword.length - 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    battleRoomType = friendBattleMode;
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
  @override
  void dispose() {
    super.dispose();
  }

Future<void> checkAndResetBattleRoom() async {
  setState(() {
    battleRoomName = roomPassword;
  });
  print(battleRoomType);
  final roomRef = FirebaseFirestore.instance.collection(battleRoomType).doc(battleRoomName);

  try {
    // ドキュメントを取得
    DocumentSnapshot document = await roomRef.get();

    if (!document.exists) {
      print("ドキュメントが存在しません");
      joinRoom((result) {
        int num = result['num'] as int;
        battlePlayerNumber = num;
        print('$battleRoomName, $battlePlayerNumber, $battleRoomType');
        context.go('/battle');
      });
      return;
    }

    // timeフィールドを取得
    int? timeField = document.get('time') as int?;
    if (timeField == null) {
      print("timeフィールドが存在しません");
      return;
    }
    if (timeField == 0) {
      joinRoom((result) {
        int num = result['num'] as int;
        battlePlayerNumber = num;
        print('$battleRoomName, $battlePlayerNumber, $battleRoomType');
        context.go('/battle');
      });
      return;
    }

    // 現在時刻を取得
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    // 24時間経過しているか判定
    if ((currentTime - timeField) >= 24 * 60 * 60 * 1000) {
      // SharedPreferencesのインスタンスを取得
      final prefs = await SharedPreferences.getInstance();
      final myName = prefs.getString('myName') ?? '';
      final skillRandomStringList = prefs.getStringList('RandomSkillNoList') ?? ['No1'];

      // Firestoreトランザクションでデータを更新
      await FirebaseFirestore.instance.runTransaction((transaction) async {
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
          'skillList1': (battleRoomType == 'friendStrategy')
              ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10'])
              : skillRandomStringList,
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
      });

      joinRoom((result) {
        int num = result['num'] as int;
        battlePlayerNumber = num;
        print('$battleRoomName, $battlePlayerNumber, $battleRoomType');
        context.go('/battle');
      });

      print("ドキュメントが24時間以上経過していたため更新されました");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('誰かが使用中の合言葉です'),
          duration: Duration(seconds: 2),
        ),
      );
      print("まだ24時間経過していません");
    }
  } catch (e) {
    print("エラーが発生しました: $e");
  }
}

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
    try {
        final DocumentReference roomRef = db.collection(battleRoomType).doc(battleRoomName);
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
                'skillList1': (battleRoomType == 'friendStrategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
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
              return {'roomName': battleRoomName, 'num': 1}; // 初期化してnum1に入室
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
                'skillList1':  (battleRoomType == 'friendStrategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
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
                return {'roomName': battleRoomName, 'num': 1};
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
                'skillList2':  (battleRoomType == 'friendStrategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
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
                return {'roomName': battleRoomName, 'num': 2};
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
                'skillList1': (battleRoomType == 'friendStrategy') ? (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']) : skillRandomStringList,
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
              return {'roomName': battleRoomName, 'num': 1}; // num1が1の状態で部屋に入室
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
      throw Exception('No vacant room found');
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        rethrow; // 最大リトライ回数に達したらエラーをスロー
      }
      await Future.delayed(Duration(seconds: 3)); // 待機時間
    }
}

  _loadPreferences() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myFriendId = prefs.getString('myFriendId') ?? 'アカウントを作成してください';
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
      body:
      Stack (

        children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    Text('友達と対戦', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),), // タイトルを追加
                  ]
                ),
                Spacer(),
                Text('↓ゲームモードを選択してください', style: TextStyle(fontFamily: 'makinas4', fontSize: 17),),
                DropdownButton<String>(
                  value: friendBattleMode,
                  style: TextStyle( fontSize: 32, color: Colors.black, fontFamily: 'makinas4'),
                  items: const [
                    DropdownMenuItem(
                      value: 'friendStrategy',
                      child: Text('戦略バトル'),
                    ),
                    DropdownMenuItem(
                      value: 'friendRandom',
                      child: Text('ランダムバトル',),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      friendBattleMode = newValue!;
                      battleRoomType = newValue!;
                    });
                  },
                  iconSize: 40,
                ),
                if (battleRoomType == 'friendStrategy')
                Text('自分の選んだ１０のスキルでバトル！', style: TextStyle(fontFamily: 'makinas4', fontSize: 17),),
                if (battleRoomType == 'friendRandom')
                Text('ランダムで選ばれる１０のスキルでバトル！', style: TextStyle(fontFamily: 'makinas4', fontSize: 17),),
                SizedBox(height: 20,),
                Text('合言葉', style: TextStyle(fontFamily: 'makinas4', fontSize: 30),),

                GestureDetector(
            onTap: () {
              setState(() {
                keyboardView = true; // タップするとキーボードを表示
              });
            },
            child: Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), // 枠線
                borderRadius: BorderRadius.circular(8), // 角丸
                color: Colors.white, // 背景色
              ),
              child: Text(
                roomPassword.isEmpty ? 'ここに合言葉を入力' : roomPassword,
                style: TextStyle(
                  fontSize: 24,
                  color: roomPassword.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: 'makinas4'
                ),
              ),
            ),
          ),


                Text('※ゲームモードと合言葉は\n両方揃えないと戦えません！', style: TextStyle(fontFamily: 'makinas4', fontSize: 15),),
                if (roomPassword != '')
                CustomImageButton(screenWidth: screenWidth, buttonText: '決定！！', onPressed: checkAndResetBattleRoom),
                // SizedBox(height: 20,),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Text('自分のフレンドコード', style: TextStyle(fontFamily: 'makinas4'),),
                //     CopyableText(myFriendId),
                //   ],
                // ),
                // Text('タップでコピーできます。↑', style: TextStyle(fontFamily: 'makinas4'),),

                // Text(
                //   '次回アプデで\nフレンド機能追加予定',
                //   style: TextStyle(
                //     fontFamily: 'makinas4',
                //     fontSize: 20,
                //     fontWeight: FontWeight.bold,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                Spacer()
              ],
            ),

            if (keyboardView)
            Align(
              alignment: Alignment.center,
            child:
            Container(height: screenHeight * 0.6,
            decoration: BoxDecoration(
              color:const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
            Column(
              children: [
                SizedBox(height: 30,),
                Text('合言葉', style: TextStyle(fontSize: 35, fontFamily: 'makinas4')),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(roomPassword, style: TextStyle(fontSize: 24, fontFamily: 'makinas4')),
                  ),
                ),
                // キーボードレイアウト
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // 5列で表示
                      childAspectRatio: 1.5,
                    ),
                    itemCount: keyboardCharacters.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (keyboardCharacters[index] != '') {
                            addCharacter(keyboardCharacters[index]);
                          }
                        },
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: keyboardCharacters[index] != '' ? Color.fromARGB(255, 186, 219, 246) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              keyboardCharacters[index],
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'makinas4'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 削除ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageButton(screenWidth: screenWidth, buttonText: '1文字削除', onPressed: removeCharacter),
                    CustomImageButton(screenWidth: screenWidth, buttonText: '閉じる', onPressed: (){setState(() {
                      keyboardView = false;
                    });}),

                  ],
                )
              ],
            )
          )
            )
        ]
      )
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

