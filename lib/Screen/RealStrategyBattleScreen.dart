import 'package:flutter/material.dart';
import 'dart:async';
import '../main.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';


class RealStrategyBattleScreen extends StatefulWidget {
  @override
  _RealStrategyBattleScreenState createState() => _RealStrategyBattleScreenState();
}

class _RealStrategyBattleScreenState extends State<RealStrategyBattleScreen>  with SingleTickerProviderStateMixin {
  final List<GlobalKey<_FlipCardState>> flipCardKeys = List.generate(
    4,
    (_) => GlobalKey<_FlipCardState>(),
  );
  final GlobalKey<_CircularCountdownTimerState> circularTimerKey =GlobalKey<_CircularCountdownTimerState>();


  BannerAd? _bannerAd;

  List<String> angryComments = ['GG!', '本気出すわ！', '頑張れ！', '次は勝つ！','まだ勝てる！', 'チキショー！', 'りんかーん！？'];
  List<String> happyComments = ['よろしく！', 'ういっすー', '久しぶり！', 'ありがとう！', 'ナイスプレイ！', 'またいつか！',];
  List<String> coolComments = ['作戦通りですね', 'ふ、ふん、、', 'どうですか？', 'それはまずい', '私は強いです。', '人民の', '人民による', '人民のための',];
  List<String> thinkComments = ['何出そう', 'これは夢？', '強すぎ...', 'この程度か、'];
  List<String> chickenComments= ['ヤバいかも', '大丈夫？', '天才？', 'チート？','もう無理だ', ];
  List<String> hakuryokuComments = ['否', '!?', '命', '生', '戯'];
  List<String> myCommentList = [];

  //アイコン用
  int gridNumber = 32;
  List<List<String>> myIcon = [];
  List<List<String>> enemyIcon = [];
  bool myIconLoad = true;

  // カードデータ
  List<Map<String, String>> myCards = [];// ここでListのデータが終了
  String mySkillNoListPref = 'No1, No2, No3, No4, No5, No6, No7, No8, No9,No10';
  List<String> enemySkillNoList = [];
  String enemySkillNoListPref = 'No1, No2, No3, No4, No5, No6, No7, No8, No9,No10';
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

  List<String> optionSkilNoList = ['No22', 'No27', 'No40'];

  List<String> enemyNames= [
    'yuu10221', 'よろしく大臣', 'まんまみーや', '猫ちゅう', 'ゴングK', 'ゆうりんち', 'ちょんま', 'カミ子', 'ハニカミ君',
    'たこ焼きマスター', '忍者スナック', 'おにぎりファイター', 'たぬき侍', 'サムライピザ',
    'ミスターシャカシャカ', 'ドーナツキング', 'ピンクパンダ', 'バナナボンバー', 'スシサムライ',
    'おばけカレー', 'ハッピーうさぎ', 'たまごプリンス', 'わらびもちヒーロー', 'サクラドラゴン',
    'カラオケキング', 'たこ焼きプリンセス', 'うさぎ忍者', 'ピーチ侍', 'おにぎりクイーン',
    'ももたろうウォリアー', 'パンダパラダイス', 'バンブーソルジャー', 'メロンマスター', 'お茶サムライ',
    'さくらもちプリンス', 'すしドラゴン', 'みたらしヒーロー', 'さくらもちプリンセス', 'カラオケプリンス',
    'ハッピーたぬき', 'ドーナツ侍', 'パンケーキプリンセス', 'バナナウォリアー', 'シャカシャカファイタ',
    'たこ焼きドラゴン', 'ピザプリンス', 'メロンキング', 'おばけクイーン', 'たまごヒーロー',
    'わらびもちドラゴン', 'カラオケクイーン', 'すしプリンス', 'ピーチプリンセス', 'ももたろうドラゴン',
    'ハッピーサムライ', 'お茶ウォリアー', 'さくらもちキング', 'みたらしファイター', 'パンケーキキング','かおる', 'ひまり', 'めい', 'ひなた', 'いちか', 'ねね', 'ののか', 'りんか', 'いろは', 'ここあ', 'なごみ',
    'ルナ', 'クレア', 'シャルロッテ', 'ライリー', 'ヴィクトリア', 'グローリア', 'エリナ', 'エリザベス', 'アリア', 'セレナーデ', 'アカネ', 'ナナ',
    '美夜', '杏華', '神楽', '雫', '和虹', '萌音', '雪', '杏樹',
    'Iris', 'Cocoa', 'Karina', 'Aira', 'Aria', 'Luli', 'Lisa', 'Sue',
    '杏', 'ここな', '萌歌', 'マロン', 'アイス', 'マシュマロ',
    'うさみ', 'ラビ', 'ひな', 'ひばり', 'すずめ', 'ねこ', 'たぬ',
    '本能寺が変', '攻撃しないで', 'ChrisBacon', '釈迦釈迦ポテト','一休さんぽ', 'カメレオンとうちゃん', 'ウサギリリック', 'シカトレーサー', 'タコにアウタコ',
    'ネコネコニャンパイア', 'サカナクションマン', 'パンダフルデイ', 'モグラのモグモグ', 'スイカピーチ',
    'ワニスケート', 'カエルピョン吉', 'イヌッコロッケ', 'カバばかり', 'トラフルート',
    'ライオンオルゴール', 'ペンギンリング', 'ハシビロハッピー', 'フクロウライト', 'キツネリゾット',
    'カラスウィング', 'ヒヨコファイア', 'ダルマイヌ', 'タヌキック', 'イタチパレード',
    'フグポップ', 'カピバラメモリー', 'カメライダー', 'ゴリラダンス', 'リスリズム',
    'ハムスターサークル', 'ゾウタップ', 'シロクマスター', 'コアラニウム', 'サルサドッグ',
    'イルカラップ', 'タカトンネル', 'クジラスクール', 'アザラシズム', 'キリンディッシュ',
    'シマウマスター', 'カバーチャート', 'トリケラトップ', 'ウマサンバ', 'ラッコバンド',
    'ネズミクイズ', 'タテガミック', 'コウモリーノ', 'アリスコープ', 'ヒトデライト','山', '❤️', 'クマ', 'アヤ', 'なぁみ', 'けんけん', 'にんにん', '頓着', '祇園', '春はあけぼの',
    '嬢', 'やました', '割下', 'カルマ', '業の深さ', 'とっく', '玉ねぎ', 'ハロウ警報', '聖夜には何もするな', '長州の力', '青木豪鬼', '近所の兄さん', '眠い君', '抜け殻', '鳩さぶれ', '土鍋ごはん', 'あなたに捧げる愛',
    '戦艦ハルバール', '偏見の形', 'ギフトフォーユー', '細胞外小胞', 'ガーリック炒飯', '反撃タイム', 'ソクラテス', '二律背反', '運命から逃げるな', '人は人を見る', '小林まこん', '社畜女子', 'ビールで大優勝',
    'グーでかつよ', 'チョキが一番強くね', 'いやグーだろ', 'そこはパー出せよ', 'そこそこ強い', 'ダルビッシュ',
  ];

  Completer<void>? _completer;

  //敵、自分のプレイヤー情報

  String myRank = 'champion3';
  String myRankJapan = 'チャンプ3';
  int myRankCount = 0;
  int myLevel = 1;
  int myLevelExp = 0;
  String myName = 'アイウエオかきくけこ';
  int myWinStreak = 0;
  double myHonestRate = 0.0;
  double myWinRate = 0.0;
  double myRockRate = 0.0;
  double myScissorRate = 0.0;
  double myPaperRate = 0.0;
  bool myInfoView = false;
  bool myRetireView = false;
  bool mySkipState = false;
  String myComment = '';

  String enemyRank = 'bronze1';
  String enemyRankJapan = '';
  String enemyName = 'enemy';
  int enemyWinStreak = 0;
  double enemyHonestRate = 0.0;
  double enemyWinRate = 0.0;
  double enemyRockRate = 0.0;
  double enemyScissorRate = 0.0;
  double enemyPaperRate = 0.0;
  bool enemyInfoView = false;
  bool enemySkipState = false;
  bool enemyBattleState = true;
  String enemyComment = '';

  //変数

  Timer? _sceneTimer;

  bool optionButton = false;
  bool isSceneChangeActive = true;
  bool myRetireState = false;
  bool enemyRetireState = false;
  bool saveBattleState = false;

  int myDeclarePoint = 20;
  int enemyDeclarePoint = 20;
  int currentRound = 0;
  int sceneTimer = 3;
  int noneSelectInt = 0;

  int winPoint = 200;
  int startPoint = 100;
  int myPoint = 100;
  int enemyPoint = 100;
  int previousMyPoint = 100;
  int previousEnemyPoint = 100;
  int myChangePoint = 0;
  int enemyChangePoint = 0;
  int myChangeMySkill = 0;
  int myChangeEnemySkill = 0;
  int enemyChangeMySkill = 0;
  int enemyChangeEnemySkill = 0;
  bool myChangePointView = false;
  bool enemyChangePointView =  false;
  bool myChangeMySkillView = false;
  bool myChangeEnemySkillView = false;
  bool enemyChangeMySkillView = false;
  bool enemyChangeEnemySkillView = false;
  bool mySkillOptionView = false;

//バトル、スキル関連の変数
  String myDeclareHand = 'rock';
  String enemyDeclareHand = 'rock';
  String myBattleHand = 'scissor';
  String enemyBattleHand = 'scissor';
  String myBattleSkillNo = 'No1';
  String enemyBattleSkillNo = 'No1';
  String handResult = 'draw';
  String mySkillSelect = '';  //optionありのスキルのための変数
  String enemySkillSelect = ''; //optionありのスキルのための変数
  String mySkillRandom = ''; //ランダムスキルのための変数
  String enemySkillRandom = ''; //ランダムスキルのための変数
  String mySkillLog = '';
  String enemySkillLog = '';
  String battleResult = 'win';

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

//リアクション変数
  bool commentListView = false;
  double _topPosition = -500; // 初期位置（画面外）
  double _bottomPosition = -500; // 初期位置（画面外）
  bool _isCommented = false; // アニメーションの状態を管理
  bool _isEnemyCommented = false;

  bool mySkillDetail = false;
  bool enemySkillDetail = false;
  bool myInfoDetail = false;
  bool enemyInfoDetail = false;
  bool battleWait = false;
  bool skillOpenWait = false;
  bool battleOpenWait = false;
  bool declareOpenWait = false;
  bool isSlideViewVisible = false;
  bool skillResultView = false;

  int nowSceneIndex = -1;
  String nowScene = '';

  Future<void> updateFieldsInFirebase({
    required Map<String, dynamic> fieldsToUpdate, // 更新するフィールドとその値
  }) async {
    try {
      // Firebaseのドキュメント参照
      final DocumentReference docRef = FirebaseFirestore.instance.collection(battleRoomType).doc(battleRoomName);

      // Firebaseにデータをアップデート
      await docRef.update(fieldsToUpdate);

      print('Fields updated successfully in Firebase.');
    } catch (e) {
      print('Error updating fields in Firebase: $e');
    }
  }

  Future<dynamic> getFieldFromFirebase({
  required String field,      // 読み取るフィールド名
  }) async {
    try {
      // Firebaseのドキュメント参照
      DocumentReference docRef =
          FirebaseFirestore.instance.collection(battleRoomType).doc(battleRoomName);

      // ドキュメントを取得
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // フィールドの値を取得して返す
        return docSnapshot.get(field);
      } else {
        print('Document does not exist.');
        return null;
      }
    } catch (e) {
      print('Error reading field from Firebase: $e');
      return null;
    }
  }

  @override
  void initState() {

    _loadEnemyInfo(battlePlayerNumber);
    _loadEnemyIcon(battlePlayerNumber);
    _loadMyIcon();
    _loadSkillList();
    _loadMyInfo();
    checkStartTime(context, battleRoomType, battleRoomName, battlePlayerNumber);
    listenToSkipState();
    _arrayCards(myCards);
    _loadRoutePass('/fakeBattle');
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
    Future.delayed(Duration(milliseconds: 3000), () {
      if (enemyCards.isEmpty){
        _loadEnemyInfo(battlePlayerNumber);
      }
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

  void checkStartTime(BuildContext context, String battleRoomType, String battleRoomName, int battlePlayerNumber) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference docRef = db.collection(battleRoomType).doc(battleRoomName);

  try {
    // Firestoreからドキュメントを1回だけ取得
    final documentSnapshot = await docRef.get();

    if (!documentSnapshot.exists) {
      print('checkRoom: Document does not exist: $battleRoomName');
      return;
    }

    final data = documentSnapshot.data() as Map<String, dynamic>;
    final int updateTime = data['time'] as int;

    if (updateTime != null) {
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      final int delayDuration = updateTime - currentTime;

      if (delayDuration > 0) {
        // 指定の時間まで遅延してからシーンを変更
        Future.delayed(Duration(milliseconds: delayDuration), () {
          print('checkRoom: Time reached. Navigating to RealStrategyBattle...');
          sceneChange(scenes[0]['seconds'] as int);
        });
      } else {
        print('checkRoom: Time already reached. Navigating immediately...');
        sceneChange(scenes[0]['seconds'] as int);
      }
    } else {
      print('checkRoom: `time` field is missing or null.');
    }
  } catch (e) {
    print('checkRoom: Error getting document: $e');
  }
}

void _loadEnemyIcon(int battlePlayerNumber) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference roomRef = db.collection(battleRoomType).doc(battleRoomName);
  final String enemyPrefix = (battlePlayerNumber == 1) ? '2' : '1';
  try {
    // Firestoreからバトルルームのデータを取得
    final DocumentSnapshot roomSnapshot = await roomRef.get();
    if (roomSnapshot.exists) {
      final Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;
      if (data.containsKey('icon$enemyPrefix')) {
        // icon フィールドが存在する場合の処理
        setState(() {
          List<String> enemyIconFlat = (data['icon$enemyPrefix'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];
          if (enemyIconFlat.length == gridNumber * gridNumber){
            setState(() {
              enemyIcon = List.generate(gridNumber, (y) {
                return List.generate(gridNumber, (x) {
                  int index = y * gridNumber + x;

                  // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
                  if (index >= 0 && index < enemyIconFlat.length) {
                    return enemyIconFlat[index]; // String を返す
                  } else {
                    return ""; // デフォルト値
                  }
                });
              });
        myIconLoad = false;
      });
          } else {
            _loadTemplateList(false);
          }
        });
      } else {
        _loadTemplateList(false);
      }
    } else {
      print('Room document does not exist.');
      _loadTemplateList(false);
    }
  } catch (error) {
    print('Failed to load enemy info: $error');
    _loadTemplateList(false);
  }
}

void _loadInitialIcon(bool own) async {
    List<int> numbers = [20, 40, 60, 80, 100, 120, 140];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    numbers.shuffle();
    List<int> values = [3, 1, numbers[0]];
    values.shuffle();
    String getRandomColor(int i) {
      int r = values[0] * ((values[0] != 3 && values[0] != 1 )? 1 : i);
      int g = values[1] * ((values[1] != 3 && values[1] != 1 )? 1 : i);
      int b = values[2] * ((values[2] != 3 && values[2] != 1 )? 1 : i);
      return '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
    }

    List<String> gridField = List<String>.generate(
      32 * 32, // 1024要素
      (index) => getRandomColor(index ~/ 32 + 1), // 行番号（1～32）を計算
    );
      setState(() {
        if (own) {
          myIcon = List.generate(gridNumber, (y) {
            return List.generate(gridNumber, (x) {
              int index = y * gridNumber + x;

              // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
              if (index >= 0 && index < gridField.length) {
                return gridField[index]; // String を返す
              } else {
                return ""; // デフォルト値
              }
            });
          });
          prefs.setStringList('myIcon', gridField);
        } else {
          enemyIcon = List.generate(gridNumber, (y) {
            return List.generate(gridNumber, (x) {
              int index = y * gridNumber + x;

              // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
              if (index >= 0 && index < gridField.length) {
                return gridField[index]; // String を返す
              } else {
                return ""; // デフォルト値
              }
            });
          });
        }
      });

    print(enemyIcon);
  }

  Future<void> _loadMyIcon() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allGrids = [];
    allGrids = prefs.getStringList('myIcon') ?? [];

    // すべてのグリッドがロードされたら、状態を更新
    if (allGrids.length == gridNumber * gridNumber) {
      setState(() {
        myIcon = List.generate(gridNumber, (y) {
          return List.generate(gridNumber, (x) {
            int index = y * gridNumber + x;

            // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
            if (index >= 0 && index < allGrids.length) {
              return allGrids[index]; // String を返す
            } else {
              return ""; // デフォルト値
            }
          });
        });
        myIconLoad = false;
      });
    } else {
      await _loadTemplateList(true);

    }
  }

  Future<void> _loadTemplateList(bool own) async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('iconTemplate').doc('initial').get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        List<String> templateList = List<String>.from((doc['nameList'] as List).map((e) => e.toString()));
        templateList.shuffle();
        _loadTemplateGrid(templateList[0], own);
        print(templateList);
      } else {
        print('Document "initial" not found');
        _loadInitialIcon(own);
      }
    } catch (e) {
      print('Error loading grid for "inital": $e');
      _loadInitialIcon(own);
    }
  }

  Future<void> _loadTemplateGrid(String templateField, bool own) async { //画面全体をロード
    final firestore = FirebaseFirestore.instance;
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // `masFill`コレクションの中から`fun1`から`fun64`までのドキュメントを取得
    List<String> allGrids = [];
    try {
      // ドキュメントを取得
      DocumentSnapshot doc = await firestore.collection('iconTemplate').doc('initial').get();
      if (doc.exists) {
        // `grid`フィールドを取得してリストに格納
        allGrids = List<String>.from((doc[templateField] as List).map((e) => e.toString()));
        print(allGrids);
      } else {
        print('Document $templateField not found');
      }
    } catch (e) {
      print('Error loading grid for $templateField: $e');
    }

    // すべてのグリッドがロードされたら、状態を更新
    setState(() {
      if (own) {
        myIcon = List.generate(gridNumber, (y) {
        return List.generate(gridNumber, (x) {
          int index = y * gridNumber + x;

          // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
          if (index >= 0 && index < allGrids.length) {
            return allGrids[index]; // String を返す
          } else {
            return ""; // デフォルト値
          }
        });
      });
      prefs.setStringList('myIcon', allGrids);
      } else {
        enemyIcon = List.generate(gridNumber, (y) {
          return List.generate(gridNumber, (x) {
            int index = y * gridNumber + x;

            // allGridsの範囲内であれば値を取得、範囲外の場合は空文字列
            if (index >= 0 && index < allGrids.length) {
              return allGrids[index]; // String を返す
            } else {
              return ""; // デフォルト値
            }
          });
        });
      }
    });
  }

Future<void> _loadEnemyInfo(int battlePlayerNumber) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final DocumentReference roomRef = db.collection(battleRoomType).doc(battleRoomName);

  // 自分が2番の場合は1番の情報を取得し、1番の場合は2番の情報を取得
  final String enemyPrefix = (battlePlayerNumber == 1) ? '2' : '1';

  try {
    // Firestoreからバトルルームのデータを取得
    final DocumentSnapshot roomSnapshot = await roomRef.get();
    if (roomSnapshot.exists) {
      final Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;

      // 敵プレイヤーの情報をセット
      setState(() {
        enemyName = (data['name$enemyPrefix'] ?? '名前はまだ無い') as String;
        enemyRank = (data['rank$enemyPrefix'] ?? 'bronze1') as String;
        enemyRankJapan = _convertRankToJapanese((data['rank$enemyPrefix'] ?? 'bronze1') as String);
        enemySkillNoList = (data['skillList$enemyPrefix'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              ['No1'];

        int totalBattleHandCount = (data['rockCount$enemyPrefix'] as int) + (data['scissorCount$enemyPrefix'] as int) + (data['paperCount$enemyPrefix'] as int);
        enemyRockRate = _calculateRate(data['rockCount$enemyPrefix'] as int, totalBattleHandCount);
        enemyScissorRate = _calculateRate(data['scissorCount$enemyPrefix'] as int, totalBattleHandCount);
        enemyPaperRate = _calculateRate(data['paperCount$enemyPrefix'] as int, totalBattleHandCount);
        enemyHonestRate = _calculateHonestRate(data['honestCount$enemyPrefix'] as int, totalBattleHandCount);
        enemyWinRate = _calculateWinRate(data['winCount$enemyPrefix'] as int, data['battleCount$enemyPrefix'] as int);
        enemyWinStreak = data['winStreak$enemyPrefix'] as int; // ストリーク情報があれば追加
      });
      print(enemySkillNoList);
      _loadEnemySkillList();
    } else {
      print('Room document does not exist.');
    }
  } catch (error) {
    print('Failed to load enemy info: $error');
  }
}

String _convertRankToJapanese(String rank) {

  if (rank.contains('bronze')) return 'ブロンズ' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('silver')) return 'シルバー' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('gold')) return 'ゴールド' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('platina')) return 'プラチナ' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('diamond')) return 'ダイヤ' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('elite')) return 'エリート' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('master')) return 'マスター' + rank.replaceAll(RegExp(r'[^\d]'), '');
  if (rank.contains('champion')) return 'チャンプ' + rank.replaceAll(RegExp(r'[^\d]'), '');

  return '不明なランク';
}

double _calculateRate(int specificCount, int totalCount) {
  if (totalCount == 0) return 0.0;
  return ((specificCount / totalCount) * 1000).round() / 10; // 小数点1桁まで
}

double _calculateHonestRate(int honestCount, int totalCount) {
  if (totalCount == 0) return 0.0;
  return ((honestCount / totalCount) * 1000).round() / 10;
}

double _calculateWinRate(int winCount, int battleTime) {
  if (battleTime == 0) return 0.0;
  return ((winCount / battleTime) * 1000).round() / 10; // 小数点1桁まで
}

  _loadMyInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      myCommentList = (prefs.getStringList('myCommentList') ?? ['よろしく！','ありがとう！', 'ナイスプレイ！', '本気出すわ！', 'チキショー！', '何出そう', '天才？', 'チート？', '!?', '否']);
      myName = (prefs.getString('myName') ?? '名前はまだ無い');
      myRank = (prefs.getString('myRank') ?? 'champion1');
      myRankCount = (prefs.getInt('myRankCount') ?? 0);
      myLevel = (prefs.getInt('myLevel') ?? 0);
      myLevelExp = (prefs.getInt('myLevelExp') ?? 0);
      List<String> rankList = ['bronze', 'silver', 'gold', 'platina','elite', 'diamond', 'master', 'champion'];
      List<String> rankNumbers = ['1', '2', '3'];
      String rank = '';
      String rankNumber = '';
      for (int i = 0; i < rankList.length; i++) {
        if(myRank.contains(rankList[i])) {
          rank = rankList[i];
        }
      }
      for (int i = 0; i < rankNumbers.length; i++) {
        if(myRank.contains(rankNumbers[i])) {
          rankNumber = rankNumbers[i];
        }
      }
      if (rank.contains('bronze')) {
        myRankJapan = 'ブロンズ' + rankNumber;
      } else if (rank.contains('silver')) {
        myRankJapan = 'シルバー' + rankNumber;
      } else if (rank.contains('gold')) {
        myRankJapan = 'ゴールド' + rankNumber;
      } else if (rank.contains('platina')) {
        myRankJapan = 'プラチナ' + rankNumber;
      } else if (rank.contains('diamond')) {
        myRankJapan = 'ダイヤ' + rankNumber;
      }  else if (rank.contains('elite')) {
        myRankJapan = 'エリート' + rankNumber;
      } else if (rank.contains('master')) {
        myRankJapan = 'マスター' + rankNumber;
      } else if (rank.contains('champion')) {
        myRankJapan = 'チャンプ' + rankNumber;
      }
      int rockCount = (prefs.getInt('myRockCount')) ?? 0;
      int scissorCount = (prefs.getInt('myScissorCount')) ?? 0;
      int paperCount = (prefs.getInt('myPaperCount')) ?? 0;
      int battleCount = (prefs.getInt('myBattleCount')) ?? 0;
      int winCount = (prefs.getInt('myWinCount')) ?? 0;
      int honestCount = (prefs.getInt('myHonestCount')) ?? 0;
      int totalCount = rockCount + scissorCount + paperCount;
      myRockRate = totalCount > 0 ? ((rockCount / totalCount) * 1000).round() / 10 : 0.0;
      myScissorRate = totalCount > 0 ? ((scissorCount / totalCount) * 1000).round() / 10 : 0.0;
      myPaperRate = totalCount > 0 ? ((paperCount / totalCount) * 1000).round() / 10 : 0.0;
      myHonestRate = totalCount > 0 ? ((honestCount / totalCount) * 1000).round() / 10 : 0.0;
      myWinRate = battleCount > 0 ? ((winCount / battleCount) * 1000).round() / 10 : 0.0;
      myWinStreak = (prefs.getInt('myWinStreak')) ?? 0;
      myLevel = (prefs.getInt('myLevel')) ?? 1;
      myLevelExp = (prefs.getInt('myLevelExp')) ?? 0;
    });
  }

  _changeRoutePass() async{
    await  resetBattleRoomData(battleRoomType, battleRoomName);
    routePass.removeLast();
    context.go('/onlineBattle');
  }

  Future<void> resetBattleRoomData(String battleRoomType, String battleRoomName) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      DocumentReference docRef = db.collection(battleRoomType).doc(battleRoomName);

      Map<String, dynamic> initialData = {
        'battleState': false,
        'battleCount1': 0,
        'battleCount2': 0,
        'comment1': '',
        'comment2': '',
        'openCard1_1': '',
        'openCard1_2': '',
        'openCard2_1': '',
        'openCard2_2': '',
        'decide1': false,
        'decide2': false,
        'declarePoint1': 0,
        'declarePoint2': 0,
        'declareHand1': '',
        'declareHand2': '',
        'giveUp1': false,
        'giveUp2': false,
        'battleSkillNo1': '',
        'battleSkillNo2': '',
        'battleHand1': '',
        'battleHand2': '',
        'name1': '',
        'name2': '',
        'num1': 0,
        'num2': 0,
        'point1': 0,
        'point2': 0,
        'reStartState': false,
        'skillList1': [],
        'skillList2': [],
        'skillParameter1': '',
        'skillParameter2': '',
        'rank1': '',
        'rank2': '',
        'time': 0,
        'uid1': '',
        'uid2': '',
        'winCount1': 0,
        'winCount2': 0,
        'winStreak1': 0,
        'winStreak2': 0,
        'rockCount1': 0,
        'rockCount2': 0,
        'scissorCount1': 0,
        'scissorCount2': 0,
        'paperCount1': 0,
        'paperCount2': 0,
        'honestCount1': 0,
        'honestCount2': 0,
        'favoriteSkillNo1': '',
        'favoriteSkillNo2': '',
        'favoriteSkillName1': '',
        'favoriteSkillName2': '',
      };
      await docRef.set(initialData, SetOptions(merge: true));
      print('Battle room data reset successfully.');
    } catch (e) {
      print('Error resetting battle room data: $e');
    }
  }


  @override
  void dispose() { // ウィジェットが破棄されるときの処理
    _completer?.complete();
    _sceneTimer?.cancel();
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
    List<String> mySkillNoList = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      mySkillNoList = (prefs.getStringList('StrategySkillNoList') ?? ['No1', 'No2', 'No3', 'No4', 'No5', 'No6', 'No7', 'No8', 'No9', 'No10']);

      // mySkillNoListが空でない場合、myCardsをmySkillNoListとmySkillTypeListに基づいて作り直す
      if (mySkillNoList.isNotEmpty) {
        myCards = List.generate(mySkillNoList.length, (index) {
          String skillNo = mySkillNoList[index];
          Map<String, String>? matchingSkill = skills.firstWhere(
            (skill) => skill['No'] == skillNo,
            orElse: () => {'name': 'Unknown Skill', 'description': 'No description available'}
          );
          return {
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'no': skillNo,
            'skillName': matchingSkill['name'] ?? '存在しない技',
            'skill': 'Images/${mySkillNoList[index]}.png',
            'description': matchingSkill['description'] ?? '説明文が存在しないスキルです。'
          };
        });
      }
      mySkillNoListPref = '';
      for (int i = 0; i < mySkillNoList.length; i++) {
        mySkillNoListPref += '${mySkillNoList[i]},';
      }
    });
  }

  void _loadEnemySkillList() {
    // enemySkillListを生成
    setState(() {

      if (enemySkillNoList.isNotEmpty) {
        enemyCards = List.generate(enemySkillNoList.length, (index) {
          String skillNo = enemySkillNoList[index];
          Map<String, String>? matchingSkill = skills.firstWhere(
            (skill) => skill['No'] == skillNo,
            orElse: () => {'name': 'Unknown Skill', 'description': 'No description available'}
          );
          return {
            'open': 'false',
            'belong': 'enemy',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': skillNo,
            'skillName': matchingSkill['name'] ?? '存在しない技',
            'image': 'Images/rock.svg',
            'skill': 'Images/${enemySkillNoList[index]}.png',
            'description': matchingSkill['description'] ?? '説明文が存在しないスキルです。'
          };
        });
      }
      enemySkillNoListPref = '';
      for (int i = 0; i < enemySkillNoList.length; i++) {
        enemySkillNoListPref += '${enemySkillNoList[i]},';
      }
    });
  }

  //シーンの遷移
  List<Map<String, dynamic>> scenes = [
    {'scene': 'start', 'seconds': 3},
    {'scene': 'roundOpen', 'seconds': 3},
    {'scene': 'cardOpen', 'seconds': 6},
    {'scene': 'skillSelect', 'seconds': 30}, //30
    {'scene': 'declareSelect', 'seconds': 13},//10
    {'scene': 'declareOpen', 'seconds': 6},
    {'scene': 'battleSelect', 'seconds': 15},//20
    {'scene': 'battleOpen', 'seconds': 8},
    {'scene': 'skillOpen', 'seconds': 3},
    {'scene': 'resultOpen', 'seconds': 6},
    {'scene': 'end', 'seconds': 20},
  ];

  void sceneChange(int sceneSeconds) {
    if (!mounted) return;
    if (nowSceneIndex == -1) {
      setOpenCard();
    }

    if ((myRetireState || enemyRetireState ) && nowScene != 'end') {
      judgeBattle();
      nowSceneIndex = scenes.length - 1;
      nowScene = scenes[nowSceneIndex]['scene'] as String;
    } else if (nowScene == 'resultOpen') {
      if ((enemyPoint < winPoint && myPoint < winPoint && currentRound < 5 && enemyPoint > 0 && myPoint > 0) || (enemyPoint == myPoint && currentRound < 10)) {
        nowSceneIndex = 1;
        nowScene = scenes[nowSceneIndex]['scene'] as String;
      } else {
        judgeBattle();
        nowSceneIndex += 1;
        nowScene = scenes[nowSceneIndex]['scene'] as String;
      }
    } else if (nowSceneIndex + 1 < scenes.length) {
      nowSceneIndex += 1;
      nowScene = scenes[nowSceneIndex]['scene'] as String;
    }

    setState(() {});  // 状態を更新するだけで具体的な操作はしない

    // 既存のタイマーをキャンセル
    _sceneTimer?.cancel();

    // 新しいタイマーを開始
    _sceneTimer = Timer(Duration(seconds: scenes[nowSceneIndex]['seconds'] as int), () {
      if (mounted) {
        if (nowSceneIndex + 1 < scenes.length) {
          sceneChange(scenes[nowSceneIndex]['seconds'] as int);
        } else {
          sceneChange(scenes[1]['seconds'] as int);
        }
        specificSceneFunc(scenes[nowSceneIndex]['scene'] as String);  // 非同期処理の後にspecificSceneFuncを実行
      } else {
        print('specific 発動できないよぉ');
      }
    });
  }

  void skipCurrentScene() {
    if (!mounted) return;
    mySkipState  = true;
    // タイマーを停止
    _sceneTimer?.cancel();

      mySkipState = false;
      if (nowSceneIndex + 1 < scenes.length && (nowScene == 'skillSelect' || nowScene == 'battleSelect')) {
        sceneChange(scenes[nowSceneIndex]['seconds'] as int); // 次のシーンのタイマーを開始
        specificSceneFunc(scenes[nowSceneIndex]['scene'] as String);
      }

    setState(() {}); // 状態を更新
  }

  void retireBattle() {
    if (!mounted) return;

    // タイマーを停止
    _sceneTimer?.cancel();
    myRetireState = true;

    // 次のシーンへ進む
    if (nowSceneIndex + 1 < scenes.length) {
      print('リタイアしました。');
      sceneChange(scenes[scenes.length - 1]['seconds'] as int); // 次のシーンのタイマーを開始
      specificSceneFunc(scenes[scenes.length - 1]['scene'] as String);
    }

    setState(() {}); // 状態を更新
  }

  void specificSceneFunc (String nowScene){
    if (nowScene == 'start') {
      print('set OpenCard!');

    } else if (nowScene == 'roundOpen') {//ラウンド開始時の諸々の処理
      setState(() {
        currentRound += 1;
      });
      setResetState();
      Future.delayed(Duration(milliseconds: 1500), () {
        print('loadOpenCard');
        loadOpenCard();
      });
      setSkipState(false);
      _myBattleCardIndex = -1;
      slideInBool = false;
      mySkillActive = false;
      enemySkillActive = false;
      skillResultView = false;
      mySkillOptionView = false;
      skillOpenWait = false;
      battleOpenWait = false;
      declareOpenWait = false;
      mySkillSelect = '';
      enemySkillSelect = '';
      enemySkipState = false;
      mySkipState = false;

      //ポイントの初期化
      previousMyPoint = myPoint;
      previousEnemyPoint = enemyPoint;
      myChangePoint = 0;
      myChangeMySkill = 0;
      myChangeEnemySkill = 0;
      enemyChangePoint = 0;
      enemyChangeMySkill = 0;
      enemyChangeEnemySkill = 0;



      //ターン開始時の諸諸の処理終了
    } else if (nowScene == 'cardOpen') { //ターン開始時のカードオープン

      Future.delayed(Duration(milliseconds: 20), () {
        for (int i = 0; i < flipCardKeys.length; i++) {
          Future.delayed(Duration(milliseconds: 500 * i), () {
            flipCardKeys[i].currentState?.flipCard();
          });
        }
      });
    } else if (nowScene == 'skillSelect') { //スキルセレクト
    arrayCards(myCards);
    arrayCards(enemyCards);
    print('スキルセレクトのはずです。${scenes[nowSceneIndex]['scene']}');
    sceneTimer = scenes[nowSceneIndex]['seconds'] as int;
    circularTimerKey.currentState?._resetTimer(scenes[nowSceneIndex]['seconds'] as int);
    } else if (nowScene == 'declareSelect') { //宣言セレクト
    Future.delayed(Duration(milliseconds: 500), () {
      loadBattleSkill();
    });

    print('宣言セレクトのはずです。${scenes[nowSceneIndex]['scene']}');
    sceneTimer = scenes[nowSceneIndex]['seconds'] as int;
    Future.delayed(Duration(milliseconds: 1500), () {
      setState(() {
        sceneTimer = 10;
        circularTimerKey.currentState?._resetTimer(10); //declareSelectの待ち時間　sceneの方では13になってるから
        skillOpenWait = true;

      });
    });

      if (_myBattleCardIndex == -1) {
        List<Map<String, dynamic>> availableCards = myCards.where((card) => card['used'] == 'false').toList();
        if (availableCards.isNotEmpty) {
          final Random random = Random();
          Map<String, dynamic> selectedCard = availableCards[random.nextInt(availableCards.length)];
          _myBattleCardIndex = myCards.indexWhere((card) => card == selectedCard);
        } else {
          throw Exception('No available cards with used == false.');
        }
        setState(() {
          myBattleSkillNo = myCards[_myBattleCardIndex]['no']!;
          setBattleSkill();
        });
        noneSelectInt += 1;
        if (noneSelectInt > 1) {
          print('user is not playing now!');
          setRetireState();
          retireBattle();
        }
      }
    } else if (nowScene == 'declareOpen') { //宣言オープン
    Future.delayed(Duration(milliseconds: 1500), () {
      loadDeclareHand();
      loadDeclarePoint();
    });

    Future.delayed(Duration(milliseconds: 3000), () {
      setState(() {
        declareOpenWait = true;
      });
    });
    print('宣言オープンのはずです。${scenes[nowSceneIndex]['scene']}');
    } else if (nowScene == 'battleSelect') { //バトルセレクト

    print('バトルセレクトのはずです。${scenes[nowSceneIndex]['scene']}');
      sceneTimer = scenes[nowSceneIndex]['seconds'] as int;
      circularTimerKey.currentState?._resetTimer(scenes[nowSceneIndex]['seconds'] as int);
    } else if (nowScene == 'battleOpen') { //バトル結果表示の際の動作
    Future.delayed(Duration(milliseconds: 1500), () {
      loadBattleHand();
    });
    print('バグ検出用：自分のスキルは$myBattleSkillNoで相手のスキルは$enemyBattleSkillNoです。');
      setState(() {
        battleWait = true;
      });
      Future.delayed(Duration(milliseconds: 3000), () {
        addBattleLog();
        setState(() {
          battleWait = false;
          myCards[_myBattleCardIndex]['used'] = 'true';
          enemyCards[_enemyBattleCardIndex]['used'] = 'true';
        });
      });
      Future.delayed(Duration(milliseconds: 3500), () {
        setState(() {
          slideInBool = true;
        });
      });
    } else if (nowScene == 'skillOpen') { //スキル発動の有無
    print('スキルオープンのはずです。${scenes[nowSceneIndex]['scene']}');
      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          judgeJanken(myBattleHand, enemyBattleHand);
          checkMySkillActive(myBattleSkillNo, enemyBattleSkillNo, myBattleHand, myDeclareHand, enemyBattleHand, enemyDeclareHand, myPoint, enemyPoint, myDeclarePoint, enemyDeclarePoint, mySkillSelect, enemySkillSelect, myCards, enemyCards);
          checkEnemySkillActive(enemyBattleSkillNo, myBattleSkillNo, enemyBattleHand, enemyDeclareHand, myBattleHand, myDeclareHand, enemyPoint, myPoint, enemyDeclarePoint, myDeclarePoint, enemySkillSelect, mySkillSelect, enemyCards, myCards);
          reviseBattleLog();
          if (mySkillActive) {
            print('$myBattleSkillNo perform');
            performMySkillEffect(myBattleSkillNo, enemyBattleSkillNo, myBattleHand, myDeclareHand, enemyBattleHand, enemyDeclareHand, myPoint, enemyPoint, myChangeMySkill, myChangeEnemySkill, enemyChangeMySkill, enemyChangeEnemySkill, myDeclarePoint, enemyDeclarePoint, mySkillSelect, enemySkillSelect, myCards, enemyCards);
          }
          if (enemySkillActive) {
            performEnemySkillEffect(enemyBattleSkillNo, myBattleSkillNo, enemyBattleHand, enemyDeclareHand, myBattleHand, myDeclareHand, enemyPoint, myPoint, enemyChangeEnemySkill, enemyChangeMySkill, myChangeEnemySkill, myChangeMySkill, enemyDeclarePoint, myDeclarePoint, enemySkillSelect, mySkillSelect, enemyCards, myCards);
          }
          skillResultView = true;
        });
      });
    } else if (nowScene == 'resultOpen') { //結果オープン　スキルの効果発動など
    setSkillRanking();
    saveUserInfo();
    setOpenCard();
    int interval = 50;
    print('myChangePoint$myChangePoint');
    print('myChangemySKill$myChangeMySkill');
    print('myChangeENemySKill$myChangeEnemySkill');
    print('enemyChangePoint$enemyChangePoint');
    print('enemyChangeMySKill$enemyChangeMySkill');
    print('enemyChangeEnemySkill$enemyChangeEnemySkill');
      () async{
        int interval = 50; // 各ステップの間隔 (ms)
        // myChangePoint の処理
        await adjustPointsSequentially(
          true,
          myChangePoint,
          interval,
          () {
            setState(() {
              myChangePointView = true; // 開始時
            });
          },
          () {
            setState(() {
              myChangePointView = false; // 終了時
            });
          },
        );
        // myChangeMySkill の処理
        await adjustPointsSequentially(
          true,
          myChangeMySkill,
          interval,
          () {
            setState(() {
              myChangeMySkillView = true; // 開始時
            });
          },
          () {
            setState(() {
              myChangeMySkillView = false; // 終了時
            });
          },
        );
        // myChange EneｍySkill の処理
        await adjustPointsSequentially(
          true,
          myChangeEnemySkill,
          interval,
          () {
            setState(() {
              myChangeEnemySkillView = true; // 開始時
            });
          },
          () {
            setState(() {
              myChangeEnemySkillView = false; // 終了時
            });
          },
        );
      }();
      () async{
        // enemyChangePoint の処理
        await adjustPointsSequentially(
          false,
          enemyChangePoint,
          interval,
          () {
            setState(() {
              enemyChangePointView = true; // 開始時
            });
          },
          () {
            setState(() {
              enemyChangePointView = false; // 終了時
            });
          },
        );

        // enemyChangeMySkill の処理
        await adjustPointsSequentially(
          false,
          enemyChangeMySkill,
          interval,
          () {
            setState(() {
              enemyChangeMySkillView = true; // 開始時
            });
          },
          () {
            setState(() {
              enemyChangeMySkillView = false; // 終了時
            });
          },
        );

        // enemyChangeEnemySkill の処理
        await adjustPointsSequentially(
          false,
          enemyChangeEnemySkill,
          interval,
          () {
            setState(() {
              enemyChangeEnemySkillView = true; // 開始時
            });
          },
          () {
            setState(() {
              enemyChangeEnemySkillView = false; // 終了時
            });
          },
        );
      }();
    } else if (nowScene == 'end') { //勝敗判定後

    }
  }

  //各シーン処理の詳細


//オンライン実装
void setOpenCard() async{
  print('setOpenCard');
  nowMyOpenCardsNo = [];
  nowMyOpenCardsName = [];
  nowEnemyOpenCardsNo = [];
  nowEnemyOpenCardsName = [];
  List<Map<String, dynamic>> falseMyOpenCards = myCards.where((card) => (card['open'] == 'false' && card['used'] == 'false')).toList();
  falseMyOpenCards.shuffle();
  int cardsToOpen = falseMyOpenCards.length >= 2 ? 2 : falseMyOpenCards.length;
  int desyabariIndex = myCards.indexWhere((card) => (card['no'] == 'No35' && card['open'] == 'false')); //スキルでしゃばり

  for (int i = 0; i < cardsToOpen; i++) {
    int index = myCards.indexWhere((card) => card == falseMyOpenCards[i]);

    if (desyabariIndex != -1) {
      myCards[desyabariIndex]['open'] = 'true';
      nowMyOpenCardsNo.add(myCards[desyabariIndex]['no']);
      nowMyOpenCardsName.add(myCards[desyabariIndex]['skillName']);
    } else
    if (index != -1) {
      myCards[index]['open'] = 'true';
      nowMyOpenCardsNo.add(myCards[index]['no']);
      nowMyOpenCardsName.add(myCards[index]['skillName']);
    }
  }

  if (battlePlayerNumber == 1){
    await updateFieldsInFirebase(
      fieldsToUpdate: {
        'openCard1_1': nowMyOpenCardsNo.isNotEmpty ? nowMyOpenCardsNo[0] : '',
        'openCard1_2': nowMyOpenCardsNo.length > 1 ? nowMyOpenCardsNo[1] : '',
      },
    );
  } else {
    await updateFieldsInFirebase(
      fieldsToUpdate: {
        'openCard2_1': nowMyOpenCardsNo.isNotEmpty ? nowMyOpenCardsNo[0] : '',
        'openCard2_2': nowMyOpenCardsNo.length > 1 ? nowMyOpenCardsNo[1] : '',
      },
    );
  }
}

void loadOpenCard() async{
  String enemyOpenCard1 = '';
  String enemyOpenCard2 = '';
  if (battlePlayerNumber == 1) {
    enemyOpenCard1 = await getFieldFromFirebase(
      field: 'openCard2_1'
    ) as String;
    enemyOpenCard2 = await getFieldFromFirebase(
      field: 'openCard2_2'
    )as String;
  } else {
    enemyOpenCard1 = await getFieldFromFirebase(
      field: 'openCard1_1'
    )as String;
    enemyOpenCard2 = await getFieldFromFirebase(
      field: 'openCard1_2'
    )as String;
  }

  bool enemyUnOpenCardExist = false;
  for (int i =0; i < enemyCards.length; i++) {
    if (enemyCards[i]['open'] == 'false') {
      enemyUnOpenCardExist = true;
    }
    if (enemyUnOpenCardExist && enemyOpenCard1 == '') { //オープンできるカードがあるのにそれが登録されていない場合
      enemyRetireState = true;
      sceneChange(1);
    }
  }


  for (int i = 0; i < enemyCards.length; i++) {
    print(enemyCards[i]['no']);
    print('$enemyOpenCard1, $enemyOpenCard2');
    if (enemyCards[i]['no'] == enemyOpenCard1) {
      print(enemyCards[i]['skillName']);
      setState(() {
        enemyCards[i]['open'] = 'true';
      });
    }
    if (enemyCards[i]['no'] == enemyOpenCard2 ) {
      print(enemyCards[i]['skillName']);
      setState(() {
        enemyCards[i]['open'] = 'true';
      });
    }
  }

  for (int i =0; i < skills.length; i++) {
    if (skills[i]['No'] == enemyOpenCard1 ) {
      nowEnemyOpenCardsNo.add(enemyOpenCard1);
      nowEnemyOpenCardsName.add(skills[i]['name']);
    }
    if (skills[i]['No'] == enemyOpenCard2 ) {
      nowEnemyOpenCardsNo.add(enemyOpenCard2);
      nowEnemyOpenCardsName.add(skills[i]['name']);
    }
  }
}

void setBattleSkill() async {
  print('setBattleSkillNo!');
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'battleSkillNo$battlePlayerNumber': myBattleSkillNo,
    },
  );
  setBattleSkillRandom();
}

void loadBattleSkill() async {
  enemyBattleSkillNo = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'battleSkillNo2' : 'battleSkillNo1'
  ) as String;
  print('相手の発動スキルは$enemyBattleSkillNo');
  if (enemyBattleSkillNo == '') {
    enemyRetireState = true;
    sceneChange(1);
  }
  for (int i = 0; i < enemyCards.length; i++) {
    if (enemyCards[i]['no'] == enemyBattleSkillNo && enemyCards[i]['used'] == 'false') {
      print('matching Card Find!');
      setState(() {
        _enemyBattleCardIndex = i;
        enemyCards[i]['open'] = 'true';
      });
    }
  }
  loadBattleSkillRandom();
  loadSkillSelect();
}

void setBattleSkillRandom() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'skillParameter$battlePlayerNumber': '',
    },
  );
  String setRandomState = '';
  var random = Random();
  switch (myBattleSkillNo) {
    case 'No16': //ギャンブラー
    List<int> randomNumber = List.generate(100, (index) => index + 1);
    setRandomState = randomNumber[random.nextInt(randomNumber.length)].toString();
    break;

    case 'No24': //縛りプレイ　ランダムで一つ無効化
    List<int> unusedIndexes = [];
    for (int i = 0; i < enemyCards.length; i++) {
      if (enemyCards[i]['used'] == 'false') {
        unusedIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty) {
      setRandomState = unusedIndexes[random.nextInt(unusedIndexes.length)].toString();
    }
    break;

    case 'No28': //変幻自在　相手のカードランダムで一つ変更 (古いスキル、新しいスキル)
    List<int> unusedIndexes = [];
    for (int i = 0; i < enemyCards.length; i++) {
      if (enemyCards[i]['used'] == 'false') {
        unusedIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty) {
      int oldSkillIndex = unusedIndexes[random.nextInt(unusedIndexes.length)];
      int newSkillIndex = random.nextInt(skills.length);
      setRandomState = '$oldSkillIndex,$newSkillIndex';
    }
    break;

    case 'No29': //ミストラル　ランダムで一つの効果を発動
    int randomInt = random.nextInt(11);
    setRandomState = randomInt.toString();
    switch (randomInt) {
        case 0: //相手のカードをランダムに変更 (0: 変える前のカードインデックス, 変えた後のスキルインデックス)
        List<int> unusedIndexes = [];
        for (int i = 0; i < enemyCards.length; i++) {
          if (enemyCards[i]['used'] == 'false') {
            unusedIndexes.add(i);
          }
        }
        if (unusedIndexes.isNotEmpty) {
          print('スキル変更する。');
          int newSkillIndex = random.nextInt(skills.length);
          int oldSkillIndex = unusedIndexes[random.nextInt(unusedIndexes.length)];
          setRandomState = '0:$oldSkillIndex,$newSkillIndex';
        }
        break;

        case 1:
        setRandomState = '1';
        break;

        case 2:
        setRandomState = '2';
        break;

        case 3: //カードをランダムに一つたす (3:新しいスキルインデックス) この数はskillNoの一個前の数になっている。
        int newSelectedIndex = random.nextInt(skills.length);
        setRandomState = '3:$newSelectedIndex';
        break;

        case 4: //スキルなしカードを２つ貰える。
        setRandomState = '4';
        break;

        case 5: //自分に+20,相手に-20
        setRandomState = '5';
        break;

        case 6: // もう一度このカードを使える。
        setRandomState = '6';
        break;

        case 7: // バトルログに「スキルの効果で誰かが幸せになった気がする。」とかく
        setRandomState = '7';
        break;

        case 8: // 相手のカードを１枚オープンしてくれる
        List<int> unOpenIndexes = [];
        for (int i = 0; i < enemyCards.length; i++) {
          if (enemyCards[i]['used'] == 'false') {
            unOpenIndexes.add(i);
          }
        }
        if (unOpenIndexes.isNotEmpty) {
          setRandomState = '8:${unOpenIndexes[random.nextInt(unOpenIndexes.length)]}';
        }
        break;

        case 9: //　自分のカードを一つランダムで複製 (9:複製するカードのインデックス)
        int newSelectedIndex = random.nextInt(myCards.length);
        setRandomState = '9:$newSelectedIndex';
        break;

        case 10: //　自分のカードを一つランダムでスキルを消してしまう。(10:消してしまう自分のカード)
        List<int> unusedIndexes = [];
        for (int i = 0; i < myCards.length; i++) {
          if (myCards[i]['used'] == 'false') {
            unusedIndexes.add(i);
          }
        }
        if (unusedIndexes.isNotEmpty) {
          setRandomState = '10:${unusedIndexes[random.nextInt(unusedIndexes.length)]}';
        }
        break;
      }
    break;

    case 'No31': //自由奔放　未使用でかつオープンされているカードをランダムで変更 (変更前のカードインデックス,変更後のスキルインデックス) スキルインデックスはskillNoにマイナス１している
    List<int> unusedIndexes = [];
    for (int i = 0; i < enemyCards.length; i++) {
      if (enemyCards[i]['used'] == 'false' && enemyCards[i]['open'] == 'true') {
        unusedIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty) {
      int oldSkillIndex = unusedIndexes[random.nextInt(unusedIndexes.length)];
      int newSkillIndex = random.nextInt(skills.length);
      setRandomState = '$oldSkillIndex,$newSkillIndex';
    }
    break;

    case 'No32': //貿易の興り　ランダムでスキル交換 (自分のカードインデックス,相手のカードインデックス)
    List<int> unusedIndexes = [];
    for (int i = 0; i < myCards.length; i++) {
      if (myCards[i]['used'] == 'false') {
        unusedIndexes.add(i);
      }
    }
    List<int> unusedOtherIndexes = [];
    for (int i = 0; i < enemyCards.length; i++) {
      if (enemyCards[i]['used'] == 'false') {
        unusedOtherIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty && unusedOtherIndexes.isNotEmpty) {
      int selectedIndex = unusedIndexes[random.nextInt(unusedIndexes.length)];
      int selectedOtherIndex = unusedOtherIndexes[random.nextInt(unusedOtherIndexes.length)];
      setRandomState = '$selectedIndex,$selectedOtherIndex';
    }
    break;

    case 'No34': //かくれんぼ　最大　自分の３枚のカードを隠してしまう (かーど１,2,3)
    List<int> unOpenIndexes = [];
    for (int i = 0; i < myCards.length; i++) {
      if (myCards[i]['used'] == 'false') {
        unOpenIndexes.add(i);
      }
    }
    if (unOpenIndexes.isNotEmpty) {
      int selectedIndex = random.nextInt(unOpenIndexes.length);
      int selectedIndex2 = random.nextInt(unOpenIndexes.length);
      int selectedIndex3 = random.nextInt(unOpenIndexes.length);
      setRandomState = '$selectedIndex,$selectedIndex2,$selectedIndex3';
    }
    break;

    case 'No38': //リバイバル　ランダムで一つカード復活 (復活させる自分のカード)
    List<int> unOpenIndexes = [];
    for (int i = 0; i < myCards.length; i++) {
      if (myCards[i]['used'] == 'true') {
        unOpenIndexes.add(i);
      }
    }
    if (unOpenIndexes.isNotEmpty){
      setRandomState = random.nextInt(unOpenIndexes.length).toString();
    }
    break;

    case 'No44': //墓荒らし　ランダムで一つ相手の墓地からスキルを奪う (奪うカードインデックス)
    List<int> unOpenIndexes = [];
    for (int i = 0; i < enemyCards.length; i++) {
      if (enemyCards[i]['used'] == 'false') {
        unOpenIndexes.add(i);
      }
    }
    if (unOpenIndexes.isNotEmpty) {
      setRandomState = random.nextInt(unOpenIndexes.length).toString();
    }
    break;

    case 'No47': //カオス　自分と相手のカードをごちゃ混ぜ (自分の新しいデッキe1,e3,m1....: 相手の新しいデッキe2,m2.....)
    List<String> combinedList = [];
    for (int i = 0; i < enemyCards.length; i++) {
      combinedList.add('e$i');
    }
    for (int i = 0; i < myCards.length; i++) {
      combinedList.add('m$i');
    }
    combinedList.shuffle();
    int mid = (combinedList.length + 1) ~/ 2;
    List myList = combinedList.sublist(0, mid);
    List enemyList = combinedList.sublist(mid);
    for (int i = 0; i < myList.length; i++) {
      setRandomState += '${myList[i]},';
    }
    combinedList.add(':');
    for (int i = 0; i < enemyList.length; i++) {
      setRandomState += '${enemyList[i]},';
    }
    break;

    case 'No48': //盗人の極意　相手のカードを1-3枚奪う (奪うカードインデックス1,2,3)
    List<int> otherNumbers = List.generate(enemyCards.length, (index) => index);
    otherNumbers.shuffle();
    int number = 0;
    if (currentRound < 2) {
      number = 1;
    } else if (currentRound < 4) {
      number = 2;
    } else {
      number = 3;
    }
    for (int i = 0; i < number; i++) {
      setRandomState += '${otherNumbers[i]},';
    }
    break;
  }
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'skillParameter$battlePlayerNumber': setRandomState,
    },
  );
}

void loadBattleSkillRandom() async {
  mySkillRandom = await getFieldFromFirebase(
    field: 'skillParameter$battlePlayerNumber'
  ) as String;
  enemySkillRandom = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'skillParameter2' : 'skillParameter1'
  ) as String;
}

void setSkillSelect() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'skillParameter$battlePlayerNumber': mySkillSelect,
    },
  );
}

void loadSkillSelect() async {
  enemySkillSelect = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'skillParameter2' : 'skillParameter1'
  ) as String;
}

void setDeclareHand() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'declareHand$battlePlayerNumber': myDeclareHand,
    },
  );
}

void loadDeclareHand() async {
  enemyDeclareHand = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'declareHand2' : 'declareHand1'
  ) as String;
  if (enemyDeclareHand == '') { //オープンできるカードがあるのにそれが登録されていない場合
    enemyRetireState = true;
    sceneChange(1);
  }
}

void setDeclarePoint() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'declarePoint$battlePlayerNumber': myDeclarePoint,
    },
  );
}

void loadDeclarePoint() async {
  enemyDeclarePoint = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'declarePoint2' : 'declarePoint1'
  ) as int;
}

void setBattleHand() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'battleHand$battlePlayerNumber': myBattleHand,
    },
  );
}

void loadBattleHand() async {
  enemyBattleHand = await getFieldFromFirebase(
    field: battlePlayerNumber == 1 ? 'battleHand2' : 'battleHand1'
  ) as String;
  if (enemyBattleHand == '') { //オープンできるカードがあるのにそれが登録されていない場合
    enemyRetireState = true;
    sceneChange(1);
  }
}

void setSkillRanking() async {
  // Firestoreインスタンスの取得
  final firestore = FirebaseFirestore.instance;

  // newRankingコレクションのskillドキュメント参照
  final skillDocRef = firestore.collection('newRanking').doc('skill');

  try {
    // 'No'の後の数字を抽出し、インデックスを計算
    final skillIndex = int.tryParse(myBattleSkillNo.replaceAll('No', '')) ?? -1;

    if (skillIndex <= 0) {
      print('Invalid skill number format: $myBattleSkillNo');
      return;
    }

    final index = skillIndex - 1; // インデックス調整

    // skillドキュメントを取得
    final docSnapshot = await skillDocRef.get();

    if (docSnapshot.exists) {
      // ドキュメントのデータを取得
      final data = docSnapshot.data() as Map<String, dynamic>;

      // skillNoフィールドを配列として取得
      final List<dynamic> skillArray = (data['skillNo'] ?? []) as List<dynamic>;

      // インデックスが有効か確認
      if (index >= 0 && index < skillArray.length) {
        // 指定インデックスの値を+1
        skillArray[index] = (skillArray[index] as int) + 1;

        // 更新した配列をFirestoreに保存
        await skillDocRef.update({'skillNo': skillArray});
        print('SkillNo updated successfully at index $index');
      } else {
        print('Invalid index: $index');
      }
    } else {
      print('Document does not exist');
    }
  } catch (e) {
    print('Error updating skillNo: $e');
  }
}


void setRetireState() async{
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'giveUp$battlePlayerNumber': true,
    },
  );
}

void setSkipState(bool skipState) async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'decide$battlePlayerNumber': skipState,
    },
  );
}

void setComment() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'comment$battlePlayerNumber': myComment,
    },
  );
}

void listenToSkipState() {
  int enemyNumber = 0;
  if (battlePlayerNumber == 1){
    enemyNumber = 2;
  } else {
    enemyNumber = 1;
  }
  FirebaseFirestore.instance
      .collection(battleRoomType) // Firestoreのコレクション名
      .doc(battleRoomName)       // ドキュメントID
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['decide$enemyNumber'] == true && data['decide$battlePlayerNumber'] == true && !enemySkipState) {
        enemySkipState = true;
        mySkipState = true;
        skipCurrentScene();
      } else {
        print('skipState is not true.');
      }
      if (data != null) {
        if (data['giveUp$enemyNumber'] as bool){
          enemyRetireState = true;
          sceneChange(1);
        }
      }
      if (data != null) {
        enemyComment = data['comment$enemyNumber'] as String;
        if (enemyComment != '') {
          showEnemyComment();
        }
      }
      if (data != null) {
        if (data['num$enemyNumber'] == 0) {
          setState(() {
            enemyBattleState = false;
          });
        }
      }

    } else {
      print('Document does not exist.');
    }
  }, onError: (error) {
    print('Error: $error');
  });
}

void setResetState() async {
  await updateFieldsInFirebase(
    fieldsToUpdate: {
      'decide1': false,
      'decide2': false,
    },
  );
}
//オフライン実装

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
    myChangePoint += ((myDeclareHand == myBattleHand) ? 20 + myDeclarePoint : 20);
    enemyChangePoint -= ((enemyDeclareHand == enemyBattleHand) ? 20 + enemyDeclarePoint : 20);
  } else {
    handResult = 'lose';
    myChangePoint -= ((myDeclareHand == myBattleHand) ? 20 + myDeclarePoint : 20);
    enemyChangePoint += ((enemyDeclareHand == enemyBattleHand) ? 20 + enemyDeclarePoint : 20);
  }
}

void judgeBattle() {
  bool kingMyBool = false;
  for (int i = 0; i < myCards.length; i++) {
    if (myCards[i]['no'] == 'K') {
      kingMyBool = true;
    }
  }
  bool kingEnemyBool = false;
  for (int i = 0; i < enemyCards.length; i++) {
    if (enemyCards[i]['no'] == 'K') {
      kingEnemyBool = true;
    }
  }
  if (myRetireState) {
    battleResult = 'lose';
  } else if (enemyRetireState) {
    battleResult = 'win';
  } else if (kingMyBool && kingEnemyBool) {
    battleResult = 'draw';
  } else if (kingEnemyBool) {
    battleResult = 'win';
  } else if (kingMyBool) {
    battleResult = 'lose';
  } else if (myPoint > enemyPoint) {
    if (currentRound < 5) {
      battleResult = 'knockOut';
    } else {
      battleResult = 'win';
    }
  } else if (myPoint == enemyPoint) {
    battleResult = 'draw';
  } else if (myPoint < enemyPoint) {
    battleResult = 'lose';
  } else {
    battleResult = 'draw';
  }
  saveBattleInfo();
}

void addBattleLog() {
  setState(() {
    battleLog.add({
      'myHand': myBattleHand,
      'enemyHand': enemyBattleHand,
      'mySkill': myBattleSkillNo,
      'enemySkill': enemyBattleSkillNo,
      'mySkillEffect': '',
      'enemySkillEffect': '',
      'result': handResult,
      'myHonest': (myBattleHand == myDeclareHand) ? 'true' : 'false',
      'enemyHonest': (enemyBattleHand == enemyDeclareHand) ? 'true' : 'false',
    });
  });
}

void reviseBattleLog() {
  setState(() {
    battleLog[currentRound - 1]['mySkillEffect'] = mySkillActive ? '$enemyNameにスキルを発動した。' : '';
    battleLog[currentRound - 1]['enemySkillEffect'] = enemySkillActive ? '$myNameにスキルを発動した。' : '';
  });
}

void reviseMyBattleLog(String detail) {
  setState(() {
    battleLog[currentRound - 1]['mySkillEffect'] = detail;
  });
}

void reviseEnemyBattleLog(String detail) {
  setState(() {
    battleLog[currentRound - 1]['enemySkillEffect'] = detail;
  });
}

void arrayCards(List<Map<String, String>> cards) {
  setState(() {

    // 'open'が'true'かつ'used'が'false'のリスト
    List<Map<String, String>> openAndUnused = cards.where((card) {
      return card['open'] == 'true' && card['used'] == 'false';
    }).toList();

    // 'open'が'false'かつ'used'が'false'のリスト
    List<Map<String, String>> closedAndUnused = cards.where((card) {
      return card['open'] == 'false' && card['used'] == 'false';
    }).toList();

    // 'used'が'true'のリスト
    List<Map<String, String>> usedCards = cards.where((card) {
      return card['used'] == 'true';
    }).toList();
    cards.clear();
    cards.addAll([
        ...openAndUnused,
        ...closedAndUnused,
        ...usedCards,
      ]
    );
  });
}

void changeTimer(int seconds) { //右上のタイマーをリセットするやつ
  setState(() {
    circularTimerKey.currentState?._resetTimer(seconds);
  });
}

void saveUserInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    if (myBattleHand == 'rock') {
      prefs.setInt('myRockCount', ((prefs.getInt('myRockCount')) ?? 0) + 1);
    } else if (myBattleHand == 'scissor') {
      prefs.setInt('myScissorCount', ((prefs.getInt('myScissorCount')) ?? 0) + 1);
    } else if (myBattleHand == 'paper') {
      prefs.setInt('myPaperCount', ((prefs.getInt('myPaperCount')) ?? 0) + 1);
    }
    if (myBattleHand == myDeclareHand) {
      prefs.setInt('myHonestCount', ((prefs.getInt('myHonestCount')) ?? 0) + 1);
    }
    prefs.setInt('mySkillCount_$myBattleSkillNo', ((prefs.getInt('mySkillCount_$myBattleSkillNo')) ?? 0) + 1);
    if (mySkillActive) {
      prefs.setInt('mySkillActive_$myBattleSkillNo', ((prefs.getInt('mySkillActive_$myBattleSkillNo')) ?? 0) + 1);
    }
  });
}

void saveBattleInfo() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  prefs.setInt('myBattleCount', ((prefs.getInt('myBattleCount')) ?? 0) + 1);
  if (battleResult == 'win' || battleResult == 'knockOut') {
    prefs.setInt('myWinCount', ((prefs.getInt('myWinCount')) ?? 0) + 1);
    prefs.setInt('myWinStreak', ((prefs.getInt('myWinStreak')) ?? 0) + 1);
  } else {
    prefs.setInt('myWinStreak', 0);
  }

  if (!saveBattleState){
    updateLogs(
      prefs,
      dateTime: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      gameType: 'strategy',
      battleResult: battleResult,
      enemyName: enemyName,
      enemyRank: enemyRank,
      enemySkillNoListPref: enemySkillNoListPref,
      enemyPoint: enemyPoint,
      myRank: myRank,
      mySkillNoListPref: mySkillNoListPref,
      myPoint: myPoint
    );
  }
  setState(() {
    saveBattleState = true;
  });
}

  void updateLogs(SharedPreferences prefs, {
    required String dateTime,
    required String gameType,
    required String battleResult,
    required String enemyName,
    required String enemyRank,
    required String enemySkillNoListPref,
    required int enemyPoint,
    required String myRank,
    required String mySkillNoListPref,
    required int myPoint,
  }) {
    // ログの更新関数
    void updateLogList(String key, String newValue) {
      List<String> logList = prefs.getStringList(key) ?? [];
      if (logList.length >= 50) {
        logList.removeAt(0); // 先頭を削除
      }
      logList.add(newValue); // 新しいデータを末尾に追加
      prefs.setStringList(key, logList);
    }

    // 各ログを更新
    updateLogList('dateLog', dateTime);
    updateLogList('gameTypeLog', gameType);
    updateLogList('resultLog', battleResult);
    updateLogList('enemyNameLog', enemyName);
    updateLogList('enemyRankLog', enemyRank);
    updateLogList('enemyCardLog', enemySkillNoListPref);
    updateLogList('enemyPointLog', '$enemyPoint'); // 整数を文字列に変換
    updateLogList('myRankLog', myRank);
    updateLogList('myCardLog', mySkillNoListPref);
    updateLogList('myPointLog', '$myPoint'); // 整数を文字列に変換
  }


Future<void> adjustPointsSequentially( //ポイント変動を刻むやつ
  bool isMyPoint,
  int totalChange,
  int interval,
  VoidCallback? onStart,
  VoidCallback? onEnd
) async {
  int adjustedPoints = 0;
  bool isReduction = totalChange < 0;
  int steps = (2000 / interval).ceil();
  int increment = (totalChange.abs() / steps).ceil(); // 各ステップの変化量を計算

  // 処理開始時のコールバックを実行
  if (onStart != null) onStart();

  while (adjustedPoints.abs() < totalChange.abs()) {
    await Future.delayed(Duration(milliseconds: interval), () {
      setState(() {
        // 残りの変化量を計算
        int remaining = totalChange.abs() - adjustedPoints.abs();
        int currentIncrement = remaining < increment ? remaining : increment;
        currentIncrement *= isReduction ? -1 : 1; // 減算なら負の値に

        // 対象のポイントを更新
        if (isMyPoint) {
          myPoint += currentIncrement;
        } else {
          enemyPoint += currentIncrement;
        }
        adjustedPoints += currentIncrement; // 累積変化量を更新
      });
    });
  }

  // 処理終了時のコールバックを実行
  if (onEnd != null) onEnd();
}

void showMyComment(String newComment) {
  _completer = Completer<void>();
  if (_isCommented) return;
  print('showMyComment');
  setState(() {
    myComment = newComment;
    _bottomPosition = 0.08;
    _isCommented = true;
    setComment();
  });

  Future.delayed(Duration(milliseconds: 2500), () {
    if (!_completer!.isCompleted) {
      setState(() {
        _bottomPosition = -1;
        myComment = '';
        setComment();
      });
      _isCommented = false;
    }
  });
}

void showEnemyComment() {
  _completer = Completer<void>();
  if (_isEnemyCommented) return;
  setState(() {
    _topPosition = 50;
    _isEnemyCommented = true;
  });

  Future.delayed(Duration(milliseconds: 2500), () {
    if (!_completer!.isCompleted) {
    setState(() {
      _topPosition = -500;
    });
    _isEnemyCommented = false;
    }
  });
}



@override
  Widget build(BuildContext context) {


    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body:Stack(
        children: [
          if(_bannerAd != null)
          Positioned(
            top:0,
            child:
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
          ),

          Positioned( //自分の宣言ポイント
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            right: 0,
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => { setState(() {
                    commentListView = !commentListView;
                  })}, // タップイベントを処理
                  child: Image.asset(
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    'Images/comment.png'
                  )
                ),
              if (nowSceneIndex > 2 && optionSkilNoList.contains(myBattleSkillNo))
              Row(
                children: [

                  Text(
                    'スキル対象→', // スキル名を表示
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (['No27', 'No40'].contains(myBattleSkillNo))
                  Image.asset(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    fit: BoxFit.contain,
                    mySkillSelect != '' ? 'Images/$mySkillSelect.png' : 'Images/none.png',
                  ),
                  if (['No22'].contains(myBattleSkillNo))
                  SvgPicture.asset(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    fit: BoxFit.contain,
                    mySkillSelect != '' ?'Images/$mySkillSelect.svg' : 'Images/none.svg'
                  ),

                ],
              ),


                  if (nowSceneIndex > 3 && nowScene != 'declareOpen' && nowScene != 'end')
                   DeclarationDisplay(hand: myDeclareHand, points: myDeclarePoint.toString()),


              ]
            )
          ),

          if (nowSceneIndex > 3 && _myBattleCardIndex != -1 && nowSceneIndex < 7 && nowScene != 'declareOpen')
          Positioned(
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            left: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  mySkillDetail = true;
                  _mySelectedCardIndex = _myBattleCardIndex;
                });
              },
              child: Stack(
              children: [
                  Image.asset(
                    'Images/cardView.png',
                    height: screenHeight * 0.07,
                    width: screenWidth * 0.6,
                    fit: BoxFit.fill,
                  ),
                  if (nowSceneIndex > 5 && _myBattleCardIndex != -1)
                  Positioned(
                        left: screenWidth * 0.8 * 0.03, // カードの左上から8.5%右へ
                        top: screenHeight * 0.015, // カードの上から40.7%下へ
                        child: SvgPicture.asset(
                          'Images/$myBattleHand.svg', // 手の画像
                          height: screenHeight * 0.03, // 手の画像のサイズ
                        ),
                      ),
                  Positioned(
                      left: screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                      top: screenHeight * 0.009, // カードの上から48%下へ
                      child: Row(
                        children: [
                          Image.asset(
                            myCards[_myBattleCardIndex]['skill']!, // スキルの画像
                            height: screenHeight * 0.05,
                            width: screenHeight * 0.05,
                            fit: BoxFit.contain// スキルの画像のサイズ
                          ),
                          SizedBox(width: 5), // スキル名との間にスペースを追加
                          Text(
                            myCards[_myBattleCardIndex]['skillName']!, // スキル名を表示
                            style: TextStyle(
                              fontFamily: 'makinas4',
                              fontSize: screenHeight * 0.02,
                              color: (myCards[_myBattleCardIndex]['used'] != 'true')
                                ? Colors.black
                                : const Color.fromARGB(255, 202, 202, 202),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ),
              ),
            ),

          if (nowSceneIndex > 3 && _enemyBattleCardIndex != -1 && nowSceneIndex < 7 && skillOpenWait && nowScene != 'declareOpen')
          Positioned(
                top: (_bannerAd?.size.height.toDouble() ?? 50.0) + (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25 + screenHeight * 0.03,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      enemySkillDetail = true;
                      _enemySelectedCardIndex = _enemyBattleCardIndex;
                    });
                  },
                child: Stack(
                  children: [
                    Image.asset(
                      'Images/button.png',
                      height: screenHeight * 0.07,
                      width: screenWidth * 0.6,
                      fit: BoxFit.fill,
                    ),
                    Positioned(
                          left: screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                          top: screenHeight * 0.009, // カードの上から48%下へ
                          child: Row(
                            children: [
                              Image.asset(
                                enemyCards[_enemyBattleCardIndex]['skill']!, // スキルの画像
                                height: screenHeight * 0.05,
                                width: screenHeight * 0.05,
                                fit: BoxFit.contain// スキルの画像のサイズ
                              ),
                              SizedBox(width: 5), // スキル名との間にスペースを追加
                              Text(
                                enemyCards[_enemyBattleCardIndex]['skillName']!, // スキル名を表示
                                style: TextStyle(
                                  fontFamily: 'makinas4',
                                  fontSize: screenHeight * 0.02,
                                  color: (enemyCards[_enemyBattleCardIndex]['used'] != 'true')
                                    ? Colors.black
                                    : const Color.fromARGB(255, 202, 202, 202),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    ),
                  ),
                ),


          Positioned( //相手の宣言ポイント
            top: (_bannerAd?.size.height.toDouble() ?? 50.0) + (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nowSceneIndex > 4 && nowScene != 'declareOpen' && nowScene != 'end')
                DeclarationDisplay(hand: enemyDeclareHand, points: enemyDeclarePoint.toString()),
                if (nowScene == 'battleSelect' || nowScene == 'skillSelect' || (nowScene == 'declareSelect' && skillOpenWait))
                 Padding(
                  padding: const EdgeInsets.only(left: 16.0, top:16.0), // 左側に16ピクセルの隙間を追加
                  child:
                  CircularCountdownTimer(
                    key: circularTimerKey,
                    initialTime: sceneTimer,
                    circleSize: 50,
                    circleColor: Colors.blue,
                    backgroundCircleColor: Colors.grey[300]!,
                  ),
                 ),
              ],
            ),
          ),

          Column(
            children: [
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: SizedBox(),
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
                    if (enemyCards.isNotEmpty && nowSceneIndex > -1)
                    SizedBox(
                      width: screenWidth * 0.6,
                      height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
                      child:
                      Stack (
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
                        ],
                      )
                    ),
                    if (enemyBattleState)
                    EnemyInfo(
                      screenWidth: screenWidth, screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0), name: enemyName, rank: enemyRank, point: enemyPoint, winPoint: winPoint, grid: enemyIcon,
                      onPressed: () => {
                        print('nameTapped!'),
                        setState(() {
                          optionButton = !(optionButton);
                          enemyInfoView = true;
                        })
                      }
                    ),
                    if (!enemyBattleState)
                    Spacer(),
                    if(!enemyBattleState)
                    Text('退出済み', style: TextStyle(fontFamily: 'makinas4'),),
                    if(!enemyBattleState)
                    Spacer(),
                  ]
                ),

              ),

              Container( // 真ん中の画面
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.5,
                width: screenWidth,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (currentRound > 0)
                        Text('ラウンド: ' + currentRound.toString() + ' / 5',
                        style: TextStyle(
                          fontFamily: 'makinas4',
                          fontSize: screenHeight * 0.03,
                        ),

                        textAlign: TextAlign.left,
                      ),

                      ],

                    ),

                    // if (optionButton)
                    // SingleChildScrollView(
                    //   scrollDirection: Axis.horizontal,
                    //   child: Row(
                    //     children: [
                    //       ElevatedButton(
                    //         onPressed: () => context.go('/onlineBattle'),
                    //         child: Text('onlineBattleへ'),
                    //       ),
                    //       Text(nowScene),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             sceneChange(nowSceneIndex != -1 ? scenes[nowSceneIndex]['seconds'] : scenes[0]['seconds']);
                    //           });
                    //         },
                    //         child: Text('start'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             _topPosition = _topPosition == 50 ? -500 : 50;
                    //           });
                    //         },
                    //         child: Text('敵発言'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             _bottomPosition = _bottomPosition == screenHeight *0.08 ? -500 : screenHeight * 0.08;
                    //           });
                    //         },
                    //         child: Text('自発言'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           skipCurrentScene();
                    //         },
                    //         child: Text('skip'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           retireBattle();
                    //         },
                    //         child: Text('retire'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           // すべてのカードを反転
                    //           for (var key in flipCardKeys) {
                    //             key.currentState?.flipCard();
                    //           }
                    //         },
                    //         child: Text('flip'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           enemySkillActiveToggle();
                    //           mySkillActiveToggle();
                    //           setState(() {
                    //             myDeclareHand = 'paper';
                    //           });
                    //         },
                    //         child: Text('両発動'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           for (int i = 0 ; i < 10 ; i++) {
                    //             Future.delayed(Duration(milliseconds: 50 * i), () {
                    //             setState(() {
                    //               myPoint += 10;
                    //             });
                    //             });
                    //           }
                    //         },
                    //         child: Text('ポイント追加'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             nowScene = 'start';
                    //           });
                    //         },
                    //         child: Text('start'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             nowScene = 'declareSelect';
                    //           });
                    //         },
                    //         child: Text('宣言選'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             nowScene = 'battleSelect';
                    //           });
                    //         },
                    //         child: Text('勝負選'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {
                    //             nowScene = 'battleOpen';

                    //             Future.delayed(Duration(milliseconds: 10), () {
                    //               slideInBoolToggle();
                    //             });
                    //           });
                    //         },
                    //         child: Text('勝負見'),
                    //       ),
                    //       ElevatedButton(
                    //         onPressed: () {
                    //           setState(() {

                    //           });
                    //         },
                    //         child: Text('start'),
                    //       ),


                    //     ],
                    //   ),
                    // ),


                    /* *********************
                    *********************
                      scene遷移の部分
                     **********************
                     **********************
                     */

                    if (nowScene == '')
                    Container(height:  screenHeight * 0.45,
                    child:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(enemyName,
                          style: TextStyle(fontSize: screenWidth * 0.08, color: const Color.fromARGB(255, 28, 28, 28),
                          fontFamily: 'makinas4',
                        ),
                        ),
                        if (enemyWinStreak > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              width: screenWidth * 0.1,
                              height: screenWidth * 0.1,
                              fit: BoxFit.contain,
                              'Images/skillActive.svg',
                            ),
                            Text('現在 $enemyWinStreak 連勝中',
                              style: TextStyle(fontSize: screenWidth * 0.08, color: const Color.fromARGB(255, 28, 28, 28),
                              fontFamily: 'makinas4',
                            ),
                            ),
                          ],
                        ),
                        Image.asset(
                          height: screenHeight * 0.23,

                          'Images/battleIcon.png'
                        ),
                        Text(myName,
                        style: TextStyle(fontSize: screenWidth * 0.08, color: const Color.fromARGB(255, 28, 28, 28),
                          fontFamily: 'makinas4',
                        ),
                        ),
                        if (myWinStreak > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              width: screenWidth * 0.1,
                              height: screenWidth * 0.1,
                              fit: BoxFit.contain,
                              'Images/skillActive.svg',
                            ),
                            Text('現在 $myWinStreak 連勝中',
                              style: TextStyle(fontSize: screenWidth * 0.08, color: const Color.fromARGB(255, 28, 28, 28),
                              fontFamily: 'makinas4',
                            ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),

                    if (nowScene == 'start')
                    Text(
                      'バトル\nスタート！！',
                      style: TextStyle(fontSize: screenWidth * 0.1, color: const Color.fromARGB(255, 28, 28, 28),
                        fontFamily: 'makinas4',
                      ),
                      textAlign: TextAlign.center
                    ),

                    if (nowScene == 'cardOpen' && nowEnemyOpenCardsName.isEmpty && nowMyOpenCardsName.isEmpty)
                    Text(
                      'オープンカードなし',
                      style: TextStyle(fontSize: screenWidth * 0.1, color: const Color.fromARGB(255, 28, 28, 28),
                        fontFamily: 'makinas4',
                      ),
                    ),

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

                    if (nowScene == 'declareOpen' && declareOpenWait)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SvgPicture.asset(
                              height: screenHeight * 0.1,
                              width: screenHeight * 0.1,
                              'Images/$enemyDeclareHand.svg'
                            ),
                            Text(
                              '${enemyDeclarePoint}pt',
                              style: TextStyle(fontSize: screenWidth * 0.16, color: const Color.fromARGB(255, 28, 28, 28),
                                fontFamily: 'makinas4',
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.1),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.1,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: screenWidth * 0.1),
                            SvgPicture.asset(
                              height: screenHeight * 0.1,
                              width: screenHeight * 0.1,
                              'Images/$myDeclareHand.svg'
                            ),
                            Text(
                              '${myDeclarePoint}pt',
                              style: TextStyle(fontSize: screenWidth * 0.16, color: const Color.fromARGB(255, 28, 28, 28),
                                fontFamily: 'makinas4',
                              ),
                            )
                          ],
                        ),
                      ],
                    ),

                    if (nowScene == 'declareOpen' && !declareOpenWait)
                    Text(
                      '何を宣言したのか？',
                      style: TextStyle(fontSize: screenWidth * 0.08, color: const Color.fromARGB(255, 28, 28, 28),
                        fontFamily: 'makinas4',
                      ),
                    ),

                    if (nowScene == 'battleOpen' && !battleWait) Container(
                      height: screenHeight* 0.19,
                      width: screenWidth,
                      child:EnemySlideInStack(screenHeight: screenHeight, screenWidth: screenWidth, isVisible: slideInBool, handType: enemyBattleHand, skillNo: enemyBattleSkillNo,),
                    ),

                    if (nowScene == 'battleOpen' && !battleWait)  Container(
                      height: screenHeight* 0.19,
                      width: screenWidth,
                      child:MySlideInStack(screenHeight: screenHeight, screenWidth: screenWidth, isVisible: slideInBool, handType: myBattleHand, skillNo: myBattleSkillNo,),
                    ),

                    if (nowScene == 'skillOpen' && mySkillActive == false && enemySkillActive == false && skillResultView)
                    Text(
                      'スキル発動なし',
                      style: TextStyle(fontSize: screenWidth * 0.1, color: const Color.fromARGB(255, 28, 28, 28),
                        fontFamily: 'makinas4',
                      ),
                    ),

                    if (nowScene == 'resultOpen') //ポイント変動を表すView
                    Column(
                      children: [
                        // Enemy Point Display
                        SizedBox(height: screenHeight * 0.17,
                        child:
                        Column(
                          children: [
                            Text(
                              '${previousEnemyPoint} → ${enemyPoint.toString()}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.1,
                                color: const Color.fromARGB(255, 28, 28, 28),
                                fontFamily: 'makinas4',
                              ),
                            ),
                            if (nowScene == 'resultOpen' && enemyChangePointView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    enemyChangePoint > 0
                                        ? '+${enemyChangePoint.toString()}pt'
                                        : '${enemyChangePoint.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: enemyChangePoint > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                            if (nowScene == 'resultOpen' && enemyChangeEnemySkillView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Images/$enemyBattleSkillNo.png',
                                    height: screenWidth * 0.1,
                                    width: screenWidth * 0.1,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    enemyChangeEnemySkill > 0
                                        ? '+${enemyChangeEnemySkill.toString()}pt'
                                        : '${enemyChangeEnemySkill.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: enemyChangeEnemySkill > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                            if (nowScene == 'resultOpen' && enemyChangeMySkillView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Images/$myBattleSkillNo.png',
                                    height: screenWidth * 0.1,
                                    width: screenWidth * 0.1,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    enemyChangeMySkill > 0
                                        ? '+${enemyChangeMySkill.toString()}pt'
                                        : '${enemyChangeMySkill.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: enemyChangeMySkill > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        ),

                        SizedBox(height: screenWidth * 0.06), // Enemy and My Points spacing

                        // My Point Display
                        if (nowScene == 'resultOpen')
                        SizedBox(height: screenHeight * 0.17,
                        child:
                        Column(
                          children: [
                            Text(
                              '${previousMyPoint} → ${myPoint.toString()}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.1,
                                color: const Color.fromARGB(255, 28, 28, 28),
                                fontFamily: 'makinas4',
                              ),
                            ),
                            if (nowScene == 'resultOpen' && myChangePointView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    myChangePoint > 0
                                        ? '+${myChangePoint.toString()}pt'
                                        : '${myChangePoint.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: myChangePoint > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                            if (nowScene == 'resultOpen' && myChangeMySkillView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Images/$myBattleSkillNo.png',
                                    height: screenWidth * 0.1,
                                    width: screenWidth * 0.1,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    myChangeMySkill > 0
                                        ? '+${myChangeMySkill.toString()}pt'
                                        : '${myChangeMySkill.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: myChangeMySkill > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                            if (nowScene == 'resultOpen' && myChangeEnemySkillView)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Images/$enemyBattleSkillNo.png',
                                    height: screenWidth * 0.1,
                                    width: screenWidth * 0.1,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    myChangeEnemySkill > 0
                                        ? '+${myChangeEnemySkill.toString()}pt'
                                        : '${myChangeEnemySkill.toString()}pt',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.15,
                                      fontWeight: FontWeight.bold,
                                      color: myChangeEnemySkill > 0
                                          ? const Color.fromARGB(255, 42, 194, 0)
                                          : const Color.fromARGB(255, 181, 12, 12),
                                      fontFamily: 'makinas4',
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        ),

                      ],
                    ),
                    if (nowScene == 'end')
                    Text('自$myPoint pt  V.S. 敵$enemyPoint pt',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'makinas4',
                      ),
                    ),
                    if (nowScene == 'end' && battleResult == 'win')
                    WaveText(text: 'You WIN!'),
                    if (nowScene == 'end' && battleResult == 'win' && enemyRetireState)
                    Text('相手は勝負を降りました。',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontFamily: 'makinas4',
                      ),
                    ),
                    if (nowScene == 'end' && battleResult == 'win')
                    AnimatedBattleResultUI(
                      battleResult: battleResult, // 'win' または 'lose'
                      myRank: myRankJapan, // 現在のランク
                      myLevel: myLevel, // 現在のレベル
                      myLevelExp: myLevelExp, // 現在の経験値
                      myRankCount: myRankCount, // 現在のランクポイント
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onPressed: _changeRoutePass,
                    ),

                    if (nowScene == 'end' && battleResult == 'lose')
                    WaveText(text: 'You LOSE!'),
                    if (nowScene == 'end' && battleResult == 'lose')
                    AnimatedBattleResultUI(
                      battleResult: battleResult, // 'win' または 'lose'
                      myRank: myRankJapan, // 現在のランク
                      myLevel: myLevel, // 現在のレベル
                      myLevelExp: myLevelExp, // 現在の経験値
                      myRankCount: myRankCount, // 現在のランクポイント
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onPressed: _changeRoutePass,
                    ),

                    if (nowScene == 'end' && battleResult == 'draw')
                    WaveText(text: 'DRAW!'),
                    if (nowScene == 'end' && battleResult == 'draw')
                    AnimatedBattleResultUI(
                      battleResult: battleResult, // 'win' または 'lose'
                      myRank: myRankJapan, // 現在のランク
                      myLevel: myLevel, // 現在のレベル
                      myLevelExp: myLevelExp, // 現在の経験値
                      myRankCount: myRankCount, // 現在のランクポイント
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onPressed: _changeRoutePass,
                    ),

                    if (nowScene == 'end' && battleResult == 'knockOut')
                    WaveText(text: 'ノックアウト!!'),
                    if (nowScene == 'end' && battleResult == 'knockOut')
                    AnimatedBattleResultUI(
                      battleResult: battleResult, // 'win' または 'lose'
                      myRank: myRankJapan, // 現在のランク
                      myLevel: myLevel, // 現在のレベル
                      myLevelExp: myLevelExp, // 現在の経験値
                      myRankCount: myRankCount, // 現在のランクポイント
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onPressed: _changeRoutePass,
                    ),
                  ],
                ),
              ),

              if (nowScene != 'end')
              Container( // 下4分の１の画面下4分の１の画面
                height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
                width: screenWidth,
                child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyInfo(
                      screenWidth: screenWidth, screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0), name: myName, rank: myRank, point: myPoint, winPoint: winPoint, grid: myIcon,
                      onPressed: () => {
                        print('nameTapped!'),
                        setState(() {
                          myInfoView = true;
                        }),

                      }
                      ),
                    if (nowSceneIndex > -1)
                    SizedBox(
                      width: screenWidth * 0.6,
                      height: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
                      child:
                      Stack (
                        children: [
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
                  ]
                )
              ),
            ],
          ),

          if (nowScene == 'battleSelect')
          Positioned(
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25 + screenHeight * 0.07 + 10,
            child:
            BattleHandSelection(
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              onRockSelected: () {
                setState(() {
                  myBattleHand = 'rock';
                  setBattleHand();
                });
              },
              onScissorsSelected: () {
                setState(() {
                  myBattleHand = 'scissor';
                  setBattleHand();
                });
              },
              onPaperSelected: () {
                setState(() {
                  myBattleHand = 'paper';
                  setBattleHand();
                });
              },
            ),
          ),

          if (nowScene == 'skillSelect')
            Positioned(
              bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25 + screenHeight * 0.07 + 10,
              child:
              Container(
                child:
                Column(
                  children: [
                    SkillSelection(cards: myCards, battleIndex: _myBattleCardIndex, screenHeight: screenHeight, screenWidth: screenWidth),
                    if (_myBattleCardIndex != -1)
                    CustomImageButton(screenWidth: screenWidth, buttonText: mySkipState ? '決定済' : '決定', onPressed: () => {setState(() {mySkipState = true;}), setSkipState(true)})
                  ]
                )
              )
            ),

          if (nowScene == 'declareSelect')
          Positioned(
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25 + screenHeight * 0.07 + 10,
            child:
            DeclareHandSelection(
              screenHeight: screenHeight,
              screenWidth: screenWidth,
              onRockSelected: () {
                setState(() {
                  myDeclareHand = 'rock';
                  setDeclareHand();
                });
              },
              onScissorsSelected: () {
                setState(() {
                  myDeclareHand = 'scissor';
                  setDeclareHand();
                });
              },
              onPaperSelected: () {
                setState(() {
                  myDeclareHand = 'paper';
                  setDeclareHand();
                });
              },
              onPointSelected: (int point) {
                setState(() {
                  myDeclarePoint = point; // ポイントを設定
                  setDeclarePoint();
                });
              },
            ),
          ),
          if (battleWait)
          Positioned(
            bottom: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25 + screenHeight * 0.07 + 10,
            child:
            Container(
              width: screenWidth,
              child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '勝負の結果は？',
                  style: TextStyle(fontSize: screenWidth * 0.08, color: Colors.black,
                    fontFamily: 'makinas4',
                  ),
                ),
              ]
             ),
            )
          ),


          Positioned( // battleLogの表示
            left: 0,
            top: (_bannerAd?.size.height.toDouble() ?? 50.0) + (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.25,
            width: screenWidth, // スライドビューの幅を指定します（画面の75％に設定）
            height: (screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0)) * 0.5, // 高さを画面全体に指定
            child:
            SlideView(
              screenWidth: screenWidth,
              screenHeight: screenHeight - (_bannerAd?.size.height.toDouble() ?? 50.0),
              isSlideViewVisible: isSlideViewVisible,
              onToggleSlideView: () => {
                setState(() {
                  isSlideViewVisible = !isSlideViewVisible;
                })
                },
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: screenWidth* 0.38,
                                    child:
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                            Positioned(
                                              bottom: screenWidth * 0.05,
                                              left: 0, // 右下に配置
                                              child:
                                              Text(
                                                log['myHonest'] == 'true' ? '真' : '嘘',
                                                style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black,
                                                  fontFamily: 'makinas4',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: screenWidth * 0.38, // 幅を制限
                                        child: Text(
                                          log['mySkillEffect']!,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.037,
                                            color: Colors.black,
                                            fontFamily: 'makinas4',
                                          ),
                                          textAlign: TextAlign.start, // 左揃えで改行
                                          softWrap: true, // 自動で改行
                                          overflow: TextOverflow.visible, // 残り部分も表示
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),

                                  SizedBox(
                                    width: screenWidth * 0.4,
                                    child:
                                    Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                            Positioned(
                                              bottom: screenWidth * 0.05,
                                              left: 0, // 右下に配置
                                              child:
                                              Text(
                                                log['enemyHonest'] == 'true' ? '真' : '嘘',
                                                style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.black,
                                                  fontFamily: 'makinas4',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: screenWidth * 0.4, // 幅を制限
                                        child: Text(
                                          log['enemySkillEffect']!,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.037,
                                            color: Colors.black,
                                            fontFamily: 'makinas4',
                                          ),
                                          textAlign: TextAlign.start, // 左揃えで改行
                                          softWrap: true, // 自動で改行
                                          overflow: TextOverflow.visible, // 残り部分も表示
                                        ),
                                      ),
                                    ],
                                  ),
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

          if (nowScene == 'skillSelect' && mySkillOptionView && (myCards[_mySelectedCardIndex]['no'] == 'No40' || myCards[_mySelectedCardIndex]['no'] == 'No27')) //optionありスキルの選択画面
          Positioned(
            bottom: screenHeight * 0.3,
            left: screenWidth * 0.1,
            child:
            Column(
              children: [
                SkillListWidget(
                  skills: skills, // 提供されたスキルリスト
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                  mySkillSelect: mySkillSelect,
                  onSkillSelected: (String selectedNo) {
                    setState(() {
                      mySkillSelect = selectedNo;
                      setSkillSelect();
                    });
                    print('選択されたスキル: $mySkillSelect');
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '決定',
                    onPressed: () => {
                      setState(() {
                        mySkillOptionView = false;
                        _myBattleCardIndex = _mySelectedCardIndex;
                        myBattleSkillNo = myCards[_myBattleCardIndex]['no'] ?? 'No0';
                        setBattleSkill();
                      })
                    }
                  ),
                    SizedBox(width: screenWidth * 0.1),
                    CustomImageButton(
                      screenWidth: screenWidth,
                      buttonText: '閉じる',
                      onPressed: () => {
                        setState(() {
                          mySkillOptionView = false;
                        })
                      }
                    ),
                  ]
                ),
              ]
            )
          ),

          if (nowScene == 'skillSelect' && mySkillOptionView && (myCards[_mySelectedCardIndex]['no'] == 'No22')) //optionありスキルの選択画面
          Positioned(
            bottom: screenHeight * 0.3,
            left: screenWidth * 0.1,
            child:
            Column(
              children: [
                HandListWidget(
                  screenHeight: MediaQuery.of(context).size.height,
                  screenWidth: MediaQuery.of(context).size.width,
                  mySkillSelect: mySkillSelect,
                  onSkillSelected: (hand) {
                    setState(() {
                      mySkillSelect = hand;
                      setSkillSelect();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '決定',
                    onPressed: () => {
                      setState(() {
                        mySkillOptionView = false;
                        _myBattleCardIndex = _mySelectedCardIndex;
                        myBattleSkillNo = myCards[_myBattleCardIndex]['no'] ?? 'No0';
                        setBattleSkill();
                      })
                    }
                  ),
                    SizedBox(width: screenWidth * 0.1),
                    CustomImageButton(
                      screenWidth: screenWidth,
                      buttonText: '閉じる',
                      onPressed: () => {
                        setState(() {
                          mySkillOptionView = false;
                        })
                      }
                    ),
                  ]
                ),
              ]
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
                if (mySkillDetail && nowScene == 'skillSelect' && myCards[_mySelectedCardIndex]['used'] == 'false') CustomImageButton(
                  screenWidth: screenWidth,
                  buttonText: '決定',
                  onPressed: () => {
                    setState(() {
                      mySkillDetail = false;
                      if (optionSkilNoList.contains(myCards[_mySelectedCardIndex]['no'])) {
                        mySkillOptionView = true;
                      } else {
                        _myBattleCardIndex = _mySelectedCardIndex;
                        myBattleSkillNo = myCards[_myBattleCardIndex]['no'] ?? 'No0';
                        setBattleSkill();
                      }

                    })
                  }
                  ),
                SizedBox(width: screenWidth * 0.1),
                if (mySkillDetail) CustomImageButton(
                  screenWidth: screenWidth,
                  buttonText: '閉じる',
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
                  buttonText: '閉じる',
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

          if (commentListView && myCommentList.isNotEmpty)
          Positioned(
            bottom: screenHeight * 0.5,
            right: 0,
            child:
            Container(
              height: screenHeight * 0.4, // 高さの制限
              width: screenWidth * 0.4,  // 幅の制限
              child: ListView.builder(
                itemCount: myCommentList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        commentListView = false;
                        print('commnet');
                        showMyComment(myCommentList[index]);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: CommentText(
                        screenWidth: screenWidth,
                        text: myCommentList[index],
                        angryComments: angryComments,
                        happyComments: happyComments,
                        chickenComments: chickenComments,
                        coolComments: coolComments,
                        hakuryokuComments: hakuryokuComments,
                        thinkComments: thinkComments,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if(myInfoView)
          Positioned(
            top: screenHeight * 0.1,
            left: screenWidth * 0.05,
            child:
            Column(children: [
              UserInfoView(
                userName: myName,
                userRank: myRank,
                userRankJapan: myRankJapan,
                userRockRate: myRockRate,
                userScissorRate: myScissorRate,
                userPaperRate: myPaperRate,
                userHonestRate: myHonestRate,
                userWinRate: myWinRate,
                userIcon: myIcon,
                userWinStreak: myWinStreak,
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              Row(
                children: [
                  CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '降参',
                    onPressed: () => {
                      setState(() {
                        myRetireView = true;
                        myInfoView = false;
                      })
                    }
                  ),
                  CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '閉じる',
                    onPressed: () => {
                      setState(() {
                        myInfoView = false;
                      })
                    }
                  ),
                ],
              ),
            ],
            )
          ),

          if (myRetireView)
          Positioned(
            top: screenHeight * 0.4,
            left: screenWidth * 0.1,
            child: RetireWidget(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            onSkillSelected: (bool isRetire) {
              setState(() {
                if (isRetire) {
                  setRetireState();
                  myRetireState = true; // 「諦める」が選択された
                  myRetireView = false;
                  sceneChange(1);
                } else {
                  myRetireView = false; // 「戦う」が選択された
                }
              });
            },
          ),
          ),

          if (enemyInfoView)
          Positioned(
            top: screenHeight * 0.1,
            left: screenWidth * 0.05,
            child:
            Column(
              children: [
              UserInfoView(
                userName: enemyName,
                userRank: enemyRank,
                userRankJapan: enemyRankJapan,
                userRockRate: enemyRockRate,
                userScissorRate: enemyScissorRate,
                userPaperRate: enemyPaperRate,
                userHonestRate: enemyHonestRate,
                userWinRate: enemyWinRate,
                userIcon: enemyIcon,
                userWinStreak: enemyWinStreak,
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              Row(
                children: [
                  CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '降参',
                    onPressed: () => {
                      setState(() {
                        myRetireView = true;
                        enemyInfoView = false;
                      })
                    }
                  ),
                  CustomImageButton(
                    screenWidth: screenWidth,
                    buttonText: '閉じる',
                    onPressed: () => {
                      setState(() {
                        enemyInfoView = false;
                      })
                    }
                  ),
                ],
              ),
              ],
            )
          ),

          AnimatedPositioned(
            duration: Duration(seconds: 1), // アニメーションの時間
            curve: Curves.easeInOut, // アニメーションの動き
            top: _topPosition, // 現在の位置
            right: 0,
            child: EnemyCommentText(
              screenWidth: screenWidth,
              text: enemyComment,
              angryComments: angryComments,
              happyComments: happyComments,
              chickenComments: chickenComments,
              coolComments: coolComments,
              hakuryokuComments: hakuryokuComments,
              thinkComments: thinkComments,
            ),
          ),

          AnimatedPositioned(
            duration: Duration(seconds: 1), // アニメーションの時間
            curve: Curves.easeInOut, // アニメーションの動き
            bottom: screenHeight * _bottomPosition, // 現在の位置
            left: 0,
            child: CommentText(
              screenWidth: screenWidth,
              text: myComment,
              angryComments: angryComments,
              happyComments: happyComments,
              chickenComments: chickenComments,
              coolComments: coolComments,
              hakuryokuComments: hakuryokuComments,
              thinkComments: thinkComments,
            ),
          ),


        ]
      ),
    );
  }

  void checkMySkillActive (String skillNo, String otherSkillNo, String battleHand, String declareHand, String otherBattleHand, String otherDeclareHand, int point, int otherPoint, int declarePoint, int otherDeclarePoint, String skillSelect, String otherSkillSelect, List<Map<String, String>> cards, List<Map<String, String>> otherCards) {
    if (otherSkillNo != 'No30') { //相手がスキル封印でない場合
    switch (skillNo) {
      case 'No1': //硬い拳
      if (battleHand == 'rock' && handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No2': //硬い掌
      if (battleHand == 'paper' && handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No3': //硬い指
      if (battleHand == 'scissor' && handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No4': //相打ちの極意
      if (battleHand == otherBattleHand) {
        mySkillActive = true;
      }
      break;

      case 'No5': //拳砕き
      if ('rock' == otherBattleHand) {
        mySkillActive = true;
      }
      break;

      case 'No6': //掌やぶり
      if ('paper' == otherBattleHand) {
        mySkillActive = true;
      }
      break;

      case 'No7': //刀折り
      if ('scissor' == otherBattleHand) {
        mySkillActive = true;

      }
      break;

      case 'No8': //連勝ボーナス
      int winStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'win') {
          winStreak++;
        } else {
          break;
        }
      }
      if (winStreak > 1) {
        mySkillActive = true;
      }
      break;

      case 'No9': //救済措置 連敗
      int loseStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'lose') {
          loseStreak++;
        } else {
          break;
        }
      }
      if (loseStreak > 1) {
        mySkillActive = true;
      }
      break;

      case 'No10': //平和主義 アイコ連続
      int drawStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'draw') {
          drawStreak++;
        } else {
          break;
        }
      }
      if (drawStreak > 1) {
        mySkillActive = true;
      }
      break;

      case 'No11': //宣教師　宣言した手で勝つ
      if (handResult == 'win' && declareHand == battleHand) {
        mySkillActive = true;
      }
      break;

      case 'No12': //ライアー　宣言していない手でかつ
      if (handResult == 'win' && declareHand != battleHand) {
        mySkillActive = true;
      }
      break;

      case 'No13': //不幸中の幸い 3連敗
      int loseStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'lose') {
          loseStreak++;
        } else {
          break;
        }
      }
      if (loseStreak == 3) {
        mySkillActive = true;
      }
      break;

      case 'No14': //追い風　３連勝
      int winStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'win') {
          winStreak++;
        } else {
          break;
        }
      }
      if (winStreak == 3) {
        mySkillActive = true;
      }
      break;

      case 'No15': //均衡崩壊 アイコかつ宣言とは違う手を出す
      if (handResult == 'draw' && battleHand != declareHand) {
        mySkillActive = true;
      }
      break;

      case 'No16': //ギャンブラー
        mySkillActive = true;
      break;

      case 'No17': //会心の一撃
      if (handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No18': //不変の意志
      String? latestHand = battleLog.last['myHand'];
      int count = 0;
      for (var log in battleLog.reversed) {
        if (log['myHand'] == latestHand) {
          count++;
        } else {
          break;
        }
      }
      if (count > 1) {
        mySkillActive = true;
      }
      break;

      case 'No19': //疾風怒濤　開始2ラウンド以内
      if (currentRound < 3 && declareHand == battleHand) {
        mySkillActive = true;
      }
      break;

      case 'No20': //不屈の闘志 自分のポイントが敵より少ない時
      if (point < otherPoint && handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No21': //冥土の土産 勝った時
      if (handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No22': //預言者　相手の出す手を当てる
      if (mySkillSelect == otherBattleHand) {
        mySkillActive = true;
      }
      break;

      case 'No23': //超アーマー
      if (handResult == 'lose') {
        mySkillActive = true;
      }
      break;

      case 'No24': //縛りプレイ
        mySkillActive = true;
      break;

      case 'No25': //痛み分け
      if (handResult == 'lose') {
        mySkillActive = true;
      }
      break;

      case 'No26': //収益停止
      if (handResult == 'lose') {
        mySkillActive = true;
      }
      break;

      case 'No27': //読心術
      if (skillSelect == otherSkillNo) {
        mySkillActive = true;
      }
      break;

      case 'No28': //変幻自在
        mySkillActive = true;
      break;

      case 'No29': //ミストラル
        mySkillActive = true;
      break;

      case 'No30': //スキル封印
        mySkillActive = true;
      break;

      case 'No31': //自由奔放
        mySkillActive = true;
      break;

      case 'No32': //貿易の怒り
        mySkillActive = true;
      break;

      case 'No33': //秘密の共有
      if (currentRound >= 3) {
        mySkillActive = true;
      }
      break;

      case 'No34': //かくれんぼ
        mySkillActive = true;
      break;

      case 'No35': //でしゃばり
      break;

      case 'No36': //公開処刑
        mySkillActive = true;
      break;

      case 'No37': //羞恥心
      final matchingSkill = cards.firstWhere(
        (skill) => skill['no'] == skillNo,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty && matchingSkill['open'] == 'false') {
        mySkillActive = true;
      }
      break;

      case 'No38': //露出狂
      final matchingSkill = cards.firstWhere(
        (skill) => skill['no'] == skillNo,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty && matchingSkill['open'] == 'true') {
        mySkillActive = true;
      }
      break;

      case 'No39': //リバイバル
        mySkillActive = true;
      break;

      case 'No40': //存在抹消
      final matchingSkill = otherCards.firstWhere(
        (skill) => skill['open'] == 'false' && skill['no'] == skillSelect,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty) {
        mySkillActive = true;
      }
      break;

      case 'No41': //嘘は嫌い　自分は宣言、　相手は宣言以外
      if (battleHand == declareHand && otherBattleHand != otherDeclareHand) {
        mySkillActive = true;
      }
      break;

      case 'No42': //真実の加護
      if (battleHand == declareHand) {
        mySkillActive = true;
      }
      break;

      case 'No43': //生命保険
      if (handResult == 'win') {
        mySkillActive = true;
      }
      break;

      case 'No44': //墓あらし
      if (currentRound > 1) {
        mySkillActive = true;
      }
      break;

      case 'No45': //初志貫徹
      if (battleLog.length > 1) {
        battleLog;
        bool flug = true;
        for (int i = 0; i < battleLog.length - 1; i++) {
          if (battleLog[i]['myHonest'] == 'false') {
            flug = false;
          }
        }
        if (flug) {
          mySkillActive = true;
        }
      }
      break;

      case 'No46': //インフレ防止
        mySkillActive = true;
      break;

      case 'No47': //カオス
        mySkillActive = true;
      break;

      case 'No48': //盗賊の極意
        mySkillActive = true;
      break;

      case 'No49': //過去の階層
      if (currentRound >= 3) {
        int number = 0;
        int otherNumber = 0;
        for (int i = 0; i < otherCards.length; i++) {
          if (otherCards[i]['used'] == 'true') {
            otherNumber ++;
          }
        }
        for (int i = 0; i < cards.length; i++) {
          if (cards[i]['used'] == 'true') {
            number ++;
          }
        }
        if (number >= 2 && otherNumber >= 2) {
          mySkillActive = true;
        }
      }
      break;

      case 'No50': //人生革命
      if (currentRound <= 3 && point < otherPoint) {
        mySkillActive = true;
      }
      break;

      case 'R':
      if (otherSkillNo == 'K'){
        mySkillActive = true;
      }
      break;

      case 'K':
      if (otherSkillNo != 'R'){
        mySkillActive = true;
      }
      break;
      }
    }
  }

  void checkEnemySkillActive (String skillNo, String otherSkillNo, String battleHand, String declareHand, String otherBattleHand, String otherDeclareHand, int point, int otherPoint, int declarePoint, int otherDeclarePoint, String skillSelect, String otherSkillSelect, List<Map<String, String>> cards, List<Map<String, String>> otherCards) {
    if (otherSkillNo != 'No30') { //相手がスキル封印でない場合
    switch (skillNo) {
      case 'No1': //硬い拳
      if (battleHand == 'rock' && handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No2': //硬い掌
      if (battleHand == 'paper' && handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No3': //硬い指
      if (battleHand == 'scissor' && handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No4': //相打ちの極意
      if (battleHand == otherBattleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No5': //拳砕き
      if ('rock' == otherBattleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No6': //掌やぶり
      if ('paper' == otherBattleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No7': //刀折り
      if ('scissor' == otherBattleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No8': //連勝ボーナス
      int winStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'lose') {
          winStreak++;
        } else {
          break;
        }
      }
      if (winStreak > 1) {
        enemySkillActive = true;
      }
      break;

      case 'No9': //救済措置 連敗
      int loseStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'win') {
          loseStreak++;
        } else {
          break;
        }
      }
      if (loseStreak > 1) {
        enemySkillActive = true;
      }
      break;

      case 'No10': //平和主義 アイコ連続
      int drawStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'draw') {
          drawStreak++;
        } else {
          break;
        }
      }
      if (drawStreak > 1) {
        enemySkillActive = true;
      }
      break;

      case 'No11': //宣教師　宣言した手で勝つ
      if (handResult == 'lose' && declareHand == battleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No12': //ライアー　宣言していない手でかつ
      if (handResult == 'lose' && declareHand != battleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No13': //不幸中の幸い 3連敗
      int loseStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'win') {
          loseStreak++;
        } else {
          break;
        }
      }
      if (loseStreak == 3) {
        enemySkillActive = true;
      }
      break;

      case 'No14': //追い風　３連勝
      int winStreak = 0;
      for (var log in battleLog.reversed) {
        if (log['result'] == 'lose') {
          winStreak++;
        } else {
          break;
        }
      }
      if (winStreak == 3) {
        enemySkillActive = true;
      }
      break;

      case 'No15': //均衡崩壊 アイコかつ宣言とは違う手を出す
      if (handResult == 'draw' && battleHand != declareHand) {
        enemySkillActive = true;
      }
      break;

      case 'No16': //ギャンブラー
        enemySkillActive = true;
      break;

      case 'No17': //会心の一撃
      if (handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No18': //不変の意志
      String? latestHand = battleLog.last['enemyHand'];
      int count = 0;
      for (var log in battleLog.reversed) {
        if (log['enemyHand'] == latestHand) {
          count++;
        } else {
          break;
        }
      }
      if (count > 1) {
        enemySkillActive = true;
      }
      break;

      case 'No19': //疾風怒濤　開始2ラウンド以内
      if (currentRound < 3 && declareHand == battleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No20': //不屈の闘志 自分のポイントが敵より少ない時
      if (point < otherPoint && handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No21': //冥土の土産 勝った時
      if (handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No22': //預言者　相手の出す手を当てる
      if (skillSelect == otherBattleHand) {
        enemySkillActive = true;
      }
      break;

      case 'No23': //超アーマー
      if (handResult == 'win') {
        enemySkillActive = true;
      }
      break;

      case 'No24': //縛りプレイ
        enemySkillActive = true;
      break;

      case 'No25': //痛み分け
      if (handResult == 'win') {
        enemySkillActive = true;
      }
      break;

      case 'No26': //収益停止
      if (handResult == 'win') {
        enemySkillActive = true;
      }
      break;

      case 'No27': //読心術
      if (skillSelect == otherSkillNo) {
        enemySkillActive = true;
      }
      break;

      case 'No28': //変幻自在
        enemySkillActive = true;
      break;

      case 'No29': //ミストラル
        enemySkillActive = true;
      break;

      case 'No30': //スキル封印
        enemySkillActive = true;
      break;

      case 'No31': //自由奔放
        enemySkillActive = true;
      break;

      case 'No32': //貿易の怒り
        enemySkillActive = true;
      break;

      case 'No33': //秘密の共有
      if (currentRound >= 3) {
        enemySkillActive = true;
      }
      break;

      case 'No34': //かくれんぼ
        enemySkillActive = true;
      break;

      case 'No35': //でしゃばり
      break;

      case 'No36': //公開処刑
        enemySkillActive = true;
      break;

      case 'No37': //羞恥心
      final matchingSkill = cards.firstWhere(
        (skill) => skill['no'] == skillNo,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty && matchingSkill['open'] == 'false') {
        enemySkillActive = true;
      }
      break;

      case 'No38': //露出狂
      final matchingSkill = cards.firstWhere(
        (skill) => skill['no'] == skillNo,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty && matchingSkill['open'] == 'true') {
        enemySkillActive = true;
      }
      break;

      case 'No39': //リバイバル
        enemySkillActive = true;
      break;

      case 'No40': //存在抹消
      final matchingSkill = otherCards.firstWhere(
        (skill) => skill['open'] == 'false' && skill['no'] == skillSelect,
        orElse: () => {},
      );
      if (matchingSkill.isNotEmpty) {
        enemySkillActive = true;
      }
      break;

      case 'No41': //嘘は嫌い　自分は宣言、　相手は宣言以外
      if (battleHand == declareHand && otherBattleHand != otherDeclareHand) {
        enemySkillActive = true;
      }
      break;

      case 'No42': //真実の加護
      if (battleHand == declareHand) {
        enemySkillActive = true;
      }
      break;

      case 'No43': //生命保険
      if (handResult == 'lose') {
        enemySkillActive = true;
      }
      break;

      case 'No44': //墓あらし
      if (currentRound > 1) {
        enemySkillActive = true;
      }
      break;

      case 'No45': //初志貫徹
      if (battleLog.length > 1) {
        battleLog;
        bool flug = true;
        for (int i = 0; i < battleLog.length - 1; i++) {
          if (battleLog[i]['enemyHonest'] == 'false') {
            flug = false;
          }
        }
        if (flug) {
          enemySkillActive = true;
        }
      }
      break;

      case 'No46': //インフレ防止
        enemySkillActive = true;
      break;

      case 'No47': //カオス
        enemySkillActive = true;
      break;

      case 'No48': //盗賊の極意
        enemySkillActive = true;
      break;

      case 'No49': //過去の階層
      if (currentRound >= 3) {
        int number = 0;
        int otherNumber = 0;
        for (int i = 0; i < otherCards.length; i++) {
          if (otherCards[i]['used'] == 'true') {
            otherNumber ++;
          }
        }
        for (int i = 0; i < cards.length; i++) {
          if (cards[i]['used'] == 'true') {
            number ++;
          }
        }
        if (number >= 2 && otherNumber >= 2) {
          enemySkillActive = true;
        }
      }
      break;

      case 'No50': //人生革命
      if (currentRound <= 3 && point < otherPoint) {
        enemySkillActive = true;
      }
      break;

      case 'R':
      if (otherSkillNo == 'K'){
        enemySkillActive = true;
      }
      break;

      case 'K':
      if (otherSkillNo != 'R'){
       enemySkillActive = true;
      }
      break;
      }
    }
  }

  void performMySkillEffect(String skillNo, String otherSkillNo, String battleHand, String declareHand, String otherBattleHand, String otherDeclareHand, int point, int otherPoint, int changeSkill, int changeOtherSkill, int otherChangeSkill, int otherChangeOtherSkill, int declarePoint, int otherDeclarePoint, String skillSelect, String otherSkillSelect, List<Map<String, String>> cards, List<Map<String, String>> otherCards) {
    changeSkill = 0;
    otherChangeSkill = 0;
    switch (skillNo) {
    case 'No1': //硬い拳
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No2': //硬い掌
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No3': //硬い指
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No4': //相打ちの極意
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No5': //拳砕き
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No6': //掌やぶり
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No7': //刀折り
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No8': //連勝ボーナス
    int winStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'win') {
        winStreak++;
      } else {
        break;
      }
    }
    if (winStreak > 1) {
      changeSkill = winStreak * 10;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    }
    break;

    case 'No9': //救済措置 連敗
    int loseStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'lose') {
        loseStreak++;
      } else {
        break;
      }
    }
    if (loseStreak > 1) {
      changeSkill = loseStreak * 10;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    }
    break;

    case 'No10': //平和主義 アイコ連続
    int drawStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'draw') {
        drawStreak++;
      } else {
        break;
      }
    }
    if (drawStreak > 1) {
        changeSkill = drawStreak * 10;
        point += changeSkill;
        reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
      }
    break;

    case 'No11': //宣教師　宣言した手で勝つ
    setState(() {
      changeSkill = 30;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No12': //ライアー　宣言していない手でかつ
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No13': //不幸中の幸い 3連敗
    setState(() {
      otherChangeSkill = -70;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No14': //追い風　３連勝
    setState(() {
      changeSkill = 50;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No15': //均衡崩壊 アイコかつ宣言とは違う手を出す
    setState(() {
      changeSkill = 20;
      if (otherBattleHand == otherDeclareHand) {
        otherChangeSkill = -(20 + otherDeclarePoint);
      } else {
        otherChangeSkill = -20;
      }
      point += changeSkill;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。${enemyName}に${otherChangeSkill}ptした。');
    });
    break;

    case 'No16': //ギャンブラー
    int? selectedNumber = int.tryParse(mySkillRandom);
    if (selectedNumber != null) {
    setState(() {
      if (selectedNumber > 91) {
        changeSkill = -50;
        point += changeSkill;
      } else if (selectedNumber > 78) {
        changeSkill = 40;
        point += changeSkill;
      } else if (selectedNumber > 65) {
        changeSkill = 30;
        point += changeSkill;
      } else if (selectedNumber > 52) {
        changeSkill = 20;
        point += changeSkill;
      } else if (selectedNumber > 39) {
        changeSkill = 10;
        point += changeSkill;
      } else if (selectedNumber > 26) {
        otherChangeSkill = -30;
        otherPoint += otherChangeSkill;
      } else if (selectedNumber > 13) {
        otherChangeSkill = -20;
        otherPoint += otherChangeSkill;
      } else if (selectedNumber > 0) {
        otherChangeSkill = -10;
        otherPoint += otherChangeSkill;
      }
      if (changeSkill > 0) {
        reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
      } else if (otherChangeSkill < 0) {
        reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
      } else if (changeSkill < 0) {
        reviseMyBattleLog('不運にも$myNameに${changeSkill}ptされた。');
      }
    });
    }
    break;

    case 'No17': //会心の一撃
    setState(() {
      if (declareHand == battleHand) {
        changeSkill = 20 + declarePoint;
        point += changeSkill;
      } else {
        changeSkill = 20;
        point += changeSkill;
      }
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No18': //不変の意志
    String? latestHand = battleLog.last['myHand'];
    int count = 0;
    for (var log in battleLog.reversed) {
      if (log['myHand'] == latestHand) {
        count++;
      } else {
        break;
      }
    }
    if (count > 1) {
      changeSkill = 10 * count;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    }
    break;

    case 'No19': //疾風怒濤　開始2ラウンド以内
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No20': //不屈の闘志 自分のポイントが敵より少ない時
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No21': //冥土の土産 勝った時
    setState(() {
      if (battleHand == declareHand) {
        changeSkill = -declarePoint;
        otherChangeSkill = -declarePoint;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      } else {
        changeSkill = -20;
        otherChangeSkill = -20;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      }
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No22': //預言者　相手の出す手を当てる
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No23': //超アーマー
    setState(() {
      changeSkill = (battleHand == declareHand) ? 20 + declarePoint : 20;
      point += changeSkill;
      reviseMyBattleLog('20ptと宣言ポイントは減らずに済んだ。');
    });
    break;

    case 'No24': //縛りプレイ
    setState(() {
      int? selectedIndex = int.tryParse(mySkillRandom);
      if (selectedIndex != null) {
        otherCards[selectedIndex]['description'] = '\nこのカードは「縛りプレイ」によってスキルが無効化されました。';
        otherCards[selectedIndex]['skillName'] = '元' + otherCards[selectedIndex]['skillName']!;
        otherCards[selectedIndex]['skill'] = 'Images/none.png';
        otherCards[selectedIndex]['no'] = 'none';
        otherCards[selectedIndex]['open'] = 'true';
        reviseMyBattleLog('$enemyNameの${otherCards[selectedIndex]['skillName']}は無効化された。');
      }
    });
    break;

    case 'No25': //痛み分け
    setState(() {
      if (battleHand == declareHand) {
        changeSkill = (10 + (declarePoint ~/2));
        otherChangeSkill = -(10 + (declarePoint ~/2));
        point += changeSkill;
        otherPoint += otherChangeSkill;
      } else {
        changeSkill = 10;
        otherChangeSkill = -10;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      }
      reviseMyBattleLog('$enemyNameに減るはずのポイントを半分押し付けた。');
    });
    break;

    case 'No26': //収益停止
    setState(() {
      if(otherBattleHand == otherDeclareHand) {
        otherChangeSkill = -declarePoint - 20;
        otherPoint = otherChangeSkill;
      } else {
        otherChangeSkill = -20;
        otherPoint = otherChangeSkill;
      }
      reviseMyBattleLog('$enemyNameの勝ちポイントを帳消しにした。');
    });
    break;

    case 'No27': //読心術
    setState(() {
      changeSkill = 50;
      point += 50;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No28': //変幻自在
    List<String> parts = mySkillRandom.split(','); //前半が古いスキル、後半が新しいスキル
    int? oldSkillIndex = int.tryParse(parts[0]);
    int? newSkillIndex = int.tryParse(parts[1]);
    String newSkillNo = 'No${(newSkillIndex ?? 0) + 1}';
    setState(() {
      otherCards[oldSkillIndex ?? 0]['description'] = '元 ${otherCards[oldSkillIndex ?? 0]['skillName']!}\n${skills[newSkillIndex ?? 0]['description']!}';
      otherCards[oldSkillIndex ?? 0]['skillName'] = skills[newSkillIndex ?? 0]['name']!;
      otherCards[oldSkillIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
      otherCards[oldSkillIndex ?? 0]['no'] = newSkillNo;
      reviseMyBattleLog('$enemyNameのスキルを別のスキルに変えてしまった。');
    });
    break;

    case 'No29': //ミストラル
    List<String> randomString = mySkillRandom.split(':');
    int? randomInt = int.tryParse(randomString[0]);
      setState(() {
      switch (randomInt) {
        case 0: //相手のカードをランダムに変更
        List<String> parts = mySkillRandom.split(':'); //[0]は0, [1]は(変更前カード,変更後カード)
        List<String> skillParts = parts[1].split(','); //[0]は変更前カード、[1]は変更後カード
        int? newSelectedIndex = int.tryParse(skillParts[1]);
        int? selectedIndex = int.tryParse(skillParts[0]);
        String newSkillNo = 'No' + ((newSelectedIndex ?? 0) + 1).toString();
        otherCards[selectedIndex ?? 0]['description'] = '元 ${otherCards[selectedIndex ?? 0]['skillName']!}\n${skills[newSelectedIndex ?? 0]['description']!}';
        otherCards[selectedIndex ?? 0]['skillName'] = skills[newSelectedIndex ?? 0]['name']!;
        otherCards[selectedIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
        otherCards[selectedIndex ?? 0]['no'] = newSkillNo;
        reviseMyBattleLog('$enemyNameのスキルを別のスキルに変えてしまった。');
        break;

        case 1:
        setState(() {
          changeSkill = 20;
          point += 20;
          reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
        });
        break;

        case 2:
        setState(() {
          otherChangeSkill = -20;
          otherPoint += otherChangeSkill;
          reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
        });
        break;

        case 3: //カードをランダムに一つたす
        setState(() {
          List<String> parts = mySkillRandom.split(':'); //[0]は3, [1]は新しいスキルインデックス
          int? selectedIndex = int.tryParse(parts[1]);
          String newSkillNo = 'No' + ((selectedIndex ?? 0) + 1).toString();
          cards.add({
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': newSkillNo,
            'image': 'Images/rock.svg',
            'skillName': skills[selectedIndex ?? 0]['name'] ?? '存在しない技',
            'skill': 'Images/$skillNo.png',
            'description': skills[selectedIndex ?? 0]['description'] ?? '説明文が存在しないスキルです。'
          });
          reviseMyBattleLog('$myNameに${skills[selectedIndex ?? 0]['name']}が追加された。');
        });
        break;

        case 4: //スキルなしカードを２つ貰える。
        setState(() {
          cards.add({
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': 'none',
            'image': 'Images/rock.svg',
            'skillName': 'スキルなし',
            'skill': 'Images/$skillNo.png',
            'description': '「ミストラル」によってもらった能無しカード'
          });
          cards.add({
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': 'none',
            'image': 'Images/rock.svg',
            'skillName': 'スキルなし',
            'skill': 'Images/$skillNo.png',
            'description': '「ミストラル」によってもらった能無しカード'
          });
          reviseMyBattleLog('$myNameに能無しカードが2枚追加された。');
        });
        break;

        case 5: //自分に+20,相手に-20
        setState(() {
          changeSkill = 20;
          point += 20;
          otherChangeSkill = -20;
          otherPoint += otherChangeSkill;
          reviseMyBattleLog('$myNameに${changeSkill}ptが追加された。$enemyNameに${otherChangeSkill}ptした。');
        });
        break;

        case 6: // もう一度このカードを使える。
        setState(() {
          myCards[_myBattleCardIndex]['used'] = 'false';
          reviseMyBattleLog('ミストラルがもう一度使えるようになった。');
        });
        break;

        case 7: // バトルログに「スキルの効果で誰かが幸せになった気がする。」とかく
        setState(() {
          reviseMyBattleLog('スキルの効果で誰かが幸せになった気がする。');
        });
        break;

        case 8: // 相手のカードを１枚オープンしてくれる
        List<String> parts = mySkillRandom.split(':'); //[0]は8, [1]は相手のカードのインデックス
        int? selectedIndex = int.tryParse(parts[1]);
        setState(() {
          if (selectedIndex != null) {
            otherCards[selectedIndex]['open'] = 'true';
            reviseMyBattleLog('$enemyNameのスキルを一つオープンした。');
          }
        });
        break;

        case 9: //　自分のカードを一つランダムで複製
        List<String> parts = mySkillRandom.split(':'); //[0]は9, [1]は自分のカードのインデックス
        int? selectedIndex = int.tryParse(parts[1]);
        setState(() {
          cards.add({
            'open': 'false',
            'belong': 'mine',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': cards[selectedIndex ?? 0]['no']!,
            'image': 'Images/rock.svg',
            'skillName': cards[selectedIndex ?? 0]['skillName']!,
            'skill': 'Images/${cards[selectedIndex ?? 0]['no']!}.png',
            'description': '「ミストラル」によって複製されたカード\n${cards[selectedIndex ?? 0]['description']!}'
          });
          reviseMyBattleLog('${cards[selectedIndex ?? 0]['skillName']}を一つ複製した。');
        });
        break;

        case 10: //　自分のカードを一つランダムでスキルを消してしまう。
        setState(() {
          List<String> parts = mySkillRandom.split(':'); //[0]は10, [1]は自分のカードのインデックス
          int? selectedIndex = int.tryParse(parts[1]);
          cards[selectedIndex ?? 0]['description'] = '\nこのカードは「ミストラル」によってスキルが無効化されました。';
          cards[selectedIndex ?? 0]['skillName'] = '元' + cards[selectedIndex ?? 0]['skillName']!;
          cards[selectedIndex ?? 0]['skill'] = 'Images/none.png';
          cards[selectedIndex ?? 0]['no'] = 'none';
          cards[selectedIndex ?? 0]['open'] = 'true';
          reviseMyBattleLog('不運にも$myNameの${cards[selectedIndex ?? 0]['skillName']}を無効化してしまった。');
        });
        break;
      }
    });
    break;

    case 'No30': //スキル封印
    reviseMyBattleLog('$enemyNameのスキルを封印した。');
    break;

    case 'No31': //自由奔放
    setState(() {
      List<String> parts = mySkillRandom.split(','); //[0]は古いカード, [1]は新しいスキル
      int? selectedIndex = int.tryParse(parts[0]);
      int? newSelectedIndex = int.tryParse(parts[1]);
      String newSkillNo = 'No' + ((newSelectedIndex ?? 0) + 1).toString();
      otherCards[selectedIndex ?? 0]['description'] = '元 ${otherCards[selectedIndex ?? 0]['skillName']!}\n${skills[newSelectedIndex ?? 0]['description']!}';
      otherCards[selectedIndex ?? 0]['skillName'] = skills[newSelectedIndex ?? 0]['name']!;
      otherCards[selectedIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
      otherCards[selectedIndex ?? 0]['no'] = newSkillNo;
      reviseMyBattleLog('$enemyNameのスキルを別のスキルに変えてしまった。');
    });
    break;

    case 'No32': //貿易の怒り
    List<String> parts = mySkillRandom.split(','); //[0]は自分のカード, [1]は相手のカード
    int? selectedIndex = int.tryParse(parts[0]);
    int? selectedOtherIndex = int.tryParse(parts[1]);
    setState(() {
      if (selectedIndex != null && selectedOtherIndex != null) {
        cards.add({
          'open': 'false',
          'belong': 'mine',
          'used': 'false',
          'type': 'rock',
          'typeOpen': 'false',
          'no': otherCards[selectedOtherIndex]['no']!,
          'image': 'Images/rock.svg',
          'skillName': otherCards[selectedOtherIndex]['skillName']!,
          'skill': 'Images/${otherCards[selectedOtherIndex]['no']!}.png',
          'description': '「貿易の興り」によって交換されたカード\n${otherCards[selectedOtherIndex]['description']!}'
        });
        otherCards.add({
          'open': 'false',
          'belong': 'enemy',
          'used': 'false',
          'type': 'rock',
          'typeOpen': 'false',
          'no': cards[selectedIndex]['no']!,
          'image': 'Images/rock.svg',
          'skillName': cards[selectedIndex]['skillName']!,
          'skill': 'Images/${cards[selectedIndex]['no']!}.png',
          'description': '「貿易の興り」によって交換されたカード\n${cards[selectedIndex]['description']!}'
        });
        cards.removeAt(selectedIndex);
        otherCards.removeAt(selectedOtherIndex);
        reviseMyBattleLog('スキルを１枚ずつ交換した。');
      }
    });
    break;

    case 'No33': //秘密の共有
    List<int> unOpenIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (otherCards[i]['used'] == 'false' && otherCards[i]['open'] == 'false') {
        unOpenIndexes.add(i);
      }
    }
    setState(() {
      otherChangeSkill = max (-5 * unOpenIndexes.length, -30);
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No34': //かくれんぼ
    List<String> parts = mySkillRandom.split(','); //[0]は隠すカード１枚目, [2]は２枚目、[3]は３枚目
    int selectedIndex = -1;
    int selectedIndex2 = -1;
    int selectedIndex3 = -1;
    if (parts.isNotEmpty){
     selectedIndex = int.tryParse(parts[0]) ?? 0;
     cards[selectedIndex]['open'] = 'false';
    }
    if (parts.length > 1) {
      selectedIndex2 = int.tryParse(parts[1]) ?? 0;
      cards[selectedIndex2]['open'] = 'false';
    }
    if (parts.length > 2) {
      selectedIndex3 = int.tryParse(parts[2]) ?? 0;
      cards[selectedIndex3]['open'] = 'false';
    }
    reviseMyBattleLog('$myNameのスキルを再び隠してしまった。');
    break;

    case 'No35': //でしゃばり
    reviseMyBattleLog('このカードは役目をすでに終えていた。');
    break;

    case 'No36': //公開処刑
    List<int> unOpenIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'false' && cards[i]['open'] == 'true') {
        unOpenIndexes.add(i);
      }
    }
    setState(() {
      changeSkill = 5 * unOpenIndexes.length;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No37': //羞恥心
    setState(() {
      otherChangeSkill = -20;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No38': //露出狂
    setState(() {
      changeSkill = 15;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No39': //リバイバル
    int? selectedIndex = int.tryParse(mySkillRandom);
    if (selectedIndex != null){
      cards[selectedIndex]['used'] = 'false';
      reviseMyBattleLog('$myNameの${cards[selectedIndex]['skillName']}が復活した。');
    }
    break;

    case 'No40': //存在抹消
    List<int> unusedIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (otherCards[i]['no'] == skillSelect) {
        unusedIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty) {
      int selectedIndex = unusedIndexes[0];
      otherCards[selectedIndex]['description'] = '\nこのカードは「存在抹消」によってスキルが無効化されました。';
      otherCards[selectedIndex]['skillName'] = '元' + otherCards[selectedIndex]['skillName']!;
      otherCards[selectedIndex]['skill'] = 'Images/none.png';
      otherCards[selectedIndex]['no'] = 'none';
      otherCards[selectedIndex]['open'] = 'true';
      reviseMyBattleLog('$enemyNameの${otherCards[unusedIndexes[0]]['skillName']}は抹消された。');
    }
    break;

    case 'No41': //嘘は嫌い　自分は宣言、　相手は宣言以外
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$enemyNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No42': //真実の加護
    setState(() {
      changeSkill = 15;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No43': //生命保険
    int loseCount = 0;
    for (int i = 0; i < battleLog.length; i++) {
      if (battleLog[i]['result'] == 'lose') {
        loseCount += 1;
      }
    }
    setState(() {
      changeSkill = loseCount * 15;
      point += changeSkill;
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No44': //墓あらし
    int? selectedIndex = int.tryParse(mySkillRandom);
    if (selectedIndex != null) {
      cards.add({
        'open': 'true',
        'belong': 'mine',
        'used': 'false',
        'type': 'rock',
        'typeOpen': 'false',
        'no': otherCards[selectedIndex]['no']!,
        'image': 'Images/rock.svg',
        'skillName': otherCards[selectedIndex]['skillName']!,
        'skill': 'Images/${otherCards[selectedIndex]['no']!}.png',
        'description': '「墓荒らし」によって奪ったカード\n${otherCards[selectedIndex]['description']!}'
      });
      reviseMyBattleLog('$enemyNameから${otherCards[selectedIndex]['skillName']}を奪った。');
    }
    break;

    case 'No45': //初志貫徹
    setState(() {
      if(battleHand == declareHand) {
        changeSkill = currentRound * 10;
        point += changeSkill;
      } else {
        changeSkill = currentRound * 5;
        point += changeSkill;
      }
      reviseMyBattleLog('$myNameに+${changeSkill}ptした。');
    });
    break;

    case 'No46': //インフレ防止
    setState(() {
      changeSkill = -30;
      otherChangeSkill = -30;
      point += changeSkill;
      otherPoint += otherChangeSkill;
      reviseMyBattleLog('$myNameと$enemyNameに${changeSkill}ptした。');
    });
    break;

    case 'No47': //カオス
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'true') {
        cards[i]['used'] = 'false';
      }
    }
    for (int i = 0; i < otherCards.length; i++) {
      if (otherCards[i]['used'] == 'true') {
        otherCards[i]['used'] = 'false';
      }
    }
    List<String> cardLists = mySkillRandom.split(':'); //前半が自分の新しいカードたち、後半が相手の新しいカードたち
    List<String> newCards = cardLists[0].split(',');
    List<String> newOtherCards = cardLists[1].split(',');
    List<Map<String, String>> newCardList = [];
    List<Map<String, String>> newOtherCardList = [];

    for (int i = 0; i < newCards.length; i++) {
      if (newCards[i].contains('e')) {
        String numberPart = newCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newCardList.add(otherCards[index ?? 0]);
      }
      if (newCards[i].contains('m')){
        String numberPart = newCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newCardList.add(cards[index ?? 0]);
      }
    }
    for (int i = 0; i < newOtherCards.length; i++) {
      if (newOtherCards[i].contains('e')) {
        String numberPart = newOtherCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newOtherCardList.add(otherCards[index ?? 0]);
      }
      if (newOtherCards[i].contains('m')){
        String numberPart = newOtherCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newOtherCardList.add(cards[index ?? 0]);
      }
    }
    for (int i = 0; i < newCardList.length; i++){
      newCardList[i]['belong'] = 'mine';
    }
    for (int i = 0; i < newOtherCardList.length; i++){
      newOtherCardList[i]['belong'] = 'enemy';
    }
    setState(() {
      myCards = newCardList;
      enemyCards = newOtherCardList;
    });
    reviseMyBattleLog('全てのスキルを蘇らせシャッフルしてしまった。');
    break;

    case 'No48': //盗賊の極意
    List<String> otherNumbers= mySkillRandom.split(',');
    for (int i = 0; i < otherNumbers.length; i++) {
      cards.add({
        'open': 'true',
        'belong': 'mine',
        'used': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['used']!,
        'type': 'rock',
        'typeOpen': 'false',
        'no': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no']!,
        'image': 'Images/rock.svg',
        'skillName': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName']!,
        'skill': 'Images/${otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no']!}.png',
        'description': '「盗賊の極意」によって奪ったカード\n${otherCards[int.tryParse(otherNumbers[i]) ?? 0]['description']!}'
      });
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['description'] = '\nこのカードは「盗賊の極意」によってスキルが無効化されました。';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName'] = '元' + otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName']!;
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skill'] = 'Images/none.png';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no'] = 'none';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['open'] = 'true';
    }
    reviseMyBattleLog('$enemyNameからスキルを奪ってしまった。');
    break;

    case 'No49': //過去の階層
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'true') {
        cards[i]['used'] = 'false';
      } else {
        cards[i]['used'] = 'true';
      }
    }
    for (int i = 0; i < otherCards.length; i++) {
      if (otherCards[i]['used'] == 'true') {
        otherCards[i]['used'] = 'false';
      } else {
        otherCards[i]['used'] = 'true';
      }
    }
    reviseMyBattleLog('時は遡り、スキルは復活した。しかし残っていたスキルは使えなくなった。');
    break;

    case 'No50': //人生革命
    cards.add({
      'open': 'true',
      'belong': 'mine',
      'used': 'false',
      'type': 'rock',
      'typeOpen': 'false',
      'no': 'R',
      'image': 'Images/rock.svg',
      'skillName': '革命カード',
      'skill': 'Images/R.png',
      'description': '条件：相手が「キングカード」を出したとき\n効果：自分に+100ptもらえる。'
    });
    otherCards.add({
      'open': 'true',
      'belong': 'enemy',
      'used': 'false',
      'type': 'rock',
      'typeOpen': 'false',
      'no': 'K',
      'image': 'Images/rock.svg',
      'skillName': 'キングカード',
      'skill': 'Images/K.png',
      'description': '条件：相手が「革命カード」を出していないとき\n効果：自分に+30ptもらえる。\n特殊効果：このカードは5ラウンド終了時に持っていると負けが確定する。'
    });
    reviseMyBattleLog('革命が起き、$myNameには「革命カード」が$enemyNameには「キングカード」が与えられた。');
    break;

    case 'R':
    setState(() {
      changeSkill = 100;
      point += changeSkill;
      reviseMyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'K':
    setState(() {
      changeSkill = 30;
      point += changeSkill;
      reviseMyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;
    }
    setState(() {
      myChangeMySkill = changeSkill;
      enemyChangeMySkill = otherChangeSkill;
    });
  }

  void performEnemySkillEffect(String skillNo, String otherSkillNo, String battleHand, String declareHand, String otherBattleHand, String otherDeclareHand, int point, int otherPoint, int changeSkill, int changeOtherSkill, int otherChangeSkill, int otherChangeOtherSkill, int declarePoint, int otherDeclarePoint, String skillSelect, String otherSkillSelect, List<Map<String, String>> cards, List<Map<String, String>> otherCards) {
    changeSkill = 0;
    otherChangeSkill = 0;
    switch (skillNo) {
    case 'No1': //硬い拳
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No2': //硬い掌
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No3': //硬い指
    setState(() {
      changeSkill = 30;
      point += 30;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No4': //相打ちの極意
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No5': //拳砕き
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseEnemyBattleLog('$myNameに+${otherChangeSkill}ptした。');
    });
    break;

    case 'No6': //掌やぶり
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseEnemyBattleLog('$myNameに+${otherChangeSkill}ptした。');
    });
    break;

    case 'No7': //刀折り
    setState(() {
      otherChangeSkill = -20;
      otherPoint -= 20;
      reviseEnemyBattleLog('$myNameに+${otherChangeSkill}ptした。');
    });
    break;

    case 'No8': //連勝ボーナス
    int winStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'lose') {
        winStreak++;
      } else {
        break;
      }
    }
    if (winStreak > 1) {
      changeSkill = winStreak * 10;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    }
    break;

    case 'No9': //救済措置 連敗
    int loseStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'win') {
        loseStreak++;
      } else {
        break;
      }
    }
    if (loseStreak > 1) {
      changeSkill = loseStreak * 10;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    }
    break;

    case 'No10': //平和主義 アイコ連続
    int drawStreak = 0;
    for (var log in battleLog.reversed) {
      if (log['result'] == 'draw') {
        drawStreak++;
      } else {
        break;
      }
    }
    if (drawStreak > 1) {
        changeSkill = drawStreak * 10;
        point += changeSkill;
        reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
      }
    break;

    case 'No11': //宣教師　宣言した手で勝つ
    setState(() {
      changeSkill = 30;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No12': //ライアー　宣言していない手でかつ
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No13': //不幸中の幸い 3連敗
    setState(() {
      otherChangeSkill = -70;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No14': //追い風　３連勝
    setState(() {
      changeSkill = 50;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No15': //均衡崩壊 アイコかつ宣言とは違う手を出す
    setState(() {
      changeSkill = 20;
      if (otherBattleHand == otherDeclareHand) {
        otherChangeSkill = -(20 + otherDeclarePoint);
      } else {
        otherChangeSkill = -20;
      }
      point += changeSkill;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。${myName}に${otherChangeSkill}ptした。');
    });
    break;

    case 'No16': //ギャンブラー
    int? selectedNumber = int.tryParse(enemySkillRandom);
    if (selectedNumber != null) {
    setState(() {
      if (selectedNumber > 91) {
        changeSkill = -50;
        point += changeSkill;
      } else if (selectedNumber > 78) {
        changeSkill = 40;
        point += changeSkill;
      } else if (selectedNumber > 65) {
        changeSkill = 30;
        point += changeSkill;
      } else if (selectedNumber > 52) {
        changeSkill = 20;
        point += changeSkill;
      } else if (selectedNumber > 39) {
        changeSkill = 10;
        point += changeSkill;
      } else if (selectedNumber > 26) {
        otherChangeSkill = -30;
        otherPoint += otherChangeSkill;
      } else if (selectedNumber > 13) {
        otherChangeSkill = -20;
        otherPoint += otherChangeSkill;
      } else if (selectedNumber > 0) {
        otherChangeSkill = -10;
        otherPoint += otherChangeSkill;
      }
      if (changeSkill > 0) {
        reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
      } else if (otherChangeSkill < 0) {
        reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
      } else if (changeSkill < 0) {
        reviseEnemyBattleLog('不運にも$enemyNameに${changeSkill}ptされた。');
      }
    });
    }
    break;

    case 'No17': //会心の一撃
    setState(() {
      if (declareHand == battleHand) {
        changeSkill = 20 + declarePoint;
        point += changeSkill;
      } else {
        changeSkill = 20;
        point += changeSkill;
      }
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No18': //不変の意志
    String? latestHand = battleLog.last['enemyHand'];
    int count = 0;
    for (var log in battleLog.reversed) {
      if (log['enemyHand'] == latestHand) {
        count++;
      } else {
        break;
      }
    }
    if (count > 1) {
      changeSkill = 10 * count;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    }
    break;

    case 'No19': //疾風怒濤　開始2ラウンド以内
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No20': //不屈の闘志 自分のポイントが敵より少ない時
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No21': //冥土の土産 勝った時
    setState(() {
      if (battleHand == declareHand) {
        changeSkill = -declarePoint;
        otherChangeSkill = -declarePoint;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      } else {
        changeSkill = -20;
        otherChangeSkill = -20;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      }
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No22': //預言者　相手の出す手を当てる
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No23': //超アーマー
    setState(() {
      changeSkill = (battleHand == declareHand) ? 20 + declarePoint : 20;
      point += changeSkill;
      reviseEnemyBattleLog('20ptと宣言ポイントは減らずに済んだ。');
    });
    break;

    case 'No24': //縛りプレイ
    setState(() {
      int? selectedIndex = int.tryParse(enemySkillRandom);
      if (selectedIndex != null) {
      otherCards[selectedIndex]['description'] = '\nこのカードは「縛りプレイ」によってスキルが無効化されました。';
      otherCards[selectedIndex]['skillName'] = '元' + otherCards[selectedIndex]['skillName']!;
      otherCards[selectedIndex]['skill'] = 'Images/none.png';
      otherCards[selectedIndex]['no'] = 'none';
      otherCards[selectedIndex]['open'] = 'true';
      reviseEnemyBattleLog('$myNameの${otherCards[selectedIndex]['skillName']}は無効化された。');
      }
    });
    break;

    case 'No25': //痛み分け
    setState(() {
      if (battleHand == declareHand) {
        changeSkill = (10 + (declarePoint ~/2));
        otherChangeSkill = -(10 + (declarePoint ~/2));
        point += changeSkill;
        otherPoint += otherChangeSkill;
      } else {
        changeSkill = 10;
        otherChangeSkill = -10;
        point += changeSkill;
        otherPoint += otherChangeSkill;
      }
      reviseEnemyBattleLog('$myNameに減るはずのポイントを半分押し付けた。');
    });
    break;

    case 'No26': //収益停止
    setState(() {
      if(otherBattleHand == otherDeclareHand) {
        otherChangeSkill = -declarePoint - 20;
        otherPoint = otherChangeSkill;
      } else {
        otherChangeSkill = -20;
        otherPoint = otherChangeSkill;
        reviseEnemyBattleLog('$myNameの勝ちポイントを帳消しにした。');
      }
    });
    break;

    case 'No27': //読心術
    setState(() {
      changeSkill = 50;
      point += 50;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No28': //変幻自在
    setState(() {
    List<String> parts = enemySkillRandom.split(','); //前半が古いスキル、後半が新しいスキル
    int? oldSkillIndex = int.tryParse(parts[0]);
    int? newSkillIndex = int.tryParse(parts[1]);
    String newSkillNo = 'No${(newSkillIndex ?? 0) + 1}';
    otherCards[oldSkillIndex ?? 0]['description'] = '元 ${otherCards[oldSkillIndex ?? 0]['skillName']!}\n${skills[newSkillIndex ?? 0]['description']!}';
    otherCards[oldSkillIndex ?? 0]['skillName'] = skills[newSkillIndex ?? 0]['name']!;
    otherCards[oldSkillIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
    otherCards[oldSkillIndex ?? 0]['no'] = newSkillNo;
    reviseEnemyBattleLog('$myNameのスキルを${otherCards[oldSkillIndex ?? 0]['skillName']}に変えてしまった。');
    });
    break;

    case 'No29': //ミストラル
    List<String> randomString = enemySkillRandom.split(':');
    int? randomInt = int.tryParse(randomString[0]);
      setState(() {
      switch (randomInt) {
        case 0: //相手のカードをランダムに変更
        List<String> parts = enemySkillRandom.split(':'); //[0]は0, [1]は(変更前カード,変更後カード)
        List<String> skillParts = parts[1].split(','); //[0]は変更前カード、[1]は変更後カード
        int? newSelectedIndex = int.tryParse(skillParts[1]);
        int? selectedIndex = int.tryParse(skillParts[0]);
        String newSkillNo = 'No' + ((newSelectedIndex ?? 0) + 1).toString();
        otherCards[selectedIndex ?? 0]['description'] = '元 ${otherCards[selectedIndex ?? 0]['skillName']!}\n${skills[newSelectedIndex ?? 0]['description']!}';
        otherCards[selectedIndex ?? 0]['skillName'] = skills[newSelectedIndex ?? 0]['name']!;
        otherCards[selectedIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
        otherCards[selectedIndex ?? 0]['no'] = newSkillNo;
        reviseEnemyBattleLog('$myNameのスキルを${otherCards[selectedIndex ?? 0]['skillName']}に変えてしまった。');
        break;

        case 1:
        setState(() {
          changeSkill = 20;
          point += 20;
          reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
        });
        break;

        case 2:
        setState(() {
          otherChangeSkill = -20;
          otherPoint += otherChangeSkill;
          reviseEnemyBattleLog('$myNameに+${otherChangeSkill}ptした。');
        });
        break;

        case 3: //カードをランダムに一つたす
        setState(() {
          List<String> parts = enemySkillRandom.split(':'); //[0]は3, [1]は新しいスキルインデックス
          int? selectedIndex = int.tryParse(parts[1]);
          String newSkillNo = 'No' + ((selectedIndex ?? 0) + 1).toString();
          cards.add({
            'open': 'false',
            'belong': 'enemy',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': newSkillNo,
            'image': 'Images/rock.svg',
            'skillName': skills[selectedIndex ?? 0]['name'] ?? '存在しない技',
            'skill': 'Images/$skillNo.png',
            'description': skills[selectedIndex ?? 0]['description'] ?? '説明文が存在しないスキルです。'
          });
          reviseEnemyBattleLog('$enemyNameにランダムにスキルが一つ追加された。');
        });
        break;

        case 4: //スキルなしカードを２つ貰える。
        setState(() {
          cards.add({
            'open': 'false',
            'belong': 'enemy',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': 'none',
            'image': 'Images/rock.svg',
            'skillName': 'スキルなし',
            'skill': 'Images/$skillNo.png',
            'description': '「ミストラル」によってもらった能無しカード'
          });
          cards.add({
            'open': 'false',
            'belong': 'enemy',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': 'none',
            'image': 'Images/rock.svg',
            'skillName': 'スキルなし',
            'skill': 'Images/$skillNo.png',
            'description': '「ミストラル」によってもらった能無しカード'
          });
          reviseEnemyBattleLog('$enemyNameに能無しカードが２枚追加された。');
        });
        break;

        case 5: //自分に+20,相手に-20
        setState(() {
          changeSkill = 20;
          point += 20;
          otherChangeSkill = -20;
          otherPoint += otherChangeSkill;
          reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。$myNameに${otherChangeSkill}ptした。');
        });
        break;

        case 6: // もう一度このカードを使える。
        setState(() {
          enemyCards[_enemyBattleCardIndex]['used'] = 'false';
          reviseEnemyBattleLog('ミストラルがもう一度使えるようになった。');
        });
        break;

        case 7: // バトルログに「スキルの効果で誰かが幸せになった気がする。」とかく
        setState(() {
          reviseEnemyBattleLog('スキルの効果で誰かが幸せになった気がする。');
        });
        break;

        case 8: // 相手のカードを１枚オープンしてくれる
        List<String> parts = enemySkillRandom.split(':'); //[0]は8, [1]は相手のカードのインデックス
        int? selectedIndex = int.tryParse(parts[1]);
        setState(() {
          if (selectedIndex != null) {
            otherCards[selectedIndex]['open'] = 'true';
            reviseEnemyBattleLog('$myNameのスキルを一つオープンした。');
          }
        });
        break;

        case 9: //　自分のカードを一つランダムで複製
        List<String> parts = enemySkillRandom.split(':'); //[0]は9, [1]は自分のカードのインデックス
        int? selectedIndex = int.tryParse(parts[1]);
        setState(() {
          cards.add({
            'open': 'false',
            'belong': 'enemy',
            'used': 'false',
            'type': 'rock',
            'typeOpen': 'false',
            'no': cards[selectedIndex ?? 0]['no']!,
            'image': 'Images/rock.svg',
            'skillName': cards[selectedIndex ?? 0]['skillName']!,
            'skill': 'Images/${cards[selectedIndex ?? 0]['no']!}.png',
            'description': '「ミストラル」によって複製されたカード\n${cards[selectedIndex ?? 0]['description']!}'
          });
          reviseEnemyBattleLog('$enemyNameのスキルを一つ複製した。');
        });
        break;

        case 10: //　自分のカードを一つランダムでスキルを消してしまう。
        setState(() {
          List<String> parts = enemySkillRandom.split(':'); //[0]は10, [1]は自分のカードのインデックス
          int? selectedIndex = int.tryParse(parts[1]);
          cards[selectedIndex ?? 0]['description'] = '\nこのカードは「ミストラル」によってスキルが無効化されました。';
          cards[selectedIndex ?? 0]['skillName'] = '元' + cards[selectedIndex ?? 0]['skillName']!;
          cards[selectedIndex ?? 0]['skill'] = 'Images/none.png';
          cards[selectedIndex ?? 0]['no'] = 'none';
          cards[selectedIndex ?? 0]['open'] = 'true';
          reviseEnemyBattleLog('不運にも$enemyNameの${cards[selectedIndex ?? 0]['skillName']}を無効化してしまった。');
        });
        break;
      }
    });
    break;

    case 'No30': //スキル封印
    reviseEnemyBattleLog('$myNameのスキルを封印した。');
    break;

    case 'No31': //自由奔放
    setState(() {
      List<String> parts = enemySkillRandom.split(','); //[0]は古いカード, [1]は新しいスキル
      int? selectedIndex = int.tryParse(parts[0]);
      int? newSelectedIndex = int.tryParse(parts[1]);
      String newSkillNo = 'No' + ((newSelectedIndex ?? 0) + 1).toString();
      otherCards[selectedIndex ?? 0]['description'] = '元 ${otherCards[selectedIndex ?? 0]['skillName']!}\n${skills[newSelectedIndex ?? 0]['description']!}';
      print('${otherCards[selectedIndex ?? 0]['skillName']!}が${skills[newSelectedIndex ?? 0]['name']!} になる。');
      otherCards[selectedIndex ?? 0]['skillName'] = skills[newSelectedIndex ?? 0]['name']!;
      otherCards[selectedIndex ?? 0]['skill'] = 'Images/$newSkillNo.png';
      otherCards[selectedIndex ?? 0]['no'] = newSkillNo;
      reviseEnemyBattleLog('$myNameのスキルを${otherCards[selectedIndex ?? 0]['skillName']}に変えてしまった。');
    });
    break;

    case 'No32': //貿易の怒り
    List<String> parts = enemySkillRandom.split(','); //[0]は自分のカード, [1]は相手のカード
    int? selectedIndex = int.tryParse(parts[0]);
    int? selectedOtherIndex = int.tryParse(parts[1]);
    setState(() {
      if (selectedIndex != null && selectedOtherIndex != null) {
        cards.add({
          'open': 'false',
          'belong': 'enemy',
          'used': 'false',
          'type': 'rock',
          'typeOpen': 'false',
          'no': otherCards[selectedOtherIndex]['no']!,
          'image': 'Images/rock.svg',
          'skillName': otherCards[selectedOtherIndex]['skillName']!,
          'skill': 'Images/${otherCards[selectedOtherIndex]['no']!}.png',
          'description': '「貿易の興り」によって交換されたカード\n${otherCards[selectedOtherIndex]['description']!}'
        });
        otherCards.add({
          'open': 'false',
          'belong': 'mine',
          'used': 'false',
          'type': 'rock',
          'typeOpen': 'false',
          'no': cards[selectedIndex]['no']!,
          'image': 'Images/rock.svg',
          'skillName': cards[selectedIndex]['skillName']!,
          'skill': 'Images/${cards[selectedIndex]['no']!}.png',
          'description': '「貿易の興り」によって交換されたカード\n${cards[selectedIndex]['description']!}'
        });
        cards.removeAt(selectedIndex);
        otherCards.removeAt(selectedOtherIndex);
        reviseEnemyBattleLog('スキルを１枚ずつ交換した。');
      }
    });
    break;

    case 'No33': //秘密の共有
    List<int> unOpenIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (otherCards[i]['used'] == 'false' && otherCards[i]['open'] == 'false') {
        unOpenIndexes.add(i);
      }
    }
    setState(() {
      otherChangeSkill = max (-5 * unOpenIndexes.length, -30);
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No34': //かくれんぼ
    List<String> parts = enemySkillRandom.split(','); //[0]は隠すカード１枚目, [2]は２枚目、[3]は３枚目
    int selectedIndex = -1;
    int selectedIndex2 = -1;
    int selectedIndex3 = -1;
    if (parts.isNotEmpty){
     selectedIndex = int.tryParse(parts[0]) ?? 0;
     cards[selectedIndex]['open'] = 'false';
    }
    if (parts.length > 1) {
      selectedIndex2 = int.tryParse(parts[1]) ?? 0;
      cards[selectedIndex2]['open'] = 'false';
    }
    if (parts.length > 2) {
      selectedIndex3 = int.tryParse(parts[2]) ?? 0;
      cards[selectedIndex3]['open'] = 'false';
    }
    reviseEnemyBattleLog('$enemyNameのスキルを再び隠してしまった。');
    break;

    case 'No35': //でしゃばり
    reviseEnemyBattleLog('このカードはすでに役目を終えていた。');
    break;

    case 'No36': //公開処刑
    List<int> unOpenIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'false' && cards[i]['open'] == 'true') {
        unOpenIndexes.add(i);
      }
    }
    setState(() {
      changeSkill = 5 * unOpenIndexes.length;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No37': //羞恥心
    setState(() {
      otherChangeSkill = -20;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに${otherChangeSkill}ptした。');
    });
    break;

    case 'No38': //露出狂
    setState(() {
      changeSkill = 15;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No39': //リバイバル
    int? selectedIndex = int.tryParse(enemySkillRandom);
    if (selectedIndex != null){
      cards[selectedIndex]['used'] = 'false';
      reviseEnemyBattleLog('$enemyNameの${cards[selectedIndex]['skillName']}が復活した。');
    }
    break;

    case 'No40': //存在抹消
    List<int> unusedIndexes = [];
    for (int i = 0; i < cards.length; i++) {
      if (otherCards[i]['no'] == skillSelect) {
        unusedIndexes.add(i);
      }
    }
    if (unusedIndexes.isNotEmpty) {
      int selectedIndex = unusedIndexes[0];
      otherCards[selectedIndex]['description'] = '\nこのカードは「存在抹消」によってスキルが無効化されました。';
      otherCards[selectedIndex]['skillName'] = '元' + otherCards[selectedIndex]['skillName']!;
      otherCards[selectedIndex]['skill'] = 'Images/none.png';
      otherCards[selectedIndex]['no'] = 'none';
      otherCards[selectedIndex]['open'] = 'true';
      reviseEnemyBattleLog('$myNameの${otherCards[unusedIndexes[0]]['skillName']}は抹消された。');
    }

    break;

    case 'No41': //嘘は嫌い　自分は宣言、　相手は宣言以外
    setState(() {
      otherChangeSkill = -30;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameに+${otherChangeSkill}ptした。');
    });
    break;

    case 'No42': //真実の加護
    setState(() {
      changeSkill = 15;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No43': //生命保険
    int loseCount = 0;
    for (int i = 0; i < battleLog.length; i++) {
      if (battleLog[i]['result'] == 'win') {
        loseCount += 1;
      }
    }
    setState(() {
      changeSkill = loseCount * 15;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'No44': //墓あらし
    int? selectedIndex = int.tryParse(enemySkillRandom);
    if (selectedIndex != null) {
      cards.add({
        'open': 'true',
        'belong': 'enemy',
        'used': 'false',
        'type': 'rock',
        'typeOpen': 'false',
        'no': otherCards[selectedIndex]['no']!,
        'image': 'Images/rock.svg',
        'skillName': otherCards[selectedIndex]['skillName']!,
        'skill': 'Images/${otherCards[selectedIndex]['no']!}.png',
        'description': '「墓荒らし」によって奪ったカード\n${otherCards[selectedIndex]['description']!}'
      });
      reviseEnemyBattleLog('$myNameから${otherCards[selectedIndex]['skillName']}を奪った。');
    }
    break;

    case 'No45': //初志貫徹
    setState(() {
      if(battleHand == declareHand) {
        changeSkill = currentRound * 10;
        point += changeSkill;
      } else {
        changeSkill = currentRound * 5;
        point += changeSkill;
        reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
      }
    });
    break;

    case 'No46': //インフレ防止
    setState(() {
      changeSkill = -30;
      otherChangeSkill = -30;
      point += changeSkill;
      otherPoint += otherChangeSkill;
      reviseEnemyBattleLog('$myNameと$enemyNameに${changeSkill}ptした。');
    });
    break;

    case 'No47': //カオス
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'true') {
        cards[i]['used'] = 'false';
      }
    }
    for (int i = 0; i < otherCards.length; i++) {
      if (otherCards[i]['used'] == 'true') {
        otherCards[i]['used'] = 'false';
      }
    }
    List<String> cardLists = enemySkillRandom.split(':'); //前半が自分の新しいカードたち、後半が相手の新しいカードたち
    List<String> newCards = cardLists[0].split(',');
    List<String> newOtherCards = cardLists[1].split(',');
    List<Map<String, String>> newCardList = [];
    List<Map<String, String>> newOtherCardList = [];

    for (int i = 0; i < newCards.length; i++) {
      if (newCards[i].contains('e')) {
        String numberPart = newCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newCardList.add(otherCards[index ?? 0]);
      }
      if (newCards[i].contains('m')){
        String numberPart = newCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newCardList.add(cards[index ?? 0]);
      }
    }
    for (int i = 0; i < newOtherCards.length; i++) {
      if (newOtherCards[i].contains('e')) {
        String numberPart = newOtherCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newOtherCardList.add(otherCards[index ?? 0]);
      }
      if (newOtherCards[i].contains('m')){
        String numberPart = newOtherCards[i].substring(1);
        int? index = int.tryParse(numberPart);
        newOtherCardList.add(cards[index ?? 0]);
      }
    }
    for (int i = 0; i < newCardList.length; i++){
      newCardList[i]['belong'] = 'enemy';
    }
    for (int i = 0; i < newOtherCardList.length; i++){
      newOtherCardList[i]['belong'] = 'mine';
    }
    setState(() {
      enemyCards = newCardList;
      myCards = newOtherCardList;
    });

    reviseEnemyBattleLog('全てのスキルを蘇らせシャッフルしてしまった。');
    break;

    case 'No48': //盗賊の極意
    List<String> otherNumbers= enemySkillRandom.split(',');
    for (int i = 0; i < otherNumbers.length; i++) {
      cards.add({
        'open': 'true',
        'belong': 'enemy',
        'used': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['used']!,
        'type': 'rock',
        'typeOpen': 'false',
        'no': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no']!,
        'image': 'Images/rock.svg',
        'skillName': otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName']!,
        'skill': 'Images/${otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no']!}.png',
        'description': '「盗賊の極意」によって奪ったカード\n${otherCards[int.tryParse(otherNumbers[i]) ?? 0]['description']!}'
      });
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['description'] = '\nこのカードは「盗賊の極意」によってスキルが無効化されました。';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName'] = '元' + otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skillName']!;
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['skill'] = 'Images/none.png';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['no'] = 'none';
      otherCards[int.tryParse(otherNumbers[i]) ?? 0]['open'] = 'true';
      reviseEnemyBattleLog('$myNameからスキルを奪ってしまった。');
    }
    break;

    case 'No49': //過去の階層
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['used'] == 'true') {
        cards[i]['used'] = 'false';
      } else {
        cards[i]['used'] = 'true';
      }
    }
    for (int i = 0; i < otherCards.length; i++) {
      if (otherCards[i]['used'] == 'true') {
        otherCards[i]['used'] = 'false';
      } else {
        otherCards[i]['used'] = 'true';
      }
    }
    reviseEnemyBattleLog('時は遡り、スキルは復活した。しかし残っていたスキルは使えなくなった。');
    break;

    case 'No50': //人生革命
    cards.add({
      'open': 'true',
      'belong': 'enemy',
      'used': 'false',
      'type': 'rock',
      'typeOpen': 'false',
      'no': 'R',
      'image': 'Images/rock.svg',
      'skillName': '革命カード',
      'skill': 'Images/R.png',
      'description': '条件：相手が「キングカード」を出したとき\n効果：自分に+100ptもらえる。'
    });
    otherCards.add({
      'open': 'true',
      'belong': 'mine',
      'used': 'false',
      'type': 'rock',
      'typeOpen': 'false',
      'no': 'K',
      'image': 'Images/rock.svg',
      'skillName': 'キングカード',
      'skill': 'Images/K.png',
      'description': '条件：相手が「キングカード」を出していないとき\n効果：自分に+30ptもらえる。\n特殊効果：このカードは5ラウンド終了時に持っていると負けが確定する。'
    });
    reviseEnemyBattleLog('革命が起き、$enemyNameには「革命カード」が$myNameには「キングカード」が与えられた。');
    break;

    case 'R':
    setState(() {
      changeSkill = 100;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;

    case 'K':
    setState(() {
      changeSkill = 30;
      point += changeSkill;
      reviseEnemyBattleLog('$enemyNameに+${changeSkill}ptした。');
    });
    break;
    }
    setState(() {
      enemyChangeEnemySkill = changeSkill;
      myChangeEnemySkill += otherChangeSkill;
    });
  }
}


//
//
//
//
//
//
//
//ここからクラス
//
//
//
//
//
//
//
//

class PixelGrid extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final List<List<String>> grid;
  final int gridNumber;

  PixelGrid({
    required this.screenWidth,
    required this.screenHeight,
    required this.grid,
    required this.gridNumber,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize =
        (min(screenHeight * 0.15, screenWidth * 0.4) / gridNumber).floorToDouble();
    final containerSize = cellSize * gridNumber;

    return Stack(
      children: [
        SizedBox(
          width: containerSize,
          height: containerSize,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridNumber,
              childAspectRatio: 1,
            ),
            itemCount: gridNumber * gridNumber,
            itemBuilder: (context, index) {
              int row = index ~/ gridNumber;
              int col = index % gridNumber;

              return Container(
                  color: Color(int.parse('0xFF' + grid[row][col])),

              );
            },
          ),
        ),
      ],
    );
  }
}

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
                      margin: EdgeInsets.symmetric(vertical: 0.0), // 上下に8.0のマージンを追加
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Image.asset(
                            'Images/button.png',
                            width: widget.screenWidth * 0.6, // カードの幅を画面の80%に設定
                            height: widget.screenHeight * 0.08, // カードの高さを指定
                            fit: BoxFit.fill, // 画像をカードサイズに合わせる
                          ),

                          if (widget.cards[index]['open'] == 'true' || widget.cards[index]['belong'] == 'mine')
                          Positioned(
                            left: widget.screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                            top: widget.screenHeight * 0.009, // カードの上から48%下へ
                            child: Row(
                              children: [
                                Image.asset(
                                  widget.cards[index]['skill']!, // スキルの画像
                                  height: widget.screenHeight * 0.05,
                                  width: widget.screenHeight * 0.05,
                                  fit: BoxFit.contain// スキルの画像のサイズ
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
                            top: widget.screenHeight * 0.02, // カードの上から48%下へ
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
                              top: widget.screenHeight * 0.023,
                              left: widget.screenWidth * 0.45,
                                child: Image.asset(
                                  'Images/pointer.png',
                                  height: widget.screenHeight * 0.04,
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
  final List<List<String>> grid;

  MyInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.name,
    required this.rank,
    required this.point,
    required this.winPoint,
    required this.onPressed,
    required this.grid,
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
            if (grid.isNotEmpty)
            PixelGrid(screenWidth: screenWidth, screenHeight: screenHeight, grid: grid, gridNumber: 32),
            // ボタンの背景画像
            Row(
              children: [

                Expanded( // テキストが横幅を占有できるように設定
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: min((screenWidth * 0.35 / (name.length >= 5 ? name.length : 5)), screenHeight * 0.06),
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
  final List<List<String>> grid;

  EnemyInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.name,
    required this.rank,
    required this.point,
    required this.winPoint,
    required this.onPressed,
    required this.grid,
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
            if (grid.isNotEmpty)
            PixelGrid(screenWidth: screenWidth, screenHeight: screenHeight, grid: grid, gridNumber: 32),
            // ボタンの背景画像
            Row(
              children: [

                Expanded( // テキストが横幅を占有できるように設定
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: min((screenWidth * 0.35 / (name.length >= 5 ? name.length : 5)), screenHeight * 0.06),
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
  final bool isSlideViewVisible;
  final VoidCallback onToggleSlideView; // コールバック関数

  const SlideView({
    Key? key,
    required this.screenWidth,
    required this.screenHeight,
    required this.content,
    required this.isSlideViewVisible,
    required this.onToggleSlideView, // 必須パラメータに追加
  }) : super(key: key);

  @override
  _SlideViewState createState() => _SlideViewState();
}

class _SlideViewState extends State<SlideView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          top: 0,
          bottom: 0,
          left: widget.isSlideViewVisible ? 0 : -(widget.screenWidth - 30),
          width: widget.screenWidth + 30, // ボタンの幅を含めたサイズ
          child: Row(
            children: [
              // スライドビューの内容
              Container(
                width: widget.screenWidth - 30,
                color: Colors.grey.withOpacity(0.9),
                padding: EdgeInsets.all(16),
                child: widget.content,
              ),
              // スライドボタン
              GestureDetector(
                onTap: widget.onToggleSlideView, // 親ウィジェットの関数を呼び出す
                child: Container(
                  width: 30,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.isSlideViewVisible ? '<' : '>',
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
      clipBehavior: Clip.none,
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
          right: isVisible ? screenWidth * 0.36 : -screenHeight * 1, // 位置を調整
          top: -30,
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
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 20,
          top: 0,
          child: Transform.rotate(
            angle: 65 * (3.14159265359 / 180), // 45度回転
            child: SvgPicture.asset(
              'Images/$handType.svg',
              height: screenHeight * 0.18,
              width: screenHeight * 0.18,
              fit: BoxFit.contain,
            ),
          ),
        ),

        AnimatedPositioned(
          duration: Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          left: isVisible ? screenWidth * 0.4 : -screenHeight * 1, // 位置を調整
          bottom: -30 ,
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
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onScissorsSelected,
                icon: SvgPicture.asset(
                  'Images/scissor.svg',
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onPaperSelected,
                icon: SvgPicture.asset(
                  'Images/paper.svg',
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
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

class BattleHandSelection extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final VoidCallback onRockSelected;
  final VoidCallback onScissorsSelected;
  final VoidCallback onPaperSelected;

  BattleHandSelection({
    required this.screenHeight,
    required this.screenWidth,
    required this.onRockSelected,
    required this.onScissorsSelected,
    required this.onPaperSelected,
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
              IconButton(
                onPressed: onRockSelected,
                icon: SvgPicture.asset(
                  'Images/rock.svg',
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onScissorsSelected,
                icon: SvgPicture.asset(
                  'Images/scissor.svg',
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              IconButton(
                onPressed: onPaperSelected,
                icon: SvgPicture.asset(
                  'Images/paper.svg',
                  height: screenHeight * 0.07,
                  width: screenHeight * 0.07,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),

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
          '勝負する手を選べ！',
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

class SkillSelection extends StatelessWidget {
  final List<Map<String, String>> cards;
  final int battleIndex;
  final double screenHeight;
  final double screenWidth;

  SkillSelection({
    required this.cards,
    required this.battleIndex,
    required this.screenHeight,
    required this.screenWidth,
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
            '発動するスキルを選べ！！',
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.07,
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
                'Images/button.png',
                width: screenWidth * 0.6, // カードの幅を画面の80%に設定
                height: screenHeight * 0.08, // カードの高さを指定
                fit: BoxFit.fill, // 画像をカードサイズに合わせる
              ),



              Positioned(
                left: screenWidth * 0.8 * 0.15, // カードの左上から20%右へ
                top: screenHeight * 0.009, // カードの上から48%下へ
                child: Row(
                  children: [
                    Image.asset(
                       battleIndex >= 0 ? cards[battleIndex]['skill']! : 'Images/none.png', // スキルの画像
                      height: screenHeight * 0.06, // スキルの画像のサイズ
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

class CircularCountdownTimer extends StatefulWidget {
  final int initialTime; // カウントダウンの初期時間（秒）
  final double circleSize; // 円のサイズ
  final Color circleColor; // 円の色
  final Color backgroundCircleColor; // 背景の円の色

  const CircularCountdownTimer({
    Key? key,
    required this.initialTime,
    this.circleSize = 100,
    this.circleColor = Colors.blue,
    this.backgroundCircleColor = Colors.grey,
  }) : super(key: key);

  @override
  _CircularCountdownTimerState createState() => _CircularCountdownTimerState();
}

class _CircularCountdownTimerState extends State<CircularCountdownTimer> {
  late int _remainingTime;
  late double _percentage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialTime;
    _percentage = 1.0; // 初期は円がフル
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          _percentage = _remainingTime / widget.initialTime;
        } else {
          timer.cancel(); // タイマーを停止
        }
      });
    });
  }

  void _resetTimer(int newTime) {
    setState(() {
      _timer?.cancel();
      _remainingTime = newTime;
      _percentage = 1.0;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景円
        Container(
          width: widget.circleSize,
          height: widget.circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundCircleColor,
          ),
        ),
        // 時間経過に応じて小さくなる円弧
        CustomPaint(
          size: Size(widget.circleSize, widget.circleSize),
          painter: ArcPainter(
            percentage: _percentage,
            color: widget.circleColor,
          ),
        ),
        // 数字を中央に表示
        Text(
          _remainingTime > 0 ? '$_remainingTime' : 'Time Up!',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  final double percentage;
  final Color color;

  ArcPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1; // 円の線幅

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 描画する角度
    final sweepAngle = -2 * pi * percentage;

    // 円弧を描画
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 開始角度（上が0度）
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SkillListWidget extends StatelessWidget {
  final List<Map<String, String>> skills;
  final double screenHeight;
  final double screenWidth;
  final String mySkillSelect; // 現在選択されているスキルNo
  final ValueChanged<String> onSkillSelected;

  const SkillListWidget({
    Key? key,
    required this.skills,
    required this.screenHeight,
    required this.screenWidth,
    required this.mySkillSelect,
    required this.onSkillSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.5,
      width: screenWidth * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SizedBox(height: 10,),
          Text(
            '発動対象を選べ！！', // スキル名を表示
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child:
          ListView.builder(
        itemCount: skills.length,
        itemBuilder: (context, index) {
          final skill = skills[index];
          final isSelected = skill['No'] == mySkillSelect;

          return GestureDetector(
            onTap: () {
              onSkillSelected(skill['No'] ?? '');
            },
            child: Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // スキル画像
                  Image.asset(
                    'Images/${skill['No']}.png',
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 8),
                  // スキル名と説明
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            skill['name']!, // スキル名を表示
                            style: TextStyle(
                              fontFamily: 'makinas4',
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Text(
                            skill['description'] ?? '',
                            style: TextStyle(fontSize: 8, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
          ),

      ]
      ),
    );
  }
}

class HandListWidget extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final String mySkillSelect;
  final ValueChanged<String> onSkillSelected;

  const HandListWidget({
    Key? key,
    required this.screenHeight,
    required this.screenWidth,
    required this.mySkillSelect,
    required this.onSkillSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.3,
      width: screenWidth * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '相手の出す手を\n予想しろ！！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rock
              GestureDetector(
                onTap: () => onSkillSelected('rock'),
                child: Container(
                  decoration: BoxDecoration(
                    color: mySkillSelect == 'rock' ? Colors.blue[100] : Colors.transparent,
                    border: Border.all(
                      color: mySkillSelect == 'rock' ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'Images/rock.svg',
                    height: screenWidth * 0.15,
                    width: screenWidth * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Scissor
              GestureDetector(
                onTap: () => onSkillSelected('scissor'),
                child: Container(
                  decoration: BoxDecoration(
                    color: mySkillSelect == 'scissor' ? Colors.blue[100] : Colors.transparent,
                    border: Border.all(
                      color: mySkillSelect == 'scissor' ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'Images/scissor.svg',
                    height: screenWidth * 0.15,
                    width: screenWidth * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Paper
              GestureDetector(
                onTap: () => onSkillSelected('paper'),
                child: Container(
                  decoration: BoxDecoration(
                    color: mySkillSelect == 'paper' ? Colors.blue[100] : Colors.transparent,
                    border: Border.all(
                      color: mySkillSelect == 'paper' ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'Images/paper.svg',
                    height: screenWidth * 0.15,
                    width: screenWidth * 0.15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RetireWidget extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;
  final ValueChanged<bool> onSkillSelected;

  const RetireWidget({
    Key? key,
    required this.screenHeight,
    required this.screenWidth,
    required this.onSkillSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.2,
      width: screenWidth * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '諦めるんですか？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => onSkillSelected(true), // 諦めるボタン
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'Images/button.png',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      '諦める',
                      style: TextStyle(
                        fontFamily: 'makinas4',
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onSkillSelected(false), // 戦うボタン
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'Images/button.png',
                      width: screenWidth * 0.3,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      '戦う',
                      style: TextStyle(
                        fontFamily: 'makinas4',
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BattleResultView extends StatelessWidget {
  final String battleResult;
  final double screenHeight;

  BattleResultView({required this.battleResult, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: Duration(seconds: 2),
        child: _buildResultView(battleResult),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildResultView(String result) {
    switch (result) {
      case 'win':
        return Container(
          height: screenHeight * 0.4,
          color: Colors.green,
          alignment: Alignment.center,
          child: Text(
            'You Win!',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        );
      case 'lose':
        return Container(
          height: screenHeight * 0.4,
          color: Colors.red[900],
          alignment: Alignment.center,
          child: Text(
            'You Lose!',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        );
      case 'draw':
        return Container(
          height: screenHeight * 0.4,
          color: Colors.blueGrey,
          alignment: Alignment.center,
          child: Text(
            'Draw!',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        );
      case 'knock Out':
        return Container(
          height: screenHeight * 0.4,
          color: Colors.black,
          alignment: Alignment.center,
          child: Text(
            'Knock Out!',
            style: TextStyle(fontSize: 32, color: Colors.red),
          ),
        );
      default:
        return Container(
          height: screenHeight * 0.4,
          color: Colors.grey,
          alignment: Alignment.center,
          child: Text(
            'No Result',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        );
    }
  }
}

class WaveText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final Duration duration;
  final double waveHeight;

  WaveText({
    required this.text,
    this.textStyle = const TextStyle(fontSize: 50, color: Colors.black,
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

class UserInfoView extends StatelessWidget {
  final String userName;
  final String userRank;
  final String userRankJapan;
  final double userRockRate;
  final double userScissorRate;
  final double userPaperRate;
  final double userHonestRate;
  final double userWinRate;
  final List<List<String>> userIcon;
  final int userWinStreak;
  final double screenHeight;
  final double screenWidth;

  const UserInfoView({
    Key? key,
    required this.userName,
    required this.userRank,
    required this.userRankJapan,
    required this.userRockRate,
    required this.userScissorRate,
    required this.userPaperRate,
    required this.userHonestRate,
    required this.userWinRate,
    required this.userIcon,
    required this.userWinStreak,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: screenHeight * 0.6,
      width: screenWidth * 0.9,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child:
      SingleChildScrollView(
        child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PixelGrid(screenWidth: screenWidth * 0.7, screenHeight: screenHeight * 0.7, grid: userIcon, gridNumber: 32),
              Column(
                children: [
                  CustomImageButton(screenWidth: screenWidth, buttonText: '名前', onPressed: (){}),
                  Text(
                    userName,
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: (userName.length < 7) ? screenWidth * 0.055 : screenWidth * 0.045,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),

            ],
          ),

          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                height: screenWidth * 0.25,
                width: screenWidth * 0.25,
                fit: BoxFit.contain,
                'Images/$userRank.svg'
              ),
              Column(
                children: [
                  CustomImageButton(screenWidth: screenWidth, buttonText: 'ランク', onPressed: (){}),
                  Text(
                    '$userRankJapan',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.055,
                    ),
                  ),
                  Text(
                    '勝率：$userWinRate%',
                    style: TextStyle(
                      fontFamily: 'makinas4',
                      fontSize: screenWidth * 0.045,
                    ),
                  ),

                ]
              ),
            ],
          ),
          SizedBox(height: 8),
          if (userWinStreak > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageButton(screenWidth: screenWidth, buttonText: '連勝数', onPressed: (){}),
              SvgPicture.asset(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                fit: BoxFit.contain,
                'Images/skillActive.svg',
              ),
              SizedBox(width: 10),
              Text(
                '現在$userWinStreak連勝中！',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 20,),
          CustomImageButton(screenWidth: screenWidth, buttonText: '確率', onPressed: (){}),
          SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 5),
              Column(
                children: [
                  SvgPicture.asset(
                    'Images/rock.svg',
                    height: screenWidth * 0.12,
                    width: screenWidth * 0.12,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$userRockRate%',
                    style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
              Column(
                children: [
                  SvgPicture.asset(
                    'Images/scissor.svg',
                    height: screenWidth * 0.12,
                    width: screenWidth * 0.12,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$userScissorRate%',
                    style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
              Column(
                children: [
                  SvgPicture.asset(
                    'Images/paper.svg',
                    height: screenWidth * 0.12,
                    width: screenWidth * 0.12,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$userPaperRate%',
                    style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
              SizedBox(width: 5),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageButton(screenWidth: screenWidth, buttonText: '正直率', onPressed: (){}),

              Text(
                '  $userHonestRate%',
                style: TextStyle(
                  fontFamily: 'makinas4',
                  fontSize: screenWidth * 0.065,
                ),
              ),
            ],
          ),

        ],
      ),
      )
    );
  }
}

class CommentText extends StatelessWidget {
  final double screenWidth;
  final String text;
  final List<String> angryComments;
  final List<String> happyComments;
  final List<String> coolComments;
  final List<String> thinkComments;
  final List<String> chickenComments;
  final List<String> hakuryokuComments;

  const CommentText({
    Key? key,
    required this.screenWidth,
    required this.text,
    required this.angryComments,
    required this.happyComments,
    required this.coolComments,
    required this.thinkComments,
    required this.chickenComments,
    required this.hakuryokuComments,
  }) : super(key: key);



  @override

  Widget build(BuildContext context) {
    return
    Stack(
      alignment: Alignment.center,
      children: [
        if (angryComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentAngry.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: screenWidth * 0.12,
            child:
          Text(
            text,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          ),
        ],
        ),
        if (happyComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentHappy.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (coolComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(1.0, 1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentCool.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          bottom: screenWidth * 0.04,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (thinkComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentThink.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          bottom: screenWidth * 0.1,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (chickenComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(1.0, 1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentChicken.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          bottom: screenWidth * 0.13,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (hakuryokuComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          SvgPicture.asset(
          'Images/commentHakuryoku.svg',
          width: screenWidth * 0.24,
          fit: BoxFit.contain,
        ),
        Positioned(
          bottom: screenWidth * 0.048,
          child:
        Text(
          text,
          style: TextStyle(
            fontSize: screenWidth * 0.1,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
      ],
    );
  }
}


class EnemyCommentText extends StatelessWidget {
  final double screenWidth;
  final String text;
  final List<String> angryComments;
  final List<String> happyComments;
  final List<String> coolComments;
  final List<String> thinkComments;
  final List<String> chickenComments;
  final List<String> hakuryokuComments;

  const EnemyCommentText({
    Key? key,
    required this.screenWidth,
    required this.text,
    required this.angryComments,
    required this.happyComments,
    required this.coolComments,
    required this.thinkComments,
    required this.chickenComments,
    required this.hakuryokuComments,
  }) : super(key: key);



  @override

  Widget build(BuildContext context) {

    return
    Stack(
      alignment: Alignment.center,
      children: [
        if (angryComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(1.0, -1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentAngry.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: screenWidth * 0.12,
            child:
          Text(
            text,
            style: TextStyle(
              fontFamily: 'makinas4',
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          ),
        ],
        ),
        if (happyComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(1.0, -1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentHappy.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (coolComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, -1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentCool.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          bottom: screenWidth * 0.04,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (thinkComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(1.0, -1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentThink.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          top: screenWidth * 0.1,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (chickenComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, -1.0), // X軸を反転
            child: SvgPicture.asset(
              'Images/commentChicken.svg',
              width: screenWidth * 0.4,
              fit: BoxFit.contain,
            ),
          ),
        Positioned(
          top: screenWidth * 0.13,
          child:
        Text(
          text,
          style: TextStyle(
            fontFamily: 'makinas4',
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
         if (hakuryokuComments.contains(text))
        Stack(
          alignment: Alignment.center,
          children: [
          SvgPicture.asset(
          'Images/commentHakuryoku.svg',
          width: screenWidth * 0.24,
          fit: BoxFit.contain,
        ),
        Positioned(
          bottom: screenWidth * 0.048,
          child:
        Text(
          text,
          style: TextStyle(
            fontSize: screenWidth * 0.1,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        ),
        ],
        ),
      ],
    );
  }
}

class AnimatedBattleResultUI extends StatefulWidget {
  final String battleResult; // 'win' または 'lose'
  final String myRank;
  final int myLevel;
  final int myLevelExp;
  final int myRankCount;
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onPressed;

  AnimatedBattleResultUI({
    required this.battleResult,
    required this.myRank,
    required this.myLevel,
    required this.myLevelExp,
    required this.myRankCount,
    required this.screenHeight,
    required this.screenWidth,
    required this.onPressed,
  });

  @override
  _AnimatedBattleResultUIState createState() => _AnimatedBattleResultUIState();
}

class _AnimatedBattleResultUIState extends State<AnimatedBattleResultUI> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _expAnimation;
  late Animation<int> _rankAnimation;

  late int level;
  late int levelExp;
  late int rankCount;
  late String rank;


  int oldLevel = 0;
  String oldRank = 'ブロンズ1';
  int oldRankIndex = 0;

  bool levelUpState = false;
  bool rankUpState = false;
  bool rankDownState = false;
  List<String> rankList = [
    'ブロンズ1', 'ブロンズ2', 'ブロンズ3',
    'シルバー1', 'シルバー2', 'シルバー3',
    'ゴールド1', 'ゴールド2', 'ゴールド3',
    'プラチナ1', 'プラチナ2', 'プラチナ3',
    'ダイヤ1', 'ダイヤ2', 'ダイヤ3',
    'エリート1', 'エリート2', 'エリート3',
    'マスター1', 'マスター2', 'マスター3',
    'チャンプ1', 'チャンプ2', 'チャンプ3',
  ];
  List<String> rankListEnglish = [
    'bronze1', 'bronze2', 'bronze3',
    'silver1', 'silver2', 'silver3',
    'gold1', 'gold2', 'gold3',
    'platina1', 'platina2', 'platina3',
    'diamond1', 'diamond2', 'diamond3',
    'elite1', 'elite2', 'elite3',
    'master1', 'master2', 'master3',
    'champion1', 'champion2', 'champion3',
  ];
  int rankIndex = 0;
  bool returnButton = false;

  @override
  void initState() {
    super.initState();
    level = widget.myLevel;
    oldLevel = level;
    levelExp = widget.myLevelExp;
    rankCount = widget.myRankCount;
    rank = widget.myRank;
    oldRank = widget.myRank;
    for (int i = 0; i < rankList.length; i++) {
      if (rank == rankList[i]){
        rankIndex = i;
        oldRankIndex = i;
      }
    }

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _expAnimation = IntTween(begin: levelExp, end: levelExp).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _rankAnimation = IntTween(begin: rankCount, end: rankCount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // バトル結果を処理してアニメーション設定
    _processBattleResult();

    // アニメーションを開始
    _controller.forward();

    _controller.forward().whenComplete(() {
      print('result process finish!');
      saveInfo();
      setState(() {
        returnButton = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _processBattleResult() async{
    int earnedExp = _calculateEarnedExp(widget.battleResult);
    int earnedRankPoints = _calculateEarnedRankPoints(widget.myRank, widget.battleResult);

    int finalExp = levelExp + earnedExp;
    int finalRankCount = rankCount + earnedRankPoints;


    // レベルアップ処理
    while (finalExp >= _requiredExpForLevelUp(level)) {
      setState(() {
        levelUpState = true;
      });
      finalExp -= _requiredExpForLevelUp(level);
      level++;
    }

    // ランクアップ処理
    while (finalRankCount >= 100) {
      setState(() {
        rankUpState = true;
      });
      if (rankIndex < rankList.length - 1) {
        finalRankCount -= 100;
        rankIndex++;
        rank = rankList[rankIndex];
      }
    }

    //ランクダウン処理
    while (finalRankCount < 0) {
      setState(() {
        rankDownState = true;
      });
      if (rankIndex < rankList.length - 1) {
        finalRankCount += 100;
        rankIndex--;
        rank = rankList[rankIndex];
      }
    }

    await _updateRankCountInFirebase(oldRank, rank);

    // アニメーション範囲設定
    _expAnimation = IntTween(begin: levelExp, end: finalExp).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rankAnimation = IntTween(begin: rankCount, end: finalRankCount).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    levelExp = finalExp;
    rankCount = finalRankCount;
  }

  Future<void> _updateRankCountInFirebase(String oldRank, String newRank) async {
    try {
      final populationRef = FirebaseFirestore.instance.collection('population').doc('rank');
      final rankFields = [
        'bronze',
        'silver',
        'gold',
        'platina',
        'diamond',
        'elite',
        'master',
        'champion',
      ];

      // 古いランクを減算
      if (rankFields.contains(_rankPrefix(_rankToEnglish(oldRank)))) {
        await populationRef.update({
          _rankPrefix(_rankToEnglish(oldRank)): FieldValue.increment(-1),
        });
      }

      // 新しいランクを加算
      if (rankFields.contains(_rankPrefix(_rankToEnglish(newRank)))) {
        await populationRef.update({
          _rankPrefix(_rankToEnglish(newRank)): FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Failed to update rank count in Firebase: $e');
    }
  }

  String _rankToEnglish(String rank) {
    final index = rankList.indexOf(rank);
    if (index != -1) {
      return rankListEnglish[index];
    }
    return '';
  }

  String _rankPrefix(String rank) {
    // ランク名から接頭辞を抽出
    final match = RegExp(r'^[^\d]+').firstMatch(rank);
    return match?.group(0) ?? '';
  }

  int _calculateEarnedExp(String result) {
    if (result == 'win') {
      return 200; // 勝利時のポイント
    } else if (result == 'knockOut') {
      return 500;
    } else if (result == 'draw') {
      return 100; // 勝利時のポイント
    } else if (result == 'lose') {
      return 50;
    } else {
      return 0;
    }
  }

  int _calculateEarnedGachaPoint(String result) {
    if (result == 'win') {
      return 500; // 勝利時のポイント
    } else if (result == 'knockOut') {
      return 1000;
    } else if (result == 'draw') {
      return 300; // 勝利時のポイント
    } else if (result == 'lose') {
      return 0;
    } else {
      return 0;
    }
  }


  int _calculateEarnedRankPoints(String rank, String result) {
    if (result == 'win') {
      return 30; // 勝利時のポイント
    } else if (result == 'knockOut') {
      return 50;
    } else if (result == 'lose') {
      // 敗北時のランクに応じたポイント減少
      if (rank == 'ブロンズ1'){
        return 0;
      } else if (rank.contains('ブロンズ')) {
        return -5;
      } else if (rank.contains('シルバー')) {
        return -7;
      } else if (rank.contains('ゴールド')) {
        return -10;
      } else if (rank.contains('プラチナ')) {
        return -15;
      } else if (rank.contains('ダイヤ')) {
        return -20;
      } else if (rank.contains('エリート')) {
        return -25;
      } else if (rank.contains('マスター')) {
        return -25;
      } else if (rank.contains('チャンプ')) {
        return -30;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

  int _requiredExpForLevelUp(int currentLevel) {
    return (5 * pow(currentLevel, 1.5).round()) + 200;
  }

  void saveInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('saveInfo!');
    await prefs.setInt('myGachaPoint', (prefs.getInt('myGachaPoint') ?? 0) + _calculateEarnedGachaPoint(widget.battleResult));
    await prefs.setString('myRank', rankListEnglish[rankIndex]); // 現在のランク
    await prefs.setInt('myRankCount', rankCount); // 現在のランクポイント
    await prefs.setInt('myLevel', level); // 現在のレベル
    await prefs.setInt('myLevelExp', levelExp); // 現在の経験値
    await prefs.setInt('myTrophy', (prefs.getInt('myTrophy') ?? 0) + _calculateEarnedRankPoints(rank, widget.battleResult));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (returnButton)
            CustomImageButton(screenWidth: widget.screenWidth, buttonText: '戻る', onPressed: () {widget.onPressed();}),
        if (rankUpState)
        Text('ランクアップ！', style: TextStyle(fontSize: 16, fontFamily: 'makinas4')),
        if (rankDownState)
        Text('ランクダウン...', style: TextStyle(fontSize: 16, fontFamily: 'makinas4')),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                SvgPicture.asset(
                  'Images/${rankListEnglish[oldRankIndex]}.svg',
                  height: widget.screenHeight * 0.1,
                ),
                Text(oldRank, style: TextStyle(fontSize: 16, fontFamily: 'makinas4')),
              ],
            ),
            if (rankDownState || rankUpState)
            Text('→'),
            if (rankDownState || rankUpState)
            Column(
              children: [
                SvgPicture.asset(
                  'Images/${rankListEnglish[rankIndex]}.svg',
                  height: widget.screenHeight * 0.1,
                ),
                Text(rank, style: TextStyle(fontSize: 16, fontFamily: 'makinas4')),
              ],
            ),
          ],
        ),

        AnimatedBuilder(
          animation: _rankAnimation,
          builder: (context, child) {
            return Text(
              'ランクポイント: ${_rankAnimation.value} / 100 (${_calculateEarnedRankPoints(widget.myRank, widget.battleResult) > 0 ? '+${_calculateEarnedRankPoints(widget.myRank, widget.battleResult)}': _calculateEarnedRankPoints(widget.myRank, widget.battleResult)})',
              style: TextStyle(fontSize: 16, fontFamily: 'makinas4'),
            );
          },
        ),

        SizedBox(height: 20,),
        Row( //レベルと経験値のビュー
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (levelUpState)
                Text(
                  'Level UP! $oldLevel → レベル$level',
                  style: TextStyle(fontSize: 16, fontFamily: 'makinas4'),
                ),
                if (!levelUpState)
                Text(
                  '現在レベル$level',
                  style: TextStyle(fontSize: 16, fontFamily: 'makinas4'),
                ),
            AnimatedBuilder(
              animation: _expAnimation,
              builder: (context, child) {
                // アニメーション値と進捗を計算
                int currentExp = _expAnimation.value.toInt();
                double progress = currentExp / _requiredExpForLevelUp(level).toDouble();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(alignment: Alignment.center,
                    children: [
                      Container(
                        height: 16,
                        width: widget.screenWidth * 0.65, // 必ず幅を固定
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: (progress.clamp(0.0, 1.0)) * widget.screenWidth * 0.65, // 親幅の80%を最大
                            decoration: BoxDecoration(
                              color: Colors.blue, // 経験値バーの色
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '$currentExp  / ${_requiredExpForLevelUp(level)} exp',
                        style: TextStyle(fontSize: 16, fontFamily: 'makinas4'),
                      ),
                    ],
                    ),
                    Text(
                      ' +${_calculateEarnedExp(widget.battleResult)}exp',
                      style: TextStyle(fontSize: widget.screenWidth * 0.04, fontFamily: 'makinas4'),
                    ),

                  ],
                );
              },
            ),
            Row(
              children: [
                Icon(
                  Icons.military_tech, // 条件に応じて変更可能
                  size: (widget.screenHeight * 0.04), // 大きさを指定
                  color: Colors.black, // 必要に応じて色を指定
                ),
                Text('+${_calculateEarnedGachaPoint(widget.battleResult)}枚', style: TextStyle(fontFamily: 'makinas4', fontSize: widget.screenHeight * 0.025),),
                Image.asset('Images/trophy.png', width: widget.screenWidth * 0.13,),
                Text(_calculateEarnedRankPoints(rank, widget.battleResult) > 0 ?  '+${_calculateEarnedRankPoints(rank, widget.battleResult)}' : '${_calculateEarnedRankPoints(rank, widget.battleResult)}', style: TextStyle(fontSize: widget.screenHeight * 0.03, fontFamily: 'makinas4'),)
              ],
            ),


              ]
            ),
          ]
        ),
      ],
    );
  }
}

/*変更点書き出し

241214  お互いのカードリストビューを表示できるのはnowSceneIndexが-1以外の時だけ→ 実行済

241216 skillOpenWait,battleOpenWait, declareOpenWaitを加えて確実に相手の情報を取れるようにした。。→実装済み
241216 相手、自分の情報（勝率など）をスクロールにした。→実装済み
241216 宣言オープンで背景と被らないようにした→実装済み
241216 各時間を変更タイマーも変更

241229 対戦記録を記録する関数を実装 void updateLogsで実装





*/