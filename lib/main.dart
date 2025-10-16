import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter_application_1/State/mainState.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flame/game.dart';  // GameWidgetを提供するパッケージ
import 'package:flame_forge2d/flame_forge2d.dart';  // Forge2Dエンジンのためのパッケージ


// 各画面をインポート
import 'Screen/IconBoardScreen.dart';
import 'Screen/LoadingScreen.dart';
import 'Screen/OnlineBattleScreen.dart';
import 'Screen/FriendBattleScreen.dart';
import 'Screen/SkillScreen.dart';
import 'Screen/DataScreen.dart';
import 'Screen/BattleScreen.dart';
import 'Screen/StudyScreen.dart';
import 'Screen/WinScreen.dart';
import 'Screen/LoseScreen.dart';
import 'Screen/DrawScreen.dart';
import 'Screen/NameInputScreen.dart';
import 'Screen/MenuScreen.dart';
import 'Screen/OptionScreen.dart';
import 'Screen/SignUpScreen.dart';
import 'Screen/AdLookScreen.dart';
import 'Screen/RankingScreen.dart';
import 'Screen/PurchaseScreen.dart';
import 'Screen/TutorialBattleScreen.dart';
import 'Screen/FakeSpeedBattleScreen.dart';
import 'Screen/FakeStrategyBattleScreen.dart';
import 'Screen/FakeRandomBattleScreen.dart';
import 'Screen/RealSpeedBattleScreen.dart';
import 'Screen/RealStrategyBattleScreen.dart';
import 'Screen/RealRandomBattleScreen.dart';
import 'Screen/IDLoginScreen.dart';
import 'Screen/MiniGameScreen.dart';
import 'Screen/MasFillScreen.dart';
import 'Screen/BoardScreen.dart';
import 'Screen/JankenScreen.dart';
import 'Screen/MakeSoundScreen.dart';
import 'Screen/MakeIconScreen.dart';
import 'Screen/BlockBreakScreen.dart';

import 'Screen/StartScreen.dart';


List<String> routePass = [];
String uid = ''; //firebaseのユーザーID

//battle用関数
String battleRoomType = 'strategy';//戦いの部屋タイプ　コレクションに相当
String battleRoomName = 'rooma1'; //戦いの部屋番号　ドキュメントに相当
int battlePlayerNumber = 1;
List<Map<String, String>> skills = [
    {'No': 'No1', 'name': '硬い拳', 'description': '発動条件：グーで勝つ\n効果：自分に+30pt', 'quest': 'レベル5以上'}, //+++
    {'No': 'No2', 'name': '硬い掌', 'description': '発動条件：パーで勝つ\n効果：自分に+30pt', 'quest': 'レベル5以上'},//+++
    {'No': 'No3', 'name': '硬い指', 'description': '発動条件：チョキで勝つ\n効果：自分に+30pt', 'quest': 'レベル5以上'},//+++
    {'No': 'No4', 'name': '相打ちの極意', 'description': '発動条件：あいこになる\n効果：相手に-20pt', 'quest': 'レベル5以上'},//---
    {'No': 'No5', 'name': '拳砕き', 'description': '発動条件：相手がグーを出す\n効果：相手に-20pt', 'quest': 'レベル5以上'},//---
    {'No': 'No6', 'name': '掌破り', 'description': '発動条件：相手がパーを出す\n効果：相手に-20pt', 'quest': 'レベル5以上'},//---
    {'No': 'No7', 'name': '刀折り', 'description': '発動条件：相手がチョキを出す\n効果：相手に-20pt', 'quest': 'レベル5以上'},//---
    {'No': 'No8', 'name': '連勝ボーナス', 'description': '発動条件：発動ターンで最低でも２連勝している\n効果：連勝数かける+10ptを自分に加える', 'quest': 'レベル5以上'},//+++
    {'No': 'No9', 'name': '救済措置', 'description': '発動条件：発動ターンで最低でも2連敗している\n効果：連敗数かける+10ptを自分に加える', 'quest': 'レベル5以上'},//+++
    {'No': 'No10', 'name': '平和主義', 'description': '発動条件：発動ターンであいこが最低でも2回続いている\n効果：あいこの連続回数かける+10ptを自分に加える', 'quest': 'レベル5以上'},//+++
    {'No': 'No11', 'name': '宣教師', 'description': '発動条件：宣言した手で勝つ\n効果：自分に+30pt', 'quest': 'レベル5以上'},//+++
    {'No': 'No12', 'name': 'ライアー', 'description': '発動条件：宣言した手以外で勝つ\n効果：相手に-30pt', 'quest': 'レベル5以上'}, // ---
    {'No': 'No13', 'name': '不幸中の幸い', 'description': '発動条件：発動ターンで３連続で負ける\n効果：相手に-70pt', 'quest': 'レベル5以上'},//---
    {'No': 'No14', 'name': '追い風', 'description': '発動条件：発動ターンで３連続で勝つ\n効果：自分に+50pt', 'quest': 'レベル5以上'},//+++
    {'No': 'No15', 'name': '均衡崩壊', 'description': '発動条件：あいこかつ宣言とは違う手を出す\n効果：無理やりあいこを勝利にしてしまう。（ユーザー様考案）', 'quest': 'レベル5以上'},
    /*Random*/{'No': 'No16', 'name': 'ギャンブラー', 'description': '発動条件：場に出す\n効果：自分に0~+40ptが加算されるか、相手に0~-30ptのダメージを与えられる。稀に自分が-30ptされる。', 'quest': 'レベル7以上'},//+++---
    {'No': 'No17', 'name': '会心の一撃', 'description': '発動条件：勝つこと\n効果：貰えるポイントが２倍される', 'quest': 'レベル7以上'},//+++
    {'No': 'No18', 'name': '不変の意志', 'description': '発動条件：発動ターンで最低でも2回以上同じ手を出し続ける\n効果：連続して同じ手を出した回数かける+10pt自分に加わる。', 'quest': 'レベル7以上'},//+++
    {'No': 'No19', 'name': '疾風怒濤', 'description': '発動条件：開始2ROUNDの間に宣言通りの手を出す\n効果：相手に-20pt', 'quest': 'レベル7以上'}, // ---
    {'No': 'No20', 'name': '不屈の闘志', 'description': '発動条件：相手よりもptが少ない時に勝つ\n効果：相手に-30pt', 'quest': 'レベル7以上'}, //自分に+30 => 相手に-30---
    {'No': 'No21', 'name': '冥土の土産', 'description': '発動条件：勝ったとき\n効果：自分の宣言ポイントの分だけ相手の点数を減らすが、自分には宣言ポイントの分は入らない。', 'quest': 'レベル10以上'},//---
    /*option*/{'No': 'No22', 'name': '預言者', 'description': '発動条件：相手の出す手を当てる\n効果：相手に-30pt', 'quest': 'レベル10以上'},// 自分に＋３0 => 相手に-30---
    {'No': 'No23', 'name': '超アーマー', 'description': '発動条件：負けたとき\n効果：そのROUNDの負けを無効化。そのROUNDの負けた分のポイントが返ってくる。スキルによる効果は貫通してしまう。', 'quest': 'レベル10以上'},
    /*Random*/{'No': 'No24', 'name': '縛りプレイ', 'description': '発動条件：場に出す\n効果：相手のカードをランダムで1つだけスキルのみを強制的に無効化', 'quest': 'レベル10以上'},
    {'No': 'No25', 'name': '痛み分け', 'description': '発動条件：負けたとき\n効果：宣言した手を出した場合は、-20ptと宣言ポイントを相手と半分こ。宣言した手を出していない場合は-20ptを相手と半分こ', 'quest': 'レベル10以上'}, //---
    {'No': 'No26', 'name': '収益停止', 'description': '発動条件：負けたとき\n効果：相手が勝っても相手には宣言ポイントの分は入らない', 'quest': 'レベル12以上'},
    /*option*/{'No': 'No27', 'name': '読心術', 'description': '発動条件：相手の発動するスキルを当てる\n効果：自分に+50pt', 'quest': 'レベル12以上'},//+++
    /*Random*/{'No': 'No28', 'name': '変幻自在', 'description': '発動条件：場に出す\n効果：相手のスキルをランダムで一つだけ違うスキルにランダムに変化させる。', 'quest': 'レベル12以上'},
    /*Random*/{'No': 'No29', 'name': 'ミストラル', 'description': '発動条件：場に出す\n効果：何が起こるかは誰にもわからない。基本的には発動者にとって得なことしか起こらないはずだが、', 'quest': 'レベル12以上'},
    {'No': 'No30', 'name': 'スキル封印', 'description': '発動条件：場に出す\n効果：そのターンに発動する相手のスキルを無効化', 'quest': 'レベル12以上'},
    /*Random*/{'No': 'No31', 'name': '自由奔放', 'description': '発動条件：場に出す\n効果：未使用でかつオープンされている相手のスキルをランダムで一つ違うスキルに変えてしまう。', 'quest': 'レベル15以上'},
    /*Random*/{'No': 'No32', 'name': '貿易の興り', 'description': '発動条件：場に出す\n効果：自分の未使用のスキルと相手の未使用のスキルをランダムで1つ交換する。', 'quest': 'レベル15以上'},
    /*Random*/{'No': 'No33', 'name': '秘密の共有', 'description': '発動条件：3Round以降に場に出す\n効果：相手の未オープン未使用のカードの枚数かける5pt相手にダメージを与える。最大30pt。', 'quest': 'レベル15以上'}, //自分と相手のカードをランダムで1つオープンしてしまう。 => 相手の未オープン、未使用の枚数かける5pt相手に---未使用は含まない。
    /*Random*/{'No': 'No34', 'name': 'かくれんぼ', 'description': '発動条件：場に出す\n効果：自分のオープンしているカードを最大3枚隠してしまう。', 'quest': 'レベル15以上'},
    {'No': 'No35', 'name': 'でしゃばり', 'description': '発動条件：手札にある\n効果：このカードは必ず最初のターンにオープンされる。', 'quest': 'レベル15以上'},
    {'No': 'No36', 'name': '公開処刑', 'description': '発動条件：場に出す\n効果：オープンされていて未使用のカードの数かける+5ptされる。', 'quest': 'レベル20以上'},//+++
    {'No': 'No37', 'name': '羞恥心', 'description': '発動条件：オープンされていない状態で出すこと\n効果：相手に-20pt', 'quest': 'レベル20以上'},//--- //条件　オープンされていない状態で出すこと 自分に+30 => 相手に-20
    {'No': 'No38', 'name': '露出狂', 'description': '発動条件：オープンされた状態で出すこと\n効果：自分に+15pt', 'quest': 'レベル20以上'}, //+++ //条件　オープンされた状態で出すこと 自分に+30 => +15
    /*Random*/{'No': 'No39', 'name': 'リバイバル', 'description': '発動条件：場に出すこと\n効果：使用済みの自分のカードをランダムで一枚復活させる', 'quest': 'レベル20以上'},
    /*option*/{'No': 'No40', 'name': '存在抹消', 'description': '発動条件：オープンされていない相手のカードのスキルを当てる\n効果：当てた相手のスキルの効果を消してしまう。', 'quest': 'レベル20以上'},
    {'No': 'No41', 'name': '嘘は嫌い', 'description': '発動条件：自分は宣言通りの手を出して、相手が宣言されていない手を出したとき\n効果：相手に-30pt', 'quest': 'レベル25以上'}, //---
    {'No': 'No42', 'name': '真実の加護', 'description': '発動条件：宣言通りの手を出す\n効果：自分に+15pt', 'quest': 'レベル25以上'},//+++
    {'No': 'No43', 'name': '生命保険', 'description': '発動条件：勝つこと\n効果：今までに負けた回数かける+15ptを自分に加える', 'quest': 'レベル25以上'},//+++
    /*Random*/{'No': 'No44', 'name': '墓荒らし', 'description': '発動条件：場に出すこと\n効果：相手の使用済みのカードをランダムで一枚復活させて自分の手札に加えてしまう。', 'quest': 'レベル25以上'},
    {'No': 'No45', 'name': '初志貫徹', 'description': '発動条件：今までのターンで宣言とは違う手を出していない。発動ターンに限り宣言と違う手を出しても良い。\n効果：宣言通りの手を出せば自分にターン数かける+10pt、宣言通りの手でない場合はターン数かける+5ptを自分に加える。', 'quest': 'レベル25以上'}, //+++
    {'No': 'No46', 'name': 'インフレ防止', 'description': '発動条件：場に出すこと\n効果：自分と相手の点数を-30ptする。', 'quest': 'レベル30以上'},//---
    /*Random*/{'No': 'No47', 'name': 'カオス', 'description': '発動条件：場に出すこと\n効果：相手と自分の使用済みスキルを復活させて自分と相手のカードをシャッフルしてしまう。', 'quest': 'レベル30以上'},
    /*Random*/{'No': 'No48', 'name': '盗人の極意', 'description': '発動条件：場に出すこと\n効果：現在のターン数に応じて相手のスキルをランダムで奪ってしまう。ただし、使用済みのスキルは奪っても使えない。1ターン目は１枚のみ、2,3ターン目は２枚、4ターン目以降は３枚奪える。', 'quest': 'レベル30以上'},
    {'No': 'No49', 'name': '過去の回想', 'description': '発動条件：現在のラウンドが3以上であること\n効果：自分と相手の使用済みのスキルを全て復活させてしまい、未使用のスキルを全て使用済みにしてしまう。', 'quest': 'レベル30以上'},
    {'No': 'No50', 'name': '人生革命', 'description': '発動条件：相手よりptが低く、現在のラウンドが3以下であること\n効果：相手には「キングカード」、自分には「革命カード」が配布される。\n キングカード：相手が「革命カード」を出さなければ、「キングカード」を出すだけで+30ptがもらえる。しかし、「キングカード」は5ラウンド目終了時に持っていると負けが確定する。\n革命カード：相手が「キングカード」を出した時に「革命カード」を出せば+100ptもらえる。', 'quest': 'レベル30以上'},
  ];



//version確認用
String version = '0.0.25';

//icon掲示板用
String nowPost = 'makeIcon';

bool loginState = false;
void main() async {
  // Firebaseの初期化に必要な設定
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAppState()),
        ChangeNotifierProvider(create: (context) => LoginStateNotifier()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  MyApp({super.key});

  final GoRouter router = GoRouter(
  initialLocation: '/load',
  routes: <RouteBase>[
    GoRoute(
      path: '/load',
      builder: (BuildContext context, GoRouterState state) {
        return LoadingScreen();
      },

    ),
    GoRoute(
      path: '/onlineBattle',
      builder: (BuildContext context, GoRouterState state) {
        return OnlineBattleScreen();
      },

    ),
    GoRoute(
      path: '/friendBattle',
      builder: (BuildContext context, GoRouterState state) {
        return FriendBattleScreen();
      },
    ),
    GoRoute(
      path: '/skill',
      builder: (BuildContext context, GoRouterState state) {
        return SkillScreen();
      },
    ),
    GoRoute(
      path: '/data',
      builder: (BuildContext context, GoRouterState state) {
        return DataScreen();
      },
    ),
    GoRoute(
      path: '/battle',
      builder: (BuildContext context, GoRouterState state) {
        return BattleScreen();
      },
    ),
    GoRoute(
      path: '/win',
      builder: (BuildContext context, GoRouterState state) {
        return WinScreen();
      },
    ),
    GoRoute(
      path: '/lose',
      builder: (BuildContext context, GoRouterState state) {
        return LoseScreen();
      },
    ),
    GoRoute(
      path: '/draw',
      builder: (BuildContext context, GoRouterState state) {
        return DrawScreen();
      },
    ),
    GoRoute(
      path: '/nameInput',
      builder: (BuildContext context, GoRouterState state) {
        return NameInputScreen();
      },
    ),
    GoRoute(
      path: '/menu',
      builder: (BuildContext context, GoRouterState state) {
        return MenuScreen();
      },
    ),
    GoRoute(
      path: '/option',
      builder: (BuildContext context, GoRouterState state) {
        return OptionScreen();
      },
    ),
    GoRoute(
      path: '/signUp',
      builder: (BuildContext context, GoRouterState state) {
        return SignUpScreen();
      },
    ),
    GoRoute(
      path: '/ad',
      builder: (BuildContext context, GoRouterState state) {
        return AdLookScreen();
      },
    ),
    GoRoute(
      path: '/ranking',
      builder: (BuildContext context, GoRouterState state) {
        return RankingScreen();
      },
    ),
    GoRoute(
      path: '/purchase',
      builder: (BuildContext context, GoRouterState state) {
        return PurchaseScreen();
      },
    ),
    GoRoute(
      path: '/tutorialBattle',
      builder: (BuildContext context, GoRouterState state) {
        return TutorialBattleScreen();
      },
    ),
    GoRoute(
      path: '/realSpeedBattle',
      builder: (BuildContext context, GoRouterState state) {
        return RealSpeedBattleScreen();
      },
    ),
    GoRoute(
      path: '/fakeSpeedBattle',
      builder: (BuildContext context, GoRouterState state) {
        return FakeSpeedBattleScreen();
      },
    ),
    GoRoute(
      path: '/realStrategyBattle',
      builder: (BuildContext context, GoRouterState state) {
        return RealStrategyBattleScreen();
      },
    ),
    GoRoute(
      path: '/fakeStrategyBattle',
      builder: (BuildContext context, GoRouterState state) {
        return FakeStrategyBattleScreen();
      },
    ),
    GoRoute(
      path: '/realRandomBattle',
      builder: (BuildContext context, GoRouterState state) {
        return RealRandomBattleScreen();
      },
    ),
    GoRoute(
      path: '/fakeRandomBattle',
      builder: (BuildContext context, GoRouterState state) {
        return FakeRandomBattleScreen();
      },
    ),
    GoRoute(
      path: '/IDLogin',
      builder: (BuildContext context, GoRouterState state) {
        return IDLoginScreen();
      },
    ),
    GoRoute(
      path: '/miniGame',
      builder: (BuildContext context, GoRouterState state) {
        return MiniGameScreen();
      },
    ),
    GoRoute(
      path: '/masFill',
      builder: (BuildContext context, GoRouterState state) {
        return MasFillScreen();
      },
    ),
    GoRoute(
      path: '/janken',
      builder: (BuildContext context, GoRouterState state) {
        return JankenScreen();
      },
    ),
    GoRoute(
      path: '/makeSound',
      builder: (BuildContext context, GoRouterState state) {
        return MakeSoundScreen();
      },
    ),
    GoRoute(
      path: '/makeIcon',
      builder: (BuildContext context, GoRouterState state) {
        return MakeIconScreen();
      },
    ),
    GoRoute(
      path: '/IconBoard',
      builder: (BuildContext context, GoRouterState state) {
        return IconBoardScreen();
      },
    ),
    GoRoute(
      path: '/study',
      builder: (BuildContext context, GoRouterState state) {
        return StudyScreen();
      },
    ),
    GoRoute(
      path: '/blockBreak',
      builder: (BuildContext context, GoRouterState state) {
        return BlockBreakScreen();
      },
    ),
    GoRoute(
      path: '/board',
      builder: (BuildContext context, GoRouterState state) {
        return BoardScreen();
      },
    ),
  ],
);


  Future<InitializationStatus> _initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }


  @override
  Widget build(BuildContext context) {
    // return ChangeNotifierProvider(
    //   // MyAppStateをProviderで管理
    //   create: (context) => MyAppState(),
    //   child: MaterialApp(
    //     title: 'Namer App',
    //     theme: ThemeData(
    //       useMaterial3: true,
    //       colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
    //     ),

    //   ),
    // );
    return MaterialApp.router(
      // ルーターからの情報を元にアプリケーションのルーティングを行う
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(80, 0, 1, 33)), // テーマの色をブルーに設定
    ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

enum ViewIdentifier {
  load,
  onlineBattle,
  friendBattle,
  skill,
  data,
  battle,
  realBattle,
  win,
  lose,
  draw,
  nameInput,
  menu,
  option,
  signUp,
  ad,
  ranking,
  purchase,
  fakeBattle,
  IDLogin,
}

void removeLastRouteAndNavigate(BuildContext context, List<String> routePass) {
  if (routePass.isNotEmpty) {
    print(routePass.join(', '));
    routePass.removeLast(); // 末尾のルートを削除
  }

  if (routePass.isNotEmpty) {
    String lastRoute = routePass.last;
    print(lastRoute); // 残った末尾のルートを取得
    context.go(lastRoute); // go_routerで移動
  }
}







